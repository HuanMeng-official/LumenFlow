import 'dart:convert';
import 'dart:async';
import 'dart:io';
import 'package:http/http.dart' as http;
import 'settings_service.dart';
import 'user_service.dart';
import 'file_service.dart';
import '../models/message.dart';
import '../models/attachment.dart';

class AIService {
  final SettingsService _settingsService = SettingsService();
  final UserService _userService = UserService();
  final FileService _fileService = FileService();

  // 文件大小限制（字节）
  static const int maxFileSizeForBase64 = 20 * 1024 * 1024; // 20MB
  static const int maxFileSizeForTextExtraction = 5 * 1024 * 1024; // 5MB
  static const int maxTotalAttachmentsSize = 50 * 1024 * 1024; // 50MB

  String _formatFileSize(int bytes) {
    if (bytes < 1024) {
      return '$bytes B';
    } else if (bytes < 1024 * 1024) {
      return '${(bytes / 1024).toStringAsFixed(1)} KB';
    } else if (bytes < 1024 * 1024 * 1024) {
      return '${(bytes / (1024 * 1024)).toStringAsFixed(1)} MB';
    } else {
      return '${(bytes / (1024 * 1024 * 1024)).toStringAsFixed(1)} GB';
    }
  }

  // 检查文件类型是否支持Vision API（图片、视频、音频）
  bool _isVisionSupportedFile(Attachment attachment) {
    final mimeType = attachment.mimeType?.toLowerCase() ?? '';
    return mimeType.startsWith('image/') ||
           mimeType.startsWith('video/') ||
           mimeType.startsWith('audio/');
  }

  // 构建OpenAI Vision API格式的消息内容
  Future<dynamic> _buildOpenAIMessageContent(String message, List<Attachment> attachments) async {
    if (attachments.isEmpty) {
      return message;
    }

    // 检查总附件大小
    final totalSize = attachments.fold<int>(0, (sum, attachment) => sum + (attachment.fileSize ?? 0));
    if (totalSize > maxTotalAttachmentsSize) {
      throw Exception('附件总大小超过${maxTotalAttachmentsSize ~/ (1024 * 1024)}MB限制');
    }

    final contentParts = <Map<String, dynamic>>[];

    // 添加文本部分（如果有）
    if (message.isNotEmpty) {
      contentParts.add({
        'type': 'text',
        'text': message
      });
    }

    for (final attachment in attachments) {
      try {
        if (attachment.filePath == null || !await _fileService.fileExists(attachment.filePath!)) {
          // 文件不存在，添加错误信息
          contentParts.add({
            'type': 'text',
            'text': '文件 ${attachment.fileName} 不存在或已删除'
          });
          continue;
        }

        final file = File(attachment.filePath!);
        final fileSize = attachment.fileSize ?? await _fileService.getFileSize(attachment.filePath!);

        // 检查单个文件大小
        if (fileSize > maxFileSizeForBase64) {
          contentParts.add({
            'type': 'text',
            'text': '文件 ${attachment.fileName} (${_formatFileSize(fileSize)}) 过大，无法处理'
          });
          continue;
        }

        if (_isVisionSupportedFile(attachment)) {
          // 支持Vision API的文件类型：图片、视频、音频
          try {
            final dataUrl = await _fileService.getFileDataUrl(file, attachment.mimeType);
            contentParts.add({
              'type': 'image_url',
              'image_url': {
                'url': dataUrl
              }
            });
          } catch (e) {
            contentParts.add({
              'type': 'text',
              'text': '处理文件 ${attachment.fileName} 时出错: $e'
            });
          }
        } else {
          // 不支持Vision API的文件类型：尝试读取文本内容
          if (fileSize <= maxFileSizeForTextExtraction) {
            try {
              final content = await _fileService.readTextFile(file);
              contentParts.add({
                'type': 'text',
                'text': '文件: ${attachment.fileName} (${_formatFileSize(fileSize)})\n内容:\n$content'
              });
            } catch (e) {
              // 读取失败，只发送文件名信息
              contentParts.add({
                'type': 'text',
                'text': '附件: ${attachment.fileName} (${_formatFileSize(fileSize)}, ${attachment.mimeType ?? '未知类型'}) - 无法读取内容'
              });
            }
          } else {
            // 文件太大，只发送文件名信息
            contentParts.add({
              'type': 'text',
              'text': '附件: ${attachment.fileName} (${_formatFileSize(fileSize)}, ${attachment.mimeType ?? '未知类型'})'
            });
          }
        }
      } catch (e) {
        contentParts.add({
          'type': 'text',
          'text': '处理文件 ${attachment.fileName} 时出错: $e'
        });
      }
    }

    // 如果只有一个文本部分，返回字符串（兼容性）
    if (contentParts.length == 1 && contentParts[0]['type'] == 'text') {
      return contentParts[0]['text'] as String;
    }

    return contentParts;
  }

  // 构建Gemini API格式的消息内容
  Future<List<Map<String, dynamic>>> _buildGeminiContents(
    String message,
    List<Message> chatHistory,
    List<Attachment> attachments,
    String systemPrompt,
    bool enableHistory,
    int historyContextLength,
  ) async {
    final contents = <Map<String, dynamic>>[];

    // 处理系统提示：作为第一个用户消息，然后是模型确认
    if (systemPrompt.isNotEmpty) {
      contents.add({
        'role': 'user',
        'parts': [
          {'text': systemPrompt}
        ]
      });
      contents.add({
        'role': 'model',
        'parts': [
          {'text': 'Understood. I will follow these instructions.'}
        ]
      });
    }

    // 处理历史对话
    if (enableHistory && chatHistory.isNotEmpty) {
      final recentHistory = chatHistory
          .where((msg) => msg.status != MessageStatus.error)
          .toList()
          .reversed
          .take(historyContextLength * 2)
          .toList()
          .reversed
          .toList();

      for (final historyMsg in recentHistory) {
        contents.add({
          'role': historyMsg.isUser ? 'user' : 'model',
          'parts': [
            {'text': historyMsg.content}
          ]
        });
      }
    }

    // 处理当前消息和附件
    final userMessageParts = <Map<String, dynamic>>[];

    // 添加文本部分
    if (message.isNotEmpty) {
      userMessageParts.add({'text': message});
    }

    // 添加文件附件部分
    if (attachments.isNotEmpty) {
      final fileParts = await _prepareFilesForGemini(attachments);
      userMessageParts.addAll(fileParts);
    }

    // 只有当有内容时才添加用户消息
    if (userMessageParts.isNotEmpty) {
      // 如果上一条消息已经是用户消息，则合并
      if (contents.isNotEmpty && contents.last['role'] == 'user') {
        final lastParts = (contents.last['parts'] as List<Map<String, dynamic>>);
        lastParts.addAll(userMessageParts);
      } else {
        contents.add({
          'role': 'user',
          'parts': userMessageParts
        });
      }
    }

    return contents;
  }

  // 准备文件附件用于Gemini API
  Future<List<Map<String, dynamic>>> _prepareFilesForGemini(List<Attachment> attachments) async {
    final fileParts = <Map<String, dynamic>>[];

    // 检查总附件大小
    final totalSize = attachments.fold<int>(0, (sum, attachment) => sum + (attachment.fileSize ?? 0));
    if (totalSize > maxTotalAttachmentsSize) {
      throw Exception('附件总大小超过${maxTotalAttachmentsSize ~/ (1024 * 1024)}MB限制');
    }

    for (final attachment in attachments) {
      try {
        if (attachment.filePath == null || !await _fileService.fileExists(attachment.filePath!)) {
          fileParts.add({
            'text': '文件 ${attachment.fileName} 不存在或已删除'
          });
          continue;
        }

        final file = File(attachment.filePath!);
        final fileSize = attachment.fileSize ?? await _fileService.getFileSize(attachment.filePath!);

        // 检查单个文件大小
        if (fileSize > maxFileSizeForBase64) {
          fileParts.add({
            'text': '文件 ${attachment.fileName} (${_formatFileSize(fileSize)}) 过大，无法处理'
          });
          continue;
        }

        // 检查是否为支持的媒体类型（图片、视频、音频）
        final mimeType = attachment.mimeType?.toLowerCase() ?? '';
        final isSupportedMedia = mimeType.startsWith('image/') ||
                                mimeType.startsWith('video/') ||
                                mimeType.startsWith('audio/');

        if (isSupportedMedia) {
          try {
            // 获取base64数据（不含data URL前缀）
            final base64Data = await _fileService.getFileBase64(file);
            // 移除可能的data URL前缀
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
            fileParts.add({
              'text': '处理文件 ${attachment.fileName} 时出错: $e'
            });
          }
        } else {
          // 非媒体文件：尝试读取文本内容
          if (fileSize <= maxFileSizeForTextExtraction) {
            try {
              final content = await _fileService.readTextFile(file);
              fileParts.add({
                'text': '文件: ${attachment.fileName} (${_formatFileSize(fileSize)})\n内容:\n$content'
              });
            } catch (e) {
              // 读取失败，只发送文件名信息
              fileParts.add({
                'text': '附件: ${attachment.fileName} (${_formatFileSize(fileSize)}, ${attachment.mimeType ?? '未知类型'}) - 无法读取内容'
              });
            }
          } else {
            // 文件太大，只发送文件名信息
            fileParts.add({
              'text': '附件: ${attachment.fileName} (${_formatFileSize(fileSize)}, ${attachment.mimeType ?? '未知类型'})'
            });
          }
        }
      } catch (e) {
        fileParts.add({
          'text': '处理文件 ${attachment.fileName} 时出错: $e'
        });
      }
    }

    return fileParts;
  }

  Future<String> sendMessage(String message, List<Message> chatHistory, {List<Attachment> attachments = const []}) async {
    final apiEndpoint = await _settingsService.getApiEndpoint();
    final apiKey = await _settingsService.getApiKey();
    final model = await _settingsService.getModel();
    final temperature = await _settingsService.getTemperature();
    final maxTokens = await _settingsService.getMaxTokens();
    final enableHistory = await _settingsService.getEnableHistory();
    final historyContextLength = await _settingsService.getHistoryContextLength();
    final userProfile = await _userService.getUserProfile();
    final customSystemPrompt = await _settingsService.getCustomSystemPrompt();
    final apiType = await _settingsService.getApiType();

    if (apiKey.isEmpty) {
      throw Exception('请先在设置中配置API密钥');
    }

    try {
      List<Map<String, dynamic>> messages = [];

      String baseSystemPrompt = '用户的名字是"${userProfile.username}",请在对话中适当地使用这个名字来称呼用户。';
      String fullSystemPrompt = baseSystemPrompt;
      if (customSystemPrompt.isNotEmpty) {
        fullSystemPrompt += customSystemPrompt;
      }

      messages.add({
        'role': 'system',
        'content': fullSystemPrompt,
      });

      if (enableHistory && chatHistory.isNotEmpty) {
        final recentHistory = chatHistory
            .where((msg) => msg.status != MessageStatus.error)
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

      final userMessageContent = await _buildOpenAIMessageContent(message, attachments);
      messages.add({
        'role': 'user',
        'content': userMessageContent,
      });

      String responseText;
      if (apiType == 'gemini') {
        // 构建Gemini格式的消息内容
        final contents = await _buildGeminiContents(
          message,
          chatHistory,
          attachments,
          fullSystemPrompt,
          enableHistory,
          historyContextLength,
        );

        responseText = await _sendGeminiMessage(
          apiEndpoint: apiEndpoint,
          apiKey: apiKey,
          model: model,
          temperature: temperature,
          maxTokens: maxTokens,
          contents: contents,
        );
      } else {
        final response = await http.post(
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
          }),
        );

        if (response.statusCode == 200) {
          final data = jsonDecode(response.body);
          responseText = data['choices'][0]['message']['content'].trim();
        } else {
          final errorData = jsonDecode(response.body);
          throw Exception('API错误: ${errorData['error']['message'] ?? response.statusCode}');
        }
      }

      return responseText;
    } catch (e) {
      if (e.toString().contains('API错误')) {
        rethrow;
      }
      throw Exception('网络错误: $e');
    }
  }

  Stream<String> sendMessageStreaming(String message, List<Message> chatHistory, {List<Attachment> attachments = const []}) async* {
    final apiEndpoint = await _settingsService.getApiEndpoint();
    final apiKey = await _settingsService.getApiKey();
    final model = await _settingsService.getModel();
    final temperature = await _settingsService.getTemperature();
    final maxTokens = await _settingsService.getMaxTokens();
    final enableHistory = await _settingsService.getEnableHistory();
    final historyContextLength = await _settingsService.getHistoryContextLength();
    final userProfile = await _userService.getUserProfile();
    final customSystemPrompt = await _settingsService.getCustomSystemPrompt();
    final apiType = await _settingsService.getApiType();

    if (apiKey.isEmpty) {
      throw Exception('请先在设置中配置API密钥');
    }

    try {
      if (apiType == 'gemini') {
        // 构建Gemini格式的消息内容
        final contents = await _buildGeminiContents(
          message,
          chatHistory,
          attachments,
          '用户的名字是"${userProfile.username}",请在对话中适当地使用这个名字来称呼用户。${customSystemPrompt.isNotEmpty ? customSystemPrompt : ''}',
          enableHistory,
          historyContextLength,
        );

        // 使用Gemini流式API
        yield* _sendGeminiMessageStreaming(
          apiEndpoint: apiEndpoint,
          apiKey: apiKey,
          model: model,
          temperature: temperature,
          maxTokens: maxTokens,
          contents: contents,
        );
        return;
      }

      // OpenAI格式处理
      List<Map<String, dynamic>> messages = [];

      String baseSystemPrompt = '用户的名字是"${userProfile.username}",请在对话中适当地使用这个名字来称呼用户。';
      String fullSystemPrompt = baseSystemPrompt;
      if (customSystemPrompt.isNotEmpty) {
        fullSystemPrompt += customSystemPrompt;
      }

      messages.add({
        'role': 'system',
        'content': fullSystemPrompt,
      });

      if (enableHistory && chatHistory.isNotEmpty) {
        final recentHistory = chatHistory
            .where((msg) => msg.status != MessageStatus.error)
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

      final userMessageContent = await _buildOpenAIMessageContent(message, attachments);
      messages.add({
        'role': 'user',
        'content': userMessageContent,
      });

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
      });

      final client = http.Client();
      try {
        final streamedResponse = await client.send(request);

        if (streamedResponse.statusCode != 200) {
          final errorBody = await streamedResponse.stream.transform(utf8.decoder).join();
          final errorData = jsonDecode(errorBody);
          throw Exception('API错误: ${errorData['error']['message'] ?? streamedResponse.statusCode}');
        }

        final stream = streamedResponse.stream
            .transform(utf8.decoder)
            .transform(const LineSplitter());

        await for (final line in stream) {
          if (line.isEmpty) continue;
          if (line.startsWith('data: ')) {
            final data = line.substring(6);
            if (data == '[DONE]') {
              break;
            }
            try {
              final jsonData = jsonDecode(data);
              final delta = jsonData['choices'][0]['delta'];
              if (delta.containsKey('content')) {
                final content = delta['content'] as String;
                yield content;
              }
            } catch (e) {
              // Ignore parsing errors for incomplete JSON
            }
          }
        }
      } finally {
        client.close();
      }
    } catch (e) {
      if (e.toString().contains('API错误')) {
        rethrow;
      }
      throw Exception('网络错误: $e');
    }
  }

  Future<String> _sendGeminiMessage({
    required String apiEndpoint,
    required String apiKey,
    required String model,
    required double temperature,
    required int maxTokens,
    required List<Map<String, dynamic>> contents,
  }) async {
    try {
      // 构建Gemini API请求体
      final requestBody = {
        'contents': contents,
        'generationConfig': {
          'temperature': temperature,
          'maxOutputTokens': maxTokens,
        }
      };

      // 构建URL
      // Gemini API端点格式: https://generativelanguage.googleapis.com/v1beta/models/{model}:generateContent?key={apiKey}
      String url = apiEndpoint;

      // 确保端点包含模型路径
      if (!url.contains('/models/')) {
        // 如果端点只是基础URL，添加模型路径
        final modelPath = model.contains('/') ? model : 'models/$model';
        url = url.endsWith('/') ? '$url$modelPath:generateContent' : '$url/$modelPath:generateContent';
      } else if (!url.contains(':generateContent')) {
        // 如果端点包含模型路径但没有方法，添加generateContent
        url = url.endsWith('/') ? '${url}generateContent' : '$url:generateContent';
      }

      // 添加API密钥参数
      if (!url.contains('?key=')) {
        url = '$url?key=$apiKey';
      }

      final response = await http.post(
        Uri.parse(url),
        headers: {
          'Content-Type': 'application/json',
        },
        body: jsonEncode(requestBody),
      );

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);

        // 解析Gemini响应
        if (data['candidates'] != null && data['candidates'].isNotEmpty) {
          final candidate = data['candidates'][0];
          if (candidate['finishReason'] == 'SAFETY') {
            throw Exception('响应被安全过滤器阻止');
          }
          if (candidate['content'] != null &&
              candidate['content']['parts'] != null &&
              candidate['content']['parts'].isNotEmpty) {
            return candidate['content']['parts'][0]['text'].trim();
          }
        }
        throw Exception('无效的Gemini API响应格式');
      } else {
        final errorData = jsonDecode(response.body);
        final errorMessage = errorData['error']?['message'] ?? errorData['message'] ?? '未知错误';
        throw Exception('Gemini API错误: $errorMessage (状态码: ${response.statusCode})');
      }
    } catch (e) {
      if (e is Exception) rethrow;
      throw Exception('Gemini API请求失败: $e');
    }
  }

  Stream<String> _sendGeminiMessageStreaming({
    required String apiEndpoint,
    required String apiKey,
    required String model,
    required double temperature,
    required int maxTokens,
    required List<Map<String, dynamic>> contents,
  }) async* {
    try {
      // 构建Gemini API请求体
      final requestBody = {
        'contents': contents,
        'generationConfig': {
          'temperature': temperature,
          'maxOutputTokens': maxTokens,
        }
      };

      // 构建流式URL
      // Gemini流式端点格式: https://generativelanguage.googleapis.com/v1beta/models/{model}:streamGenerateContent?key={apiKey}&alt=sse
      String url;
      if (apiEndpoint.contains('streamGenerateContent')) {
        url = apiEndpoint.contains('?key=')
            ? '$apiEndpoint&alt=sse'
            : '$apiEndpoint?key=$apiKey&alt=sse';
      } else {
        // 替换generateContent为streamGenerateContent
        url = apiEndpoint.replaceFirst('generateContent', 'streamGenerateContent');
        if (!url.contains('?key=')) {
          url = '$url?key=$apiKey';
        }
        url = '$url&alt=sse';
      }

      final request = http.Request('POST', Uri.parse(url));
      request.headers['Content-Type'] = 'application/json';
      request.headers['Accept'] = 'text/event-stream';
      request.body = jsonEncode(requestBody);

      final client = http.Client();
      try {
        final streamedResponse = await client.send(request);

        if (streamedResponse.statusCode != 200) {
          final errorBody = await streamedResponse.stream.transform(utf8.decoder).join();
          final errorData = jsonDecode(errorBody);
          final errorMessage = errorData['error']?['message'] ?? errorData['message'] ?? '未知错误';
          throw Exception('Gemini API错误: $errorMessage (状态码: ${streamedResponse.statusCode})');
        }

        final stream = streamedResponse.stream
            .transform(utf8.decoder)
            .transform(const LineSplitter());

        await for (final line in stream) {
          if (line.isEmpty) continue;
          if (line.startsWith('data: ')) {
            final data = line.substring(6);
            if (data == '[DONE]') {
              break;
            }
            try {
              final jsonData = jsonDecode(data);
              // 解析Gemini流式响应
              if (jsonData['candidates'] != null && jsonData['candidates'].isNotEmpty) {
                final candidate = jsonData['candidates'][0];
                if (candidate['content'] != null &&
                    candidate['content']['parts'] != null &&
                    candidate['content']['parts'].isNotEmpty) {
                  final text = candidate['content']['parts'][0]['text'] as String?;
                  if (text != null && text.isNotEmpty) {
                    yield text;
                  }
                }
              }
            } catch (e) {
              // 忽略解析错误
            }
          }
        }
      } finally {
        client.close();
      }
    } catch (e) {
      if (e is Exception) rethrow;
      throw Exception('Gemini API流式请求失败: $e');
    }
  }
}