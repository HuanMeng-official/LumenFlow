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

  Message({
    required this.id,
    required this.content,
    this.reasoningContent,
    required this.isUser,
    required this.timestamp,
    this.status = MessageStatus.sent,
    this.attachments = const [],
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
    };
  }

  factory Message.fromJson(Map<String, dynamic> json) {
    final attachmentsJson = json['attachments'] as List? ?? [];
    return Message(
      id: json['id'],
      content: json['content'],
      reasoningContent: json['reasoningContent'],
      isUser: json['isUser'],
      timestamp: DateTime.parse(json['timestamp']),
      status: MessageStatus.values[json['status']],
      attachments: attachmentsJson.map((a) => Attachment.fromJson(a)).toList(),
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
  }) {
    return Message(
      id: id ?? this.id,
      content: content ?? this.content,
      reasoningContent: reasoningContent ?? this.reasoningContent,
      isUser: isUser ?? this.isUser,
      timestamp: timestamp ?? this.timestamp,
      status: status ?? this.status,
      attachments: attachments ?? this.attachments,
    );
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
