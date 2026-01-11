import 'package:flutter/cupertino.dart';

/// 设置页面开关组件
///
/// 提供统一的开关样式，包括：
/// - 标题和副标题
/// - CupertinoSwitch开关控件
/// - 自动布局
class SettingsSwitchTile extends StatelessWidget {
  final String title;
  final bool value;
  final String? subtitle;
  final ValueChanged<bool> onChanged;

  const SettingsSwitchTile({
    super.key,
    required this.title,
    required this.value,
    this.subtitle,
    required this.onChanged,
  });

  @override
  Widget build(BuildContext context) {
    final brightness = CupertinoTheme.of(context).brightness;

    return Container(
      padding: const EdgeInsets.all(16),
      child: Row(
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.w500,
                    color: brightness == Brightness.dark
                        ? CupertinoColors.label.darkColor
                        : CupertinoColors.label.color,
                  ),
                ),
                if (subtitle != null) ...[
                  const SizedBox(height: 4),
                  Text(
                    subtitle!,
                    style: TextStyle(
                      fontSize: 13,
                      color: brightness == Brightness.dark
                          ? CupertinoColors.systemGrey.darkColor
                          : CupertinoColors.systemGrey,
                    ),
                  ),
                ],
              ],
            ),
          ),
          const SizedBox(width: 16),
          CupertinoSwitch(
            value: value,
            onChanged: onChanged,
          ),
        ],
      ),
    );
  }
}
