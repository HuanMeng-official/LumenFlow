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

/// OpenAI API Provider 实现
/// 负责处理与 OpenAI 兼容的 API 通信
class OpenAIProvider extends AIProvider {
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
          );

          final response = await client.post(
            Uri.parse('$apiEndpoint/chat/completions'),
            headers: {
              'Content-Type': 'application/json',
              'Authorization': 'Bearer $apiKey',
            },
            body: jsonEncode({
              'model': model,
              'messages': messages,
              'max_tokens': maxTokens,
              'temperature': temperature,
              if (thinkingMode) 'thinking': {'type': 'enabled'},
            }),
          ).timeout(connectionTimeout + readTimeout);

          if (response.statusCode == 200) {
            return _parseResponse(response.body);
          } else {
            throw _parseError(response.body, response.statusCode);
          }
        } finally {
          client.close();
        }
      },
      onRetry: (error, retryCount, delayMs) {
        debugPrint('OpenAI API请求失败，第$retryCount次重试，延迟${delayMs}ms: $error');
      },
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
      );

      final request = http.Request(
        'POST',
        Uri.parse('$apiEndpoint/chat/completions'),
      );
      request.headers['Content-Type'] = 'application/json';
      request.headers['Authorization'] = 'Bearer $apiKey';
      request.body = jsonEncode({
        'model': model,
        'messages': messages,
        'max_tokens': maxTokens,
        'temperature': temperature,
        'stream': true,
        if (thinkingMode) 'thinking': {'type': 'enabled'},
      });

      final streamedResponse = await client.send(request).timeout(streamingTimeout);

      if (streamedResponse.statusCode != 200) {
        final errorBody =
            await streamedResponse.stream.transform(utf8.decoder).join();
        throw _parseError(errorBody, streamedResponse.statusCode);
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
            final delta = jsonData['choices']?[0]?['delta'];

            if (delta != null) {
              // 处理思考模型的推理过程
              final reasoningContent = delta['reasoning'] as String? ??
                  delta['reasoning_content'] as String?;
              if (reasoningContent != null && reasoningContent.isNotEmpty) {
                yield {'type': 'reasoning', 'content': reasoningContent};
              }

              // 处理最终回答
              final content = delta['content'] as String?;
              if (content != null && content.isNotEmpty) {
                yield {'type': 'answer', 'content': content};
              }
            }
          } catch (e) {
            // 忽略解析错误
          }
        }

        if (stopwatch.elapsed > streamingTimeout) {
          throw TimeoutException('流式响应超时：超过${streamingTimeout.inSeconds}秒未收到新数据');
        }
      }
    } finally {
      client.close();
    }
  }

  @override
  Future<String> generateConversationTitle(List<Message> messages) async {
    final apiEndpoint = await _settingsService.getApiEndpoint();
    final apiKey = await _settingsService.getApiKey();
    final model = await _settingsService.getModel();

    // 提取对话摘要（前几轮对话）
    final summaryMessages = messages.take(6).toList();
    final conversationSummary = summaryMessages.map((msg) {
      final role = msg.isUser ? '用户' : 'AI';
      return '$role: ${msg.content.trim()}';
    }).join('\n');

    final requestMessages = [
      {
        'role': 'system',
        'content': '你是一个专业的对话标题生成助手。请根据用户的语言（如果用户说中文你就用中文，用户说英文你就用英文）和对话内容生成一个简短、准确的和用户语言一致的标题，不超过15个字。只返回标题，不要加引号或其他格式。'
      },
      {
        'role': 'user',
        'content': '请根据以下对话内容生成一个和用户语言相符的简短标题：\n\n$conversationSummary'
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
          '未知错误';
      return Future.error(Exception('API错误: $errorMessage (状态码: ${response.statusCode})'));
    }
  }

  /// 构建 OpenAI 消息列表
  Future<List<Map<String, dynamic>>> _buildMessages({
    required String message,
    required List<Message> chatHistory,
    required List<Attachment> attachments,
    required String systemPrompt,
    required bool enableHistory,
    required int historyContextLength,
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
    final userMessageContent = await _buildMessageContent(message, attachments);
    messages.add({
      'role': 'user',
      'content': userMessageContent,
    });

    return messages;
  }

  /// 构建消息内容（处理附件）
  Future<dynamic> _buildMessageContent(
      String message, List<Attachment> attachments) async {
    if (attachments.isEmpty) {
      return message;
    }

    final totalSize = attachments.fold<int>(
        0, (sum, attachment) => sum + (attachment.fileSize ?? 0));
    if (totalSize > AIProvider.maxTotalAttachmentsSize) {
      throw Exception('附件总大小超过${AIProvider.maxTotalAttachmentsSize ~/ (1024 * 1024)}MB限制');
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
              {'type': 'text', 'text': '文件 ${attachment.fileName} 不存在或已删除'});
          continue;
        }

        final file = File(attachment.filePath!);
        final fileSize = attachment.fileSize ??
            await _fileService.getFileSize(attachment.filePath!);

        if (fileSize > AIProvider.maxFileSizeForBase64) {
          contentParts.add({
            'type': 'text',
            'text':
                '文件 ${attachment.fileName} (${formatFileSize(fileSize)}) 过大，无法处理'
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
              'text': '处理文件 ${attachment.fileName} 时出错: $e'
            });
          }
        } else {
          if (fileSize <= AIProvider.maxFileSizeForTextExtraction) {
            try {
              final content = await _fileService.readTextFile(file);
              contentParts.add({
                'type': 'text',
                'text':
                    '文件: ${attachment.fileName} (${formatFileSize(fileSize)})\n内容:\n$content'
              });
            } catch (e) {
              contentParts.add({
                'type': 'text',
                'text':
                    '附件: ${attachment.fileName} (${formatFileSize(fileSize)}, ${attachment.mimeType ?? '未知类型'}) - 无法读取内容'
              });
            }
          } else {
            contentParts.add({
              'type': 'text',
              'text':
                  '附件: ${attachment.fileName} (${formatFileSize(fileSize)}, ${attachment.mimeType ?? '未知类型'})'
            });
          }
        }
      } catch (e) {
        contentParts.add(
            {'type': 'text', 'text': '处理文件 ${attachment.fileName} 时出错: $e'});
      }
    }

    if (contentParts.length == 1 && contentParts[0]['type'] == 'text') {
      return contentParts[0]['text'] as String;
    }

    return contentParts;
  }

  /// 解析响应
  Map<String, dynamic> _parseResponse(String responseBody) {
    final data = jsonDecode(responseBody);
    if (data is! Map<String, dynamic> ||
        data['choices'] == null ||
        (data['choices'] as List).isEmpty) {
      throw Exception('API返回了无效的响应格式: $responseBody');
    }

    final firstChoice = data['choices'][0];
    if (firstChoice['message'] == null) {
      throw Exception('API响应中缺少message字段: $responseBody');
    }

    final message = firstChoice['message'];
    final reasoningContent =
        message['reasoning']?.toString().trim() ??
        message['reasoning_content']?.toString().trim() ?? '';
    final content = message['content']?.toString().trim() ?? '';

    return {
      'reasoningContent': reasoningContent,
      'content': content,
    };
  }

  /// 解析错误
  Exception _parseError(String responseBody, int statusCode) {
    final errorData = jsonDecode(responseBody);
    if (errorData is! Map<String, dynamic>) {
      return Exception('API错误: 无效的响应格式 (状态码: $statusCode)');
    }

    final errorMessage = errorData['error']?['message']?.toString() ??
        errorData['message']?.toString() ??
        '未知错误';
    return Exception('API错误: $errorMessage (状态码: $statusCode)');
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

    throw lastError ?? Exception('未知错误');
  }
}
