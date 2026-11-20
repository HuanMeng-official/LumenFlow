import 'dart:convert';

import '../models/character_growth.dart';
import '../models/conversation_memory.dart';
import '../models/roleplay_memory.dart';
import 'character_growth_engine.dart';
import 'memory_policy.dart';

enum FactOpType { add, supersede, update }

enum RejectedOpType { add, reopen }

class FactOperation {
  const FactOperation({
    required this.type,
    this.id,
    this.kind,
    this.text,
    this.quote,
    this.sourceMessageId,
    this.supersededBy,
  });

  final FactOpType type;
  final String? id;
  final MemoryFactKind? kind;
  final String? text;
  final String? quote;
  final String? sourceMessageId;
  final String? supersededBy;
}

class RejectedOperation {
  const RejectedOperation({
    required this.type,
    this.id,
    this.proposal,
    this.reason,
    this.sourceMessageId,
  });

  final RejectedOpType type;
  final String? id;
  final String? proposal;
  final String? reason;
  final String? sourceMessageId;
}

class MemoryUpdate {
  const MemoryUpdate({
    this.summary,
    this.emotionalState,
    this.mood,
    this.relationshipStage,
    this.scene,
    this.storyTime,
    this.characterState,
    this.intimacy,
    this.intimacyNote,
    this.unresolved,
    this.customMetrics = const {},
    this.customNickname,
    this.triggeredTransitions = const [],
    this.transitionReason,
    this.factOps = const [],
    this.rejectedOps = const [],
  });

  final String? summary;
  final String? emotionalState;
  final String? mood;
  final String? relationshipStage;
  final String? scene;
  final String? storyTime;
  final String? characterState;
  final int? intimacy;
  final String? intimacyNote;
  final String? unresolved;
  final Map<String, int> customMetrics;
  final String? customNickname;
  final List<String> triggeredTransitions;
  final String? transitionReason;
  final List<FactOperation> factOps;
  final List<RejectedOperation> rejectedOps;
}

/// 解析记忆更新模型的输出。
///
/// 模型经常把 JSON 包在代码块或解释文字里，这里做宽松提取；解析失败返回
/// null，由调用方保留旧记忆。
class MemoryUpdateParser {
  MemoryUpdateParser._();

  static MemoryUpdate? parse(String raw) {
    final jsonText = _extractJsonObject(raw);
    if (jsonText == null) return null;

    try {
      final decoded = jsonDecode(jsonText);
      if (decoded is! Map) return null;
      final map = decoded.cast<String, dynamic>();
      final roleplay = map['roleplay_state'] ?? map['roleplayState'];
      final roleplayMap = roleplay is Map
          ? roleplay.cast<String, dynamic>()
          : const <String, dynamic>{};

      return MemoryUpdate(
        summary: _stringOrNull(map['summary']),
        emotionalState: _stringOrNull(
          map['emotional_state'] ?? map['emotionalState'],
        ),
        mood: _stringOrNull(roleplayMap['mood']),
        relationshipStage: _stringOrNull(
          roleplayMap['relationship_stage'] ?? roleplayMap['relationshipStage'],
        ),
        scene: _stringOrNull(roleplayMap['scene']),
        storyTime: _stringOrNull(
          roleplayMap['story_time'] ?? roleplayMap['storyTime'],
        ),
        characterState: _stringOrNull(
          roleplayMap['character_state'] ?? roleplayMap['characterState'],
        ),
        intimacy: _intOrNull(roleplayMap['intimacy']),
        intimacyNote: _stringOrNull(
          roleplayMap['intimacy_note'] ?? roleplayMap['intimacyNote'],
        ),
        unresolved: _stringOrNull(roleplayMap['unresolved']),
        customMetrics: _parseCustomMetrics(
          roleplayMap['custom_metrics'] ?? roleplayMap['customMetrics'],
        ),
        customNickname: _stringOrNull(
          roleplayMap['custom_nickname'] ?? roleplayMap['customNickname'],
        ),
        triggeredTransitions: _parseStringList(
          roleplayMap['triggered_transitions'] ??
              roleplayMap['triggeredTransitions'],
        ),
        transitionReason: _stringOrNull(
          roleplayMap['transition_reason'] ?? roleplayMap['transitionReason'],
        ),
        factOps: _parseFactOps(map['fact_ops'] ?? map['factOps']),
        rejectedOps: _parseRejectedOps(
          map['rejected_ops'] ?? map['rejectedOps'],
        ),
      );
    } catch (_) {
      return null;
    }
  }

  static String? _extractJsonObject(String raw) {
    final start = raw.indexOf('{');
    final end = raw.lastIndexOf('}');
    if (start == -1 || end <= start) return null;
    return raw.substring(start, end + 1);
  }

  static String? _stringOrNull(Object? value) {
    if (value is String) return value;
    return null;
  }

  static int? _intOrNull(Object? value) {
    if (value is num) return value.round().clamp(0, 100);
    if (value is String) {
      final parsed = int.tryParse(value.trim());
      if (parsed != null) return parsed.clamp(0, 100);
    }
    return null;
  }

  static Map<String, int> _parseCustomMetrics(Object? raw) {
    if (raw is! Map) return const {};
    final result = <String, int>{};
    for (final entry in raw.entries) {
      final key = entry.key.toString().trim();
      if (key.isEmpty) continue;
      final value = entry.value;
      if (value is num) {
        result[key] = value.round();
      } else if (value is String) {
        final parsed = int.tryParse(value.trim());
        if (parsed != null) result[key] = parsed;
      }
    }
    return result;
  }

  static List<String> _parseStringList(Object? raw) {
    if (raw is! List) return const [];
    final items = <String>[];
    for (final item in raw) {
      if (item is String) {
        final trimmed = item.trim();
        if (trimmed.isNotEmpty) items.add(trimmed);
      }
    }
    return items;
  }

  static List<FactOperation> _parseFactOps(Object? raw) {
    if (raw is! List) return const [];
    final ops = <FactOperation>[];
    for (final value in raw) {
      if (value is! Map) continue;
      final map = value.cast<String, dynamic>();
      final type = _parseFactOpType(map['op']);
      if (type == null) continue;
      ops.add(
        FactOperation(
          type: type,
          id: _stringOrNull(map['id']),
          kind: _parseFactKind(map['kind']),
          text: _stringOrNull(map['text']),
          quote: _stringOrNull(map['quote']),
          sourceMessageId: _stringOrNull(
            map['source_message_id'] ?? map['sourceMessageId'],
          ),
          supersededBy: _stringOrNull(
            map['superseded_by'] ?? map['supersededBy'],
          ),
        ),
      );
    }
    return ops;
  }

  static List<RejectedOperation> _parseRejectedOps(Object? raw) {
    if (raw is! List) return const [];
    final ops = <RejectedOperation>[];
    for (final value in raw) {
      if (value is! Map) continue;
      final map = value.cast<String, dynamic>();
      final type = _parseRejectedOpType(map['op']);
      if (type == null) continue;
      ops.add(
        RejectedOperation(
          type: type,
          id: _stringOrNull(map['id']),
          proposal: _stringOrNull(map['proposal']),
          reason: _stringOrNull(map['reason']),
          sourceMessageId: _stringOrNull(
            map['source_message_id'] ?? map['sourceMessageId'],
          ),
        ),
      );
    }
    return ops;
  }

  static FactOpType? _parseFactOpType(Object? value) {
    switch (value?.toString().trim().toLowerCase()) {
      case 'add':
        return FactOpType.add;
      case 'supersede':
      case 'superseded':
        return FactOpType.supersede;
      case 'update':
        return FactOpType.update;
      default:
        return null;
    }
  }

  static RejectedOpType? _parseRejectedOpType(Object? value) {
    switch (value?.toString().trim().toLowerCase()) {
      case 'add':
        return RejectedOpType.add;
      case 'reopen':
      case 'reopened':
        return RejectedOpType.reopen;
      default:
        return null;
    }
  }

  static MemoryFactKind? _parseFactKind(Object? value) {
    if (value is! String) return null;
    for (final kind in MemoryFactKind.values) {
      if (kind.name == value.trim().toLowerCase()) return kind;
    }
    return null;
  }
}

/// 把模型输出的操作合并进现有账本。
///
/// 关键约束：不删除旧条目；supersede/reopen 只改状态；已废止的约定不能被
/// 一次新的 add 重新复活；“未提及”不能覆盖已有前情。
class MemoryUpdateApplier {
  MemoryUpdateApplier._();

  static ConversationMemory apply(
    ConversationMemory current,
    MemoryUpdate update, {
    required String Function() nextFactId,
    required String Function() nextRejectedId,
    String Function()? nextMilestoneId,
    CharacterGrowthConfig? growthConfig,
    String? sourceMessageId,
    void Function(GrowthEvaluationResult result)? onGrowthEvaluated,
    DateTime? now,
  }) {
    final timestamp = now ?? DateTime.now();
    final facts = List<MemoryFact>.from(current.facts);
    final rejected = List<RejectedProposal>.from(current.rejected);
    final addedFactIds = <String>[];

    for (final op in update.factOps) {
      switch (op.type) {
        case FactOpType.add:
          final text = op.text?.trim() ?? '';
          if (text.isEmpty) break;
          final normalized = _normalize(text);
          final duplicate = facts.any(
            (fact) =>
                fact.isActive && _looksSame(_normalize(fact.text), normalized),
          );
          final resurrected = facts.any(
            (fact) =>
                !fact.isActive &&
                (_looksSame(_normalize(fact.text), normalized) ||
                    (fact.quote != null &&
                        _looksSame(_normalize(fact.quote!), normalized))),
          );
          if (duplicate || resurrected) break;
          final factId = nextFactId();
          facts.add(
            MemoryFact(
              id: factId,
              kind: op.kind ?? MemoryFactKind.fact,
              text: text,
              quote: op.quote,
              sourceMessageId: op.sourceMessageId,
              createdAt: timestamp,
            ),
          );
          addedFactIds.add(factId);
          break;
        case FactOpType.supersede:
          final index = facts.indexWhere((fact) => fact.id == op.id);
          if (index == -1) break;
          facts[index] = facts[index].copyWith(
            status: MemoryFactStatus.superseded,
            supersededBy: op.supersededBy,
          );
          break;
        case FactOpType.update:
          final index = facts.indexWhere((fact) => fact.id == op.id);
          if (index == -1) break;
          final newText = op.text?.trim();
          facts[index] = facts[index].copyWith(
            text: (newText == null || newText.isEmpty) ? null : newText,
            quote: op.quote,
          );
          break;
      }
    }

    for (final op in update.rejectedOps) {
      switch (op.type) {
        case RejectedOpType.add:
          final proposal = op.proposal?.trim() ?? '';
          if (proposal.isEmpty) break;
          final normalized = _normalize(proposal);
          if (rejected.any(
            (entry) => _looksSame(_normalize(entry.proposal), normalized),
          )) {
            break;
          }
          rejected.add(
            RejectedProposal(
              id: nextRejectedId(),
              proposal: proposal,
              reason: op.reason?.trim() ?? '',
              sourceMessageId: op.sourceMessageId,
              createdAt: timestamp,
            ),
          );
          break;
        case RejectedOpType.reopen:
          final index = rejected.indexWhere((entry) => entry.id == op.id);
          if (index == -1) break;
          rejected[index] = rejected[index].copyWith(
            status: RejectedStatus.reopened,
          );
          break;
      }
    }

    final roleplay = _applyRoleplay(
      current.roleplay,
      update,
      addedFactIds,
      growthConfig: growthConfig,
      nextMilestoneId: nextMilestoneId,
      sourceMessageId: sourceMessageId,
      onGrowthEvaluated: onGrowthEvaluated,
      now: timestamp,
    );

    return current.copyWith(
      summary: _clamp(
        _resolveNarrative(update.summary, current.summary),
        MemoryPolicy.summaryMaxChars,
      ),
      emotionalState: _clamp(
        _resolveNarrative(update.emotionalState, current.emotionalState),
        MemoryPolicy.emotionalStateMaxChars,
      ),
      facts: facts,
      rejected: rejected,
      roleplay: roleplay,
      clearRoleplay: roleplay == null,
      updatedAt: timestamp,
    );
  }

  static RoleplayMemory? _applyRoleplay(
    RoleplayMemory? current,
    MemoryUpdate update,
    List<String> addedFactIds, {
    CharacterGrowthConfig? growthConfig,
    String Function()? nextMilestoneId,
    String? sourceMessageId,
    void Function(GrowthEvaluationResult result)? onGrowthEvaluated,
    required DateTime now,
  }) {
    final hasUpdate =
        update.mood != null ||
        update.relationshipStage != null ||
        update.scene != null ||
        update.storyTime != null ||
        update.characterState != null ||
        update.intimacy != null ||
        update.intimacyNote != null ||
        update.unresolved != null ||
        update.customMetrics.isNotEmpty ||
        update.customNickname != null ||
        update.triggeredTransitions.isNotEmpty;
    if (current == null && !hasUpdate && growthConfig == null) return null;

    final base = current ?? const RoleplayMemory();
    final merged = base.copyWith(
      mood: _resolveNarrative(update.mood, base.mood),
      relationshipStage: _resolveNarrative(
        update.relationshipStage,
        base.relationshipStage,
      ),
      scene: _resolveNarrative(update.scene, base.scene),
      storyTime: _resolveNarrative(update.storyTime, base.storyTime),
      characterState: _resolveNarrative(
        update.characterState,
        base.characterState,
      ),
      intimacy: growthConfig == null
          ? (update.intimacy ?? base.intimacy)
          : base.intimacy,
      previousIntimacy: growthConfig == null
          ? (update.intimacy != null ? base.intimacy : base.previousIntimacy)
          : base.previousIntimacy,
      intimacyNote: _resolveNarrative(update.intimacyNote, base.intimacyNote),
      unresolved: _resolveNarrative(update.unresolved, base.unresolved),
      customNickname: growthConfig == null
          ? _resolveNarrative(update.customNickname, base.customNickname)
          : base.customNickname,
      newFactIds: <String>{
        ...base.newFactIds,
        ...addedFactIds,
      }.toList(growable: false),
    );

    if (growthConfig != null) {
      final result = CharacterGrowthEngine.evaluate(
        config: growthConfig,
        current: merged,
        proposedIntimacy: update.intimacy,
        proposedCustomMetrics: update.customMetrics,
        proposedCustomNickname: update.customNickname,
        triggeredTransitions: update.triggeredTransitions,
        transitionReason: update.transitionReason,
        storyTime: merged.storyTime,
        sourceMessageId: sourceMessageId,
        nextMilestoneId:
            nextMilestoneId ?? () => 'ms_${now.microsecondsSinceEpoch}',
        now: now,
      );
      onGrowthEvaluated?.call(result);
      return result.memory.isEmpty ? null : result.memory;
    }

    return merged.isEmpty ? null : merged;
  }

  static String _clamp(String value, int maxChars) {
    if (maxChars <= 0 || value.length <= maxChars) return value;
    return '${value.substring(0, maxChars - 1)}…';
  }

  /// 归一化后的近似匹配：短文本是长文本的子串即视为同一条。
  /// 用于防止模型把已废止的约定换一种稍长的说法重新加回来。
  static bool _looksSame(String a, String b) {
    if (a == b) return true;
    final shorter = a.length <= b.length ? a : b;
    final longer = a.length <= b.length ? b : a;
    return shorter.length >= 4 && longer.contains(shorter);
  }

  static const Set<String> _unchangedSentinels = {
    '未提及',
    '无变化',
    'unchanged',
    'no change',
    'none',
    'null',
  };

  static String _resolveNarrative(String? next, String current) {
    if (next == null) return current;
    final trimmed = next.trim();
    if (trimmed.isEmpty) return current;
    if (_unchangedSentinels.contains(trimmed.toLowerCase())) return current;
    return trimmed;
  }

  static final RegExp _punctuation = RegExp(r'[\s，。！？、；：（）()\[\]【】,\.!\?;:]+');

  static String _normalize(String value) =>
      value.toLowerCase().replaceAll(_punctuation, '');
}
