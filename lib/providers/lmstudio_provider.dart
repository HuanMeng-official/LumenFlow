import 'dart:convert';
import 'dart:async';
import 'dart:io';
import 'package:flutter/cupertino.dart';
import 'package:http/http.dart' as http;
import 'ai_provider.dart';
import '../models/message.dart';
import '../models/attachment.dart';
import '../services/file_service.dart';
import '../services/settings_service.dart';
import '../l10n/app_localizations.dart';

/// LM-Studio Provider 实现
class LMStudioProvider extends AIProvider {
  final SettingsService _settingsService = SettingsService();
  final FileService _fileService = FileService();

  /// 超时配置
  static const Duration connectionTimeout = Duration(seconds: 30);
  static const Duration readTimeout = Duration(seconds: 60);
  static const Duration streamingTimeout = Duration(minutes: 5);

  /// 重试配置
  static const int maxRetries = 3;
  static const int retryBaseDelayMs = 1000;
  static const int retryMaxDelayMs = 10000;

  @override
  Future<Map<String, dynamic>> sendMessage({
    required String message,
    required List<Message> chatHistory,
    required List<Attachment> attachments,
    required String systemPrompt,
    required double temperature,
    required int maxTokens,
    bool thinkingMode = false,
    required AppLocalizations l10n,
  }) async {
    return await _executeWithRetry<Map<String, dynamic>>(
      () async {
        final client = _createHttpClient();
        try {
          final apiEndpoint = await _settingsService.getApiEndpoint();
          final apiKey = await _settingsService.getApiKey();
          final model = await _settingsService.getModel();
          final enableHistory = await _settingsService.getEnableHistory();
          final historyContextLength =
              await _settingsService.getHistoryContextLength();

          // 构建响应API的请求体
          final requestBody = <String, dynamic>{
            'model': model,
            'max_output_tokens': maxTokens,
            'temperature': temperature,
          };

          // 添加系统提示词作为instructions
          if (systemPrompt.isNotEmpty) {
            requestBody['instructions'] = systemPrompt;
          }

          // 构建input字段
          final input = await _buildInput(
            message: message,
            chatHistory: chatHistory,
            attachments: attachments,
            enableHistory: enableHistory,
            historyContextLength: historyContextLength,
            l10n: l10n,
          );
          requestBody['input'] = input;

          // 添加推理配置
          if (thinkingMode) {
            requestBody['reasoning'] = {'effort': 'medium', 'summary': 'auto'};
          }

          final response = await client.post(
            Uri.parse('$apiEndpoint/responses'),
            headers: {
              'Content-Type': 'application/json',
              'Authorization': 'Bearer $apiKey',
            },
            body: jsonEncode(requestBody),
          ).timeout(connectionTimeout + readTimeout);

          if (response.statusCode == 200) {
            return _parseResponse(response.body, l10n);
          } else {
            throw _parseError(response.body, response.statusCode, l10n);
          }
        } finally {
          client.close();
        }
      },
      onRetry: (error, retryCount, delayMs) {
        debugPrint('LM-Studio 请求失败，第$retryCount次重试，延迟${delayMs}ms: $error');
      },
      l10n: l10n,
    );
  }

  @override
  Stream<Map<String, dynamic>> sendMessageStreaming({
    required String message,
    required List<Message> chatHistory,
    required List<Attachment> attachments,
    required String systemPrompt,
    required double temperature,
    required int maxTokens,
    bool thinkingMode = false,
    required AppLocalizations l10n,
  }) async* {
    final client = _createHttpClient();
    try {
      final apiEndpoint = await _settingsService.getApiEndpoint();
      final apiKey = await _settingsService.getApiKey();
      final model = await _settingsService.getModel();
      final enableHistory = await _settingsService.getEnableHistory();
      final historyContextLength =
          await _settingsService.getHistoryContextLength();

      // 构建响应API的请求体
      final requestBody = <String, dynamic>{
        'model': model,
        'max_output_tokens': maxTokens,
        'temperature': temperature,
        'stream': true,
      };

      // 添加系统提示词作为instructions
      if (systemPrompt.isNotEmpty) {
        requestBody['instructions'] = systemPrompt;
      }

      // 构建input字段
      final input = await _buildInput(
        message: message,
        chatHistory: chatHistory,
        attachments: attachments,
        enableHistory: enableHistory,
        historyContextLength: historyContextLength,
        l10n: l10n,
      );
      requestBody['input'] = input;

      // 添加推理配置
      if (thinkingMode) {
        requestBody['reasoning'] = {'effort': 'medium', 'summary': 'auto'};
      }

      final request = http.Request(
        'POST',
        Uri.parse('$apiEndpoint/responses'),
      );
      request.headers['Content-Type'] = 'application/json';
      request.headers['Authorization'] = 'Bearer $apiKey';
      request.body = jsonEncode(requestBody);

      final streamedResponse = await client.send(request).timeout(streamingTimeout);

      if (streamedResponse.statusCode != 200) {
        final errorBody =
            await streamedResponse.stream.transform(utf8.decoder).join();
        throw _parseError(errorBody, streamedResponse.statusCode, l10n);
      }

      final stream = streamedResponse.stream
          .transform(utf8.decoder)
          .transform(const LineSplitter());

      // 缓冲区用于累积流式响应，避免重复
      final answerBuffer = StringBuffer();
      final reasoningBuffer = StringBuffer();

      final stopwatch = Stopwatch()..start();
      await for (final line in stream) {
        stopwatch.reset();

        if (line.isEmpty) continue;

        // 处理SSE格式：event: 和 data: 行
        if (line.startsWith('data: ')) {
          final data = line.substring(6);
          if (data == '[DONE]') {
            break;
          }
          try {
            final jsonData = jsonDecode(data);
            final type = jsonData['type'] as String?;

            // 处理响应API的流式事件
            if (type == 'response.output_text.delta') {
              final delta = jsonData['delta'] as String?;
              if (delta != null && delta.isNotEmpty) {
                answerBuffer.write(delta);
                yield {'type': 'answer', 'content': delta};
              }
            } else if (type == 'response.output_text.done') {
              final text = jsonData['text'] as String?;
              if (text != null && text.isNotEmpty) {
                final currentAnswer = answerBuffer.toString();
                if (text != currentAnswer) {
                  // 如果文本与当前缓冲区内容不同，发送差异部分
                  if (text.startsWith(currentAnswer)) {
                    final remaining = text.substring(currentAnswer.length);
                    if (remaining.isNotEmpty) {
                      yield {'type': 'answer', 'content': remaining};
                      answerBuffer.write(remaining);
                    }
                  } else {
                    // 文本与缓冲区内容不匹配，发送整个文本
                    yield {'type': 'answer', 'content': text};
                    answerBuffer.clear();
                    answerBuffer.write(text);
                  }
                }
                // 如果文本与缓冲区内容相同，则跳过，避免重复
              }
            } else if (type == 'response.reasoning.delta') {
              final delta = jsonData['delta'] as String?;
              if (delta != null && delta.isNotEmpty) {
                reasoningBuffer.write(delta);
                yield {'type': 'reasoning', 'content': delta};
              }
            } else if (type == 'response.reasoning.done') {
              final text = jsonData['text'] as String?;
              if (text != null && text.isNotEmpty) {
                final currentReasoning = reasoningBuffer.toString();
                if (text != currentReasoning) {
                  // 如果文本与当前缓冲区内容不同，发送差异部分
                  if (text.startsWith(currentReasoning)) {
                    final remaining = text.substring(currentReasoning.length);
                    if (remaining.isNotEmpty) {
                      yield {'type': 'reasoning', 'content': remaining};
                      reasoningBuffer.write(remaining);
                    }
                  } else {
                    // 文本与缓冲区内容不匹配，发送整个文本
                    yield {'type': 'reasoning', 'content': text};
                    reasoningBuffer.clear();
                    reasoningBuffer.write(text);
                  }
                }
                // 如果文本与缓冲区内容相同，则跳过，避免重复
              }
            }
          } catch (e) {
            // 忽略解析错误
          }
        }

        if (stopwatch.elapsed > streamingTimeout) {
          throw TimeoutException(l10n.providerStreamingTimeout(streamingTimeout.inSeconds));
        }
      }
    } finally {
      client.close();
    }
  }

  @override
  Future<String> generateConversationTitle(List<Message> messages, {required AppLocalizations l10n}) async {
    final apiEndpoint = await _settingsService.getApiEndpoint();
    final apiKey = await _settingsService.getApiKey();
    final model = await _settingsService.getModel();

    // 提取对话摘要（前几轮对话）
    final summaryMessages = messages.take(6).toList();
    final conversationSummary = summaryMessages.map((msg) {
      final role = msg.isUser ? l10n.providerUser : l10n.providerAi;
      return '$role: ${msg.content.trim()}';
    }).join('\n');

    // 构建响应API请求
    final requestBody = <String, dynamic>{
      'model': model,
      'instructions': l10n.providerTitleGenSystemPrompt,
      'input': l10n.providerTitleGenUserPrompt(conversationSummary),
      'max_output_tokens': 50,
      'temperature': 0.3,
    };

    final response = await http.post(
      Uri.parse('$apiEndpoint/responses'),
      headers: {
        'Content-Type': 'application/json',
        'Authorization': 'Bearer $apiKey',
      },
      body: jsonEncode(requestBody),
    );

    if (response.statusCode == 200) {
      final data = jsonDecode(response.body);

      // 从响应API格式中提取标题
      var title = '';
      final output = data['output'] as List?;
      if (output != null && output.isNotEmpty) {
        final firstOutput = output[0] as Map<String, dynamic>?;
        if (firstOutput != null && firstOutput['type'] == 'message') {
          final contentList = firstOutput['content'] as List?;
          if (contentList != null && contentList.isNotEmpty) {
            final firstContent = contentList[0] as Map<String, dynamic>?;
            if (firstContent != null && firstContent['type'] == 'output_text') {
              title = firstContent['text']?.toString().trim() ?? '';
            }
          }
        }
      }

      // 移除可能的引号
      if (title.startsWith('"') || title.startsWith('\'') || title.startsWith('|')) {
        title = title.substring(1);
      }
      if (title.endsWith('"') || title.endsWith('\'') || title.endsWith('|')) {
        title = title.substring(0, title.length - 1);
      }

      // 截断过长的标题
      if (title.length > 20) {
        title = '${title.substring(0, 20)}...';
      }
      return title;
    } else {
      final errorBody = response.body;
      final errorData = jsonDecode(errorBody);
      final errorMessage = errorData['error']?['message']?.toString() ??
          errorData['message']?.toString() ??
          l10n.providerUnknownError;
      return Future.error(Exception(l10n.providerApiError(errorMessage, response.statusCode)));
    }
  }

  /// 构建响应API的input字段
  Future<dynamic> _buildInput({
    required String message,
    required List<Message> chatHistory,
    required List<Attachment> attachments,
    required bool enableHistory,
    required int historyContextLength,
    required AppLocalizations l10n,
  }) async {
    // 如果没有历史消息，直接返回当前消息
    if (!enableHistory || chatHistory.isEmpty) {
      final userMessageContent = await _buildMessageContent(message, attachments, l10n);
      return userMessageContent;
    }

    // 构建包含历史消息的对话数组
    final messages = <Map<String, dynamic>>[];

    // 添加历史消息
    final recentHistory = chatHistory
        .where((msg) =>
            msg.status != MessageStatus.error &&
            msg.content.trim().isNotEmpty)
        .toList()
        .reversed
        .take(historyContextLength * 2)
        .toList()
        .reversed
        .toList();

    for (final historyMsg in recentHistory) {
      final role = historyMsg.isUser ? 'user' : 'assistant';
      final content = historyMsg.content;

      messages.add({
        'role': role,
        'content': content,
      });
    }

    // 添加当前用户消息
    final userMessageContent = await _buildMessageContent(message, attachments, l10n);
    messages.add({
      'role': 'user',
      'content': userMessageContent,
    });

    return messages;
  }


  /// 构建消息内容（处理附件）
  Future<dynamic> _buildMessageContent(
      String message, List<Attachment> attachments, AppLocalizations l10n) async {
    if (attachments.isEmpty) {
      return message;
    }

    final totalSize = attachments.fold<int>(
        0, (sum, attachment) => sum + (attachment.fileSize ?? 0));
    if (totalSize > AIProvider.maxTotalAttachmentsSize) {
      throw Exception(l10n.providerTotalSizeExceeded(AIProvider.maxTotalAttachmentsSize ~/ (1024 * 1024)));
    }

    final contentParts = <Map<String, dynamic>>[];

    if (message.isNotEmpty) {
      // 响应API使用 input_text 类型
      contentParts.add({'type': 'input_text', 'text': message});
    }

    for (final attachment in attachments) {
      try {
        if (attachment.filePath == null ||
            !await _fileService.fileExists(attachment.filePath!)) {
          contentParts.add(
              {'type': 'input_text', 'text': l10n.providerFileNotFound(attachment.fileName)});
          continue;
        }

        final file = File(attachment.filePath!);
        final fileSize = attachment.fileSize ??
            await _fileService.getFileSize(attachment.filePath!);

        if (fileSize > AIProvider.maxFileSizeForBase64) {
          contentParts.add({
            'type': 'input_text',
            'text': l10n.providerFileTooLarge(attachment.fileName, formatFileSize(fileSize))
          });
          continue;
        }

        if (isVisionSupportedFile(attachment)) {
          try {
            final dataUrl =
                await _fileService.getFileDataUrl(file, attachment.mimeType);
            contentParts.add({
              'type': 'input_image',
              'image_url': {'url': dataUrl}
            });
          } catch (e) {
            contentParts.add({
              'type': 'input_text',
              'text': l10n.providerFileProcessError(attachment.fileName, e.toString())
            });
          }
        } else {
          if (fileSize <= AIProvider.maxFileSizeForTextExtraction) {
            try {
              final content = await _fileService.readTextFile(file);
              contentParts.add({
                'type': 'input_text',
                'text': l10n.providerFileContent(
                  attachment.fileName,
                  formatFileSize(fileSize),
                  content
                )
              });
            } catch (e) {
              contentParts.add({
                'type': 'input_text',
                'text': l10n.providerAttachmentCannotRead(
                  attachment.fileName,
                  formatFileSize(fileSize),
                  attachment.mimeType ?? l10n.unknownMimeType
                )
              });
            }
          } else {
            contentParts.add({
              'type': 'input_text',
              'text': l10n.providerAttachmentInfo(
                attachment.fileName,
                formatFileSize(fileSize),
                attachment.mimeType ?? l10n.unknownMimeType
              )
            });
          }
        }
      } catch (e) {
        contentParts.add(
            {'type': 'input_text', 'text': l10n.providerFileProcessError(attachment.fileName, e.toString())});
      }
    }

    if (contentParts.length == 1 && contentParts[0]['type'] == 'input_text') {
      return contentParts[0]['text'] as String;
    }

    return contentParts;
  }

  /// 解析响应
  Map<String, dynamic> _parseResponse(String responseBody, AppLocalizations l10n) {
    final data = jsonDecode(responseBody);

    // 处理响应API格式
    if (data is Map<String, dynamic> && data['object'] == 'response') {
      final output = data['output'] as List?;
      String reasoningContent = '';
      String content = '';

      if (output != null) {
        for (final item in output) {
          if (item is! Map<String, dynamic>) continue;

          final type = item['type'] as String?;
          if (type == 'message') {
            final contentList = item['content'] as List?;
            if (contentList != null) {
              for (final contentItem in contentList) {
                if (contentItem is Map<String, dynamic> &&
                    contentItem['type'] == 'output_text') {
                  final text = contentItem['text'] as String?;
                  if (text != null && text.isNotEmpty) {
                    content += (content.isNotEmpty ? '\n' : '') + text;
                  }
                }
              }
            }
          }
        }
      }

      // 检查是否有推理内容
      final reasoning = data['reasoning'] as Map<String, dynamic>?;
      if (reasoning != null) {
        final summary = reasoning['summary'] as String?;
        if (summary != null && summary.isNotEmpty) {
          reasoningContent = summary;
        }
      }

      return {
        'reasoningContent': reasoningContent.trim(),
        'content': content.trim(),
      };
    }

    // 如果格式不符合预期，抛出异常
    throw Exception(l10n.providerInvalidResponseFormat);
  }

  /// 解析错误
  Exception _parseError(String responseBody, int statusCode, AppLocalizations l10n) {
    final errorData = jsonDecode(responseBody);
    if (errorData is! Map<String, dynamic>) {
      return Exception(l10n.providerInvalidResponseFormatWithCode(statusCode));
    }

    final errorMessage = errorData['error']?['message']?.toString() ??
        errorData['message']?.toString() ??
        l10n.providerUnknownError;
    return Exception(l10n.providerApiError(errorMessage, statusCode));
  }

  /// 创建HTTP客户端
  http.Client _createHttpClient() {
    return http.Client();
  }

  /// 判断错误是否可重试
  bool _isRetryableError(dynamic error, int? statusCode) {
    if (error is SocketException ||
        error is TimeoutException ||
        error is TlsException ||
        error is HttpException ||
        error.toString().contains('Connection') ||
        error.toString().contains('timeout') ||
        error.toString().contains('socket') ||
        error.toString().contains('handshake')) {
      return true;
    }

    if (statusCode != null && statusCode >= 500 && statusCode < 600) {
      return true;
    }

    if (statusCode == 429) {
      return true;
    }

    return false;
  }

  /// 计算重试延迟时间（指数退避）
  int _calculateRetryDelay(int retryCount) {
    final delay = retryBaseDelayMs * (1 << retryCount);
    return delay > retryMaxDelayMs ? retryMaxDelayMs : delay;
  }

  /// 带重试的执行函数
  Future<T> _executeWithRetry<T>(
    Future<T> Function() execute, {
    void Function(dynamic error, int retryCount, int delayMs)? onRetry,
    required AppLocalizations l10n,
  }) async {
    int attempt = 0;
    dynamic lastError;
    int? lastStatusCode;

    while (attempt <= maxRetries) {
      try {
        return await execute();
      } catch (error) {
        lastError = error;

        if (error is http.Response) {
          lastStatusCode = error.statusCode;
        } else if (error.toString().contains('statusCode')) {
          final match = RegExp(r'statusCode[:\s]*(\d+)').firstMatch(error.toString());
          if (match != null) {
            lastStatusCode = int.tryParse(match.group(1)!);
          }
        }

        if (attempt < maxRetries && _isRetryableError(error, lastStatusCode)) {
          final delayMs = _calculateRetryDelay(attempt);
          if (onRetry != null) {
            onRetry(error, attempt + 1, delayMs);
          }
          await Future.delayed(Duration(milliseconds: delayMs));
          attempt++;
          continue;
        }

        rethrow;
      }
    }

    throw lastError ?? Exception(l10n.providerUnknownError);
  }
}
