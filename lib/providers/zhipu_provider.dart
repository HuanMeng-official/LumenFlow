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

class ZhiPuProvider extends AIProvider {
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
          };

          // 智谱支持深度思考模式
          if (thinkingMode) {
            requestBody['thinking'] = {'type': 'enabled'};
          }

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
        debugPrint('ZhiPu API请求失败，第$retryCount次重试，延迟${delayMs}ms: $error');
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

      final request = http.Request(
        'POST',
        Uri.parse('$apiEndpoint/chat/completions'),
      );
      request.headers['Content-Type'] = 'application/json';
      request.headers['Authorization'] = 'Bearer $apiKey';

      final requestBody = {
        'model': model,
        'messages': messages,
        'max_tokens': maxTokens,
        'temperature': temperature,
        'stream': true,
      };

      // 智谱支持深度思考模式
      if (thinkingMode) {
        requestBody['thinking'] = {'type': 'enabled'};
      }

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
            final delta = jsonData['choices']?[0]?['delta'];

            if (delta != null) {
              // 处理思考模型的推理过程 - 智谱使用 reasoning_content
              final reasoningContent = delta['reasoning_content'] as String?;
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
      final errorData = jsonDecode(errorBody);
      final errorMessage = errorData['error']?['message']?.toString() ??
          errorData['message']?.toString() ??
          l10n.providerUnknownError;
      return Future.error(Exception(l10n.providerApiError(errorMessage, response.statusCode)));
    }
  }

  /// 构建 ZhiPu 消息列表
  /// 支持图片、视频、文档等多媒体内容
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

    // 添加当前用户消息（支持附件）
    final userMessageContent = await _buildMessageContent(message, attachments, l10n);
    messages.add({
      'role': 'user',
      'content': userMessageContent,
    });

    return messages;
  }

  /// 构建消息内容（处理附件）
  /// ZhiPu 支持图片、视频、文档等多种文件类型
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
        final mimeType = attachment.mimeType ?? _getMimeType(attachment.fileName);

        // 处理图片文件 - ZhiPu 支持 image_url 类型
        if (mimeType.startsWith('image/')) {
          if (fileSize <= AIProvider.maxFileSizeForBase64) {
            try {
              final bytes = await file.readAsBytes();
              final base64 = base64Encode(bytes);
              contentParts.add({
                'type': 'image_url',
                'image_url': {
                  'url': 'data:$mimeType;base64,$base64',
                },
              });
            } catch (e) {
              contentParts.add({
                'type': 'text',
                'text': l10n.providerAttachmentCannotRead(
                  attachment.fileName,
                  formatFileSize(fileSize),
                  mimeType
                )
              });
            }
          } else {
            // 图片过大，转为文本提示
            contentParts.add({
              'type': 'text',
              'text': l10n.providerFileProcessError(attachment.fileName, l10n.providerFileTooLarge(attachment.fileName, formatFileSize(fileSize)))
            });
          }
        }
        // 处理视频文件 - ZhiPu 支持 video_url 类型
        else if (mimeType.startsWith('video/')) {
          if (fileSize <= AIProvider.maxFileSizeForBase64) {
            try {
              final bytes = await file.readAsBytes();
              final base64 = base64Encode(bytes);
              contentParts.add({
                'type': 'video_url',
                'video_url': {
                  'url': 'data:$mimeType;base64,$base64',
                },
              });
            } catch (e) {
              contentParts.add({
                'type': 'text',
                'text': l10n.providerAttachmentCannotRead(
                  attachment.fileName,
                  formatFileSize(fileSize),
                  mimeType
                )
              });
            }
          } else {
            contentParts.add({
              'type': 'text',
              'text': l10n.providerFileProcessError(attachment.fileName, l10n.providerFileTooLarge(attachment.fileName, formatFileSize(fileSize)))
            });
          }
        }
        // 处理文档文件 - ZhiPu 支持 file_url 类型
        else if (isDocumentFile(attachment)) {
          if (fileSize <= AIProvider.maxFileSizeForBase64) {
            try {
              final bytes = await file.readAsBytes();
              final base64 = base64Encode(bytes);
              contentParts.add({
                'type': 'file_url',
                'file_url': {
                  'url': 'data:$mimeType;base64,$base64',
                },
              });
            } catch (e) {
              contentParts.add({
                'type': 'text',
                'text': l10n.providerAttachmentCannotRead(
                  attachment.fileName,
                  formatFileSize(fileSize),
                  mimeType
                )
              });
            }
          } else if (fileSize <= AIProvider.maxFileSizeForTextExtraction) {
            // 对于较大的文本文件，尝试读取文本内容
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
                  mimeType
                )
              });
            }
          } else {
            contentParts.add({
              'type': 'text',
              'text': l10n.providerAttachmentInfo(
                attachment.fileName,
                formatFileSize(fileSize),
                mimeType
              )
            });
          }
        }
        // 其他文件类型，尝试读取文本内容
        else if (fileSize <= AIProvider.maxFileSizeForTextExtraction) {
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
              'text': l10n.providerAttachmentInfo(
                attachment.fileName,
                formatFileSize(fileSize),
                mimeType
              )
            });
          }
        } else {
          contentParts.add({
            'type': 'text',
            'text': l10n.providerAttachmentInfo(
              attachment.fileName,
              formatFileSize(fileSize),
              mimeType,
            )
          });
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

  /// 判断是否为文档文件
  bool isDocumentFile(Attachment attachment) {
    final fileName = attachment.fileName.toLowerCase();
    final docExtensions = ['.pdf', '.doc', '.docx', '.txt', '.xlsx', '.xls', '.ppt', '.pptx'];
    return docExtensions.any((ext) => fileName.endsWith(ext));
  }

  /// 根据文件名获取MIME类型
  String _getMimeType(String fileName) {
    final extension = fileName.toLowerCase().split('.').last;
    switch (extension) {
      case 'pdf':
        return 'application/pdf';
      case 'doc':
        return 'application/msword';
      case 'docx':
        return 'application/vnd.openxmlformats-officedocument.wordprocessingml.document';
      case 'txt':
        return 'text/plain';
      case 'xls':
        return 'application/vnd.ms-excel';
      case 'xlsx':
        return 'application/vnd.openxmlformats-officedocument.spreadsheetml.sheet';
      case 'ppt':
        return 'application/vnd.ms-powerpoint';
      case 'pptx':
        return 'application/vnd.openxmlformats-officedocument.presentationml.presentation';
      case 'jpg':
      case 'jpeg':
        return 'image/jpeg';
      case 'png':
        return 'image/png';
      case 'gif':
        return 'image/gif';
      case 'webp':
        return 'image/webp';
      case 'bmp':
        return 'image/bmp';
      case 'mp4':
        return 'video/mp4';
      case 'mov':
        return 'video/quicktime';
      case 'avi':
        return 'video/x-msvideo';
      case 'mkv':
        return 'video/x-matroska';
      case 'webm':
        return 'video/webm';
      case 'mp3':
        return 'audio/mpeg';
      case 'wav':
        return 'audio/wav';
      case 'flac':
        return 'audio/flac';
      default:
        return 'application/octet-stream';
    }
  }

  /// 解析响应
  Map<String, dynamic> _parseResponse(String responseBody, AppLocalizations l10n) {
    final data = jsonDecode(responseBody);
    if (data is! Map<String, dynamic> ||
        data['choices'] == null ||
        (data['choices'] as List).isEmpty) {
      throw Exception(l10n.providerInvalidResponseFormat);
    }

    final firstChoice = data['choices'][0];
    if (firstChoice['message'] == null) {
      throw Exception(l10n.providerMissingMessageField);
    }

    final message = firstChoice['message'];
    final reasoningContent = message['reasoning_content']?.toString().trim() ?? '';
    final content = message['content']?.toString().trim() ?? '';

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
