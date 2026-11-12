/// 角色扮演会话的结构化状态。
///
/// 和自由文本的前情/情绪不同，这些字段用于查看器里的角色卡页面：
/// 心情、关系阶段、当前场景、故事时间、亲密度和未完成的事。
class RoleplayMemory {
  const RoleplayMemory({
    this.mood = '',
    this.relationshipStage = '',
    this.scene = '',
    this.storyTime = '',
    this.intimacy,
    this.previousIntimacy,
    this.intimacyNote = '',
    this.unresolved = '',
    this.newFactIds = const [],
  });

  final String mood;
  final String relationshipStage;
  final String scene;
  final String storyTime;

  /// 0-100，未知时为 null。
  final int? intimacy;

  /// 上一次的亲密度，用于显示 62 → 68 (+6)。
  final int? previousIntimacy;
  final String intimacyNote;
  final String unresolved;

  /// 最近一次记忆维护中新增的 fact ID，用于“本次新增记忆”。
  final List<String> newFactIds;

  bool get isEmpty =>
      mood.trim().isEmpty &&
      relationshipStage.trim().isEmpty &&
      scene.trim().isEmpty &&
      storyTime.trim().isEmpty &&
      intimacy == null &&
      intimacyNote.trim().isEmpty &&
      unresolved.trim().isEmpty &&
      newFactIds.isEmpty;

  RoleplayMemory copyWith({
    String? mood,
    String? relationshipStage,
    String? scene,
    String? storyTime,
    int? intimacy,
    int? previousIntimacy,
    String? intimacyNote,
    String? unresolved,
    List<String>? newFactIds,
  }) {
    return RoleplayMemory(
      mood: mood ?? this.mood,
      relationshipStage: relationshipStage ?? this.relationshipStage,
      scene: scene ?? this.scene,
      storyTime: storyTime ?? this.storyTime,
      intimacy: intimacy ?? this.intimacy,
      previousIntimacy: previousIntimacy ?? this.previousIntimacy,
      intimacyNote: intimacyNote ?? this.intimacyNote,
      unresolved: unresolved ?? this.unresolved,
      newFactIds: newFactIds ?? this.newFactIds,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'mood': mood,
      'relationshipStage': relationshipStage,
      'scene': scene,
      'storyTime': storyTime,
      'intimacy': intimacy,
      'previousIntimacy': previousIntimacy,
      'intimacyNote': intimacyNote,
      'unresolved': unresolved,
      'newFactIds': newFactIds,
    };
  }

  factory RoleplayMemory.fromJson(Map<String, dynamic> json) {
    return RoleplayMemory(
      mood: json['mood'] as String? ?? '',
      relationshipStage:
          (json['relationshipStage'] ?? json['relationship_stage'])
              as String? ??
          '',
      scene: json['scene'] as String? ?? '',
      storyTime:
          (json['storyTime'] ?? json['story_time']) as String? ?? '',
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
    );
  }

  static int? _clampIntimacy(Object? value) {
    if (value is! num) return null;
    return value.round().clamp(0, 100);
  }
}
