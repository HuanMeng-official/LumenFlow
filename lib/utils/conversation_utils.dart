import '../models/conversation.dart';

/// 返回 updatedAt 最新的一条会话，忽略置顶排序。
Conversation? mostRecentlyUpdatedConversation(
  List<Conversation> conversations,
) {
  if (conversations.isEmpty) return null;
  return conversations.reduce(
    (a, b) => b.updatedAt.isAfter(a.updatedAt) ? b : a,
  );
}
