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

          final contents = await _buildContents(
            message: message,
            chatHistory: chatHistory,
            attachments: attachments,
            systemPrompt: systemPrompt,
            enableHistory: enableHistory,
            historyContextLength: historyContextLength,
          );

          return await _sendMessageRequest(
            client: client,
            apiEndpoint: apiEndpoint,
            apiKey: apiKey,
            model: model,
            temperature: temperature,
            maxTokens: maxTokens,
            contents: contents,
          );
        } finally {
          client.close();
        }
      },
      onRetry: (error, retryCount, delayMs) {
        debugPrint('Gemini API请求失败，第$retryCount次重试，延迟${delayMs}ms: $error');
      },
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
  }) async* {
    final client = _createHttpClient();
    try {
      final apiEndpoint = await _settingsService.getApiEndpoint();
      final apiKey = await _settingsService.getApiKey();
      final model = await _settingsService.getModel();
      final enableHistory = await _settingsService.getEnableHistory();
      final historyContextLength =
          await _settingsService.getHistoryContextLength();

      final contents = await _buildContents(
        message: message,
        chatHistory: chatHistory,
        attachments: attachments,
        systemPrompt: systemPrompt,
        enableHistory: enableHistory,
        historyContextLength: historyContextLength,
      );

      yield* _sendMessageStreamingRequest(
        client: client,
        apiEndpoint: apiEndpoint,
        apiKey: apiKey,
        model: model,
        temperature: temperature,
        maxTokens: maxTokens,
        contents: contents,
      );
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

    final contents = [
      {
        'role': 'user',
        'parts': [
          {
            'text': '请根据以下对话内容生成一个简短的标题（不超过15个字），标题应该概括对话的主要内容：\n\n$conversationSummary'
          }
        ]
      }
    ];

    String url = apiEndpoint;
    if (!url.contains('/models/')) {
      final modelPath = model.contains('/') ? model : 'models/$model';
      url = url.endsWith('/')
          ? '$url$modelPath:generateContent'
          : '$url/$modelPath:generateContent';
    } else if (!url.contains(':generateContent')) {
      url = url.endsWith('/')
          ? '${url}generateContent'
          : '$url:generateContent';
    }

    if (!url.contains('?key=')) {
      url = '$url?key=$apiKey';
    }

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
        throw Exception('Gemini API返回了无效的响应格式');
      }

      final candidates = data['candidates'];
      if (candidates is! List || candidates.isEmpty) {
        throw Exception('Gemini API响应中缺少candidates字段');
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

      throw Exception('无效的Gemini API响应格式');
    } else {
      final errorData = jsonDecode(response.body);
      final errorMessage = errorData['error']?['message']?.toString() ??
          errorData['message']?.toString() ??
          '未知错误';
      throw Exception('Gemini API错误: $errorMessage (状态码: ${response.statusCode})');
    }
  }

  /// 构建 Gemini contents 列表
  Future<List<Map<String, dynamic>>> _buildContents({
    required String message,
    required List<Message> chatHistory,
    required List<Attachment> attachments,
    required String systemPrompt,
    required bool enableHistory,
    required int historyContextLength,
  }) async {
    final contents = <Map<String, dynamic>>[];

    // 添加系统提示词（转换为用户-模型对话对）
    if (systemPrompt.isNotEmpty) {
      contents.add({
        'role': 'user',
        'parts': <Map<String, dynamic>>[
          {'text': systemPrompt}
        ]
      });
      contents.add({
        'role': 'model',
        'parts': <Map<String, dynamic>>[
          {'text': 'Understood. I will follow these instructions.'}
        ]
      });
    }

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
        contents.add({
          'role': historyMsg.isUser ? 'user' : 'model',
          'parts': <Map<String, dynamic>>[
            {'text': historyMsg.content}
          ]
        });
      }
    }

    // 添加当前用户消息
    final userMessageParts = <Map<String, dynamic>>[];

    if (message.isNotEmpty) {
      userMessageParts.add({'text': message});
    }

    if (attachments.isNotEmpty) {
      final fileParts = await _prepareFiles(attachments);
      userMessageParts.addAll(fileParts);
    }

    if (userMessageParts.isNotEmpty) {
      if (contents.isNotEmpty && contents.last['role'] == 'user') {
        final lastParts =
            (contents.last['parts'] as List<Map<String, dynamic>>);
        lastParts.addAll(userMessageParts);
      } else {
        contents.add({'role': 'user', 'parts': userMessageParts});
      }
    }

    return contents;
  }

  /// 为 Gemini API 准备文件附件
  Future<List<Map<String, dynamic>>> _prepareFiles(List<Attachment> attachments) async {
    final fileParts = <Map<String, dynamic>>[];

    final totalSize = attachments.fold<int>(
        0, (sum, attachment) => sum + (attachment.fileSize ?? 0));
    if (totalSize > AIProvider.maxTotalAttachmentsSize) {
      throw Exception('附件总大小超过${AIProvider.maxTotalAttachmentsSize ~/ (1024 * 1024)}MB限制');
    }

    for (final attachment in attachments) {
      try {
        if (attachment.filePath == null ||
            !await _fileService.fileExists(attachment.filePath!)) {
          fileParts.add({'text': '文件 ${attachment.fileName} 不存在或已删除'});
          continue;
        }

        final file = File(attachment.filePath!);
        final fileSize = attachment.fileSize ??
            await _fileService.getFileSize(attachment.filePath!);

        if (fileSize > AIProvider.maxFileSizeForBase64) {
          fileParts.add({
            'text':
                '文件 ${attachment.fileName} (${formatFileSize(fileSize)}) 过大，无法处理'
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

            fileParts.add({
              'inlineData': {
                'mimeType': attachment.mimeType ?? 'application/octet-stream',
                'data': cleanBase64
              }
            });
          } catch (e) {
            fileParts.add({'text': '处理文件 ${attachment.fileName} 时出错: $e'});
          }
        } else {
          if (fileSize <= AIProvider.maxFileSizeForTextExtraction) {
            try {
              final content = await _fileService.readTextFile(file);
              fileParts.add({
                'text':
                    '文件: ${attachment.fileName} (${formatFileSize(fileSize)})\n内容:\n$content'
              });
            } catch (e) {
              fileParts.add({
                'text':
                    '附件: ${attachment.fileName} (${formatFileSize(fileSize)}, ${attachment.mimeType ?? '未知类型'}) - 无法读取内容'
              });
            }
          } else {
            fileParts.add({
              'text':
                  '附件: ${attachment.fileName} (${formatFileSize(fileSize)}, ${attachment.mimeType ?? '未知类型'})'
            });
          }
        }
      } catch (e) {
        fileParts.add({'text': '处理文件 ${attachment.fileName} 时出错: $e'});
      }
    }

    return fileParts;
  }

  /// 发送 Gemini 非流式请求
  Future<String> _sendMessageRequest({
    required http.Client client,
    required String apiEndpoint,
    required String apiKey,
    required String model,
    required double temperature,
    required int maxTokens,
    required List<Map<String, dynamic>> contents,
  }) async {
    final requestBody = {
      'contents': contents,
      'generationConfig': {
        'temperature': temperature,
        'maxOutputTokens': maxTokens,
      }
    };

    String url = apiEndpoint;

    if (!url.contains('/models/')) {
      final modelPath = model.contains('/') ? model : 'models/$model';
      url = url.endsWith('/')
          ? '$url$modelPath:generateContent'
          : '$url/$modelPath:generateContent';
    } else if (!url.contains(':generateContent')) {
      url = url.endsWith('/')
          ? '${url}generateContent'
          : '$url:generateContent';
    }

    if (!url.contains('?key=')) {
      url = '$url?key=$apiKey';
    }

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
        throw Exception('Gemini API返回了无效的响应格式');
      }

      final candidates = data['candidates'];
      if (candidates is! List || candidates.isEmpty) {
        throw Exception('Gemini API响应中缺少candidates字段');
      }

      final candidate = candidates[0];
      if (candidate['finishReason'] == 'SAFETY') {
        throw Exception('响应被安全过滤器阻止');
      }
      if (candidate['content'] != null &&
          candidate['content']['parts'] != null &&
          candidate['content']['parts'].isNotEmpty) {
        return candidate['content']['parts'][0]['text'].trim();
      }

      throw Exception('无效的Gemini API响应格式');
    } else {
      final errorData = jsonDecode(response.body);
      if (errorData is! Map<String, dynamic>) {
        throw Exception(
            'Gemini API错误: 无效的响应格式 (状态码: ${response.statusCode})');
      }
      final errorMessage = errorData['error']?['message']?.toString() ??
          errorData['message']?.toString() ??
          '未知错误';
      throw Exception(
          'Gemini API错误: $errorMessage (状态码: ${response.statusCode})');
    }
  }

  /// 发送 Gemini 流式请求
  Stream<Map<String, dynamic>> _sendMessageStreamingRequest({
    required http.Client client,
    required String apiEndpoint,
    required String apiKey,
    required String model,
    required double temperature,
    required int maxTokens,
    required List<Map<String, dynamic>> contents,
  }) async* {
    final requestBody = {
      'contents': contents,
      'generationConfig': {
        'temperature': temperature,
        'maxOutputTokens': maxTokens,
      }
    };

    String url;
    if (apiEndpoint.contains('streamGenerateContent')) {
      url = apiEndpoint.contains('?key=')
          ? '$apiEndpoint&alt=sse'
          : '$apiEndpoint?key=$apiKey&alt=sse';
    } else {
      url = apiEndpoint.replaceFirst(
          'generateContent', 'streamGenerateContent');
      if (!url.contains('?key=')) {
        url = '$url?key=$apiKey';
      }
      url = '$url&alt=sse';
    }

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
            'Gemini API错误: 无效的响应格式 (状态码: ${streamedResponse.statusCode})');
      }
      final errorMessage = errorData['error']?['message']?.toString() ??
          errorData['message']?.toString() ??
          '未知错误';
      throw Exception(
          'Gemini API错误: $errorMessage (状态码: ${streamedResponse.statusCode})');
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
        throw TimeoutException('Gemini流式响应超时：超过${streamingTimeout.inSeconds}秒未收到新数据');
      }
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
