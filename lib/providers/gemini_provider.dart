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

/// Google Gemini API Provider 实现
/// 负责处理与 Google Gemini API 的通信
class GeminiProvider extends AIProvider {
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
    return await _executeWithRetry<String>(
      () async {
        final client = _createHttpClient();
        try {
          final apiEndpoint = await _settingsService.getApiEndpoint();
          final apiKey = await _settingsService.getApiKey();
          final model = await _settingsService.getModel();
          final enableHistory = await _settingsService.getEnableHistory();
          final historyContextLength =
              await _settingsService.getHistoryContextLength();

          final requestBody = await _buildRequestBody(
            message: message,
            chatHistory: chatHistory,
            attachments: attachments,
            systemPrompt: systemPrompt,
            temperature: temperature,
            maxTokens: maxTokens,
            thinkingMode: thinkingMode,
            enableHistory: enableHistory,
            historyContextLength: historyContextLength,
            l10n: l10n,
          );

          final url = _buildApiUrl(
            apiEndpoint: apiEndpoint,
            apiKey: apiKey,
            model: model,
            action: 'generateContent',
          );

          return await _sendNonStreamingRequest(
            client: client,
            url: url,
            requestBody: requestBody,
            l10n: l10n,
          );
        } finally {
          client.close();
        }
      },
      onRetry: (error, retryCount, delayMs) {
        debugPrint('Gemini API请求失败，第$retryCount次重试，延迟${delayMs}ms: $error');
      },
      l10n: l10n,
    ).then((responseText) => {
      'reasoningContent': '',
      'content': responseText,
    });
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

      final requestBody = await _buildRequestBody(
        message: message,
        chatHistory: chatHistory,
        attachments: attachments,
        systemPrompt: systemPrompt,
        temperature: temperature,
        maxTokens: maxTokens,
        thinkingMode: thinkingMode,
        enableHistory: enableHistory,
        historyContextLength: historyContextLength,
        l10n: l10n,
      );

      final url = _buildApiUrl(
        apiEndpoint: apiEndpoint,
        apiKey: apiKey,
        model: model,
        action: 'streamGenerateContent',
        isStreaming: true,
      );

      yield* _sendStreamingRequest(
        client: client,
        url: url,
        requestBody: requestBody,
        l10n: l10n,
      );
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

    final contents = [
      {
        'role': 'user',
        'parts': [
          {
            'text': l10n.providerTitleGenUserPrompt(conversationSummary)
          }
        ]
      }
    ];

    final url = _buildApiUrl(
      apiEndpoint: apiEndpoint,
      apiKey: apiKey,
      model: model,
      action: 'generateContent',
    );

    final response = await http.post(
      Uri.parse(url),
      headers: {
        'Content-Type': 'application/json',
      },
      body: jsonEncode({
        'contents': contents,
        'generationConfig': {
          'temperature': 0.3,
          'maxOutputTokens': 50,
        }
      }),
    );

    if (response.statusCode == 200) {
      final data = jsonDecode(response.body);
      if (data is! Map<String, dynamic>) {
        throw Exception(l10n.providerGeminiInvalidResponse);
      }

      final candidates = data['candidates'];
      if (candidates is! List || candidates.isEmpty) {
        throw Exception(l10n.providerGeminiMissingCandidates);
      }

      final candidate = candidates[0];
      if (candidate['content'] != null &&
          candidate['content']['parts'] != null &&
          candidate['content']['parts'].isNotEmpty) {
        var title = candidate['content']['parts'][0]['text'].toString().trim();

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
      }

      throw Exception(l10n.providerGeminiInvalidFormat);
    } else {
      final errorData = jsonDecode(response.body);
      final errorMessage = errorData['error']?['message']?.toString() ??
          errorData['message']?.toString() ??
          l10n.providerUnknownError;
      throw Exception(l10n.providerGeminiError(errorMessage, response.statusCode));
    }
  }

  /// 构建符合 Gemini API 标准的请求体
  Future<Map<String, dynamic>> _buildRequestBody({
    required String message,
    required List<Message> chatHistory,
    required List<Attachment> attachments,
    required String systemPrompt,
    required double temperature,
    required int maxTokens,
    required bool thinkingMode,
    required bool enableHistory,
    required int historyContextLength,
    required AppLocalizations l10n,
  }) async {
    final contents = await _buildContents(
      message: message,
      chatHistory: chatHistory,
      attachments: attachments,
      enableHistory: enableHistory,
      historyContextLength: historyContextLength,
      l10n: l10n,
    );

    final requestBody = <String, dynamic>{
      'contents': contents,
      'generationConfig': _buildGenerationConfig(
        temperature: temperature,
        maxTokens: maxTokens,
        thinkingMode: thinkingMode,
      ),
    };

    // 添加系统指令（如果提供）
    if (systemPrompt.isNotEmpty) {
      requestBody['system_instruction'] = {
        'parts': [
          {'text': systemPrompt}
        ]
      };
    }

    return requestBody;
  }

  /// 构建 generationConfig
  Map<String, dynamic> _buildGenerationConfig({
    required double temperature,
    required int maxTokens,
    required bool thinkingMode,
  }) {
    final config = <String, dynamic>{
      'temperature': temperature,
      'maxOutputTokens': maxTokens,
    };

    // 添加思考模式配置
    if (thinkingMode) {
      config['thinkingConfig'] = {
        'thinkingBudget': 0, // 0 表示启用思考模式
      };
    }

    return config;
  }

  /// 构建 contents 列表（符合 Gemini API 标准）
  Future<List<Map<String, dynamic>>> _buildContents({
    required String message,
    required List<Message> chatHistory,
    required List<Attachment> attachments,
    required bool enableHistory,
    required int historyContextLength,
    required AppLocalizations l10n,
  }) async {
    final contents = <Map<String, dynamic>>[];

    // 添加历史消息（多轮对话）
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
        contents.add({
          'role': historyMsg.isUser ? 'user' : 'model',
          'parts': <Map<String, dynamic>>[
            {'text': historyMsg.content}
          ]
        });
      }
    }

    // 构建当前用户消息的 parts
    final userMessageParts = <Map<String, dynamic>>[];

    if (message.isNotEmpty) {
      userMessageParts.add({'text': message});
    }

    if (attachments.isNotEmpty) {
      final fileParts = await _prepareFiles(attachments, l10n);
      userMessageParts.addAll(fileParts);
    }

    if (userMessageParts.isNotEmpty) {
      contents.add({'role': 'user', 'parts': userMessageParts});
    }

    return contents;
  }

  /// 为 Gemini API 准备文件附件
  /// 使用 inlineData 格式（兼容性更好）
  Future<List<Map<String, dynamic>>> _prepareFiles(List<Attachment> attachments, AppLocalizations l10n) async {
    final fileParts = <Map<String, dynamic>>[];

    final totalSize = attachments.fold<int>(
        0, (sum, attachment) => sum + (attachment.fileSize ?? 0));
    if (totalSize > AIProvider.maxTotalAttachmentsSize) {
      throw Exception(l10n.providerTotalSizeExceeded(AIProvider.maxTotalAttachmentsSize ~/ (1024 * 1024)));
    }

    for (final attachment in attachments) {
      try {
        if (attachment.filePath == null ||
            !await _fileService.fileExists(attachment.filePath!)) {
          fileParts.add({'text': l10n.providerFileNotFound(attachment.fileName)});
          continue;
        }

        final file = File(attachment.filePath!);
        final fileSize = attachment.fileSize ??
            await _fileService.getFileSize(attachment.filePath!);

        if (fileSize > AIProvider.maxFileSizeForBase64) {
          fileParts.add({
            'text': l10n.providerFileTooLarge(attachment.fileName, formatFileSize(fileSize))
          });
          continue;
        }

        final mimeType = attachment.mimeType?.toLowerCase() ?? '';
        final isSupportedMedia = mimeType.startsWith('image/') ||
            mimeType.startsWith('video/') ||
            mimeType.startsWith('audio/');

        if (isSupportedMedia) {
          try {
            final base64Data = await _fileService.getFileBase64(file);
            String cleanBase64 = base64Data;
            if (base64Data.contains(',')) {
              cleanBase64 = base64Data.split(',').last;
            }

            // 使用 inlineData 格式（兼容性更好）
            fileParts.add({
              'inlineData': {
                'mimeType': attachment.mimeType ?? 'application/octet-stream',
                'data': cleanBase64
              }
            });
          } catch (e) {
            fileParts.add({'text': l10n.providerFileProcessError(attachment.fileName, e.toString())});
          }
        } else {
          // 对于非多媒体文件，提取文本内容
          if (fileSize <= AIProvider.maxFileSizeForTextExtraction) {
            try {
              final content = await _fileService.readTextFile(file);
              fileParts.add({
                'text': l10n.providerFileContent(
                  attachment.fileName,
                  formatFileSize(fileSize),
                  content
                )
              });
            } catch (e) {
              fileParts.add({
                'text': l10n.providerAttachmentCannotRead(
                  attachment.fileName,
                  formatFileSize(fileSize),
                  attachment.mimeType ?? l10n.unknownMimeType
                )
              });
            }
          } else {
            fileParts.add({
              'text': l10n.providerAttachmentInfo(
                attachment.fileName,
                formatFileSize(fileSize),
                attachment.mimeType ?? l10n.unknownMimeType
              )
            });
          }
        }
      } catch (e) {
        fileParts.add({'text': l10n.providerFileProcessError(attachment.fileName, e.toString())});
      }
    }

    return fileParts;
  }

  /// 发送非流式请求
  Future<String> _sendNonStreamingRequest({
    required http.Client client,
    required String url,
    required Map<String, dynamic> requestBody,
    required AppLocalizations l10n,
  }) async {
    final response = await client.post(
      Uri.parse(url),
      headers: {
        'Content-Type': 'application/json',
      },
      body: jsonEncode(requestBody),
    ).timeout(connectionTimeout + readTimeout);

    if (response.statusCode == 200) {
      final data = jsonDecode(response.body);
      if (data is! Map<String, dynamic>) {
        throw Exception(l10n.providerGeminiInvalidResponse);
      }

      final candidates = data['candidates'];
      if (candidates is! List || candidates.isEmpty) {
        throw Exception(l10n.providerGeminiMissingCandidates);
      }

      final candidate = candidates[0];
      if (candidate['finishReason'] == 'SAFETY') {
        throw Exception(l10n.providerResponseBlocked);
      }
      if (candidate['content'] != null &&
          candidate['content']['parts'] != null &&
          candidate['content']['parts'].isNotEmpty) {
        return candidate['content']['parts'][0]['text'].trim();
      }

      throw Exception(l10n.providerGeminiInvalidFormat);
    } else {
      final errorData = jsonDecode(response.body);
      if (errorData is! Map<String, dynamic>) {
        throw Exception(l10n.providerGeminiInvalidFormatWithCode(response.statusCode));
      }
      final errorMessage = errorData['error']?['message']?.toString() ??
          errorData['message']?.toString() ??
          l10n.providerUnknownError;
      throw Exception(l10n.providerGeminiError(errorMessage, response.statusCode));
    }
  }

  /// 发送流式请求
  Stream<Map<String, dynamic>> _sendStreamingRequest({
    required http.Client client,
    required String url,
    required Map<String, dynamic> requestBody,
    required AppLocalizations l10n,
  }) async* {
    final request = http.Request('POST', Uri.parse(url));
    request.headers['Content-Type'] = 'application/json';
    request.headers['Accept'] = 'text/event-stream';
    request.body = jsonEncode(requestBody);

    final streamedResponse = await client.send(request).timeout(streamingTimeout);

    if (streamedResponse.statusCode != 200) {
      final errorBody =
          await streamedResponse.stream.transform(utf8.decoder).join();
      final errorData = jsonDecode(errorBody);
      if (errorData is! Map<String, dynamic>) {
        throw Exception(
            l10n.providerGeminiInvalidFormatWithCode(streamedResponse.statusCode));
      }
      final errorMessage = errorData['error']?['message']?.toString() ??
          errorData['message']?.toString() ??
          l10n.providerUnknownError;
      throw Exception(
          l10n.providerGeminiError(errorMessage, streamedResponse.statusCode));
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
          if (jsonData is! Map<String, dynamic>) {
            continue;
          }
          final candidates = jsonData['candidates'];
          if (candidates is! List || candidates.isEmpty) {
            continue;
          }
          final candidate = candidates[0];
          if (candidate is! Map<String, dynamic>) {
            continue;
          }
          final content = candidate['content'];
          if (content is! Map<String, dynamic>) {
            continue;
          }
          final parts = content['parts'];
          if (parts is! List || parts.isEmpty) {
            continue;
          }
          final firstPart = parts[0];
          if (firstPart is! Map<String, dynamic>) {
            continue;
          }
          final text = firstPart['text'] as String?;
          if (text != null && text.isNotEmpty) {
            yield {'type': 'answer', 'content': text};
          }
        } catch (e) {
          // 忽略解析错误
        }
      }

      if (stopwatch.elapsed > streamingTimeout) {
        throw TimeoutException(l10n.providerGeminiStreamingTimeout(streamingTimeout.inSeconds));
      }
    }
  }

  /// 构建完整的 API URL
  /// 支持自定义端点和代理
  String _buildApiUrl({
    required String apiEndpoint,
    required String apiKey,
    required String model,
    required String action,
    bool isStreaming = false,
  }) {
    String url = apiEndpoint;

    // 如果端点不包含 /models/，则构建完整路径
    if (!url.contains('/models/')) {
      final modelPath = model.contains('/') ? model : 'models/$model';
      url = url.endsWith('/')
          ? '$url$modelPath:$action'
          : '$url/$modelPath:$action';
    } else if (!url.contains(':$action') && !url.contains(':generateContent') && !url.contains(':streamGenerateContent')) {
      // 如果端点已包含 /models/ 但不包含 action，则添加 action
      url = url.endsWith('/')
          ? '$url$action'
          : '$url:$action';
    }

    // 添加 API 密钥
    if (!url.contains('?key=')) {
      url = '$url?key=$apiKey';
    }

    // 对于流式请求，添加 alt=sse 参数
    if (isStreaming && !url.contains('alt=sse')) {
      url = '$url&alt=sse';
    }

    return url;
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
