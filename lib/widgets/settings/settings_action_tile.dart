import 'package:flutter/cupertino.dart';

/// 设置页面操作按钮组件
///
/// 提供统一的操作按钮样式，包括：
/// - 图标和标题
/// - 危险操作支持（红色样式）
/// - 点击回调
class SettingsActionTile extends StatelessWidget {
  final String title;
  final IconData icon;
  final VoidCallback onTap;
  final bool isDestructive;

  const SettingsActionTile({
    super.key,
    required this.title,
    required this.icon,
    required this.onTap,
    this.isDestructive = false,
  });

  @override
  Widget build(BuildContext context) {
    final brightness = CupertinoTheme.of(context).brightness;

    return CupertinoListTile(
      leading: Icon(
        icon,
        color: isDestructive
            ? CupertinoColors.systemRed
            : CupertinoColors.systemBlue,
      ),
      title: Text(
        title,
        style: TextStyle(
          color: isDestructive
              ? CupertinoColors.systemRed
              : (brightness == Brightness.dark
                  ? CupertinoColors.label.darkColor
                  : CupertinoColors.label.color),
        ),
      ),
      trailing: const Icon(CupertinoIcons.chevron_right),
      onTap: onTap,
    );
  }
}
