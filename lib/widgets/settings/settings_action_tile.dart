import 'package:flutter/cupertino.dart';

/// 设置页面操作按钮组件
///
/// 提供统一的操作按钮样式，包括：
/// - 图标和标题
/// - 副标题和尾部控件
/// - 危险操作支持（红色样式）
/// - 点击回调
class SettingsActionTile extends StatelessWidget {
  final String title;
  final IconData icon;
  final VoidCallback? onTap;
  final bool isDestructive;
  final String? subtitle;
  final Widget? trailing;

  const SettingsActionTile({
    super.key,
    required this.title,
    required this.icon,
    required this.onTap,
    this.isDestructive = false,
    this.subtitle,
    this.trailing,
  });

  @override
  Widget build(BuildContext context) {
    final brightness = CupertinoTheme.of(context).brightness;
    final isEnabled = onTap != null;

    return CupertinoListTile(
      leading: Icon(
        icon,
        color: isDestructive
            ? CupertinoColors.systemRed
            : (isEnabled
                ? CupertinoColors.systemBlue
                : CupertinoColors.systemGrey),
      ),
      title: Text(
        title,
        style: TextStyle(
          color: isDestructive
              ? CupertinoColors.systemRed
              : (isEnabled
                  ? (brightness == Brightness.dark
                      ? CupertinoColors.label.darkColor
                      : CupertinoColors.label.color)
                  : CupertinoColors.systemGrey),
        ),
      ),
      subtitle: subtitle != null
          ? Text(
              subtitle!,
              style: TextStyle(
                color: isEnabled
                    ? CupertinoColors.systemGrey
                    : CupertinoColors.systemGrey3,
              ),
            )
          : null,
      trailing: trailing ?? const Icon(CupertinoIcons.chevron_right),
      onTap: onTap,
    );
  }
}
