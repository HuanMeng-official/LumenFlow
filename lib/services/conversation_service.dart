import 'dart:convert';
import 'package:shared_preferences/shared_preferences.dart';
import '../models/conversation.dart';

class ConversationService {
  static const String _conversationsKey = 'conversations';
  static const String _currentConversationIdKey = 'current_conversation_id';

  Future<List<Conversation>> loadConversations() async {
    final prefs = await SharedPreferences.getInstance();
    final conversationsString = prefs.getString(_conversationsKey);

    if (conversationsString == null) return [];

    final conversationsJson = jsonDecode(conversationsString) as List;
    return conversationsJson
        .map((json) => Conversation.fromJson(json as Map<String, dynamic>))
        .toList()
      ..sort((a, b) => b.updatedAt.compareTo(a.updatedAt));
  }

  Future<void> saveConversations(List<Conversation> conversations) async {
    final prefs = await SharedPreferences.getInstance();
    final conversationsJson = conversations.map((c) => c.toJson()).toList();
    await prefs.setString(_conversationsKey, jsonEncode(conversationsJson));
  }

  Future<String?> getCurrentConversationId() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getString(_currentConversationIdKey);
  }

  Future<void> setCurrentConversationId(String conversationId) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_currentConversationIdKey, conversationId);
  }

  Future<Conversation> createNewConversation() async {
    final conversation = Conversation(
      id: DateTime.now().millisecondsSinceEpoch.toString(),
      title: '新对话',
      createdAt: DateTime.now(),
      updatedAt: DateTime.now(),
      messages: [],
    );

    final conversations = await loadConversations();
    conversations.insert(0, conversation);
    await saveConversations(conversations);
    await setCurrentConversationId(conversation.id);

    return conversation;
  }

  Future<void> updateConversation(Conversation conversation) async {
    final conversations = await loadConversations();
    final index = conversations.indexWhere((c) => c.id == conversation.id);

    if (index != -1) {
      conversations[index] = conversation.copyWith(updatedAt: DateTime.now());
      await saveConversations(conversations);
    }
  }

  Future<void> deleteConversation(String conversationId) async {
    final conversations = await loadConversations();
    conversations.removeWhere((c) => c.id == conversationId);
    await saveConversations(conversations);

    final currentId = await getCurrentConversationId();
    if (currentId == conversationId) {
      final prefs = await SharedPreferences.getInstance();
      await prefs.remove(_currentConversationIdKey);
    }
  }

  Future<Conversation?> getConversationById(String id) async {
    final conversations = await loadConversations();
    try {
      return conversations.firstWhere((c) => c.id == id);
    } catch (e) {
      return null;
    }
  }

  Future<void> updateConversationTitle(String conversationId, String title) async {
    final conversations = await loadConversations();
    final index = conversations.indexWhere((c) => c.id == conversationId);

    if (index != -1) {
      conversations[index] = conversations[index].copyWith(
        title: title,
        updatedAt: DateTime.now(),
      );
      await saveConversations(conversations);
    }
  }
}