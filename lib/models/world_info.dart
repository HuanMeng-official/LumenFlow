const int _maxWorldInfoEntries = 500;
const int _maxWorldInfoContentRunes = 4000;
const int _maxWorldInfoKeys = 20;
const int _maxWorldInfoRegexRunes = 200;

enum WorldInfoCategory { character, location, item, rule, event, lore, other }

enum WorldInfoMatchMode { substring, word, regex }

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
  });

  static const String format = 'lumenflow_world_info';
  static const int version = 1;

  final String name;
  final String description;
  final String background;
  final int scanDepth;
  final int budgetTokens;
  final List<WorldInfoEntry> entries;

  Map<String, dynamic> toJson() {
    return {
      '_format': format,
      '_version': version,
      'name': name,
      'description': description,
      'background': background,
      'scan_depth': scanDepth,
      'budget_tokens': budgetTokens,
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
    if (scanDepth < 0) {
      throw const FormatException('scan_depth must not be negative');
    }
    if (budgetTokens < 0) {
      throw const FormatException('budget_tokens must not be negative');
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
  final title = titleValue is String && titleValue.isNotEmpty
      ? titleValue
      : id;

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
  if (positionValue is! String) {
    throw FormatException('Invalid position for world info entry $id');
  }
  final depth = _optionalInt(json, 'depth') ?? 0;
  if (depth < 0) {
    throw FormatException('Invalid depth for world info entry $id');
  }

  if (match == WorldInfoMatchMode.regex) {
    _validateRegexKeys(keys, caseSensitive, id);
    _validateRegexKeys(secondaryKeys, caseSensitive, id);
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
      throw FormatException('Invalid $field value for world info entry $entryId');
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
