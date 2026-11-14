import 'package:cupertino_ui/cupertino_ui.dart';
import 'package:flutter_markdown_plus/flutter_markdown_plus.dart'
    show MarkdownStyleSheet;

import '../utils/app_theme.dart';
import '../utils/markdown_math.dart';

/// 只读、可选择的 Markdown 正文，统一角色卡与世界书内容的渲染样式。
class ReadOnlyMarkdown extends StatelessWidget {
  const ReadOnlyMarkdown({
    super.key,
    required this.data,
    this.fontSize = 14,
    this.lineHeight = 1.6,
  });

  final String data;
  final double fontSize;
  final double lineHeight;

  @override
  Widget build(BuildContext context) {
    final fallback = cjkFontFallbackForLocale(
      Localizations.maybeLocaleOf(context),
    );
    return SelectableRegion(
      selectionControls: cupertinoTextSelectionControls,
      child: MathMarkdownBody(
        data: data,
        styleSheet: _markdownStyle(context, fallback),
        clearCodeBlockWrapper: false,
      ),
    );
  }

  MarkdownStyleSheet _markdownStyle(
    BuildContext context,
    List<String> fallback,
  ) {
    final label = CupertinoColors.label.resolveFrom(context);
    final secondary = CupertinoColors.secondaryLabel.resolveFrom(context);
    final divider = CupertinoColors.separator.resolveFrom(context);
    final codeBackground = CupertinoColors.systemGrey5.resolveFrom(context);
    final base = TextStyle(
      fontSize: fontSize,
      height: lineHeight,
      color: label,
      fontFamilyFallback: fallback,
    );

    return MarkdownStyleSheet(
      p: base,
      a: base.copyWith(color: CupertinoColors.activeBlue.resolveFrom(context)),
      em: base.copyWith(fontStyle: FontStyle.italic),
      strong: base.copyWith(fontWeight: FontWeight.w600),
      del: base.copyWith(decoration: TextDecoration.lineThrough),
      h1: base.copyWith(fontSize: fontSize + 5, fontWeight: FontWeight.w600),
      h2: base.copyWith(fontSize: fontSize + 3, fontWeight: FontWeight.w600),
      h3: base.copyWith(fontSize: fontSize + 1, fontWeight: FontWeight.w600),
      h4: base.copyWith(fontWeight: FontWeight.w600),
      h5: base.copyWith(fontWeight: FontWeight.w600),
      h6: base.copyWith(fontWeight: FontWeight.w600),
      listBullet: base,
      listIndent: 18,
      blockquote: base.copyWith(color: secondary),
      blockquoteDecoration: BoxDecoration(
        border: Border(left: BorderSide(color: divider, width: 3)),
      ),
      blockquotePadding: const EdgeInsets.only(left: 12),
      code: TextStyle(
        fontFamily: 'Menlo',
        fontFamilyFallback: ['Courier', 'monospace', ...fallback],
        fontSize: fontSize - 1,
        color: label,
        backgroundColor: codeBackground,
      ),
      codeblockDecoration: BoxDecoration(
        color: codeBackground,
        borderRadius: BorderRadius.circular(8),
      ),
      codeblockPadding: const EdgeInsets.all(10),
      tableBorder: TableBorder.all(color: divider),
      tableHead: base.copyWith(fontWeight: FontWeight.w600),
      tableBody: base,
      tableCellsPadding: const EdgeInsets.symmetric(horizontal: 8, vertical: 6),
    );
  }
}
