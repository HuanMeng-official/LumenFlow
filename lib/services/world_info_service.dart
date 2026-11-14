import '../models/world_info.dart';
import '../utils/token_estimator.dart';

/// 任何非 ASCII 关键词都按子串处理；单词边界对 CJK 与非 BMP 字符不可靠。
final RegExp _cjkPattern = RegExp(r'[^\x00-\x7F]');

class ActivatedWorldInfoEntry {
  const ActivatedWorldInfoEntry({
    required this.entry,
    required this.matchedKey,
    required this.tokens,
  });

  final WorldInfoEntry entry;
  final String matchedKey;
  final int tokens;
}

class WorldInfoActivation {
  const WorldInfoActivation({
    required this.info,
    required this.matched,
    required this.skipped,
    required this.backgroundTokens,
    required this.entryTokens,
    required this.totalTokens,
  });

  final WorldInfo info;
  final List<ActivatedWorldInfoEntry> matched;
  final List<WorldInfoEntry> skipped;
  final int backgroundTokens;
  final int entryTokens;
  final int totalTokens;
}

class WorldInfoService {
  const WorldInfoService._();

  static WorldInfo parse(Map<String, dynamic> json) {
    return WorldInfo.fromJson(json);
  }

  static WorldInfoActivation activate(WorldInfo info, String scanText) {
    final skippedIds = <String>{};
    final candidates = <({WorldInfoEntry entry, String matchedKey})>[];

    for (final entry in info.entries) {
      if (!entry.enabled) {
        skippedIds.add(entry.id);
        continue;
      }

      final primaryKey = _findMatchedKey(entry, entry.keys, scanText);
      if (primaryKey == null) {
        skippedIds.add(entry.id);
        continue;
      }

      if (entry.secondaryKeys.isNotEmpty &&
          _findMatchedKey(entry, entry.secondaryKeys, scanText) == null) {
        skippedIds.add(entry.id);
        continue;
      }

      candidates.add((entry: entry, matchedKey: primaryKey));
    }

    candidates.sort((a, b) {
      final byPriority = b.entry.priority.compareTo(a.entry.priority);
      if (byPriority != 0) {
        return byPriority;
      }
      final byKeyLength =
          b.matchedKey.runes.length.compareTo(a.matchedKey.runes.length);
      if (byKeyLength != 0) {
        return byKeyLength;
      }
      return a.entry.id.compareTo(b.entry.id);
    });

    final matched = <ActivatedWorldInfoEntry>[];
    var entryTokens = 0;
    for (final candidate in candidates) {
      final tokens = TokenEstimator.estimate(candidate.entry.content);
      if (entryTokens + tokens > info.budgetTokens) {
        skippedIds.add(candidate.entry.id);
        continue;
      }
      entryTokens += tokens;
      matched.add(
        ActivatedWorldInfoEntry(
          entry: candidate.entry,
          matchedKey: candidate.matchedKey,
          tokens: tokens,
        ),
      );
    }

    final backgroundTokens = TokenEstimator.estimate(info.background);
    final skipped = info.entries
        .where((entry) => skippedIds.contains(entry.id))
        .toList(growable: false);

    return WorldInfoActivation(
      info: info,
      matched: matched,
      skipped: skipped,
      backgroundTokens: backgroundTokens,
      entryTokens: entryTokens,
      totalTokens: backgroundTokens + entryTokens,
    );
  }

  static String formatBlock(WorldInfoActivation activation) {
    final background = activation.info.background.trim();
    final entries = activation.matched
        .where((item) => item.entry.content.trim().isNotEmpty)
        .toList(growable: false);
    if (background.isEmpty && entries.isEmpty) {
      return '';
    }

    final name = activation.info.name.trim();
    final lines = <String>[name.isEmpty ? '[世界书]' : '[世界书 · $name]'];

    if (background.isNotEmpty) {
      lines
        ..add('[世界背景]')
        ..add(background);
    }

    for (final item in entries) {
      final entry = item.entry;
      final title = entry.title.trim().isEmpty ? entry.id : entry.title.trim();
      lines
        ..add('')
        ..add('[$title]')
        ..add(entry.content.trim());
    }

    return lines.join('\n');
  }

  static String? _findMatchedKey(
    WorldInfoEntry entry,
    List<String> keys,
    String scanText,
  ) {
    String? best;
    for (final key in keys) {
      if (!_matches(entry, key, scanText)) {
        continue;
      }
      if (best == null || key.runes.length > best.runes.length) {
        best = key;
      }
    }
    return best;
  }

  static bool _matches(WorldInfoEntry entry, String key, String scanText) {
    switch (entry.match) {
      case WorldInfoMatchMode.substring:
        return _contains(scanText, key, entry.caseSensitive);
      case WorldInfoMatchMode.word:
        if (_cjkPattern.hasMatch(key)) {
          return _contains(scanText, key, entry.caseSensitive);
        }
        final regex = RegExp(
          r'\b' + RegExp.escape(key) + r'\b',
          caseSensitive: entry.caseSensitive,
        );
        return regex.hasMatch(scanText);
      case WorldInfoMatchMode.regex:
        final regex = RegExp(key, caseSensitive: entry.caseSensitive);
        return regex.hasMatch(scanText);
    }
  }

  static bool _contains(String text, String key, bool caseSensitive) {
    if (caseSensitive) {
      return text.contains(key);
    }
    return text.toLowerCase().contains(key.toLowerCase());
  }
}
