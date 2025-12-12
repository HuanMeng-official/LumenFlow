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

  static const int maxFileSizeForBase64 = 25 * 1024 * 1024;
  static const int maxFileSizeForTextExtraction = 10 * 1024 * 1024;
  static const int maxTotalAttachmentsSize = 50 * 1024 * 1024;

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

  bool _isVisionSupportedFile(Attachment attachment) {
    final mimeType = attachment.mimeType?.toLowerCase() ?? '';
    return mimeType.startsWith('image/') ||
           mimeType.startsWith('video/') ||
           mimeType.startsWith('audio/');
  }

  Future<dynamic> _buildOpenAIMessageContent(String message, List<Attachment> attachments) async {
    if (attachments.isEmpty) {
      return message;
    }

    final totalSize = attachments.fold<int>(0, (sum, attachment) => sum + (attachment.fileSize ?? 0));
    if (totalSize > maxTotalAttachmentsSize) {
      throw Exception('附件总大小超过${maxTotalAttachmentsSize ~/ (1024 * 1024)}MB限制');
    }

    final contentParts = <Map<String, dynamic>>[];

    if (message.isNotEmpty) {
      contentParts.add({
        'type': 'text',
        'text': message
      });
    }

    for (final attachment in attachments) {
      try {
        if (attachment.filePath == null || !await _fileService.fileExists(attachment.filePath!)) {
          contentParts.add({
            'type': 'text',
            'text': '文件 ${attachment.fileName} 不存在或已删除'
          });
          continue;
        }

        final file = File(attachment.filePath!);
        final fileSize = attachment.fileSize ?? await _fileService.getFileSize(attachment.filePath!);

        if (fileSize > maxFileSizeForBase64) {
          contentParts.add({
            'type': 'text',
            'text': '文件 ${attachment.fileName} (${_formatFileSize(fileSize)}) 过大，无法处理'
          });
          continue;
        }

        if (_isVisionSupportedFile(attachment)) {
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
          if (fileSize <= maxFileSizeForTextExtraction) {
            try {
              final content = await _fileService.readTextFile(file);
              contentParts.add({
                'type': 'text',
                'text': '文件: ${attachment.fileName} (${_formatFileSize(fileSize)})\n内容:\n$content'
              });
            } catch (e) {
              contentParts.add({
                'type': 'text',
                'text': '附件: ${attachment.fileName} (${_formatFileSize(fileSize)}, ${attachment.mimeType ?? '未知类型'}) - 无法读取内容'
              });
            }
          } else {
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

    if (contentParts.length == 1 && contentParts[0]['type'] == 'text') {
      return contentParts[0]['text'] as String;
    }

    return contentParts;
  }

  Future<List<Map<String, dynamic>>> _buildGeminiContents(
    String message,
    List<Message> chatHistory,
    List<Attachment> attachments,
    String systemPrompt,
    bool enableHistory,
    int historyContextLength,
  ) async {
    final contents = <Map<String, dynamic>>[];

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

    final userMessageParts = <Map<String, dynamic>>[];

    if (message.isNotEmpty) {
      userMessageParts.add({'text': message});
    }

    if (attachments.isNotEmpty) {
      final fileParts = await _prepareFilesForGemini(attachments);
      userMessageParts.addAll(fileParts);
    }

    if (userMessageParts.isNotEmpty) {
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

  Future<List<Map<String, dynamic>>> _prepareFilesForGemini(List<Attachment> attachments) async {
    final fileParts = <Map<String, dynamic>>[];

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

        if (fileSize > maxFileSizeForBase64) {
          fileParts.add({
            'text': '文件 ${attachment.fileName} (${_formatFileSize(fileSize)}) 过大，无法处理'
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
            fileParts.add({
              'text': '处理文件 ${attachment.fileName} 时出错: $e'
            });
          }
        } else {
          if (fileSize <= maxFileSizeForTextExtraction) {
            try {
              final content = await _fileService.readTextFile(file);
              fileParts.add({
                'text': '文件: ${attachment.fileName} (${_formatFileSize(fileSize)})\n内容:\n$content'
              });
            } catch (e) {
              fileParts.add({
                'text': '附件: ${attachment.fileName} (${_formatFileSize(fileSize)}, ${attachment.mimeType ?? '未知类型'}) - 无法读取内容'
              });
            }
          } else {
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
        final contents = await _buildGeminiContents(
          message,
          chatHistory,
          attachments,
          '用户的名字是"${userProfile.username}",请在对话中适当地使用这个名字来称呼用户。${customSystemPrompt.isNotEmpty ? customSystemPrompt : ''}',
          enableHistory,
          historyContextLength,
        );

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
        url = url.endsWith('/') ? '$url$modelPath:generateContent' : '$url/$modelPath:generateContent';
      } else if (!url.contains(':generateContent')) {
        url = url.endsWith('/') ? '${url}generateContent' : '$url:generateContent';
      }

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