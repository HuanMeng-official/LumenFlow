import './attachment.dart';

class Message {
  final String id;
  final String content;
  final bool isUser;
  final DateTime timestamp;
  final MessageStatus status;
  final List<Attachment> attachments;

  Message({
    required this.id,
    required this.content,
    required this.isUser,
    required this.timestamp,
    this.status = MessageStatus.sent,
    this.attachments = const [],
  });

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'content': content,
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
      isUser: json['isUser'],
      timestamp: DateTime.parse(json['timestamp']),
      status: MessageStatus.values[json['status']],
      attachments: attachmentsJson.map((a) => Attachment.fromJson(a)).toList(),
    );
  }

  Message copyWith({
    String? id,
    String? content,
    bool? isUser,
    DateTime? timestamp,
    MessageStatus? status,
    List<Attachment>? attachments,
  }) {
    return Message(
      id: id ?? this.id,
      content: content ?? this.content,
      isUser: isUser ?? this.isUser,
      timestamp: timestamp ?? this.timestamp,
      status: status ?? this.status,
      attachments: attachments ?? this.attachments,
    );
  }
}

enum MessageStatus {
  sending,
  sent,
  error,
}