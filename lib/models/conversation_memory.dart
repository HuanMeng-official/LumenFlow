import 'roleplay_memory.dart';

/// 会话记忆的数据模型。
///
/// 记忆分两层：
/// - 大概的记忆：`summary` + `emotionalState`，允许改写和取舍；
/// - 明确的记忆：`facts` + `rejected` 账本，只增/改状态，不能整段丢失。
class ConversationMemory {
  const ConversationMemory({
    required this.summary,
    required this.emotionalState,
    required this.facts,
    required this.rejected,
    this.roleplay,
    this.coveredUntilMessageId,
    this.fingerprint,
    this.updatedAt,
  });

  factory ConversationMemory.empty() => const ConversationMemory(
    summary: '',
    emotionalState: '',
    facts: [],
    rejected: [],
  );

  /// 前情梗概，滚动重写。
  final String summary;

  /// 当前关系与情绪快照，滚动重写。
  final String emotionalState;

  /// 约定、规则、事实、结论账本。
  final List<MemoryFact> facts;

  /// 被否方案账本。
  final List<RejectedProposal> rejected;

  /// 角色扮演会话的结构化状态；普通对话为 null。
  final RoleplayMemory? roleplay;

  /// 记忆覆盖到的最后一条消息 ID。
  final String? coveredUntilMessageId;

  /// 被覆盖消息的内容指纹，用于检测编辑/删除。
  final String? fingerprint;

  final DateTime? updatedAt;

  List<MemoryFact> get activeFacts =>
      facts.where((fact) => fact.isActive).toList(growable: false);

  List<MemoryFact> get supersededFacts =>
      facts.where((fact) => !fact.isActive).toList(growable: false);

  List<RejectedProposal> get visibleRejected => rejected
      .where(
        (entry) =>
            entry.status == RejectedStatus.active ||
            entry.status == RejectedStatus.reopened,
      )
      .toList(growable: false);

  /// 没有任何可注入内容时视为空。覆盖边界不算内容。
  bool get isEmpty =>
      summary.trim().isEmpty &&
      emotionalState.trim().isEmpty &&
      activeFacts.isEmpty &&
      visibleRejected.isEmpty &&
      (roleplay == null || roleplay!.isEmpty);

  ConversationMemory copyWith({
    String? summary,
    String? emotionalState,
    List<MemoryFact>? facts,
    List<RejectedProposal>? rejected,
    RoleplayMemory? roleplay,
    String? coveredUntilMessageId,
    String? fingerprint,
    DateTime? updatedAt,
    bool clearCoverage = false,
    bool clearRoleplay = false,
  }) {
    return ConversationMemory(
      summary: summary ?? this.summary,
      emotionalState: emotionalState ?? this.emotionalState,
      facts: facts ?? this.facts,
      rejected: rejected ?? this.rejected,
      roleplay: clearRoleplay ? null : (roleplay ?? this.roleplay),
      coveredUntilMessageId: clearCoverage
          ? null
          : (coveredUntilMessageId ?? this.coveredUntilMessageId),
      fingerprint: clearCoverage ? null : (fingerprint ?? this.fingerprint),
      updatedAt: updatedAt ?? this.updatedAt,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'summary': summary,
      'emotionalState': emotionalState,
      'facts': facts.map((fact) => fact.toJson()).toList(),
      'rejected': rejected.map((entry) => entry.toJson()).toList(),
      'roleplay': roleplay?.toJson(),
      'coveredUntilMessageId': coveredUntilMessageId,
      'fingerprint': fingerprint,
      'updatedAt': updatedAt?.millisecondsSinceEpoch,
    };
  }

  factory ConversationMemory.fromJson(Map<String, dynamic> json) {
    final rawFacts = json['facts'];
    final rawRejected = json['rejected'];
    return ConversationMemory(
      summary: json['summary'] as String? ?? '',
      emotionalState: json['emotionalState'] as String? ?? '',
      facts: rawFacts is List
          ? rawFacts
                .whereType<Map>()
                .map(
                  (value) =>
                      MemoryFact.fromJson(value.cast<String, dynamic>()),
                )
                .toList()
          : const [],
      rejected: rawRejected is List
          ? rawRejected
                .whereType<Map>()
                .map(
                  (value) =>
                      RejectedProposal.fromJson(value.cast<String, dynamic>()),
                )
                .toList()
          : const [],
      roleplay: _parseRoleplay(json['roleplay']),
      coveredUntilMessageId: json['coveredUntilMessageId'] as String?,
      fingerprint: json['fingerprint'] as String?,
      updatedAt: _parseDate(json['updatedAt']),
    );
  }

  static DateTime? _parseDate(Object? value) {
    if (value is int) {
      return DateTime.fromMillisecondsSinceEpoch(value);
    }
    if (value is String) {
      return DateTime.tryParse(value);
    }
    return null;
  }

  static RoleplayMemory? _parseRoleplay(Object? value) {
    if (value is! Map) return null;
    final roleplay = RoleplayMemory.fromJson(
      value.cast<String, dynamic>(),
    );
    return roleplay.isEmpty ? null : roleplay;
  }
}

enum MemoryFactKind { agreement, rule, fact, decision }

enum MemoryFactStatus { active, superseded }

class MemoryFact {
  const MemoryFact({
    required this.id,
    required this.kind,
    required this.text,
    this.quote,
    this.status = MemoryFactStatus.active,
    this.supersededBy,
    this.sourceMessageId,
    this.createdAt,
  });

  final String id;
  final MemoryFactKind kind;

  /// 约定/事实的文本。尽量保留原话的语义。
  final String text;

  /// 原文摘录，用于精确遵守。
  final String? quote;

  final MemoryFactStatus status;
  final String? supersededBy;
  final String? sourceMessageId;
  final DateTime? createdAt;

  bool get isActive => status == MemoryFactStatus.active;

  MemoryFact copyWith({
    String? id,
    MemoryFactKind? kind,
    String? text,
    String? quote,
    MemoryFactStatus? status,
    String? supersededBy,
    String? sourceMessageId,
    DateTime? createdAt,
  }) {
    return MemoryFact(
      id: id ?? this.id,
      kind: kind ?? this.kind,
      text: text ?? this.text,
      quote: quote ?? this.quote,
      status: status ?? this.status,
      supersededBy: supersededBy ?? this.supersededBy,
      sourceMessageId: sourceMessageId ?? this.sourceMessageId,
      createdAt: createdAt ?? this.createdAt,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'kind': kind.name,
      'text': text,
      'quote': quote,
      'status': status.name,
      'supersededBy': supersededBy,
      'sourceMessageId': sourceMessageId,
      'createdAt': createdAt?.millisecondsSinceEpoch,
    };
  }

  factory MemoryFact.fromJson(Map<String, dynamic> json) {
    return MemoryFact(
      id: json['id'] as String? ?? '',
      kind: _parseKind(json['kind']),
      text: json['text'] as String? ?? '',
      quote: json['quote'] as String?,
      status: _parseStatus(json['status']),
      supersededBy: json['supersededBy'] as String?,
      sourceMessageId: json['sourceMessageId'] as String?,
      createdAt: ConversationMemory._parseDate(json['createdAt']),
    );
  }

  static MemoryFactKind _parseKind(Object? value) {
    if (value is String) {
      for (final kind in MemoryFactKind.values) {
        if (kind.name == value) return kind;
      }
    }
    return MemoryFactKind.fact;
  }

  static MemoryFactStatus _parseStatus(Object? value) {
    if (value is String) {
      for (final status in MemoryFactStatus.values) {
        if (status.name == value) return status;
      }
    }
    return MemoryFactStatus.active;
  }
}

enum RejectedStatus { active, reopened }

class RejectedProposal {
  const RejectedProposal({
    required this.id,
    required this.proposal,
    required this.reason,
    this.status = RejectedStatus.active,
    this.sourceMessageId,
    this.createdAt,
  });

  final String id;
  final String proposal;
  final String reason;
  final RejectedStatus status;
  final String? sourceMessageId;
  final DateTime? createdAt;

  RejectedProposal copyWith({
    String? id,
    String? proposal,
    String? reason,
    RejectedStatus? status,
    String? sourceMessageId,
    DateTime? createdAt,
  }) {
    return RejectedProposal(
      id: id ?? this.id,
      proposal: proposal ?? this.proposal,
      reason: reason ?? this.reason,
      status: status ?? this.status,
      sourceMessageId: sourceMessageId ?? this.sourceMessageId,
      createdAt: createdAt ?? this.createdAt,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'proposal': proposal,
      'reason': reason,
      'status': status.name,
      'sourceMessageId': sourceMessageId,
      'createdAt': createdAt?.millisecondsSinceEpoch,
    };
  }

  factory RejectedProposal.fromJson(Map<String, dynamic> json) {
    return RejectedProposal(
      id: json['id'] as String? ?? '',
      proposal: json['proposal'] as String? ?? '',
      reason: json['reason'] as String? ?? '',
      status: _parseStatus(json['status']),
      sourceMessageId: json['sourceMessageId'] as String?,
      createdAt: ConversationMemory._parseDate(json['createdAt']),
    );
  }

  static RejectedStatus _parseStatus(Object? value) {
    if (value is String) {
      for (final status in RejectedStatus.values) {
        if (status.name == value) return status;
      }
    }
    return RejectedStatus.active;
  }
}
