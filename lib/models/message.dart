import './attachment.dart';

/// 消息数据模型，表示聊天中的一条消息
///
/// 属性说明:
/// - id: 消息唯一标识符
/// - content: 消息文本内容
/// - reasoningContent: AI思考过程内容（可选）
/// - isUser: 是否为用户发送的消息（true为用户，false为AI）
/// - timestamp: 消息时间戳
/// - status: 消息状态（发送中、已发送、错误）
/// - attachments: 附件列表，支持文件、图片等
///
/// 功能:
/// - toJson/fromJson: 支持JSON序列化和反序列化
/// - copyWith: 创建消息的副本并修改指定字段
class Message {
  final String id;
  final String content;
  final String? reasoningContent;
  final bool isUser;
  final DateTime timestamp;
  final MessageStatus status;
  final List<Attachment> attachments;

  /// AI 回复的多个版本；用户消息通常为空。
  final List<MessageVariant> variants;
  final int activeVariantIndex;

  Message({
    required this.id,
    required this.content,
    this.reasoningContent,
    required this.isUser,
    required this.timestamp,
    this.status = MessageStatus.sent,
    this.attachments = const [],
    this.variants = const [],
    this.activeVariantIndex = 0,
  });

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'content': content,
      'reasoningContent': reasoningContent,
      'isUser': isUser,
      'timestamp': timestamp.toIso8601String(),
      'status': status.index,
      'attachments': attachments.map((a) => a.toJson()).toList(),
      'variants': variants.map((v) => v.toJson()).toList(),
      'activeVariantIndex': activeVariantIndex,
    };
  }

  factory Message.fromJson(Map<String, dynamic> json) {
    final attachmentsJson = json['attachments'] as List? ?? [];
    final variantsJson = json['variants'] as List? ?? [];
    final variants = variantsJson
        .map((v) => MessageVariant.fromJson((v as Map).cast<String, dynamic>()))
        .toList();
    final rawIndex = json['activeVariantIndex'] as int? ?? 0;
    final activeIndex = variants.isEmpty
        ? 0
        : rawIndex.clamp(0, variants.length - 1);

    return Message(
      id: json['id'],
      content: json['content'],
      reasoningContent: json['reasoningContent'],
      isUser: json['isUser'],
      timestamp: DateTime.parse(json['timestamp']),
      status: MessageStatus.values[json['status']],
      attachments: attachmentsJson.map((a) => Attachment.fromJson(a)).toList(),
      variants: variants,
      activeVariantIndex: activeIndex,
    );
  }

  Message copyWith({
    String? id,
    String? content,
    String? reasoningContent,
    bool? isUser,
    DateTime? timestamp,
    MessageStatus? status,
    List<Attachment>? attachments,
    List<MessageVariant>? variants,
    int? activeVariantIndex,
  }) {
    return Message(
      id: id ?? this.id,
      content: content ?? this.content,
      reasoningContent: reasoningContent ?? this.reasoningContent,
      isUser: isUser ?? this.isUser,
      timestamp: timestamp ?? this.timestamp,
      status: status ?? this.status,
      attachments: attachments ?? this.attachments,
      variants: variants ?? this.variants,
      activeVariantIndex: activeVariantIndex ?? this.activeVariantIndex,
    );
  }
}

/// AI 回复的一个版本。
class MessageVariant {
  final String content;
  final String? reasoningContent;
  final DateTime timestamp;
  final MessageStatus status;

  const MessageVariant({
    required this.content,
    this.reasoningContent,
    required this.timestamp,
    required this.status,
  });

  factory MessageVariant.fromJson(Map<String, dynamic> json) {
    return MessageVariant(
      content: json['content'] as String? ?? '',
      reasoningContent: json['reasoningContent'] as String?,
      timestamp: DateTime.parse(json['timestamp'] as String),
      status: MessageStatus.values[json['status'] as int],
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'content': content,
      'reasoningContent': reasoningContent,
      'timestamp': timestamp.toIso8601String(),
      'status': status.index,
    };
  }
}

/// 消息状态枚举，表示消息的发送状态
///
/// 状态说明:
/// - sending: 消息正在发送中（适用于AI响应流式输出）
/// - sent: 消息已成功发送/接收
/// - error: 消息发送/接收失败
/// - stopped: 消息生成被用户手动停止
enum MessageStatus {
  sending,
  sent,
  error,
  stopped,
}
