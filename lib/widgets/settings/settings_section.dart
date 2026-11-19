import 'package:cupertino_ui/cupertino_ui.dart';

import '../../utils/app_theme.dart';

/// 设置分组容器组件（原生 Apple 分组卡片风格：纯表面圆角容器 + 0.5px 内分割线）
class SettingsSection extends StatelessWidget {
  final String title;
  final List<Widget> children;
  final EdgeInsetsGeometry? padding;
  final EdgeInsetsGeometry? margin;
  final String? footer;

  const SettingsSection({
    super.key,
    required this.title,
    required this.children,
    this.padding,
    this.margin,
    this.footer,
  });

  @override
  Widget build(BuildContext context) {
    final fontFallback =
        cjkFontFallbackForLocale(Localizations.maybeLocaleOf(context));
    final horizontalMargin = margin ?? const EdgeInsets.symmetric(horizontal: 16);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        if (title.isNotEmpty)
          Padding(
            padding: const EdgeInsets.fromLTRB(28, 18, 20, 6),
            child: Text(
              title,
              style: TextStyle(
                fontSize: 12.5,
                fontFamilyFallback: fontFallback,
                color: AppTokens.labelSecondary(context),
                fontWeight: FontWeight.w500,
              ),
            ),
          )
        else
          const SizedBox(height: 16),
        Container(
          margin: horizontalMargin,
          clipBehavior: Clip.antiAlias,
          decoration: BoxDecoration(
            color: AppTokens.elevatedSurface(context),
            borderRadius: BorderRadius.circular(AppTokens.radiusMd),
          ),
          child: Column(
            children: _addDividers(context, children),
          ),
        ),
        if (footer != null && footer!.isNotEmpty)
          Padding(
            padding: const EdgeInsets.fromLTRB(28, 6, 20, 2),
            child: Text(
              footer!,
              style: TextStyle(
                fontSize: 12,
                height: 1.4,
                fontFamilyFallback: fontFallback,
                color: AppTokens.labelSecondary(context),
              ),
            ),
          ),
      ],
    );
  }

  List<Widget> _addDividers(BuildContext context, List<Widget> children) {
    final List<Widget> dividedChildren = [];
    for (int i = 0; i < children.length; i++) {
      dividedChildren.add(children[i]);
      if (i < children.length - 1) {
        dividedChildren.add(
          Container(
            margin: const EdgeInsets.only(left: 16),
            height: 0.5,
            color: AppTokens.separator(context),
          ),
        );
      }
    }
    return dividedChildren;
  }
}
