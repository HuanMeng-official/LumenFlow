import 'character_growth.dart';

const int _maxWorldInfoEntries = 500;
const int _maxWorldInfoContentRunes = 4000;
const int _maxWorldInfoKeys = 20;
const int _maxWorldInfoRegexRunes = 200;
const int _maxWorldInfoGroupRunes = 64;
const int _maxWorldInfoTiming = 1000;
const int _maxWorldInfoMinActivations = 50;
const int _maxWorldInfoRecursionDepth = 10;

/// 条目在提示词中的注入位置。
const Set<String> worldInfoEntryPositions = {
  'system',
  'before_preset',
  'after_preset',
  'at_depth',
};

enum WorldInfoCategory { character, location, item, rule, event, lore, other }

enum WorldInfoMatchMode { substring, word, regex }

/// 世界书条目的成长阶段与数值解锁门控（可选）。
class WorldInfoUnlockCondition {
  const WorldInfoUnlockCondition({
    this.stageIds = const [],
    this.minIntimacy,
    this.maxIntimacy,
    this.metricConditions = const [],
    this.hiddenUntilUnlocked = false,
  });

  final List<String> stageIds;
  final int? minIntimacy;
  final int? maxIntimacy;
  final List<GrowthMetricCondition> metricConditions;
  final bool hiddenUntilUnlocked;

  bool get hasConditions =>
      stageIds.isNotEmpty ||
      minIntimacy != null ||
      maxIntimacy != null ||
      metricConditions.isNotEmpty;

  Map<String, dynamic> toJson() {
    return {
      if (stageIds.isNotEmpty) 'stage_ids': stageIds,
      if (minIntimacy != null) 'min_intimacy': minIntimacy,
      if (maxIntimacy != null) 'max_intimacy': maxIntimacy,
      if (metricConditions.isNotEmpty)
        'metric_conditions': metricConditions.map((c) => c.toJson()).toList(),
      if (hiddenUntilUnlocked) 'hidden_until_unlocked': hiddenUntilUnlocked,
    };
  }

  factory WorldInfoUnlockCondition.fromJson(
    Map<String, dynamic> json,
    String entryId,
  ) {
    final stageIds = _stringList(
      json['stage_ids'] ?? json['stageIds'],
      'unlock.stage_ids',
      entryId,
    );
    final minIntimacy = _optionalInt(json, 'min_intimacy') ??
        _optionalInt(json, 'minIntimacy');
    final maxIntimacy = _optionalInt(json, 'max_intimacy') ??
        _optionalInt(json, 'maxIntimacy');
    if (minIntimacy != null && (minIntimacy < 0 || minIntimacy > 100)) {
      throw FormatException('Invalid unlock.min_intimacy for entry $entryId');
    }
    if (maxIntimacy != null && (maxIntimacy < 0 || maxIntimacy > 100)) {
      throw FormatException('Invalid unlock.max_intimacy for entry $entryId');
    }
    if (minIntimacy != null &&
        maxIntimacy != null &&
        minIntimacy > maxIntimacy) {
      throw FormatException(
        'unlock.min_intimacy exceeds unlock.max_intimacy for entry $entryId',
      );
    }

    final rawMetrics = json['metric_conditions'] ?? json['metricConditions'];
    final metricConditions = <GrowthMetricCondition>[];
    if (rawMetrics != null) {
      if (rawMetrics is! List) {
        throw FormatException(
          'Invalid unlock.metric_conditions for entry $entryId',
        );
      }
      for (final item in rawMetrics) {
        if (item is! Map) {
          throw FormatException(
            'Invalid unlock.metric_conditions item for entry $entryId',
          );
        }
        metricConditions.add(
          GrowthMetricCondition.fromJson(
            item.cast<String, dynamic>(),
            context: 'world info entry $entryId unlock',
          ),
        );
      }
    }

    final rawHidden =
        json['hidden_until_unlocked'] ?? json['hiddenUntilUnlocked'] ?? false;
    if (rawHidden is! bool) {
      throw FormatException(
        'Invalid unlock.hidden_until_unlocked for entry $entryId',
      );
    }

    return WorldInfoUnlockCondition(
      stageIds: stageIds,
      minIntimacy: minIntimacy,
      maxIntimacy: maxIntimacy,
      metricConditions: metricConditions,
      hiddenUntilUnlocked: rawHidden,
    );
  }
}

class WorldInfoEntry {
  const WorldInfoEntry({
    required this.id,
    required this.title,
    required this.category,
    required this.tags,
    required this.keys,
    required this.secondaryKeys,
    required this.match,
    required this.caseSensitive,
    required this.content,
    required this.priority,
    required this.enabled,
    required this.position,
    required this.depth,
    this.group = '',
    this.probability = 100,
    this.recursive = false,
    this.sticky = 0,
    this.cooldown = 0,
    this.unlock,
  });

  final String id;
  final String title;
  final WorldInfoCategory category;
  final List<String> tags;
  final List<String> keys;
  final List<String> secondaryKeys;
  final WorldInfoMatchMode match;
  final bool caseSensitive;
  final String content;
  final int priority;
  final bool enabled;
  final String position;
  final int depth;

  /// 包含组：同一组最多激活一个条目，组名为空表示不分组。
  final String group;

  /// 命中后的激活概率，0-100。100 表示必定激活。
  final int probability;

  /// 激活后是否允许用本条内容继续触发其他条目。
  final bool recursive;

  /// 命中后继续保持在注入块中的消息数。
  final int sticky;

  /// 命中后抑制再次激活的消息数。
  final int cooldown;

  /// 可选的成长阶段 / 亲密度 / 自定义属性解锁门控。
  final WorldInfoUnlockCondition? unlock;

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'title': title,
      'category': category.name,
      'tags': tags,
      'keys': keys,
      'secondary_keys': secondaryKeys,
      'match': match.name,
      'case_sensitive': caseSensitive,
      'content': content,
      'priority': priority,
      'enabled': enabled,
      'position': position,
      'depth': depth,
      'group': group,
      'probability': probability,
      'recursive': recursive,
      'sticky': sticky,
      'cooldown': cooldown,
      if (unlock != null &&
          (unlock!.hasConditions || unlock!.hiddenUntilUnlocked))
        'unlock': unlock!.toJson(),
    };
  }
}

class WorldInfo {
  const WorldInfo({
    required this.name,
    required this.description,
    required this.background,
    required this.scanDepth,
    required this.budgetTokens,
    required this.entries,
    this.minActivations = 0,
    this.recursionDepth = 0,
  });

  static const String format = 'lumenflow_world_info';
  static const int version = 1;

  final String name;
  final String description;
  final String background;
  final int scanDepth;
  final int budgetTokens;
  final List<WorldInfoEntry> entries;

  /// 至少尝试激活多少条；聊天扫描会为它扩大回看窗口。
  final int minActivations;

  /// 递归激活的最大层数；0 表示关闭递归。
  final int recursionDepth;

  Map<String, dynamic> toJson() {
    return {
      '_format': format,
      '_version': version,
      'name': name,
      'description': description,
      'background': background,
      'scan_depth': scanDepth,
      'budget_tokens': budgetTokens,
      'min_activations': minActivations,
      'recursion_depth': recursionDepth,
      'entries': entries.map((entry) => entry.toJson()).toList(),
    };
  }

  factory WorldInfo.fromJson(Map<String, dynamic> json) {
    if (json['_format'] != format) {
      throw const FormatException('Invalid world info format');
    }
    if (json['_version'] != version) {
      throw FormatException(
        'Unsupported world info version: ${json['_version']}',
      );
    }

    final name = _optionalString(json, 'name') ?? '';
    final description = _optionalString(json, 'description') ?? '';
    final background = _optionalString(json, 'background') ?? '';
    final scanDepth = _optionalInt(json, 'scan_depth') ?? 4;
    final budgetTokens = _optionalInt(json, 'budget_tokens') ?? 1000;
    final minActivations = _optionalInt(json, 'min_activations') ?? 0;
    final recursionDepth = _optionalInt(json, 'recursion_depth') ?? 0;
    if (scanDepth < 0) {
      throw const FormatException('scan_depth must not be negative');
    }
    if (budgetTokens < 0) {
      throw const FormatException('budget_tokens must not be negative');
    }
    if (minActivations < 0 || minActivations > _maxWorldInfoMinActivations) {
      throw const FormatException('Invalid min_activations');
    }
    if (recursionDepth < 0 || recursionDepth > _maxWorldInfoRecursionDepth) {
      throw const FormatException('Invalid recursion_depth');
    }

    final entriesValue = json['entries'] ?? const <dynamic>[];
    if (entriesValue is! List) {
      throw const FormatException('Invalid world info entries');
    }
    if (entriesValue.length > _maxWorldInfoEntries) {
      throw const FormatException('Too many world info entries');
    }

    final entries = <WorldInfoEntry>[];
    final ids = <String>{};
    for (final item in entriesValue) {
      if (item is! Map) {
        throw const FormatException('Invalid world info entry');
      }
      final entry = _entryFromJson(item.cast<String, dynamic>());
      if (!ids.add(entry.id)) {
        throw FormatException('Duplicate world info entry id: ${entry.id}');
      }
      entries.add(entry);
    }

    return WorldInfo(
      name: name,
      description: description,
      background: background,
      scanDepth: scanDepth,
      budgetTokens: budgetTokens,
      entries: entries,
      minActivations: minActivations,
      recursionDepth: recursionDepth,
    );
  }
}

WorldInfoEntry _entryFromJson(Map<String, dynamic> json) {
  final id = json['id'];
  if (id is! String || id.isEmpty) {
    throw const FormatException('World info entry is missing an id');
  }

  final titleValue = json['title'];
  if (titleValue != null && titleValue is! String) {
    throw FormatException('Invalid title for world info entry $id');
  }
  final title = titleValue is String && titleValue.isNotEmpty ? titleValue : id;

  final category = _categoryFromJson(json['category']);
  final match = _matchFromJson(json['match']);
  final tags = _stringList(json['tags'], 'tags', id);
  final keys = _stringList(json['keys'], 'keys', id);
  final secondaryKeys = _stringList(
    json['secondary_keys'],
    'secondary_keys',
    id,
  );
  if (keys.isEmpty) {
    throw FormatException('World info entry $id has no primary keys');
  }
  if (keys.length > _maxWorldInfoKeys ||
      secondaryKeys.length > _maxWorldInfoKeys) {
    throw FormatException('World info entry $id has too many keys');
  }

  final caseSensitiveValue = json['case_sensitive'] ?? false;
  if (caseSensitiveValue is! bool) {
    throw FormatException('Invalid case_sensitive for world info entry $id');
  }
  final caseSensitive = caseSensitiveValue;

  final contentValue = json['content'];
  if (contentValue is! String) {
    throw FormatException('World info entry $id is missing content');
  }
  if (contentValue.runes.length > _maxWorldInfoContentRunes) {
    throw FormatException('World info entry $id content is too long');
  }

  final priority = _optionalInt(json, 'priority') ?? 0;
  final enabledValue = json['enabled'] ?? true;
  if (enabledValue is! bool) {
    throw FormatException('Invalid enabled for world info entry $id');
  }
  final positionValue = json['position'] ?? 'system';
  if (positionValue is! String ||
      !worldInfoEntryPositions.contains(positionValue)) {
    throw FormatException('Invalid position for world info entry $id');
  }
  final depth = _optionalInt(json, 'depth') ?? 0;
  if (depth < 0 || depth > _maxWorldInfoTiming) {
    throw FormatException('Invalid depth for world info entry $id');
  }

  final groupValue = json['group'] ?? '';
  if (groupValue is! String) {
    throw FormatException('Invalid group for world info entry $id');
  }
  final group = groupValue.trim();
  if (group.runes.length > _maxWorldInfoGroupRunes) {
    throw FormatException('World info entry $id group is too long');
  }

  final probability = _optionalInt(json, 'probability') ?? 100;
  if (probability < 0 || probability > 100) {
    throw FormatException('Invalid probability for world info entry $id');
  }

  final recursiveValue = json['recursive'] ?? false;
  if (recursiveValue is! bool) {
    throw FormatException('Invalid recursive for world info entry $id');
  }

  final sticky = _optionalInt(json, 'sticky') ?? 0;
  final cooldown = _optionalInt(json, 'cooldown') ?? 0;
  if (sticky < 0 || sticky > _maxWorldInfoTiming) {
    throw FormatException('Invalid sticky for world info entry $id');
  }
  if (cooldown < 0 || cooldown > _maxWorldInfoTiming) {
    throw FormatException('Invalid cooldown for world info entry $id');
  }

  if (match == WorldInfoMatchMode.regex) {
    _validateRegexKeys(keys, caseSensitive, id);
    _validateRegexKeys(secondaryKeys, caseSensitive, id);
  }

  WorldInfoUnlockCondition? unlock;
  final rawUnlock = json['unlock'];
  if (rawUnlock != null) {
    if (rawUnlock is! Map) {
      throw FormatException('Invalid unlock condition for world info entry $id');
    }
    final parsed = WorldInfoUnlockCondition.fromJson(
      rawUnlock.cast<String, dynamic>(),
      id,
    );
    if (parsed.hasConditions || parsed.hiddenUntilUnlocked) {
      unlock = parsed;
    }
  }

  return WorldInfoEntry(
    id: id,
    title: title,
    category: category,
    tags: tags,
    keys: keys,
    secondaryKeys: secondaryKeys,
    match: match,
    caseSensitive: caseSensitive,
    content: contentValue,
    priority: priority,
    enabled: enabledValue,
    position: positionValue,
    depth: depth,
    group: group,
    probability: probability,
    recursive: recursiveValue,
    sticky: sticky,
    cooldown: cooldown,
    unlock: unlock,
  );
}

WorldInfoCategory _categoryFromJson(Object? value) {
  switch (value ?? 'other') {
    case 'character':
      return WorldInfoCategory.character;
    case 'location':
      return WorldInfoCategory.location;
    case 'item':
      return WorldInfoCategory.item;
    case 'rule':
      return WorldInfoCategory.rule;
    case 'event':
      return WorldInfoCategory.event;
    case 'lore':
      return WorldInfoCategory.lore;
    case 'other':
      return WorldInfoCategory.other;
    default:
      throw FormatException('Unknown world info category: $value');
  }
}

WorldInfoMatchMode _matchFromJson(Object? value) {
  switch (value ?? 'substring') {
    case 'substring':
      return WorldInfoMatchMode.substring;
    case 'word':
      return WorldInfoMatchMode.word;
    case 'regex':
      return WorldInfoMatchMode.regex;
    default:
      throw FormatException('Unknown world info match mode: $value');
  }
}

List<String> _stringList(Object? value, String field, String entryId) {
  if (value == null) {
    return const [];
  }
  if (value is! List) {
    throw FormatException('Invalid $field for world info entry $entryId');
  }
  final result = <String>[];
  for (final item in value) {
    if (item is! String || item.isEmpty) {
      throw FormatException(
        'Invalid $field value for world info entry $entryId',
      );
    }
    result.add(item);
  }
  return result;
}

String? _optionalString(Map<String, dynamic> json, String key) {
  final value = json[key];
  if (value == null) {
    return null;
  }
  if (value is! String) {
    throw FormatException('Invalid $key in world info');
  }
  return value;
}

int? _optionalInt(Map<String, dynamic> json, String key) {
  final value = json[key];
  if (value == null) {
    return null;
  }
  if (value is! int) {
    throw FormatException('Invalid $key in world info');
  }
  return value;
}

void _validateRegexKeys(List<String> keys, bool caseSensitive, String entryId) {
  for (final key in keys) {
    if (key.runes.length > _maxWorldInfoRegexRunes) {
      throw FormatException('Regex is too long for world info entry $entryId');
    }
    try {
      RegExp(key, caseSensitive: caseSensitive);
    } on FormatException {
      throw FormatException('Invalid regex for world info entry $entryId');
    }
  }
}
