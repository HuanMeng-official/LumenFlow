import 'package:cupertino_ui/cupertino_ui.dart';

import '../../utils/app_theme.dart';

/// 设置页面导航跳转组件（支持 iOS 系统设置风格圆角彩色徽标）
class SettingsNavigationTile extends StatelessWidget {
  final String title;
  final String? subtitle;
  final IconData icon;
  final Color? badgeColor;
  final VoidCallback onTap;

  const SettingsNavigationTile({
    super.key,
    required this.title,
    this.subtitle,
    required this.icon,
    this.badgeColor,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final leading = badgeColor != null
        ? Container(
            width: 28,
            height: 28,
            decoration: BoxDecoration(
              color: badgeColor,
              borderRadius: BorderRadius.circular(7),
            ),
            child: Icon(
              icon,
              size: 16,
              color: CupertinoColors.white,
            ),
          )
        : Icon(
            icon,
            color: AppTokens.accent(context),
          );

    return CupertinoListTile(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
      leading: leading,
      title: Text(
        title,
        style: TextStyle(
          fontSize: 15.5,
          color: AppTokens.label(context),
        ),
      ),
      subtitle: subtitle != null
          ? Text(
              subtitle!,
              style: TextStyle(
                fontSize: 12.5,
                color: AppTokens.labelSecondary(context),
              ),
            )
          : null,
      trailing: Icon(
        CupertinoIcons.chevron_right,
        size: 16,
        color: AppTokens.labelTertiary(context),
      ),
      onTap: onTap,
    );
  }
}
