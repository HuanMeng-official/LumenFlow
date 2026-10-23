import 'dart:convert';
import 'dart:math' as math;

import '../contracts/ai_tool.dart';
import '../contracts/ai_tool_executor.dart';

/// Compares two texts and reports a line diff.
class BuiltInTextCompareTool implements AIToolExecutor {
  BuiltInTextCompareTool({this.enabled = true});

  static const String toolName = 'builtin__text_compare';
  static const int maxTextLength = 20000;
  static const int maxLevenshteinLength = 2000;
  static const int maxDiffCells = 250000;
  static const int maxDiffOutputLines = 400;

  static const AIToolDefinition definition = AIToolDefinition(
    name: toolName,
    description:
        'Compare two texts. Returns whether they are equal, the first '
        'differing character index, a line-by-line diff, and (for short '
        'texts) the Levenshtein distance and similarity. Use this to review '
        'edits or find differences.',
    inputSchema: {
      'type': 'object',
      'properties': {
        'a': {
          'type': 'string',
          'description': 'The original text.',
        },
        'b': {
          'type': 'string',
          'description': 'The text to compare against.',
        },
        'ignore_case': {
          'type': 'boolean',
          'description': 'Ignore letter case when comparing.',
        },
      },
      'required': ['a', 'b'],
    },
  );

  final bool enabled;

  @override
  List<AIToolDefinition> get tools {
    return enabled ? const [definition] : const [];
  }

  @override
  Future<AIToolResult> execute(AIToolCall call) async {
    if (!call.arguments.containsKey('a') ||
        !call.arguments.containsKey('b')) {
      return _error(call, 'a and b are required');
    }

    final a = call.arguments['a']?.toString() ?? '';
    final b = call.arguments['b']?.toString() ?? '';
    if (a.length > maxTextLength || b.length > maxTextLength) {
      return _error(
        call,
        'Each text must be at most $maxTextLength characters.',
      );
    }

    final ignoreCase = call.arguments['ignore_case'] == true;
    final normalizedA = ignoreCase ? a.toLowerCase() : a;
    final normalizedB = ignoreCase ? b.toLowerCase() : b;
    final firstDifference = _firstDifference(normalizedA, normalizedB);
    final equal = firstDifference == null;
    final maxLength = math.max(a.length, b.length);
    final distance = a.length <= maxLevenshteinLength &&
            b.length <= maxLevenshteinLength
        ? _levenshtein(normalizedA, normalizedB)
        : null;
    final similarity = distance == null
        ? null
        : maxLength == 0
            ? 1.0
            : (1 - distance / maxLength).clamp(0.0, 1.0);
    final diff = equal
        ? (lines: const <String>[], truncated: false)
        : _lineDiff(a, b, ignoreCase);
    final diffTruncated =
        diff.truncated || diff.lines.length > maxDiffOutputLines;
    final diffLines = diff.lines.length > maxDiffOutputLines
        ? [
            ...diff.lines.take(maxDiffOutputLines),
            '… (diff truncated)',
          ]
        : diff.lines;

    return AIToolResult(
      toolCallId: call.id,
      name: call.name,
      content: jsonEncode({
        'equal': equal,
        'first_difference_index': firstDifference,
        'length_a': a.length,
        'length_b': b.length,
        'levenshtein_distance': distance,
        'similarity': similarity == null ? null : _round(similarity),
        'line_diff': diffLines,
        'line_diff_truncated': diffTruncated,
      }),
    );
  }

  AIToolResult _error(AIToolCall call, String message) {
    return AIToolResult(
      toolCallId: call.id,
      name: call.name,
      content: jsonEncode({'error': message}),
      isError: true,
    );
  }

  int? _firstDifference(String a, String b) {
    final minLength = math.min(a.length, b.length);
    for (var index = 0; index < minLength; index++) {
      if (a.codeUnitAt(index) != b.codeUnitAt(index)) {
        return index;
      }
    }
    return a.length == b.length ? null : minLength;
  }

  int _levenshtein(String a, String b) {
    if (a.isEmpty) return b.length;
    if (b.isEmpty) return a.length;

    var previous = List<int>.generate(b.length + 1, (index) => index);
    var current = List<int>.filled(b.length + 1, 0);

    for (var i = 1; i <= a.length; i++) {
      current[0] = i;
      for (var j = 1; j <= b.length; j++) {
        final cost = a.codeUnitAt(i - 1) == b.codeUnitAt(j - 1) ? 0 : 1;
        final deletion = current[j - 1] + 1;
        final insertion = previous[j] + 1;
        final substitution = previous[j - 1] + cost;
        current[j] = math.min(math.min(deletion, insertion), substitution);
      }

      final swap = previous;
      previous = current;
      current = swap;
    }

    return previous[b.length];
  }

  ({List<String> lines, bool truncated}) _lineDiff(
    String a,
    String b,
    bool ignoreCase,
  ) {
    final aLines = a.replaceAll('\r\n', '\n').split('\n');
    final bLines = b.replaceAll('\r\n', '\n').split('\n');
    String normalize(String line) => ignoreCase ? line.toLowerCase() : line;

    if (aLines.length * bLines.length > maxDiffCells) {
      var prefix = 0;
      while (prefix < aLines.length &&
          prefix < bLines.length &&
          normalize(aLines[prefix]) == normalize(bLines[prefix])) {
        prefix++;
      }

      var suffix = 0;
      while (suffix < aLines.length - prefix &&
          suffix < bLines.length - prefix &&
          normalize(aLines[aLines.length - 1 - suffix]) ==
              normalize(bLines[bLines.length - 1 - suffix])) {
        suffix++;
      }

      return (
        lines: [
          for (var i = 0; i < prefix; i++) '  ${aLines[i]}',
          for (var i = prefix; i < aLines.length - suffix; i++)
            '- ${aLines[i]}',
          for (var i = prefix; i < bLines.length - suffix; i++)
            '+ ${bLines[i]}',
          for (var i = aLines.length - suffix; i < aLines.length; i++)
            '  ${aLines[i]}',
        ],
        truncated: true,
      );
    }

    final lengths = List.generate(
      aLines.length + 1,
      (_) => List<int>.filled(bLines.length + 1, 0),
    );

    for (var i = aLines.length - 1; i >= 0; i--) {
      for (var j = bLines.length - 1; j >= 0; j--) {
        if (normalize(aLines[i]) == normalize(bLines[j])) {
          lengths[i][j] = lengths[i + 1][j + 1] + 1;
        } else {
          lengths[i][j] = math.max(lengths[i + 1][j], lengths[i][j + 1]);
        }
      }
    }

    final lines = <String>[];
    var i = 0;
    var j = 0;
    while (i < aLines.length && j < bLines.length) {
      if (normalize(aLines[i]) == normalize(bLines[j])) {
        lines.add('  ${aLines[i]}');
        i++;
        j++;
      } else if (lengths[i + 1][j] >= lengths[i][j + 1]) {
        lines.add('- ${aLines[i]}');
        i++;
      } else {
        lines.add('+ ${bLines[j]}');
        j++;
      }
    }
    while (i < aLines.length) {
      lines.add('- ${aLines[i]}');
      i++;
    }
    while (j < bLines.length) {
      lines.add('+ ${bLines[j]}');
      j++;
    }

    return (lines: lines, truncated: false);
  }

  static double _round(double value) {
    return (value * 10000).round() / 10000;
  }
}

/// Counts characters, words, lines, paragraphs, and CJK characters.
class BuiltInTextStatsTool implements AIToolExecutor {
  BuiltInTextStatsTool({this.enabled = true});

  static const String toolName = 'builtin__text_stats';
  static const int maxTextLength = 100000;

  static const AIToolDefinition definition = AIToolDefinition(
    name: toolName,
    description:
        'Count Unicode characters, characters without whitespace, words, '
        'lines, paragraphs, and CJK characters in a text.',
    inputSchema: {
      'type': 'object',
      'properties': {
        'text': {
          'type': 'string',
          'description': 'The text to analyze.',
        },
      },
      'required': ['text'],
    },
  );

  final bool enabled;

  @override
  List<AIToolDefinition> get tools {
    return enabled ? const [definition] : const [];
  }

  @override
  Future<AIToolResult> execute(AIToolCall call) async {
    if (!call.arguments.containsKey('text')) {
      return _error(call, 'text is required');
    }

    final text = call.arguments['text']?.toString() ?? '';
    if (text.length > maxTextLength) {
      return _error(
        call,
        'text is longer than $maxTextLength characters',
      );
    }

    final trimmed = text.trim();
    final characters = text.runes.length;
    final charactersNoWhitespace =
        text.replaceAll(RegExp(r'\s+'), '').runes.length;
    final words = trimmed.isEmpty
        ? 0
        : trimmed.split(RegExp(r'\s+')).length;
    final lines = text.isEmpty
        ? 0
        : '\n'.allMatches(text).length + (text.endsWith('\n') ? 0 : 1);
    final paragraphs = trimmed.isEmpty
        ? 0
        : trimmed.split(RegExp(r'\n\s*\n')).length;
    final cjkCharacters = RegExp(
      r'[㐀-䶿一-鿿豈-﫿぀-ヿ가-힯]',
    ).allMatches(text).length;

    return AIToolResult(
      toolCallId: call.id,
      name: call.name,
      content: jsonEncode({
        'characters': characters,
        'utf16_units': text.length,
        'characters_no_whitespace': charactersNoWhitespace,
        'words': words,
        'lines': lines,
        'paragraphs': paragraphs,
        'cjk_characters': cjkCharacters,
      }),
    );
  }

  AIToolResult _error(AIToolCall call, String message) {
    return AIToolResult(
      toolCallId: call.id,
      name: call.name,
      content: jsonEncode({'error': message}),
      isError: true,
    );
  }
}
