/// 对话模型主动留下的一条记忆便签。
///
/// 便签是追加式的证据，不会直接改写正式记忆；后台维护模型会在下一次更新时
/// 把它合并进前情、约定账本或被否方案，然后标记为已处理。
enum MemoryNoteKind { agreement, fact, decision, emotion, rejected }

enum MemoryNoteStatus { pending, processed }

class MemoryNoteDraft {
  const MemoryNoteDraft({
    required this.kind,
    required this.text,
    this.quote,
    this.reason,
  });

  final MemoryNoteKind kind;
  final String text;
  final String? quote;
  final String? reason;
}

class MemoryNote {
  const MemoryNote({
    required this.id,
    required this.conversationId,
    required this.kind,
    required this.text,
    this.quote,
    this.reason,
    this.sourceMessageId,
    required this.createdAt,
    this.status = MemoryNoteStatus.pending,
  });

  final String id;
  final String conversationId;
  final MemoryNoteKind kind;
  final String text;
  final String? quote;
  final String? reason;
  final String? sourceMessageId;
  final DateTime createdAt;
  final MemoryNoteStatus status;

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'conversationId': conversationId,
      'kind': kind.name,
      'text': text,
      'quote': quote,
      'reason': reason,
      'sourceMessageId': sourceMessageId,
      'createdAt': createdAt.millisecondsSinceEpoch,
      'status': status.name,
    };
  }

  factory MemoryNote.fromJson(Map<String, dynamic> json) {
    final createdAt = json['createdAt'];
    return MemoryNote(
      id: json['id'] as String? ?? '',
      conversationId: json['conversationId'] as String? ?? '',
      kind: parseMemoryNoteKind(json['kind']) ?? MemoryNoteKind.fact,
      text: json['text'] as String? ?? '',
      quote: json['quote'] as String?,
      reason: json['reason'] as String?,
      sourceMessageId: json['sourceMessageId'] as String?,
      createdAt: createdAt is int
          ? DateTime.fromMillisecondsSinceEpoch(createdAt)
          : DateTime.now(),
      status: parseMemoryNoteStatus(json['status']),
    );
  }
}

/// 解析工具参数里的便签类型；接受少量常见别名，避免模型换个词就失败。
MemoryNoteKind? parseMemoryNoteKind(Object? value) {
  if (value is! String) return null;
  switch (value.trim().toLowerCase()) {
    case 'agreement':
    case 'rule':
    case 'promise':
      return MemoryNoteKind.agreement;
    case 'fact':
    case 'preference':
      return MemoryNoteKind.fact;
    case 'decision':
    case 'conclusion':
      return MemoryNoteKind.decision;
    case 'emotion':
    case 'feeling':
      return MemoryNoteKind.emotion;
    case 'rejected':
    case 'reject':
      return MemoryNoteKind.rejected;
    default:
      return null;
  }
}

MemoryNoteStatus parseMemoryNoteStatus(Object? value) {
  return value == MemoryNoteStatus.processed.name
      ? MemoryNoteStatus.processed
      : MemoryNoteStatus.pending;
}
