import 'package:flutter/cupertino.dart';

/// 设置页面导航跳转组件
///
/// 提供统一的导航样式，包括：
/// - 图标、标题、副标题
/// - 右侧箭头
/// - 点击跳转功能
class SettingsNavigationTile extends StatelessWidget {
  final String title;
  final String? subtitle;
  final IconData icon;
  final VoidCallback onTap;

  const SettingsNavigationTile({
    super.key,
    required this.title,
    this.subtitle,
    required this.icon,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final brightness = CupertinoTheme.of(context).brightness;

    return CupertinoListTile(
      leading: Icon(
        icon,
        color: CupertinoColors.systemBlue,
      ),
      title: Text(
        title,
        style: TextStyle(
          color: brightness == Brightness.dark
              ? CupertinoColors.label.darkColor
              : CupertinoColors.label.color,
        ),
      ),
      subtitle: subtitle != null
          ? Text(
              subtitle!,
              style: TextStyle(
                fontSize: 13,
                color: brightness == Brightness.dark
                    ? CupertinoColors.systemGrey.darkColor
                    : CupertinoColors.systemGrey,
              ),
            )
          : null,
      trailing: const Icon(CupertinoIcons.chevron_right),
      onTap: onTap,
    );
  }
}
