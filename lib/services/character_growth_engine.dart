import '../models/character_growth.dart';
import '../models/roleplay_memory.dart';
import 'world_info_service.dart';

/// 一次成长判定后的输出结果。
class GrowthEvaluationResult {
  const GrowthEvaluationResult({
    required this.memory,
    this.transitionedFrom,
    this.transitionedTo,
    this.matchedTransition,
    this.milestone,
  });

  final RoleplayMemory memory;
  final GrowthStage? transitionedFrom;
  final GrowthStage? transitionedTo;
  final GrowthTransition? matchedTransition;
  final GrowthMilestone? milestone;

  bool get didTransition => transitionedTo != null;
}

/// 成长型角色卡的确定性状态机引擎（单会话独立周目）。
///
/// LLM 仅负责在记忆更新时提出数值变化建议和叙事事件触发 ID；
/// 所有数值限幅、阈值校验、分支优先级和阶段跃迁都由本引擎确定性执行。
class CharacterGrowthEngine {
  CharacterGrowthEngine._();

  static const Set<String> _unchangedSentinels = {
    '未提及',
    '无变化',
    'unchanged',
    'no change',
    'none',
    'null',
  };

  /// 获取当前所处的成长阶段；未初始化或 ID 无效时回退到初始阶段。
  static GrowthStage currentStage(
    CharacterGrowthConfig config,
    RoleplayMemory? memory,
  ) {
    return config.stageById(memory?.currentStageId) ?? config.initialStage;
  }

  /// 为世界书门控构造当前会话的成长上下文。
  static WorldInfoGrowthContext buildWorldInfoContext(
    CharacterGrowthConfig config,
    RoleplayMemory? memory,
  ) {
    final stage = currentStage(config, memory);
    final metrics = <String, int>{
      for (final def in config.metrics)
        def.id: (memory?.customMetrics[def.id] ?? def.initial).clamp(
          def.min,
          def.max,
        ),
    };
    return WorldInfoGrowthContext(
      currentStageId: stage.id,
      intimacy: (memory?.intimacy ?? config.initialIntimacy).clamp(0, 100),
      customMetrics: metrics,
    );
  }

  /// 确保 [RoleplayMemory] 已补全该成长配置所需的初始阶段与初始数值。
  static RoleplayMemory ensureInitialized(
    RoleplayMemory? current,
    CharacterGrowthConfig config,
  ) {
    final initialStage = config.initialStage;
    if (current == null) {
      return RoleplayMemory(
        relationshipStage: initialStage.name,
        intimacy: config.initialIntimacy.clamp(0, 100),
        currentStageId: initialStage.id,
        visitedStageIds: [initialStage.id],
        customMetrics: config.initialCustomMetrics(),
      );
    }

    final resolvedStage =
        config.stageById(current.currentStageId) ?? initialStage;
    final visited = List<String>.from(current.visitedStageIds);
    if (!visited.contains(resolvedStage.id)) {
      visited.add(resolvedStage.id);
    }

    final mergedMetrics = <String, int>{};
    for (final def in config.metrics) {
      final raw = current.customMetrics[def.id] ?? def.initial;
      mergedMetrics[def.id] = raw.clamp(def.min, def.max);
    }

    final intimacy = (current.intimacy ?? config.initialIntimacy).clamp(0, 100);
    final relationshipStage = current.relationshipStage.trim().isEmpty
        ? resolvedStage.name
        : current.relationshipStage;

    return current.copyWith(
      relationshipStage: relationshipStage,
      intimacy: intimacy,
      currentStageId: resolvedStage.id,
      visitedStageIds: visited,
      customMetrics: mergedMetrics,
    );
  }

  /// 根据记忆维护模型的输出提案，确定性执行限幅、指标更新与分支阶段跃迁。
  static GrowthEvaluationResult evaluate({
    required CharacterGrowthConfig config,
    required RoleplayMemory? current,
    int? proposedIntimacy,
    Map<String, int> proposedCustomMetrics = const {},
    String? proposedCustomNickname,
    List<String> triggeredTransitions = const [],
    String? transitionReason,
    String? storyTime,
    String? sourceMessageId,
    required String Function() nextMilestoneId,
    DateTime? now,
  }) {
    final base = ensureInitialized(current, config);
    if (base.growthLocked) {
      return GrowthEvaluationResult(memory: base);
    }

    final prevIntimacy = (base.intimacy ?? config.initialIntimacy).clamp(
      0,
      100,
    );
    var nextIntimacy = prevIntimacy;
    int? nextPrevIntimacy = base.previousIntimacy;
    if (proposedIntimacy != null) {
      final clampedProposal = proposedIntimacy.clamp(0, 100);
      final delta = (clampedProposal - prevIntimacy).clamp(
        -config.maxIntimacyLoss,
        config.maxIntimacyGain,
      );
      nextIntimacy = (prevIntimacy + delta).clamp(0, 100);
      if (nextIntimacy != prevIntimacy) {
        nextPrevIntimacy = prevIntimacy;
      }
    }

    final nextCustomMetrics = Map<String, int>.from(base.customMetrics);
    final nextPrevCustomMetrics = Map<String, int>.from(
      base.previousCustomMetrics,
    );
    for (final def in config.metrics) {
      final prevVal = (base.customMetrics[def.id] ?? def.initial).clamp(
        def.min,
        def.max,
      );
      final proposed = proposedCustomMetrics[def.id];
      if (proposed == null) {
        nextCustomMetrics[def.id] = prevVal;
        continue;
      }
      final clampedProposal = proposed.clamp(def.min, def.max);
      final delta = (clampedProposal - prevVal).clamp(
        -def.maxLoss,
        def.maxGain,
      );
      final nextVal = (prevVal + delta).clamp(def.min, def.max);
      nextCustomMetrics[def.id] = nextVal;
      if (nextVal != prevVal) {
        nextPrevCustomMetrics[def.id] = prevVal;
      }
    }

    var nextNickname = base.customNickname;
    if (proposedCustomNickname != null) {
      final trimmed = proposedCustomNickname.trim();
      if (trimmed.isNotEmpty &&
          !_unchangedSentinels.contains(trimmed.toLowerCase())) {
        nextNickname = trimmed;
      }
    }

    final stage = currentStage(config, base);
    final sortedTransitions = List<GrowthTransition>.from(stage.transitions)
      ..sort((a, b) => b.priority.compareTo(a.priority));
    final triggeredSet = triggeredTransitions
        .map((id) => id.trim())
        .where((id) => id.isNotEmpty)
        .toSet();

    GrowthTransition? matched;
    GrowthStage? targetStage;
    for (final transition in sortedTransitions) {
      if (!_matchesAllConditions(
        transition.conditions,
        config: config,
        intimacy: nextIntimacy,
        customMetrics: nextCustomMetrics,
      )) {
        continue;
      }
      if (transition.hasNarrativeTrigger &&
          !triggeredSet.contains(transition.id)) {
        continue;
      }
      final candidateTarget = config.stageById(transition.toStageId);
      if (candidateTarget == null) continue;
      matched = transition;
      targetStage = candidateTarget;
      break;
    }

    if (matched != null && targetStage != null) {
      final visited = List<String>.from(base.visitedStageIds);
      if (!visited.contains(targetStage.id)) {
        visited.add(targetStage.id);
      }

      final reasonText = (transitionReason ?? '').trim().isNotEmpty
          ? transitionReason!.trim()
          : matched.narrativeTrigger;
      final milestone = GrowthMilestone(
        id: nextMilestoneId(),
        fromStageId: stage.id,
        toStageId: targetStage.id,
        title: matched.milestoneTitle.trim().isNotEmpty
            ? matched.milestoneTitle.trim()
            : '${stage.name} → ${targetStage.name}',
        reason: reasonText,
        storyTime: (storyTime ?? '').trim().isNotEmpty
            ? storyTime!.trim()
            : base.storyTime,
        sourceMessageId: sourceMessageId,
        createdAt: now ?? DateTime.now(),
      );

      final beatText = matched.transitionBeat.trim().isNotEmpty
          ? matched.transitionBeat.trim()
          : reasonText;
      final updated = base.copyWith(
        relationshipStage: targetStage.name,
        intimacy: nextIntimacy,
        previousIntimacy: nextPrevIntimacy,
        currentStageId: targetStage.id,
        visitedStageIds: visited,
        customMetrics: nextCustomMetrics,
        previousCustomMetrics: nextPrevCustomMetrics,
        customNickname: nextNickname,
        milestones: [...base.milestones, milestone],
        pendingTransition: StageTransitionBeat(
          fromStageId: stage.id,
          toStageId: targetStage.id,
          reason: beatText,
          remainingTurns: 2,
        ),
      );
      return GrowthEvaluationResult(
        memory: updated,
        transitionedFrom: stage,
        transitionedTo: targetStage,
        matchedTransition: matched,
        milestone: milestone,
      );
    }

    final updated = base.copyWith(
      relationshipStage: stage.name,
      intimacy: nextIntimacy,
      previousIntimacy: nextPrevIntimacy,
      customMetrics: nextCustomMetrics,
      previousCustomMetrics: nextPrevCustomMetrics,
      customNickname: nextNickname,
    );
    return GrowthEvaluationResult(memory: updated);
  }

  /// 生成注入到对话模型系统提示词中的 `<character_growth>` 阶段增量块。
  ///
  /// 只附加当前阶段的行为叠加层与刚发生跃迁时的 1~2 轮过渡指引，不修改原始人设。
  static String buildStagePromptBlock(
    CharacterGrowthConfig config,
    RoleplayMemory? memory,
  ) {
    final stage = currentStage(config, memory);
    final lines = <String>[
      '当前成长阶段：${_escapeTag(stage.name)}',
      if (stage.summary.trim().isNotEmpty)
        '阶段概述：${_escapeTag(stage.summary.trim())}',
      if (stage.isEnding) '状态：当前已进入结局分支阶段。',
    ];

    final nickname = memory?.customNickname.trim() ?? '';
    if (nickname.isNotEmpty) {
      lines.add('当前对用户的称呼：${_escapeTag(nickname)}');
    }

    final sections = <String>[lines.join('\n')];

    final overlay = stage.promptOverlay.trim();
    if (overlay.isNotEmpty) {
      sections.add('[本阶段态度与表现]\n${_escapeTag(overlay)}');
    }

    final pending = memory?.pendingTransition;
    if (pending != null &&
        pending.remainingTurns > 0 &&
        pending.toStageId == stage.id) {
      final fromName =
          config.stageById(pending.fromStageId)?.name ?? pending.fromStageId;
      final beatLines = <String>[
        '你们的关系刚刚从「${_escapeTag(fromName)}」步入「${_escapeTag(stage.name)}」。请用自然渐进的语气呈现这一转变，不要生硬宣告数值或系统提示。',
        if (pending.reason.trim().isNotEmpty)
          '过渡表现指引：${_escapeTag(pending.reason.trim())}',
      ];
      sections.add('[阶段过渡指引]\n${beatLines.join('\n')}');
    }

    return '<character_growth>\n'
        '以下是角色在本对话当前成长阶段的增量指引，请与基础角色设定自然融合。\n\n'
        '${sections.join('\n\n')}\n'
        '</character_growth>';
  }

  /// 每次对话回复完成后消耗一轮过渡提示计数；归零后自动清除。
  static RoleplayMemory consumeTransitionTurn(RoleplayMemory memory) {
    final pending = memory.pendingTransition;
    if (pending == null) return memory;
    final nextTurns = pending.remainingTurns - 1;
    if (nextTurns <= 0) {
      return memory.copyWith(clearPendingTransition: true);
    }
    return memory.copyWith(
      pendingTransition: pending.copyWith(remainingTurns: nextTurns),
    );
  }

  /// 用户手动切换阶段。
  static RoleplayMemory applyManualStageSwitch({
    required CharacterGrowthConfig config,
    required RoleplayMemory? current,
    required String targetStageId,
    required String reason,
    required String Function() nextMilestoneId,
    DateTime? now,
  }) {
    final base = ensureInitialized(current, config);
    final target = config.stageById(targetStageId);
    if (target == null || target.id == base.currentStageId) return base;

    final fromStage = currentStage(config, base);
    final visited = List<String>.from(base.visitedStageIds);
    if (!visited.contains(target.id)) {
      visited.add(target.id);
    }

    GrowthTransition? directEdge;
    for (final transition in fromStage.transitions) {
      if (transition.toStageId == target.id) {
        directEdge = transition;
        break;
      }
    }

    final milestone = GrowthMilestone(
      id: nextMilestoneId(),
      fromStageId: fromStage.id,
      toStageId: target.id,
      title: directEdge != null && directEdge.milestoneTitle.trim().isNotEmpty
          ? directEdge.milestoneTitle.trim()
          : '${fromStage.name} → ${target.name}',
      reason: reason,
      storyTime: base.storyTime,
      createdAt: now ?? DateTime.now(),
    );

    return base.copyWith(
      relationshipStage: target.name,
      currentStageId: target.id,
      visitedStageIds: visited,
      milestones: [...base.milestones, milestone],
      pendingTransition:
          directEdge != null && directEdge.transitionBeat.trim().isNotEmpty
          ? StageTransitionBeat(
              fromStageId: fromStage.id,
              toStageId: target.id,
              reason: directEdge.transitionBeat.trim(),
              remainingTurns: 1,
            )
          : null,
      clearPendingTransition:
          directEdge == null || directEdge.transitionBeat.trim().isEmpty,
    );
  }

  /// 重置当前对话中的成长进度（保留普通场景与消息记录）。
  static RoleplayMemory resetGrowth(
    CharacterGrowthConfig config,
    RoleplayMemory? current,
  ) {
    final initialStage = config.initialStage;
    final base = current ?? const RoleplayMemory();
    return base.copyWith(
      relationshipStage: initialStage.name,
      intimacy: config.initialIntimacy.clamp(0, 100),
      clearPreviousIntimacy: true,
      intimacyNote: '',
      currentStageId: initialStage.id,
      visitedStageIds: [initialStage.id],
      customMetrics: config.initialCustomMetrics(),
      previousCustomMetrics: const {},
      customNickname: '',
      milestones: const [],
      clearPendingTransition: true,
      growthLocked: false,
    );
  }

  /// 切换自动成长锁定状态。
  static RoleplayMemory setGrowthLocked(
    CharacterGrowthConfig config,
    RoleplayMemory? current,
    bool locked,
  ) {
    return ensureInitialized(current, config).copyWith(growthLocked: locked);
  }

  static bool _matchesAllConditions(
    List<GrowthMetricCondition> conditions, {
    required CharacterGrowthConfig config,
    required int intimacy,
    required Map<String, int> customMetrics,
  }) {
    for (final condition in conditions) {
      final int value;
      if (condition.metric == 'intimacy') {
        value = intimacy;
      } else {
        final def = config.metricById(condition.metric);
        if (def == null) return false;
        value = customMetrics[def.id] ?? def.initial;
      }
      if (!condition.matches(value)) {
        return false;
      }
    }
    return true;
  }

  static String _escapeTag(String value) => value
      .replaceAll('<character_growth>', '＜character_growth＞')
      .replaceAll('</character_growth>', '＜/character_growth＞');
}
