/// 角色扮演会话中一次阶段跃迁的里程碑记录。
class GrowthMilestone {
  const GrowthMilestone({
    required this.id,
    required this.fromStageId,
    required this.toStageId,
    required this.title,
    this.reason = '',
    this.storyTime = '',
    this.sourceMessageId,
    required this.createdAt,
  });

  final String id;
  final String fromStageId;
  final String toStageId;
  final String title;
  final String reason;
  final String storyTime;
  final String? sourceMessageId;
  final DateTime createdAt;

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'fromStageId': fromStageId,
      'toStageId': toStageId,
      'title': title,
      if (reason.isNotEmpty) 'reason': reason,
      if (storyTime.isNotEmpty) 'storyTime': storyTime,
      if (sourceMessageId != null) 'sourceMessageId': sourceMessageId,
      'createdAt': createdAt.millisecondsSinceEpoch,
    };
  }

  factory GrowthMilestone.fromJson(Map<String, dynamic> json) {
    final createdRaw = json['createdAt'] ?? json['created_at'];
    DateTime createdAt;
    if (createdRaw is int) {
      createdAt = DateTime.fromMillisecondsSinceEpoch(createdRaw);
    } else if (createdRaw is String) {
      createdAt = DateTime.tryParse(createdRaw) ?? DateTime.now();
    } else {
      createdAt = DateTime.now();
    }
    return GrowthMilestone(
      id: json['id'] as String? ?? '',
      fromStageId:
          (json['fromStageId'] ?? json['from_stage_id']) as String? ?? '',
      toStageId: (json['toStageId'] ?? json['to_stage_id']) as String? ?? '',
      title: json['title'] as String? ?? '',
      reason: json['reason'] as String? ?? '',
      storyTime: (json['storyTime'] ?? json['story_time']) as String? ?? '',
      sourceMessageId:
          (json['sourceMessageId'] ?? json['source_message_id']) as String?,
      createdAt: createdAt,
    );
  }
}

/// 刚发生阶段跃迁后保留 1~2 轮的一次性过渡提示状态。
class StageTransitionBeat {
  const StageTransitionBeat({
    required this.fromStageId,
    required this.toStageId,
    this.reason = '',
    this.remainingTurns = 2,
  });

  final String fromStageId;
  final String toStageId;
  final String reason;
  final int remainingTurns;

  StageTransitionBeat copyWith({
    String? fromStageId,
    String? toStageId,
    String? reason,
    int? remainingTurns,
  }) {
    return StageTransitionBeat(
      fromStageId: fromStageId ?? this.fromStageId,
      toStageId: toStageId ?? this.toStageId,
      reason: reason ?? this.reason,
      remainingTurns: remainingTurns ?? this.remainingTurns,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'fromStageId': fromStageId,
      'toStageId': toStageId,
      if (reason.isNotEmpty) 'reason': reason,
      'remainingTurns': remainingTurns,
    };
  }

  factory StageTransitionBeat.fromJson(Map<String, dynamic> json) {
    final turns = json['remainingTurns'] ?? json['remaining_turns'];
    return StageTransitionBeat(
      fromStageId:
          (json['fromStageId'] ?? json['from_stage_id']) as String? ?? '',
      toStageId: (json['toStageId'] ?? json['to_stage_id']) as String? ?? '',
      reason: json['reason'] as String? ?? '',
      remainingTurns: turns is num ? turns.round().clamp(0, 5) : 0,
    );
  }
}

/// 角色扮演会话的结构化状态与单会话成长周目档案。
///
/// 和自由文本的前情/情绪不同，这些字段用于查看器里的角色卡页面与成长引擎：
/// 心情、关系阶段、当前场景、故事时间、角色自身状态、亲密度、自定义属性、
/// 成长阶段、里程碑时间线和一次性过渡指引。
class RoleplayMemory {
  const RoleplayMemory({
    this.mood = '',
    this.relationshipStage = '',
    this.scene = '',
    this.storyTime = '',
    this.characterState = '',
    this.intimacy,
    this.previousIntimacy,
    this.intimacyNote = '',
    this.unresolved = '',
    this.newFactIds = const [],
    this.currentStageId = '',
    this.visitedStageIds = const [],
    this.customMetrics = const {},
    this.previousCustomMetrics = const {},
    this.customNickname = '',
    this.milestones = const [],
    this.pendingTransition,
    this.growthLocked = false,
  });

  final String mood;
  final String relationshipStage;
  final String scene;
  final String storyTime;

  /// 角色自身可观察的当前状态：伤势、疲态、衣着、姿势、正在做的事等。
  final String characterState;

  /// 0-100，未知时为 null。
  final int? intimacy;

  /// 上一次的亲密度，用于显示 62 → 68 (+6)。
  final int? previousIntimacy;
  final String intimacyNote;
  final String unresolved;

  /// 最近一次记忆维护中新增的 fact ID，用于“本次新增记忆”。
  final List<String> newFactIds;

  /// 单会话成长：当前所处阶段 ID（为空表示尚未初始化或非成长型角色卡）。
  final String currentStageId;

  /// 本会话已到达过的阶段 ID 列表（按首次到达顺序）。
  final List<String> visitedStageIds;

  /// 作者自定义属性的当前值。
  final Map<String, int> customMetrics;

  /// 作者自定义属性的上一次值（用于展示变动差值）。
  final Map<String, int> previousCustomMetrics;

  /// 本会话中角色对用户的专属称呼演变。
  final String customNickname;

  /// 本会话的成长里程碑时间线。
  final List<GrowthMilestone> milestones;

  /// 刚突破新阶段时保留 1~2 轮的过渡语气状态。
  final StageTransitionBeat? pendingTransition;

  /// 用户手动锁定成长时为 true，后台维护不再修改阶段与数值。
  final bool growthLocked;

  bool get isEmpty =>
      mood.trim().isEmpty &&
      relationshipStage.trim().isEmpty &&
      scene.trim().isEmpty &&
      storyTime.trim().isEmpty &&
      characterState.trim().isEmpty &&
      intimacy == null &&
      intimacyNote.trim().isEmpty &&
      unresolved.trim().isEmpty &&
      newFactIds.isEmpty &&
      currentStageId.trim().isEmpty &&
      visitedStageIds.isEmpty &&
      customMetrics.isEmpty &&
      customNickname.trim().isEmpty &&
      milestones.isEmpty &&
      pendingTransition == null &&
      !growthLocked;

  RoleplayMemory copyWith({
    String? mood,
    String? relationshipStage,
    String? scene,
    String? storyTime,
    String? characterState,
    int? intimacy,
    bool clearIntimacy = false,
    int? previousIntimacy,
    bool clearPreviousIntimacy = false,
    String? intimacyNote,
    String? unresolved,
    List<String>? newFactIds,
    String? currentStageId,
    List<String>? visitedStageIds,
    Map<String, int>? customMetrics,
    Map<String, int>? previousCustomMetrics,
    String? customNickname,
    List<GrowthMilestone>? milestones,
    StageTransitionBeat? pendingTransition,
    bool clearPendingTransition = false,
    bool? growthLocked,
  }) {
    return RoleplayMemory(
      mood: mood ?? this.mood,
      relationshipStage: relationshipStage ?? this.relationshipStage,
      scene: scene ?? this.scene,
      storyTime: storyTime ?? this.storyTime,
      characterState: characterState ?? this.characterState,
      intimacy: clearIntimacy ? null : (intimacy ?? this.intimacy),
      previousIntimacy: clearPreviousIntimacy
          ? null
          : (previousIntimacy ?? this.previousIntimacy),
      intimacyNote: intimacyNote ?? this.intimacyNote,
      unresolved: unresolved ?? this.unresolved,
      newFactIds: newFactIds ?? this.newFactIds,
      currentStageId: currentStageId ?? this.currentStageId,
      visitedStageIds: visitedStageIds ?? this.visitedStageIds,
      customMetrics: customMetrics ?? this.customMetrics,
      previousCustomMetrics:
          previousCustomMetrics ?? this.previousCustomMetrics,
      customNickname: customNickname ?? this.customNickname,
      milestones: milestones ?? this.milestones,
      pendingTransition: clearPendingTransition
          ? null
          : (pendingTransition ?? this.pendingTransition),
      growthLocked: growthLocked ?? this.growthLocked,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'mood': mood,
      'relationshipStage': relationshipStage,
      'scene': scene,
      'storyTime': storyTime,
      'characterState': characterState,
      'intimacy': intimacy,
      'previousIntimacy': previousIntimacy,
      'intimacyNote': intimacyNote,
      'unresolved': unresolved,
      'newFactIds': newFactIds,
      if (currentStageId.isNotEmpty) 'currentStageId': currentStageId,
      if (visitedStageIds.isNotEmpty) 'visitedStageIds': visitedStageIds,
      if (customMetrics.isNotEmpty) 'customMetrics': customMetrics,
      if (previousCustomMetrics.isNotEmpty)
        'previousCustomMetrics': previousCustomMetrics,
      if (customNickname.isNotEmpty) 'customNickname': customNickname,
      if (milestones.isNotEmpty)
        'milestones': milestones.map((m) => m.toJson()).toList(),
      if (pendingTransition != null)
        'pendingTransition': pendingTransition!.toJson(),
      if (growthLocked) 'growthLocked': growthLocked,
    };
  }

  factory RoleplayMemory.fromJson(Map<String, dynamic> json) {
    final rawMilestones = json['milestones'];
    final rawTransition = json['pendingTransition'] ?? json['pending_transition'];
    StageTransitionBeat? pendingTransition;
    if (rawTransition is Map) {
      final parsed = StageTransitionBeat.fromJson(
        rawTransition.cast<String, dynamic>(),
      );
      if (parsed.toStageId.isNotEmpty && parsed.remainingTurns > 0) {
        pendingTransition = parsed;
      }
    }

    return RoleplayMemory(
      mood: json['mood'] as String? ?? '',
      relationshipStage:
          (json['relationshipStage'] ?? json['relationship_stage'])
              as String? ??
          '',
      scene: json['scene'] as String? ?? '',
      storyTime: (json['storyTime'] ?? json['story_time']) as String? ?? '',
      characterState:
          (json['characterState'] ?? json['character_state']) as String? ?? '',
      intimacy: _clampIntimacy(json['intimacy']),
      previousIntimacy: _clampIntimacy(
        json['previousIntimacy'] ?? json['previous_intimacy'],
      ),
      intimacyNote:
          (json['intimacyNote'] ?? json['intimacy_note']) as String? ?? '',
      unresolved: json['unresolved'] as String? ?? '',
      newFactIds: json['newFactIds'] is List
          ? (json['newFactIds'] as List).whereType<String>().toList()
          : const [],
      currentStageId:
          (json['currentStageId'] ?? json['current_stage_id']) as String? ?? '',
      visitedStageIds: _parseStringList(
        json['visitedStageIds'] ?? json['visited_stage_ids'],
      ),
      customMetrics: _parseMetricMap(
        json['customMetrics'] ?? json['custom_metrics'],
      ),
      previousCustomMetrics: _parseMetricMap(
        json['previousCustomMetrics'] ?? json['previous_custom_metrics'],
      ),
      customNickname:
          (json['customNickname'] ?? json['custom_nickname']) as String? ?? '',
      milestones: rawMilestones is List
          ? rawMilestones
                .whereType<Map>()
                .map(
                  (item) => GrowthMilestone.fromJson(
                    item.cast<String, dynamic>(),
                  ),
                )
                .where((m) => m.toStageId.isNotEmpty)
                .toList(growable: false)
          : const [],
      pendingTransition: pendingTransition,
      growthLocked:
          (json['growthLocked'] ?? json['growth_locked']) == true,
    );
  }

  static int? _clampIntimacy(Object? value) {
    if (value is! num) return null;
    return value.round().clamp(0, 100);
  }

  static List<String> _parseStringList(Object? value) {
    if (value is! List) return const [];
    return value
        .whereType<String>()
        .where((s) => s.trim().isNotEmpty)
        .toList(growable: false);
  }

  static Map<String, int> _parseMetricMap(Object? value) {
    if (value is! Map) return const {};
    final result = <String, int>{};
    for (final entry in value.entries) {
      if (entry.key is String && entry.value is num) {
        result[entry.key as String] = (entry.value as num).round();
      }
    }
    return result;
  }
}
