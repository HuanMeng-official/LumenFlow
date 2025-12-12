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

  Future<String> _buildMessageWithAttachments(String message, List<Attachment> attachments) async {
    if (attachments.isEmpty) {
      return message;
    }

    // 检查总附件大小
    final totalSize = attachments.fold<int>(0, (sum, attachment) => sum + (attachment.fileSize ?? 0));
    if (totalSize > maxTotalAttachmentsSize) {
      throw Exception('附件总大小超过${maxTotalAttachmentsSize ~/ (1024 * 1024)}MB限制');
    }

    final buffer = StringBuffer();
    if (message.isNotEmpty) {
      buffer.write(message);
      buffer.write('\n\n');
    }

    buffer.write('附件（${attachments.length}个）：\n');

    for (final attachment in attachments) {
      try {
        if (attachment.filePath == null || !await _fileService.fileExists(attachment.filePath!)) {
          buffer.write('- ${attachment.fileName}（文件不存在或已删除）\n');
          continue;
        }

        final file = File(attachment.filePath!);
        final fileSize = attachment.fileSize ?? await _fileService.getFileSize(attachment.filePath!);

        // 检查单个文件大小
        if (fileSize > maxFileSizeForBase64) {
          buffer.write('- ${attachment.fileName}（${_formatFileSize(fileSize)}，文件过大，无法处理）\n');
          continue;
        }

        // 处理文本文件：直接读取内容
        if (attachment.type == AttachmentType.document && fileSize <= maxFileSizeForTextExtraction) {
          try {
            final content = await _fileService.readTextFile(file);
            buffer.write('--- 文件：${attachment.fileName}（${_formatFileSize(fileSize)}）---\n');
            buffer.write(content);
            buffer.write('\n--- 文件结束 ---\n\n');
          } catch (e) {
            // 如果文本读取失败，回退到Base64
            final base64Content = await _fileService.getFileBase64(file);
            buffer.write('- ${attachment.fileName}（${_formatFileSize(fileSize)}，Base64编码）\n');
            buffer.write('Base64数据长度：${base64Content.length}字符\n\n');
          }
        } else {
          // 其他文件类型：Base64编码
          final base64Content = await _fileService.getFileBase64(file);
          buffer.write('- ${attachment.fileName}（${_formatFileSize(fileSize)}，${attachment.mimeType ?? '未知类型'}）\n');
          buffer.write('Base64数据长度：${base64Content.length}字符\n\n');
        }
      } catch (e) {
        buffer.write('- ${attachment.fileName}（处理失败：$e）\n');
      }
    }

    return buffer.toString();
  }

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
        return data['choices'][0]['message']['content'].trim();
      } else {
        final errorData = jsonDecode(response.body);
        throw Exception('API错误: ${errorData['error']['message'] ?? response.statusCode}');
      }
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
}