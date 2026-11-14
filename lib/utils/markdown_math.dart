import 'package:flutter/widgets.dart';
import 'package:flutter_markdown_plus/flutter_markdown_plus.dart';
import 'package:flutter_math_fork/flutter_math.dart';
import 'package:markdown/markdown.dart' as md;

/// 预处理后的 Markdown 与公式表。
class MarkdownMathData {
  const MarkdownMathData({
    required this.markdown,
    required this.inlineMath,
    required this.blockMath,
  });

  final String markdown;
  final Map<int, String> inlineMath;
  final Map<int, String> blockMath;
}

/// 把 `$...$` / `$$...$$` 替换成占位符，代码围栏和行内代码里的内容不动。
MarkdownMathData prepareMarkdownMath(String markdown) {
  final inlineMath = <int, String>{};
  final blockMath = <int, String>{};
  final fenced = RegExp(
    r'(^```[\s\S]*?^```|^~~~[\s\S]*?^~~~)',
    multiLine: true,
  );
  final buffer = StringBuffer();
  var cursor = 0;

  for (final match in fenced.allMatches(markdown)) {
    buffer.write(
      _processNonCode(
        markdown.substring(cursor, match.start),
        inlineMath,
        blockMath,
      ),
    );
    buffer.write(match.group(0));
    cursor = match.end;
  }
  buffer.write(
    _processNonCode(markdown.substring(cursor), inlineMath, blockMath),
  );

  return MarkdownMathData(
    markdown: buffer.toString(),
    inlineMath: inlineMath,
    blockMath: blockMath,
  );
}

String _processNonCode(
  String text,
  Map<int, String> inlineMath,
  Map<int, String> blockMath,
) {
  // 行内代码按反引号拆分，只处理偶数段（代码段之外）。
  final parts = text.split('`');
  for (var i = 0; i < parts.length; i += 2) {
    parts[i] = _processMath(parts[i], inlineMath, blockMath);
  }
  return parts.join('`');
}

String _processMath(
  String text,
  Map<int, String> inlineMath,
  Map<int, String> blockMath,
) {
  var result = text.replaceAllMapped(
    RegExp(r'(?<!\\)\$\$([\s\S]+?)(?<!\\)\$\$'),
    (match) {
      final tex = match.group(1)!.trim();
      if (tex.isEmpty) return match.group(0)!;
      final index = blockMath.length;
      blockMath[index] = tex;
      return '\n\n@@LFMBLOCK$index@@\n\n';
    },
  );
  result = result.replaceAllMapped(
    RegExp(r'(?<!\\)\$(?!\$)([^\n$]+?)(?<!\\)\$(?!\$)'),
    (match) {
      final tex = match.group(1)!.trim();
      if (tex.isEmpty) return match.group(0)!;
      final index = inlineMath.length;
      inlineMath[index] = tex;
      return '@@LFMATH$index@@';
    },
  );
  return result;
}

List<md.InlineSyntax> mathInlineSyntaxes(MarkdownMathData data) {
  return [_MathInlineSyntax(data.inlineMath)];
}

List<md.BlockSyntax> mathBlockSyntaxes(MarkdownMathData data) {
  return [_MathBlockSyntax(data.blockMath)];
}

/// 供 MarkdownBody 使用的公式 builders。
Map<String, MarkdownElementBuilder> mathMarkdownBuilders() {
  return {
    'mathinline': _MathElementBuilder(block: false),
    'mathblock': _MathElementBuilder(block: true),
  };
}

/// 渲染带公式的 Markdown。
class MathMarkdownBody extends StatelessWidget {
  const MathMarkdownBody({
    super.key,
    required this.data,
    this.builders = const {},
    this.styleSheet,
    this.clearCodeBlockWrapper = true,
  });

  final String data;
  final Map<String, MarkdownElementBuilder> builders;
  final MarkdownStyleSheet? styleSheet;

  /// 是否清掉 MarkdownBody 给 `pre` 自动加的背景和内边距。
  ///
  /// 聊天消息由自定义 `CodeBlockBuilder` 渲染代码块，需要清掉；只读预览
  /// 直接使用样式表时则应保留，否则代码块会失去背景。
  final bool clearCodeBlockWrapper;

  @override
  Widget build(BuildContext context) {
    final math = prepareMarkdownMath(data);
    final baseStyleSheet = styleSheet ?? MarkdownStyleSheet();
    final effectiveStyleSheet = clearCodeBlockWrapper
        ? baseStyleSheet.copyWith(
            codeblockDecoration: const BoxDecoration(),
            codeblockPadding: EdgeInsets.zero,
          )
        : baseStyleSheet;
    return MarkdownBody(
      data: math.markdown,
      inlineSyntaxes: mathInlineSyntaxes(math),
      blockSyntaxes: mathBlockSyntaxes(math),
      builders: {...builders, ...mathMarkdownBuilders()},
      styleSheet: effectiveStyleSheet,
    );
  }
}

class _MathInlineSyntax extends md.InlineSyntax {
  _MathInlineSyntax(this.values)
    : super(r'@@LFMATH(\d+)@@', startCharacter: 0x40);

  final Map<int, String> values;

  @override
  bool onMatch(md.InlineParser parser, Match match) {
    final index = int.tryParse(match.group(1)!);
    final tex = values[index];
    if (tex == null) return false;
    parser.addNode(md.Element.text('mathinline', tex));
    return true;
  }
}

class _MathBlockSyntax extends md.BlockSyntax {
  _MathBlockSyntax(this.values);

  final Map<int, String> values;

  @override
  RegExp get pattern => RegExp(r'^@@LFMBLOCK(\d+)@@\s*$');

  @override
  md.Node? parse(md.BlockParser parser) {
    final match = pattern.firstMatch(parser.current.content);
    if (match == null) return null;
    final index = int.tryParse(match.group(1)!);
    final tex = values[index] ?? '';
    parser.advance();
    return md.Element.text('mathblock', tex);
  }
}

class _MathElementBuilder extends MarkdownElementBuilder {
  _MathElementBuilder({required this.block});

  final bool block;

  @override
  bool isBlockElement() => block;

  @override
  Widget? visitElementAfterWithContext(
    BuildContext context,
    dynamic element,
    TextStyle? preferredStyle,
    TextStyle? parentStyle,
  ) {
    final tex = (element.textContent as String).trim();
    if (tex.isEmpty) return null;

    final style = parentStyle ?? preferredStyle;
    final math = Math.tex(
      tex,
      mathStyle: block ? MathStyle.display : MathStyle.text,
      textStyle: style,
    );
    if (!block) return math;

    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8),
      child: SingleChildScrollView(
        scrollDirection: Axis.horizontal,
        child: math,
      ),
    );
  }
}
