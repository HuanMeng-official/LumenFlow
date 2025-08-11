import 'dart:convert';
import 'package:http/http.dart' as http;
import 'settings_service.dart';
import 'user_service.dart';
import '../models/message.dart';

class AIService {
  final SettingsService _settingsService = SettingsService();
  final UserService _userService = UserService();

  Future<String> sendMessage(String message, List<Message> chatHistory) async {
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
        'content': message,
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
}