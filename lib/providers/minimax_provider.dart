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

/// MiniMax API Provider 实现
/// 负责处理与 MiniMax API 的通信
///
/// MiniMax API 地址: https://api.minimaxi.com/v1
///
/// 实现 OpenAI 兼容格式，支持 reasoning_split 参数将思考过程分离
class MiniMaxProvider extends AIProvider {
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

  /// MiniMax API 专用配置
  static const String defaultEndpoint = 'https://api.minimaxi.com/v1';

  /// 默认模型
  static const List<String> defaultModels = [
    'MiniMax-M2.1',
  ];

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

          final messages = await _buildMessages(
            message: message,
            chatHistory: chatHistory,
            attachments: attachments,
            systemPrompt: systemPrompt,
            enableHistory: enableHistory,
            historyContextLength: historyContextLength,
            l10n: l10n,
          );

          // 构建请求体
          final requestBody = <String, dynamic>{
            'model': model,
            'messages': messages,
            'max_tokens': maxTokens,
            'temperature': temperature,
          };

          // MiniMax 特殊参数：reasoning_split 将思考内容分离
          if (thinkingMode) {
            requestBody['extra_body'] = {
              'reasoning_split': true,
            };
          }

          debugPrint('MiniMax 请求 URL: $apiEndpoint/chat/completions');
          debugPrint('MiniMax 请求模型: $model');
          debugPrint('MiniMax API密钥: ${apiKey.isEmpty ? "(空)" : "${apiKey.substring(0, 8)}..."}');

          final response = await client.post(
            Uri.parse('$apiEndpoint/chat/completions'),
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

      final messages = await _buildMessages(
        message: message,
        chatHistory: chatHistory,
        attachments: attachments,
        systemPrompt: systemPrompt,
        enableHistory: enableHistory,
        historyContextLength: historyContextLength,
        l10n: l10n,
      );

      // 构建请求体
      final requestBody = <String, dynamic>{
        'model': model,
        'messages': messages,
        'max_tokens': maxTokens,
        'temperature': temperature,
        'stream': true,
      };

      // MiniMax 特殊参数：reasoning_split 将思考内容分离
      if (thinkingMode) {
        requestBody['extra_body'] = {
          'reasoning_split': true,
        };
      }

      final request = http.Request(
        'POST',
        Uri.parse('$apiEndpoint/chat/completions'),
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

      // 用于跟踪已接收的长度（处理重复内容）
      String reasoningBuffer = '';
      String textBuffer = '';

      final stopwatch = Stopwatch()..start();
      await for (final line in stream) {
        stopwatch.reset();

        if (line.isEmpty) continue;
        if (line.startsWith('data: ')) {
          final data = line.substring(6);
          if (data == '[DONE]') {
            break;
          }
          try {
            final jsonData = jsonDecode(data);

            // 处理 MiniMax 的流式响应格式
            final choices = jsonData['choices'] as List?;
            if (choices != null && choices.isNotEmpty) {
              final delta = choices[0]['delta'] as Map<String, dynamic>?;

              if (delta != null) {
                // 处理思考过程（reasoning_details）
                if (delta.containsKey('reasoning_details')) {
                  final reasoningDetails = delta['reasoning_details'] as List?;
                  if (reasoningDetails != null) {
                    for (final detail in reasoningDetails) {
                      if (detail is Map<String, dynamic> && detail.containsKey('text')) {
                        final reasoningText = detail['text'] as String;
                        // 只输出新增的内容
                        final newReasoning = reasoningText.substring(reasoningBuffer.length);
                        if (newReasoning.isNotEmpty) {
                          yield {'type': 'reasoning', 'content': newReasoning};
                          reasoningBuffer = reasoningText;
                        }
                      }
                    }
                  }
                }

                // 处理最终回答内容
                if (delta.containsKey('content') && delta['content'] != null) {
                  final contentText = delta['content'] as String;
                  // 只输出新增的内容
                  final newText = textBuffer.isEmpty
                      ? contentText
                      : contentText.substring(textBuffer.length);
                  if (newText.isNotEmpty) {
                    yield {'type': 'answer', 'content': newText};
                    textBuffer = contentText;
                  }
                }
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

    final requestMessages = [
      {
        'role': 'system',
        'content': l10n.providerTitleGenSystemPrompt
      },
      {
        'role': 'user',
        'content': l10n.providerTitleGenUserPrompt(conversationSummary)
      }
    ];

    final response = await http.post(
      Uri.parse('$apiEndpoint/chat/completions'),
      headers: {
        'Content-Type': 'application/json',
        'Authorization': 'Bearer $apiKey',
      },
      body: jsonEncode({
        'model': model,
        'messages': requestMessages,
        'max_tokens': 50,
        'temperature': 0.3,
      }),
    );

    if (response.statusCode == 200) {
      final data = jsonDecode(response.body);
      var title = data['choices'][0]['message']['content']?.toString().trim() ?? '';

      // 移除可能的引号
      if (title.startsWith('"') || title.startsWith("'") || title.startsWith('|')) {
        title = title.substring(1);
      }
      if (title.endsWith('"') || title.endsWith("'") || title.endsWith('|')) {
        title = title.substring(0, title.length - 1);
      }

      // 截断过长的标题
      if (title.length > 20) {
        title = '${title.substring(0, 20)}...';
      }
      return title;
    } else {
      final errorBody = response.body;
      try {
        final errorData = jsonDecode(errorBody);
        final errorMessage = errorData['error']?['message']?.toString() ??
            errorData['message']?.toString() ??
            errorData['error']?.toString() ??
            l10n.providerUnknownError;
        return Future.error(Exception(l10n.providerApiError(errorMessage, response.statusCode)));
      } catch (e) {
        return Future.error(Exception('${l10n.providerApiError(errorBody, response.statusCode)}\n解析错误响应失败: $e'));
      }
    }
  }

  /// 构建 MiniMax 消息列表
  Future<List<Map<String, dynamic>>> _buildMessages({
    required String message,
    required List<Message> chatHistory,
    required List<Attachment> attachments,
    required String systemPrompt,
    required bool enableHistory,
    required int historyContextLength,
    required AppLocalizations l10n,
  }) async {
    final messages = <Map<String, dynamic>>[];

    // 添加系统提示词
    messages.add({
      'role': 'system',
      'content': systemPrompt,
    });

    // 添加历史消息
    if (enableHistory && chatHistory.isNotEmpty) {
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
        messages.add({
          'role': historyMsg.isUser ? 'user' : 'assistant',
          'content': historyMsg.content,
        });
      }
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
      contentParts.add({'type': 'text', 'text': message});
    }

    for (final attachment in attachments) {
      try {
        if (attachment.filePath == null ||
            !await _fileService.fileExists(attachment.filePath!)) {
          contentParts.add(
              {'type': 'text', 'text': l10n.providerFileNotFound(attachment.fileName)});
          continue;
        }

        final file = File(attachment.filePath!);
        final fileSize = attachment.fileSize ??
            await _fileService.getFileSize(attachment.filePath!);

        if (fileSize > AIProvider.maxFileSizeForBase64) {
          contentParts.add({
            'type': 'text',
            'text': l10n.providerFileTooLarge(attachment.fileName, formatFileSize(fileSize))
          });
          continue;
        }

        if (isVisionSupportedFile(attachment)) {
          try {
            final dataUrl =
                await _fileService.getFileDataUrl(file, attachment.mimeType);
            contentParts.add({
              'type': 'image_url',
              'image_url': {'url': dataUrl}
            });
          } catch (e) {
            contentParts.add({
              'type': 'text',
              'text': l10n.providerFileProcessError(attachment.fileName, e.toString())
            });
          }
        } else {
          if (fileSize <= AIProvider.maxFileSizeForTextExtraction) {
            try {
              final content = await _fileService.readTextFile(file);
              contentParts.add({
                'type': 'text',
                'text': l10n.providerFileContent(
                  attachment.fileName,
                  formatFileSize(fileSize),
                  content
                )
              });
            } catch (e) {
              contentParts.add({
                'type': 'text',
                'text': l10n.providerAttachmentCannotRead(
                  attachment.fileName,
                  formatFileSize(fileSize),
                  attachment.mimeType ?? l10n.unknownMimeType
                )
              });
            }
          } else {
            contentParts.add({
              'type': 'text',
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
            {'type': 'text', 'text': l10n.providerFileProcessError(attachment.fileName, e.toString())});
      }
    }

    if (contentParts.length == 1 && contentParts[0]['type'] == 'text') {
      return contentParts[0]['text'] as String;
    }

    return contentParts;
  }

  /// 解析响应
  Map<String, dynamic> _parseResponse(String responseBody, AppLocalizations l10n) {
    if (responseBody.trim().isEmpty) {
      throw Exception(l10n.providerInvalidResponseFormat);
    }

    dynamic data;
    try {
      data = jsonDecode(responseBody);
    } catch (e) {
      throw Exception('${l10n.providerInvalidResponseFormat}\n解析错误: $e\n响应内容: ${responseBody.substring(0, responseBody.length > 200 ? 200 : responseBody.length)}...');
    }

    if (data is! Map<String, dynamic>) {
      throw Exception('${l10n.providerInvalidResponseFormat}\n响应不是Map类型: ${data.runtimeType}');
    }

    if (data['choices'] == null || (data['choices'] as List).isEmpty) {
      throw Exception('${l10n.providerInvalidResponseFormat}\n响应缺少choices字段或为空');
    }

    final firstChoice = data['choices'][0];
    if (firstChoice['message'] == null) {
      throw Exception('${l10n.providerMissingMessageField}\nchoices[0]缺少message字段');
    }

    final message = firstChoice['message'];
    final reasoningContent = message['reasoning']?.toString().trim() ?? '';
    final content = message['content']?.toString().trim() ?? '';

    return {
      'reasoningContent': reasoningContent,
      'content': content,
    };
  }

  /// 解析错误
  Exception _parseError(String responseBody, int statusCode, AppLocalizations l10n) {

    if (responseBody.trim().isEmpty) {
      return Exception(l10n.providerApiError('空响应体', statusCode));
    }

    try {
      final errorData = jsonDecode(responseBody);
      if (errorData is! Map<String, dynamic>) {
        return Exception(l10n.providerInvalidResponseFormatWithCode(statusCode));
      }

      final errorMessage = errorData['error']?['message']?.toString() ??
          errorData['message']?.toString() ??
          errorData['error']?.toString() ??
          l10n.providerUnknownError;
      return Exception(l10n.providerApiError(errorMessage, statusCode));
    } catch (e) {
      return Exception('${l10n.providerApiError(responseBody, statusCode)}\n解析错误响应失败: $e');
    }
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
