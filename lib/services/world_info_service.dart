import '../models/message.dart';
import '../models/world_info.dart';
import '../utils/token_estimator.dart';

/// 任何非 ASCII 关键词都按子串处理；单词边界对 CJK 与非 BMP 字符不可靠。
final RegExp _cjkPattern = RegExp(r'[^\x00-\x7F]');

enum WorldInfoSkipReason {
  disabled,
  noPrimaryKey,
  missingSecondaryKey,
  cooldown,
  probability,
  group,
  budget,
}

class WorldInfoSkipDetail {
  const WorldInfoSkipDetail({required this.entry, required this.reason});

  final WorldInfoEntry entry;
  final WorldInfoSkipReason reason;
}

class ActivatedWorldInfoEntry {
  const ActivatedWorldInfoEntry({
    required this.entry,
    required this.matchedKey,
    required this.tokens,
    this.viaRecursion = false,
    this.recursionLevel = 0,
  });

  final WorldInfoEntry entry;
  final String matchedKey;
  final int tokens;
  final bool viaRecursion;
  final int recursionLevel;
}

class WorldInfoDepthBlock {
  const WorldInfoDepthBlock({required this.depth, required this.text});

  final int depth;
  final String text;
}

class WorldInfoInjection {
  const WorldInfoInjection({
    this.systemBlock = '',
    this.beforePresetBlock = '',
    this.afterPresetBlock = '',
    this.atDepth = const [],
  });

  final String systemBlock;
  final String beforePresetBlock;
  final String afterPresetBlock;
  final List<WorldInfoDepthBlock> atDepth;

  bool get isEmpty =>
      systemBlock.isEmpty &&
      beforePresetBlock.isEmpty &&
      afterPresetBlock.isEmpty &&
      atDepth.isEmpty;
}

class WorldInfoActivation {
  const WorldInfoActivation({
    required this.info,
    required this.matched,
    required this.skipped,
    this.skipDetails = const [],
    required this.backgroundTokens,
    required this.entryTokens,
    required this.totalTokens,
  });

  final WorldInfo info;
  final List<ActivatedWorldInfoEntry> matched;
  final List<WorldInfoEntry> skipped;
  final List<WorldInfoSkipDetail> skipDetails;
  final int backgroundTokens;
  final int entryTokens;
  final int totalTokens;
}

/// 把 at_depth 世界书条目插入聊天历史。
///
/// 这些消息只存在于本次请求，不写入数据库。使用 user 角色是因为所有平台
/// 都支持 user/assistant 历史；正文用 [notice] 明确标注“不是用户发言”。
List<Message> injectWorldInfoAtDepth(
  List<Message> history,
  List<WorldInfoDepthBlock> blocks, {
  required String notice,
}) {
  if (blocks.isEmpty) return history;

  final grouped = <int, List<String>>{};
  for (final block in blocks) {
    grouped.putIfAbsent(block.depth, () => []).add(block.text);
  }
  final depths = grouped.keys.toList()..sort((a, b) => b.compareTo(a));
  final result = List<Message>.from(history);
  final stamp = DateTime.now().microsecondsSinceEpoch;
  var index = 0;
  for (final depth in depths) {
    final insertAt = (result.length - depth).clamp(0, result.length);
    result.insert(
      insertAt,
      Message(
        id: 'world_info_${stamp}_${index++}',
        content: '$notice\n\n${grouped[depth]!.join('\n\n')}',
        isUser: true,
        timestamp: DateTime.now(),
      ),
    );
  }
  return result;
}

class WorldInfoService {
  const WorldInfoService._();

  static WorldInfo parse(Map<String, dynamic> json) {
    return WorldInfo.fromJson(json);
  }

  /// 激活世界书。
  ///
  /// [scanText] 是常规扫描窗口（当前消息 + 最近 `scan_depth` 条）的合并文本，
  /// 决定直接命中。[scanMessages] 是用于 sticky/cooldown 的逐条窗口，通常
  /// 比 [scanText] 更长；不传时退化为 `[scanText]`。
  /// 按世界书的 `scan_depth` 扫描，并在命中数不足 `min_activations` 时
  /// 逐步扩大回看窗口。
  static WorldInfoActivation activateWithExpansion(
    WorldInfo info,
    List<String> historyTexts, {
    String currentContent = '',
    bool currentAlreadyInHistory = false,
  }) {
    List<String> partsForDepth(int depth) {
      final recent = historyTexts.length > depth
          ? historyTexts.sublist(historyTexts.length - depth)
          : historyTexts;
      final parts = List<String>.from(recent);
      if (currentContent.trim().isNotEmpty && !currentAlreadyInHistory) {
        parts.add(currentContent);
      }
      return parts;
    }

    var timingWindow = 0;
    for (final entry in info.entries) {
      if (entry.sticky > timingWindow) timingWindow = entry.sticky;
      if (entry.cooldown > timingWindow) timingWindow = entry.cooldown;
    }

    var depth = info.scanDepth;
    WorldInfoActivation activation;
    while (true) {
      final directParts = partsForDepth(depth);
      final timingDepth = depth > timingWindow ? depth : timingWindow;
      final timingParts = partsForDepth(timingDepth);
      activation = activate(
        info,
        directParts.join('\n'),
        scanMessages: timingParts,
      );
      if (activation.matched.length >= info.minActivations ||
          depth >= historyTexts.length) {
        break;
      }
      var nextDepth = depth == 0 ? 1 : depth * 2;
      if (nextDepth > historyTexts.length) nextDepth = historyTexts.length;
      if (nextDepth <= depth) break;
      depth = nextDepth;
    }
    return activation;
  }

  static WorldInfoActivation activate(
    WorldInfo info,
    String scanText, {
    List<String>? scanMessages,
  }) {
    final messages = scanMessages == null || scanMessages.isEmpty
        ? <String>[scanText]
        : scanMessages;
    final reasons = <String, WorldInfoSkipReason>{};
    final candidates = <_Candidate>[];
    final candidateIds = <String>{};

    for (final entry in info.entries) {
      if (!entry.enabled) {
        reasons[entry.id] = WorldInfoSkipReason.disabled;
        continue;
      }

      final directPrimary = _findMatchedKey(entry, entry.keys, scanText);
      final directSecondaryMissing =
          entry.secondaryKeys.isNotEmpty &&
          _findMatchedKey(entry, entry.secondaryKeys, scanText) == null;

      final timing = _scanEntryTiming(entry, messages);
      final stickyActive =
          timing.lastMatchIndex != null &&
          entry.sticky > 0 &&
          timing.distanceFromEnd <= entry.sticky;

      if (directPrimary == null && !stickyActive) {
        reasons[entry.id] = timing.hadPrimaryBeforeSecondary
            ? WorldInfoSkipReason.missingSecondaryKey
            : WorldInfoSkipReason.noPrimaryKey;
        continue;
      }
      if (directPrimary != null && directSecondaryMissing && !stickyActive) {
        reasons[entry.id] = WorldInfoSkipReason.missingSecondaryKey;
        continue;
      }

      if (!stickyActive && _isCoolingDown(entry, timing)) {
        reasons[entry.id] = WorldInfoSkipReason.cooldown;
        continue;
      }

      if (!_passesProbability(entry, scanText)) {
        reasons[entry.id] = WorldInfoSkipReason.probability;
        continue;
      }

      final matchedKey = directPrimary ?? timing.matchedKey ?? entry.keys.first;
      candidates.add(_Candidate(entry: entry, matchedKey: matchedKey));
      candidateIds.add(entry.id);
    }

    // 递归：只有 recursive 条目能用自己的正文继续触发其他条目。
    if (info.recursionDepth > 0 && candidates.isNotEmpty) {
      var frontier = candidates
          .where((candidate) => candidate.entry.recursive)
          .toList(growable: false);
      for (
        var level = 1;
        level <= info.recursionDepth && frontier.isNotEmpty;
        level++
      ) {
        final nextFrontier = <_Candidate>[];
        for (final parent in frontier) {
          for (final entry in info.entries) {
            if (!entry.enabled || candidateIds.contains(entry.id)) {
              continue;
            }
            final key = _findMatchedKey(
              entry,
              entry.keys,
              parent.entry.content,
            );
            if (key == null) {
              continue;
            }
            if (entry.secondaryKeys.isNotEmpty &&
                _findMatchedKey(
                      entry,
                      entry.secondaryKeys,
                      parent.entry.content,
                    ) ==
                    null) {
              continue;
            }
            // 递归激活同样受冷却约束，避免绕过直接命中阶段的冷却检查。
            if (_isCoolingDown(entry, _scanEntryTiming(entry, messages))) {
              reasons[entry.id] = WorldInfoSkipReason.cooldown;
              continue;
            }
            if (!_passesProbability(entry, scanText)) {
              reasons[entry.id] = WorldInfoSkipReason.probability;
              continue;
            }
            final candidate = _Candidate(
              entry: entry,
              matchedKey: key,
              viaRecursion: true,
              recursionLevel: level,
            );
            candidates.add(candidate);
            candidateIds.add(entry.id);
            reasons.remove(entry.id);
            if (entry.recursive) nextFrontier.add(candidate);
          }
        }
        frontier = nextFrontier;
      }
    }

    // 包含组：同一组只保留排序最靠前的一条。
    final groupCandidates = <String, List<_Candidate>>{};
    for (final candidate in candidates) {
      final group = candidate.entry.group.trim();
      if (group.isEmpty) continue;
      groupCandidates.putIfAbsent(group, () => []).add(candidate);
    }
    final groupLosers = <String>{};
    for (final group in groupCandidates.values) {
      group.sort(_compareCandidates);
      for (final loser in group.skip(1)) {
        groupLosers.add(loser.entry.id);
      }
    }
    if (groupLosers.isNotEmpty) {
      candidates.removeWhere(
        (candidate) => groupLosers.contains(candidate.entry.id),
      );
      for (final id in groupLosers) {
        reasons[id] = WorldInfoSkipReason.group;
      }
    }

    for (final entry in info.entries) {
      if (!candidateIds.contains(entry.id) && !reasons.containsKey(entry.id)) {
        reasons[entry.id] = WorldInfoSkipReason.noPrimaryKey;
      }
    }

    candidates.sort(_compareCandidates);

    final matched = <ActivatedWorldInfoEntry>[];
    var entryTokens = 0;
    for (final candidate in candidates) {
      final tokens = TokenEstimator.estimate(candidate.entry.content);
      if (entryTokens + tokens > info.budgetTokens) {
        reasons[candidate.entry.id] = WorldInfoSkipReason.budget;
        continue;
      }
      entryTokens += tokens;
      matched.add(
        ActivatedWorldInfoEntry(
          entry: candidate.entry,
          matchedKey: candidate.matchedKey,
          tokens: tokens,
          viaRecursion: candidate.viaRecursion,
          recursionLevel: candidate.recursionLevel,
        ),
      );
      reasons.remove(candidate.entry.id);
    }

    final skipDetails = <WorldInfoSkipDetail>[
      for (final entry in info.entries)
        if (reasons[entry.id] != null)
          WorldInfoSkipDetail(entry: entry, reason: reasons[entry.id]!),
    ];
    final backgroundTokens = TokenEstimator.estimate(info.background);

    return WorldInfoActivation(
      info: info,
      matched: matched,
      skipped: skipDetails
          .map((detail) => detail.entry)
          .toList(growable: false),
      skipDetails: skipDetails,
      backgroundTokens: backgroundTokens,
      entryTokens: entryTokens,
      totalTokens: backgroundTokens + entryTokens,
    );
  }

  static int _compareCandidates(_Candidate a, _Candidate b) {
    final byPriority = b.entry.priority.compareTo(a.entry.priority);
    if (byPriority != 0) return byPriority;
    final byKeyLength = b.matchedKey.runes.length.compareTo(
      a.matchedKey.runes.length,
    );
    if (byKeyLength != 0) return byKeyLength;
    return a.entry.id.compareTo(b.entry.id);
  }

  static _EntryTiming _scanEntryTiming(
    WorldInfoEntry entry,
    List<String> messages,
  ) {
    int? lastMatchIndex;
    int? previousMatchIndex;
    String? matchedKey;
    var hadPrimaryBeforeSecondary = false;

    for (var index = 0; index < messages.length; index++) {
      final primary = _findMatchedKey(entry, entry.keys, messages[index]);
      if (primary == null) continue;
      if (entry.secondaryKeys.isNotEmpty &&
          _findMatchedKey(entry, entry.secondaryKeys, messages[index]) ==
              null) {
        hadPrimaryBeforeSecondary = true;
        continue;
      }
      previousMatchIndex = lastMatchIndex;
      lastMatchIndex = index;
      matchedKey = primary;
    }

    return _EntryTiming(
      lastMatchIndex: lastMatchIndex,
      previousMatchIndex: previousMatchIndex,
      matchedKey: matchedKey,
      distanceFromEnd: lastMatchIndex == null
          ? 1 << 30
          : messages.length - 1 - lastMatchIndex,
      previousDistanceFromEnd: previousMatchIndex == null
          ? null
          : messages.length - 1 - previousMatchIndex,
      hadPrimaryBeforeSecondary: hadPrimaryBeforeSecondary,
    );
  }

  static bool _isCoolingDown(WorldInfoEntry entry, _EntryTiming timing) {
    if (entry.cooldown <= 0) return false;
    final previous = timing.previousDistanceFromEnd;
    if (previous == null) return false;
    return previous > 0 && previous <= entry.cooldown;
  }

  static bool _passesProbability(WorldInfoEntry entry, String seed) {
    if (entry.probability >= 100) return true;
    if (entry.probability <= 0) return false;
    return _stableRoll('${entry.id}\u0000$seed') % 100 < entry.probability;
  }

  static int _stableRoll(String value) {
    var hash = 0x811C9DC5;
    for (final codeUnit in value.codeUnits) {
      hash ^= codeUnit;
      hash = (hash * 0x01000193) & 0xFFFFFFFF;
    }
    return hash;
  }

  static String formatBlock(WorldInfoActivation activation) {
    return formatPositionBlock(
      activation,
      position: null,
      includeBackground: true,
    );
  }

  /// 按注入位置格式化条目。[position] 为 null 时输出所有条目。
  static String formatPositionBlock(
    WorldInfoActivation activation, {
    required String? position,
    bool includeBackground = false,
  }) {
    final background = includeBackground
        ? activation.info.background.trim()
        : '';
    final entries = activation.matched
        .where(
          (item) =>
              item.entry.content.trim().isNotEmpty &&
              (position == null || item.entry.position == position),
        )
        .toList(growable: false);
    if (background.isEmpty && entries.isEmpty) return '';

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

  static List<WorldInfoDepthBlock> formatAtDepthBlocks(
    WorldInfoActivation activation,
  ) {
    final grouped = <int, List<ActivatedWorldInfoEntry>>{};
    for (final item in activation.matched) {
      if (item.entry.position != 'at_depth' ||
          item.entry.content.trim().isEmpty) {
        continue;
      }
      grouped.putIfAbsent(item.entry.depth, () => []).add(item);
    }
    final depths = grouped.keys.toList()..sort((a, b) => b.compareTo(a));
    return [
      for (final depth in depths)
        WorldInfoDepthBlock(
          depth: depth,
          text: _formatEntriesOnly(activation, grouped[depth]!),
        ),
    ];
  }

  static String _formatEntriesOnly(
    WorldInfoActivation activation,
    List<ActivatedWorldInfoEntry> entries,
  ) {
    final name = activation.info.name.trim();
    final lines = <String>[name.isEmpty ? '[世界书]' : '[世界书 · $name]'];
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

  static WorldInfoInjection buildInjection(WorldInfoActivation activation) {
    return WorldInfoInjection(
      systemBlock: formatPositionBlock(
        activation,
        position: 'system',
        includeBackground: true,
      ),
      beforePresetBlock: formatPositionBlock(
        activation,
        position: 'before_preset',
      ),
      afterPresetBlock: formatPositionBlock(
        activation,
        position: 'after_preset',
      ),
      atDepth: formatAtDepthBlocks(activation),
    );
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
        try {
          final regex = RegExp(key, caseSensitive: entry.caseSensitive);
          return regex.hasMatch(scanText);
        } on FormatException {
          // 解析阶段已校验；这里兜底手动构造的 WorldInfoEntry。
          return false;
        }
    }
  }

  static bool _contains(String text, String key, bool caseSensitive) {
    if (caseSensitive) {
      return text.contains(key);
    }
    return text.toLowerCase().contains(key.toLowerCase());
  }
}

class _Candidate {
  const _Candidate({
    required this.entry,
    required this.matchedKey,
    this.viaRecursion = false,
    this.recursionLevel = 0,
  });

  final WorldInfoEntry entry;
  final String matchedKey;
  final bool viaRecursion;
  final int recursionLevel;
}

class _EntryTiming {
  const _EntryTiming({
    required this.lastMatchIndex,
    required this.previousMatchIndex,
    required this.matchedKey,
    required this.distanceFromEnd,
    required this.previousDistanceFromEnd,
    required this.hadPrimaryBeforeSecondary,
  });

  final int? lastMatchIndex;
  final int? previousMatchIndex;
  final String? matchedKey;
  final int distanceFromEnd;
  final int? previousDistanceFromEnd;
  final bool hadPrimaryBeforeSecondary;
}
