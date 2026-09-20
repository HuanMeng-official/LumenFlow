import 'dart:convert';
import 'dart:async';
import 'dart:io';
import 'package:flutter/cupertino.dart';
import 'package:http/http.dart' as http;
import 'ai_provider.dart';
import 'http_provider_base.dart';
import '../models/message.dart';
import '../models/attachment.dart';
import '../services/file_service.dart';
import '../services/settings_service.dart';
import '../l10n/app_localizations.dart';

/// MiniMax API Provider 实现
/// 负责处理与 MiniMax API 的通信
class MiniMaxProvider extends HttpProviderBase {
  final SettingsService _settingsService = SettingsService();
  final FileService _fileService = FileService();

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
    return await executeWithRetry<Map<String, dynamic>>(
      () async {
        final client = createHttpClient();
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

          final response = await client.post(
            Uri.parse('$apiEndpoint/text/chatcompletion_v2'),
            headers: {
              'Content-Type': 'application/json',
              'Authorization': 'Bearer $apiKey',
            },
            body: jsonEncode(requestBody),
          ).timeout(connectionTimeout + readTimeout);

          if (response.statusCode == 200) {
            return _parseResponse(response.body, l10n);
          } else {
            throw parseError(response.body, response.statusCode, l10n);
          }
        } finally {
          client.close();
        }
      },
      onRetry: (error, retryCount, delayMs) {
        debugPrint('MiniMax API请求失败，第$retryCount次重试，延迟${delayMs}ms: $error');
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
    final client = createHttpClient();
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
        Uri.parse('$apiEndpoint/text/chatcompletion_v2'),
      );
      request.headers['Content-Type'] = 'application/json';
      request.headers['Authorization'] = 'Bearer $apiKey';
      request.body = jsonEncode(requestBody);

      final streamedResponse = await client.send(request).timeout(streamingTimeout);

      if (streamedResponse.statusCode != 200) {
        final errorBody =
            await streamedResponse.stream.transform(utf8.decoder).join();
        throw parseError(errorBody, streamedResponse.statusCode, l10n);
      }

      // 缓冲区用于累积SSE事件，处理跨chunk的事件分割
      final sseBuffer = StringBuffer();
      // 用于跟踪已接收的思考内容长度（处理重复内容）
      String reasoningBuffer = '';

      final stopwatch = Stopwatch()..start();

      // 处理SSE流，正确处理跨chunk的事件边界
      await for (final chunk in streamedResponse.stream.transform(utf8.decoder)) {
        stopwatch.reset();

        if (chunk.isEmpty) continue;

        // 将chunk添加到SSE缓冲区
        sseBuffer.write(chunk);
        final bufferContent = sseBuffer.toString();

        // 按双换行符分割SSE事件
        final events = bufferContent.split('\n\n');

        // 如果最后一个事件不完整，保留在缓冲区中
        sseBuffer.clear();
        if (!bufferContent.endsWith('\n\n') && events.isNotEmpty) {
          final lastEvent = events.removeLast();
          sseBuffer.write(lastEvent);
          if (!lastEvent.endsWith('\n')) {
            sseBuffer.write('\n');
          }
        }

        // 处理完整的SSE事件
        for (final event in events) {
          if (event.trim().isEmpty) continue;

          // 解析SSE事件行
          final lines = event.split('\n');
          String? dataLine;

          for (final line in lines) {
            if (line.startsWith('data: ')) {
              dataLine = line.substring(6);
              break;
            }
          }

          if (dataLine == null) continue;
          if (dataLine == '[DONE]') {
            break;
          }

          try {
            final jsonData = jsonDecode(dataLine);

            // 处理 MiniMax 的流式响应格式
            final choices = jsonData['choices'] as List?;
            if (choices != null && choices.isNotEmpty) {
              final delta = choices[0]['delta'] as Map<String, dynamic>?;

              if (delta != null) {
                // 处理思考过程
                // 优先使用 reasoning_content 字段（增量内容）
                final reasoningContent = delta['reasoning_content'] as String?;
                if (reasoningContent != null && reasoningContent.isNotEmpty) {
                  // reasoning_content 是增量内容，直接输出
                  yield {'type': 'reasoning', 'content': reasoningContent};
                  // 同时更新 reasoningBuffer 用于 reasoning_details 的完整文本处理
                  reasoningBuffer += reasoningContent;
                }

                // 同时处理 reasoning_details 中的完整文本（备用）
                if (delta.containsKey('reasoning_details')) {
                  final reasoningDetails = delta['reasoning_details'] as List?;
                  if (reasoningDetails != null) {
                    for (final detail in reasoningDetails) {
                      if (detail is Map<String, dynamic> && detail.containsKey('text')) {
                        final reasoningText = detail['text'] as String;
                        // 如果 reasoningBuffer 与 reasoningText 不一致，说明有新增内容
                        if (reasoningBuffer != reasoningText) {
                          final newReasoning = reasoningText.substring(reasoningBuffer.length);
                          if (newReasoning.isNotEmpty) {
                            yield {'type': 'reasoning', 'content': newReasoning};
                            reasoningBuffer = reasoningText;
                          }
                        }
                      }
                    }
                  }
                }

                // 处理最终回答内容
                final contentText = delta['content'] as String?;
                if (contentText != null && contentText.isNotEmpty) {
                  // content 字段是增量内容，直接输出
                  yield {'type': 'answer', 'content': contentText};
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
      Uri.parse('$apiEndpoint/text/chatcompletion_v2'),
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
      throw parseError(response.body, response.statusCode, l10n);
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

}
