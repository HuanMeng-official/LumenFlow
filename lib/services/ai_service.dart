import 'dart:convert';
import 'dart:async';
import 'package:http/http.dart' as http;
import 'settings_service.dart';
import 'user_service.dart';
import '../models/message.dart';
import '../models/attachment.dart';

class AIService {
  final SettingsService _settingsService = SettingsService();
  final UserService _userService = UserService();

  String _buildMessageWithAttachments(String message, List<Attachment> attachments) {
    if (attachments.isEmpty) {
      return message;
    }

    final buffer = StringBuffer();
    if (message.isNotEmpty) {
      buffer.write(message);
      buffer.write('\n\n');
    }

    buffer.write('附件：\n');
    for (final attachment in attachments) {
      buffer.write('- ${attachment.fileName}');
      if (attachment.fileSize != null) {
        buffer.write(' (${_formatFileSize(attachment.fileSize!)})');
      }
      buffer.write('\n');
    }

    return buffer.toString();
  }

  String _formatFileSize(int bytes) {
    if (bytes < 1024) {
      return '$bytes B';
    } else if (bytes < 1024 * 1024) {
      return '${(bytes / 1024).toStringAsFixed(1)} KB';
    } else {
      return '${(bytes / (1024 * 1024)).toStringAsFixed(1)} MB';
    }
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
      List<Map<String, String>> messages = [];

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

      messages.add({
        'role': 'user',
        'content': _buildMessageWithAttachments(message, attachments),
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
      List<Map<String, String>> messages = [];

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

      messages.add({
        'role': 'user',
        'content': _buildMessageWithAttachments(message, attachments),
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