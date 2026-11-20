/// 成长型角色卡的蓝图配置模型（只读模板，随角色卡存储）。
///
/// 会话内的实际成长进度存放在 `RoleplayMemory` 中，做到角色卡纯净、单会话周目独立。
const int maxGrowthMetrics = 4;
const int maxGrowthStages = 20;
const int maxGrowthTransitionsPerStage = 8;
const int maxGrowthOverlayRunes = 2000;
const int maxGrowthTextRunes = 300;
const int maxGrowthIntimacyCap = 50;

final RegExp _growthSlugPattern = RegExp(r'^[a-z][a-z0-9_]{0,31}$');

enum GrowthMetricOperator { gte, lte, gt, lt }

GrowthMetricOperator _operatorFromJson(Object? value, String context) {
  switch (value) {
    case '>=':
    case 'gte':
      return GrowthMetricOperator.gte;
    case '<=':
    case 'lte':
      return GrowthMetricOperator.lte;
    case '>':
    case 'gt':
      return GrowthMetricOperator.gt;
    case '<':
    case 'lt':
      return GrowthMetricOperator.lt;
    default:
      throw FormatException('Invalid metric operator in $context: $value');
  }
}

String _operatorToJson(GrowthMetricOperator op) {
  switch (op) {
    case GrowthMetricOperator.gte:
      return '>=';
    case GrowthMetricOperator.lte:
      return '<=';
    case GrowthMetricOperator.gt:
      return '>';
    case GrowthMetricOperator.lt:
      return '<';
  }
}

/// 单条数值门槛条件（可作用于内置 `intimacy` 或作者自定义属性）。
class GrowthMetricCondition {
  const GrowthMetricCondition({
    required this.metric,
    required this.operator,
    required this.value,
  });

  final String metric;
  final GrowthMetricOperator operator;
  final int value;

  bool matches(int currentValue) {
    switch (operator) {
      case GrowthMetricOperator.gte:
        return currentValue >= value;
      case GrowthMetricOperator.lte:
        return currentValue <= value;
      case GrowthMetricOperator.gt:
        return currentValue > value;
      case GrowthMetricOperator.lt:
        return currentValue < value;
    }
  }

  Map<String, dynamic> toJson() {
    return {
      'metric': metric,
      'op': _operatorToJson(operator),
      'value': value,
    };
  }

  factory GrowthMetricCondition.fromJson(
    Map<String, dynamic> json, {
    String context = 'condition',
  }) {
    final metric = json['metric'];
    if (metric is! String || !_growthSlugPattern.hasMatch(metric)) {
      throw FormatException('Invalid metric id in $context: $metric');
    }
    final op = _operatorFromJson(json['op'] ?? json['operator'], context);
    final rawValue = json['value'];
    if (rawValue is! int) {
      throw FormatException('Invalid numeric value in $context');
    }
    return GrowthMetricCondition(metric: metric, operator: op, value: rawValue);
  }
}

/// 作者自定义数值维度定义（如戒心、信任、默契等）。
class GrowthMetricDefinition {
  const GrowthMetricDefinition({
    required this.id,
    required this.name,
    this.description = '',
    this.min = 0,
    this.max = 100,
    this.initial = 0,
    this.maxGain = 10,
    this.maxLoss = 10,
    this.hidden = false,
  });

  final String id;
  final String name;
  final String description;
  final int min;
  final int max;
  final int initial;
  final int maxGain;
  final int maxLoss;
  final bool hidden;

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'name': name,
      if (description.isNotEmpty) 'description': description,
      'min': min,
      'max': max,
      'initial': initial,
      'max_gain': maxGain,
      'max_loss': maxLoss,
      if (hidden) 'hidden': hidden,
    };
  }

  factory GrowthMetricDefinition.fromJson(Map<String, dynamic> json) {
    final id = json['id'];
    if (id is! String || !_growthSlugPattern.hasMatch(id)) {
      throw FormatException('Invalid custom metric id: $id');
    }
    if (id == 'intimacy') {
      throw const FormatException(
        'Custom metric id cannot conflict with built-in "intimacy"',
      );
    }
    final name = _requiredTrimmedString(json['name'], 'metric $id name');
    final description = _optionalTrimmedString(
      json['description'],
      'metric $id description',
      maxRunes: maxGrowthTextRunes,
    );
    final min = _optionalInt(json['min'], 'metric $id min') ?? 0;
    final max = _optionalInt(json['max'], 'metric $id max') ?? 100;
    if (min >= max) {
      throw FormatException('Metric $id min must be less than max');
    }
    final initial = _optionalInt(json['initial'], 'metric $id initial') ?? min;
    if (initial < min || initial > max) {
      throw FormatException('Metric $id initial must be within [$min, $max]');
    }
    final span = max - min;
    final maxGain =
        _optionalInt(json['max_gain'] ?? json['maxGain'], 'metric $id max_gain') ??
        10;
    final maxLoss =
        _optionalInt(json['max_loss'] ?? json['maxLoss'], 'metric $id max_loss') ??
        10;
    if (maxGain < 1 || maxGain > span) {
      throw FormatException('Invalid max_gain for metric $id');
    }
    if (maxLoss < 1 || maxLoss > span) {
      throw FormatException('Invalid max_loss for metric $id');
    }
    final hidden = _optionalBool(json['hidden'], 'metric $id hidden') ?? false;

    return GrowthMetricDefinition(
      id: id,
      name: name,
      description: description,
      min: min,
      max: max,
      initial: initial,
      maxGain: maxGain,
      maxLoss: maxLoss,
      hidden: hidden,
    );
  }
}

/// 从一个阶段指向另一个阶段的有向跃迁边。
class GrowthTransition {
  const GrowthTransition({
    required this.id,
    required this.toStageId,
    this.priority = 100,
    this.reversible = false,
    this.conditions = const [],
    this.narrativeTrigger = '',
    this.transitionBeat = '',
    this.milestoneTitle = '',
  });

  final String id;
  final String toStageId;
  final int priority;
  final bool reversible;
  final List<GrowthMetricCondition> conditions;
  final String narrativeTrigger;
  final String transitionBeat;
  final String milestoneTitle;

  bool get hasNarrativeTrigger => narrativeTrigger.trim().isNotEmpty;

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'to_stage_id': toStageId,
      'priority': priority,
      if (reversible) 'reversible': reversible,
      if (conditions.isNotEmpty)
        'conditions': conditions.map((c) => c.toJson()).toList(),
      if (narrativeTrigger.isNotEmpty) 'narrative_trigger': narrativeTrigger,
      if (transitionBeat.isNotEmpty) 'transition_beat': transitionBeat,
      if (milestoneTitle.isNotEmpty) 'milestone_title': milestoneTitle,
    };
  }

  factory GrowthTransition.fromJson(
    Map<String, dynamic> json, {
    required String stageId,
  }) {
    final id = json['id'];
    if (id is! String || !_growthSlugPattern.hasMatch(id)) {
      throw FormatException('Invalid transition id in stage $stageId: $id');
    }
    final toStageId = json['to_stage_id'] ?? json['toStageId'];
    if (toStageId is! String || !_growthSlugPattern.hasMatch(toStageId)) {
      throw FormatException(
        'Invalid to_stage_id in transition $id: $toStageId',
      );
    }
    if (toStageId == stageId) {
      throw FormatException('Self transition is not allowed: $id');
    }
    final priority =
        _optionalInt(json['priority'], 'transition $id priority') ?? 100;
    final reversible =
        _optionalBool(json['reversible'], 'transition $id reversible') ?? false;
    final rawConditions = json['conditions'];
    final conditions = <GrowthMetricCondition>[];
    if (rawConditions != null) {
      if (rawConditions is! List) {
        throw FormatException('Invalid conditions in transition $id');
      }
      for (final item in rawConditions) {
        if (item is! Map) {
          throw FormatException('Invalid condition item in transition $id');
        }
        conditions.add(
          GrowthMetricCondition.fromJson(
            item.cast<String, dynamic>(),
            context: 'transition $id',
          ),
        );
      }
    }
    final narrativeTrigger = _optionalTrimmedString(
      json['narrative_trigger'] ?? json['narrativeTrigger'],
      'transition $id narrative_trigger',
      maxRunes: maxGrowthTextRunes,
    );
    final transitionBeat = _optionalTrimmedString(
      json['transition_beat'] ?? json['transitionBeat'],
      'transition $id transition_beat',
      maxRunes: maxGrowthTextRunes,
    );
    final milestoneTitle = _optionalTrimmedString(
      json['milestone_title'] ?? json['milestoneTitle'],
      'transition $id milestone_title',
      maxRunes: 80,
    );

    if (conditions.isEmpty && narrativeTrigger.isEmpty) {
      throw FormatException(
        'Transition $id must define at least one metric condition or narrative_trigger',
      );
    }

    return GrowthTransition(
      id: id,
      toStageId: toStageId,
      priority: priority,
      reversible: reversible,
      conditions: conditions,
      narrativeTrigger: narrativeTrigger,
      transitionBeat: transitionBeat,
      milestoneTitle: milestoneTitle,
    );
  }
}

/// 单个成长阶段节点。
class GrowthStage {
  const GrowthStage({
    required this.id,
    required this.name,
    this.summary = '',
    this.isInitial = false,
    this.isEnding = false,
    this.promptOverlay = '',
    this.avatarFile,
    this.illustrationFile,
    this.transitions = const [],
  });

  final String id;
  final String name;
  final String summary;
  final bool isInitial;
  final bool isEnding;
  final String promptOverlay;
  final String? avatarFile;
  final String? illustrationFile;
  final List<GrowthTransition> transitions;

  bool get hasAvatarFile => avatarFile != null && avatarFile!.trim().isNotEmpty;

  bool get hasIllustrationFile =>
      illustrationFile != null && illustrationFile!.trim().isNotEmpty;

  GrowthStage copyWith({
    String? id,
    String? name,
    String? summary,
    bool? isInitial,
    bool? isEnding,
    String? promptOverlay,
    String? avatarFile,
    bool clearAvatarFile = false,
    String? illustrationFile,
    bool clearIllustrationFile = false,
    List<GrowthTransition>? transitions,
  }) {
    return GrowthStage(
      id: id ?? this.id,
      name: name ?? this.name,
      summary: summary ?? this.summary,
      isInitial: isInitial ?? this.isInitial,
      isEnding: isEnding ?? this.isEnding,
      promptOverlay: promptOverlay ?? this.promptOverlay,
      avatarFile: clearAvatarFile ? null : (avatarFile ?? this.avatarFile),
      illustrationFile: clearIllustrationFile
          ? null
          : (illustrationFile ?? this.illustrationFile),
      transitions: transitions ?? this.transitions,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'name': name,
      if (summary.isNotEmpty) 'summary': summary,
      if (isInitial) 'is_initial': isInitial,
      if (isEnding) 'is_ending': isEnding,
      if (promptOverlay.isNotEmpty) 'prompt_overlay': promptOverlay,
      if (hasAvatarFile) 'avatar_file': avatarFile,
      if (hasIllustrationFile) 'illustration_file': illustrationFile,
      if (transitions.isNotEmpty)
        'transitions': transitions.map((t) => t.toJson()).toList(),
    };
  }

  factory GrowthStage.fromJson(Map<String, dynamic> json) {
    final id = json['id'];
    if (id is! String || !_growthSlugPattern.hasMatch(id)) {
      throw FormatException('Invalid stage id: $id');
    }
    final name = _requiredTrimmedString(json['name'], 'stage $id name');
    final summary = _optionalTrimmedString(
      json['summary'],
      'stage $id summary',
      maxRunes: maxGrowthTextRunes,
    );
    final isInitial =
        _optionalBool(json['is_initial'] ?? json['isInitial'], 'stage $id is_initial') ??
        false;
    final isEnding =
        _optionalBool(json['is_ending'] ?? json['isEnding'], 'stage $id is_ending') ??
        false;
    final promptOverlay = _optionalTrimmedString(
      json['prompt_overlay'] ?? json['promptOverlay'],
      'stage $id prompt_overlay',
      maxRunes: maxGrowthOverlayRunes,
    );
    final avatarFile = _optionalSafeAssetPath(
      json['avatar_file'] ?? json['avatarFile'],
      'stage $id avatar_file',
    );
    final illustrationFile = _optionalSafeAssetPath(
      json['illustration_file'] ?? json['illustrationFile'],
      'stage $id illustration_file',
    );

    final rawTransitions = json['transitions'];
    final transitions = <GrowthTransition>[];
    if (rawTransitions != null) {
      if (rawTransitions is! List) {
        throw FormatException('Invalid transitions in stage $id');
      }
      if (rawTransitions.length > maxGrowthTransitionsPerStage) {
        throw FormatException('Too many transitions in stage $id');
      }
      for (final item in rawTransitions) {
        if (item is! Map) {
          throw FormatException('Invalid transition entry in stage $id');
        }
        transitions.add(
          GrowthTransition.fromJson(
            item.cast<String, dynamic>(),
            stageId: id,
          ),
        );
      }
    }

    return GrowthStage(
      id: id,
      name: name,
      summary: summary,
      isInitial: isInitial,
      isEnding: isEnding,
      promptOverlay: promptOverlay,
      avatarFile: avatarFile,
      illustrationFile: illustrationFile,
      transitions: transitions,
    );
  }
}

/// 成长型角色卡总配置（对应 `growth.json`）。
class CharacterGrowthConfig {
  const CharacterGrowthConfig({
    this.intimacyLabel = '',
    this.intimacyDescription = '',
    this.initialIntimacy = 20,
    this.maxIntimacyGain = 8,
    this.maxIntimacyLoss = 12,
    this.metrics = const [],
    required this.stages,
  });

  static const String format = 'lumenflow_character_growth';
  static const int version = 1;

  /// 内置 `intimacy` 轴在 UI 与提示词中的自定义展示名（留空时回退本地化“亲密度”）。
  final String intimacyLabel;

  /// 内置 `intimacy` 轴的语义判定说明（例如“熟稔与信任程度，而非恋爱关系”）。
  final String intimacyDescription;

  final int initialIntimacy;
  final int maxIntimacyGain;
  final int maxIntimacyLoss;

  /// 0 ~ 4 个作者自定义数值属性。
  final List<GrowthMetricDefinition> metrics;

  /// 1 ~ 20 个成长阶段节点，其中有且仅有一个 `isInitial == true`。
  final List<GrowthStage> stages;

  GrowthStage get initialStage {
    for (final stage in stages) {
      if (stage.isInitial) return stage;
    }
    return stages.first;
  }

  GrowthStage? stageById(String? id) {
    if (id == null || id.isEmpty) return null;
    for (final stage in stages) {
      if (stage.id == id) return stage;
    }
    return null;
  }

  GrowthMetricDefinition? metricById(String id) {
    for (final metric in metrics) {
      if (metric.id == id) return metric;
    }
    return null;
  }

  int stageIndex(String id) {
    return stages.indexWhere((stage) => stage.id == id);
  }

  bool get hasBranching {
    for (final stage in stages) {
      if (stage.transitions.length > 1) return true;
    }
    return false;
  }

  Map<String, int> initialCustomMetrics() {
    return {for (final metric in metrics) metric.id: metric.initial};
  }

  CharacterGrowthConfig copyWith({
    String? intimacyLabel,
    String? intimacyDescription,
    int? initialIntimacy,
    int? maxIntimacyGain,
    int? maxIntimacyLoss,
    List<GrowthMetricDefinition>? metrics,
    List<GrowthStage>? stages,
  }) {
    return CharacterGrowthConfig(
      intimacyLabel: intimacyLabel ?? this.intimacyLabel,
      intimacyDescription: intimacyDescription ?? this.intimacyDescription,
      initialIntimacy: initialIntimacy ?? this.initialIntimacy,
      maxIntimacyGain: maxIntimacyGain ?? this.maxIntimacyGain,
      maxIntimacyLoss: maxIntimacyLoss ?? this.maxIntimacyLoss,
      metrics: metrics ?? this.metrics,
      stages: stages ?? this.stages,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      '_format': format,
      '_version': version,
      if (intimacyLabel.isNotEmpty) 'intimacy_label': intimacyLabel,
      if (intimacyDescription.isNotEmpty)
        'intimacy_description': intimacyDescription,
      'initial_intimacy': initialIntimacy,
      'max_intimacy_gain': maxIntimacyGain,
      'max_intimacy_loss': maxIntimacyLoss,
      if (metrics.isNotEmpty)
        'metrics': metrics.map((m) => m.toJson()).toList(),
      'stages': stages.map((s) => s.toJson()).toList(),
    };
  }

  factory CharacterGrowthConfig.fromJson(Map<String, dynamic> json) {
    if (json['_format'] != format) {
      throw const FormatException('Invalid character growth format');
    }
    if (json['_version'] != version) {
      throw FormatException(
        'Unsupported character growth version: ${json['_version']}',
      );
    }

    final intimacyLabel = _optionalTrimmedString(
      json['intimacy_label'] ?? json['intimacyLabel'],
      'intimacy_label',
      maxRunes: 40,
    );
    final intimacyDescription = _optionalTrimmedString(
      json['intimacy_description'] ?? json['intimacyDescription'],
      'intimacy_description',
      maxRunes: maxGrowthTextRunes,
    );
    final initialIntimacy =
        _optionalInt(
          json['initial_intimacy'] ?? json['initialIntimacy'],
          'initial_intimacy',
        ) ??
        20;
    if (initialIntimacy < 0 || initialIntimacy > 100) {
      throw const FormatException('initial_intimacy must be within 0..100');
    }
    final maxIntimacyGain =
        _optionalInt(
          json['max_intimacy_gain'] ?? json['maxIntimacyGain'],
          'max_intimacy_gain',
        ) ??
        8;
    final maxIntimacyLoss =
        _optionalInt(
          json['max_intimacy_loss'] ?? json['maxIntimacyLoss'],
          'max_intimacy_loss',
        ) ??
        12;
    if (maxIntimacyGain < 1 || maxIntimacyGain > maxGrowthIntimacyCap) {
      throw const FormatException('Invalid max_intimacy_gain');
    }
    if (maxIntimacyLoss < 1 || maxIntimacyLoss > maxGrowthIntimacyCap) {
      throw const FormatException('Invalid max_intimacy_loss');
    }

    final metrics = <GrowthMetricDefinition>[];
    final metricIds = <String>{'intimacy'};
    final rawMetrics = json['metrics'];
    if (rawMetrics != null) {
      if (rawMetrics is! List) {
        throw const FormatException('Invalid growth metrics list');
      }
      if (rawMetrics.length > maxGrowthMetrics) {
        throw const FormatException('Too many custom growth metrics');
      }
      for (final item in rawMetrics) {
        if (item is! Map) {
          throw const FormatException('Invalid growth metric entry');
        }
        final def = GrowthMetricDefinition.fromJson(
          item.cast<String, dynamic>(),
        );
        if (!metricIds.add(def.id)) {
          throw FormatException('Duplicate growth metric id: ${def.id}');
        }
        metrics.add(def);
      }
    }

    final rawStages = json['stages'];
    if (rawStages is! List || rawStages.isEmpty) {
      throw const FormatException('Growth config must define at least 1 stage');
    }
    if (rawStages.length > maxGrowthStages) {
      throw const FormatException('Too many growth stages');
    }

    final stages = <GrowthStage>[];
    final stageIds = <String>{};
    var initialCount = 0;
    for (final item in rawStages) {
      if (item is! Map) {
        throw const FormatException('Invalid growth stage entry');
      }
      final stage = GrowthStage.fromJson(item.cast<String, dynamic>());
      if (!stageIds.add(stage.id)) {
        throw FormatException('Duplicate growth stage id: ${stage.id}');
      }
      if (stage.isInitial) initialCount++;
      stages.add(stage);
    }
    if (initialCount != 1) {
      throw FormatException(
        'Growth config must have exactly 1 initial stage (found $initialCount)',
      );
    }

    // 校验所有出边引用目标和指标均存在且 ID 全局唯一。
    final transitionIds = <String>{};
    for (final stage in stages) {
      for (final transition in stage.transitions) {
        if (!transitionIds.add(transition.id)) {
          throw FormatException(
            'Duplicate growth transition id: ${transition.id}',
          );
        }
        if (!stageIds.contains(transition.toStageId)) {
          throw FormatException(
            'Transition ${transition.id} references unknown stage '
            '${transition.toStageId}',
          );
        }
        for (final condition in transition.conditions) {
          if (!metricIds.contains(condition.metric)) {
            throw FormatException(
              'Transition ${transition.id} references unknown metric '
              '${condition.metric}',
            );
          }
        }
      }
    }

    return CharacterGrowthConfig(
      intimacyLabel: intimacyLabel,
      intimacyDescription: intimacyDescription,
      initialIntimacy: initialIntimacy,
      maxIntimacyGain: maxIntimacyGain,
      maxIntimacyLoss: maxIntimacyLoss,
      metrics: metrics,
      stages: stages,
    );
  }
}

String _requiredTrimmedString(Object? value, String field) {
  if (value is! String || value.trim().isEmpty) {
    throw FormatException('Missing required $field');
  }
  final trimmed = value.trim();
  if (trimmed.runes.length > 80) {
    throw FormatException('$field is too long');
  }
  return trimmed;
}

String _optionalTrimmedString(
  Object? value,
  String field, {
  required int maxRunes,
}) {
  if (value == null) return '';
  if (value is! String) {
    throw FormatException('Invalid string for $field');
  }
  final trimmed = value.trim();
  if (trimmed.runes.length > maxRunes) {
    throw FormatException('$field exceeds $maxRunes characters');
  }
  return trimmed;
}

int? _optionalInt(Object? value, String field) {
  if (value == null) return null;
  if (value is! int) {
    throw FormatException('Invalid integer for $field');
  }
  return value;
}

bool? _optionalBool(Object? value, String field) {
  if (value == null) return null;
  if (value is! bool) {
    throw FormatException('Invalid boolean for $field');
  }
  return value;
}

String? _optionalSafeAssetPath(Object? value, String field) {
  if (value == null) return null;
  if (value is! String) {
    throw FormatException('Invalid path for $field');
  }
  final normalized = value.replaceAll('\\', '/').trim();
  if (normalized.isEmpty) return null;
  if (normalized.startsWith('/') || RegExp(r'^[A-Za-z]:').hasMatch(normalized)) {
    throw FormatException('Absolute path not allowed in $field');
  }
  final segments = normalized.split('/');
  if (segments.any((s) => s.isEmpty || s == '.' || s == '..')) {
    throw FormatException('Invalid relative path in $field');
  }
  return normalized;
}
