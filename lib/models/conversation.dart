import 'message.dart';

class Conversation {
  final String id;
  final String title;
  final DateTime createdAt;
  final DateTime updatedAt;
  final List<Message> messages;

  /// 会话级思考模式，不跟随全局设置。
  final bool thinkingMode;

  /// 会话级角色预设开关与预设 ID。
  final bool promptPresetEnabled;
  final String promptPresetId;

  /// 是否置顶；置顶会话排在列表最前。
  final bool isPinned;

  Conversation({
    required this.id,
    required this.title,
    required this.createdAt,
    required this.updatedAt,
    required this.messages,
    this.thinkingMode = false,
    this.promptPresetEnabled = false,
    this.promptPresetId = '',
    this.isPinned = false,
  });

  Conversation copyWith({
    String? id,
    String? title,
    DateTime? createdAt,
    DateTime? updatedAt,
    List<Message>? messages,
    bool? thinkingMode,
    bool? promptPresetEnabled,
    String? promptPresetId,
    bool? isPinned,
  }) {
    return Conversation(
      id: id ?? this.id,
      title: title ?? this.title,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
      messages: messages ?? this.messages,
      thinkingMode: thinkingMode ?? this.thinkingMode,
      promptPresetEnabled:
          promptPresetEnabled ?? this.promptPresetEnabled,
      promptPresetId: promptPresetId ?? this.promptPresetId,
      isPinned: isPinned ?? this.isPinned,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'title': title,
      'createdAt': createdAt.toIso8601String(),
      'updatedAt': updatedAt.toIso8601String(),
      'messages': messages.map((m) => m.toJson()).toList(),
      'thinkingMode': thinkingMode,
      'promptPresetEnabled': promptPresetEnabled,
      'promptPresetId': promptPresetId,
      'isPinned': isPinned,
    };
  }

  factory Conversation.fromJson(Map<String, dynamic> json) {
    return Conversation(
      id: json['id'] as String,
      title: json['title'] as String,
      createdAt: DateTime.parse(json['createdAt'] as String),
      updatedAt: DateTime.parse(json['updatedAt'] as String),
      messages: (json['messages'] as List)
          .map((m) => Message.fromJson(m as Map<String, dynamic>))
          .toList(),
      thinkingMode: json['thinkingMode'] as bool? ?? false,
      promptPresetEnabled: json['promptPresetEnabled'] as bool? ?? false,
      promptPresetId: json['promptPresetId'] as String? ?? '',
      isPinned: json['isPinned'] as bool? ?? false,
    );
  }

  static String generateTitle(String firstMessage) {
    if (firstMessage.length <= 20) {
      return firstMessage;
    }
    return '${firstMessage.substring(0, 20)}...';
  }
}
