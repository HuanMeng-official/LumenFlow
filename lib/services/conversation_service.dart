import 'dart:convert';
import 'package:shared_preferences/shared_preferences.dart';
import '../models/conversation.dart';

/// 对话服务，管理对话的持久化存储和CRUD操作
///
/// 使用SharedPreferences作为本地存储，存储对话列表和当前对话ID
/// 提供对话的创建、读取、更新、删除等完整功能
///
/// 设计特点:
/// - 自动按更新时间排序（最近更新的对话在前）
/// - 维护当前对话ID，支持快速切换
/// - 线程安全的异步操作
class ConversationService {
  static const String _conversationsKey = 'conversations';
  static const String _currentConversationIdKey = 'current_conversation_id';

  /// 从本地存储加载所有对话
  /// 返回按更新时间倒序排序的对话列表（最近更新的在前）
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

  Future<void> updateConversationTitle(
      String conversationId, String title) async {
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
