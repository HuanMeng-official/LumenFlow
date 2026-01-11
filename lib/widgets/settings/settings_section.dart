import 'package:flutter/cupertino.dart';

/// 设置分组容器组件
///
/// 提供统一的设置分组样式，包括：
/// - 灰色标题文字
/// - 圆角边框容器
/// - 自动添加分隔线
class SettingsSection extends StatelessWidget {
  final String title;
  final List<Widget> children;
  final EdgeInsetsGeometry? padding;
  final EdgeInsetsGeometry? margin;

  const SettingsSection({
    super.key,
    required this.title,
    required this.children,
    this.padding,
    this.margin,
  });

  @override
  Widget build(BuildContext context) {
    final brightness = CupertinoTheme.of(context).brightness;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.fromLTRB(16, 20, 16, 8),
          child: Text(
            title,
            style: TextStyle(
              fontSize: 13,
              color: brightness == Brightness.dark
                  ? CupertinoColors.systemGrey.darkColor
                  : CupertinoColors.systemGrey,
              fontWeight: FontWeight.w500,
            ),
          ),
        ),
        Container(
          margin: margin ?? const EdgeInsets.symmetric(horizontal: 16),
          decoration: BoxDecoration(
            color: brightness == Brightness.dark
                ? CupertinoColors.systemBackground.darkColor
                : CupertinoColors.systemBackground.color,
            borderRadius: BorderRadius.circular(12),
            border: Border.all(
              color: CupertinoColors.systemGrey4,
              width: 0.5,
            ),
          ),
          child: Column(
            children: _addDividers(children),
          ),
        ),
      ],
    );
  }

  List<Widget> _addDividers(List<Widget> children) {
    final List<Widget> dividedChildren = [];
    for (int i = 0; i < children.length; i++) {
      dividedChildren.add(children[i]);
      if (i < children.length - 1) {
        dividedChildren.add(
          Container(
            margin: const EdgeInsets.only(left: 16, right: 16),
            height: 0.5,
            color: CupertinoColors.systemGrey4,
          ),
        );
      }
    }
    return dividedChildren;
  }
}
