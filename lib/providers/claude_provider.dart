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

/// Claude API Provider 实现
/// 负责处理与 Anthropic Claude API 的通信
class ClaudeProvider extends AIProvider {
  final SettingsService _settingsService = SettingsService();
  final FileService _fileService = FileService();

  // 超时配置
  static const Duration connectionTimeout = Duration(seconds: 30);
  static const Duration readTimeout = Duration(seconds: 60);
  static const Duration streamingTimeout = Duration(minutes: 5);

  // 重试配置
  static const int maxRetries = 3;
  static const int retryBaseDelayMs = 1000;
  static const int retryMaxDelayMs = 10000;

  // Claude API 版本
  static const String anthropicVersion = '2023-06-01';

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

          final requestBody = {
            'model': model,
            'messages': messages,
            'max_tokens': maxTokens,
            'temperature': temperature,
            if (systemPrompt.isNotEmpty) 'system': systemPrompt,
            if (thinkingMode) 'thinking': {'type': 'enabled', 'budget_tokens': 1000},
          };

          final response = await client.post(
            Uri.parse('$apiEndpoint/messages'),
            headers: {
              'Content-Type': 'application/json',
              'X-Api-Key': apiKey,
              'anthropic-version': anthropicVersion,
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
        debugPrint('Claude API请求失败，第$retryCount次重试，延迟${delayMs}ms: $error');
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

      final requestBody = {
        'model': model,
        'messages': messages,
        'max_tokens': maxTokens,
        'temperature': temperature,
        'stream': true,
        if (systemPrompt.isNotEmpty) 'system': systemPrompt,
        if (thinkingMode) 'thinking': {'type': 'enabled', 'budget_tokens': 1000},
      };

      final request = http.Request(
        'POST',
        Uri.parse('$apiEndpoint/messages'),
      );
      request.headers['Content-Type'] = 'application/json';
      request.headers['X-Api-Key'] = apiKey;
      request.headers['anthropic-version'] = anthropicVersion;
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
            final type = jsonData['type'] as String?;

            if (type == 'content_block_delta') {
              final delta = jsonData['delta'] as Map<String, dynamic>?;
              if (delta != null) {
                final deltaType = delta['type'] as String?;

                if (deltaType == 'thinking_delta') {
                  final reasoningContent = delta['thinking'] as String?;
                  if (reasoningContent != null && reasoningContent.isNotEmpty) {
                    yield {'type': 'reasoning', 'content': reasoningContent};
                  }
                } else if (deltaType == 'text_delta') {
                  final content = delta['text'] as String?;
                  if (content != null && content.isNotEmpty) {
                    yield {'type': 'answer', 'content': content};
                  }
                }
                // 忽略 signature_delta 等其他类型
              }
            }
            // 忽略其他事件类型：message_start, content_block_start, content_block_stop, message_delta, message_stop
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

    // 提取对话摘要
    final summaryMessages = messages.take(6).toList();
    final conversationSummary = summaryMessages.map((msg) {
      final role = msg.isUser ? l10n.providerUser : l10n.providerAi;
      return '$role: ${msg.content.trim()}';
    }).join('\n');

    final requestMessages = [
      {
        'role': 'user',
        'content': l10n.providerTitleGenUserPrompt(conversationSummary)
      }
    ];

    final requestBody = {
      'model': model,
      'messages': requestMessages,
      'max_tokens': 50,
      'temperature': 0.3,
    };

    final response = await http.post(
      Uri.parse('$apiEndpoint/messages'),
      headers: {
        'Content-Type': 'application/json',
        'X-Api-Key': apiKey,
        'anthropic-version': anthropicVersion,
      },
      body: jsonEncode(requestBody),
    );

    if (response.statusCode == 200) {
      final data = jsonDecode(response.body);
      var title = data['content']?[0]?['text']?.toString().trim() ?? '';

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

  /// 构建 Claude 消息列表
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

    // Claude API 使用 system 参数而不是消息角色
    // 系统提示词将在请求体中单独处理

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
            // 如果有URL，使用URL引用图片，否则使用base64编码
            if (attachment.url != null && attachment.url!.isNotEmpty &&
                (attachment.url!.startsWith('http://') || attachment.url!.startsWith('https://'))) {
              contentParts.add({
                'type': 'image',
                'source': {
                  'type': 'url',
                  'url': attachment.url!,
                }
              });
            } else {
              final dataUrl =
                  await _fileService.getFileDataUrl(file, attachment.mimeType);
              // 使用 base64 编码的图片
              final base64Data = dataUrl.replaceFirst(RegExp(r'^data:[^;]+;base64,'), '');
              contentParts.add({
                'type': 'image',
                'source': {
                  'type': 'base64',
                  'media_type': attachment.mimeType ?? 'image/jpeg',
                  'data': base64Data,
                }
              });
            }
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
    final data = jsonDecode(responseBody);
    if (data is! Map<String, dynamic> || data['content'] == null) {
      throw Exception(l10n.providerInvalidResponseFormat);
    }

    final contentList = data['content'] as List;
    if (contentList.isEmpty) {
      throw Exception(l10n.providerMissingMessageField);
    }

    // 提取思考内容：先从thinking字段，再从content数组中的thinking类型项目
    String reasoningContent = data['thinking']?.toString().trim() ?? '';
    final thinkingFromContent = contentList
        .where((item) => item['type'] == 'thinking')
        .map<String>((item) => item['thinking']?.toString().trim() ?? item['text']?.toString().trim() ?? '')
        .join('');
    if (thinkingFromContent.isNotEmpty) {
      reasoningContent = reasoningContent.isEmpty ? thinkingFromContent : '$reasoningContent\n$thinkingFromContent';
    }

    // 提取文本内容
    final content = contentList
        .where((item) => item['type'] == 'text')
        .map<String>((item) => item['text']?.toString().trim() ?? '')
        .join('');

    return {
      'reasoningContent': reasoningContent,
      'content': content,
    };
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