import 'package:flutter/cupertino.dart';

/// 设置页面输入框组件
///
/// 提供统一的输入框样式，包括：
/// - 标题和副标题
/// - 帮助按钮
/// - 密码可见性切换
/// - 自动输入类型支持
class SettingsInputTile extends StatelessWidget {
  final String title;
  final TextEditingController controller;
  final String placeholder;
  final String? subtitle;
  final bool obscureText;
  final bool showVisibilityToggle;
  final bool showHelpButton;
  final TextInputType? keyboardType;
  final VoidCallback? onVisibilityToggle;
  final VoidCallback? onHelpPressed;
  final int? maxLines;
  final ValueChanged<String>? onChanged;

  const SettingsInputTile({
    super.key,
    required this.title,
    required this.controller,
    required this.placeholder,
    this.subtitle,
    this.obscureText = false,
    this.showVisibilityToggle = false,
    this.showHelpButton = false,
    this.keyboardType,
    this.onVisibilityToggle,
    this.onHelpPressed,
    this.maxLines = 1,
    this.onChanged,
  });

  @override
  Widget build(BuildContext context) {
    final brightness = CupertinoTheme.of(context).brightness;

    return Container(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Expanded(
                child: Text(
                  title,
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.w500,
                    color: brightness == Brightness.dark
                        ? CupertinoColors.label.darkColor
                        : CupertinoColors.label.color,
                  ),
                ),
              ),
              if (showHelpButton)
                CupertinoButton(
                  padding: EdgeInsets.zero,
                  onPressed: onHelpPressed,
                  child: const Icon(
                    CupertinoIcons.question_circle,
                    size: 20,
                    color: CupertinoColors.systemBlue,
                  ),
                ),
            ],
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
          const SizedBox(height: 12),
          CupertinoTextField(
            controller: controller,
            placeholder: placeholder,
            obscureText: obscureText,
            keyboardType: keyboardType,
            maxLines: obscureText ? 1 : maxLines,
            onChanged: onChanged,
            suffix: showVisibilityToggle
                ? CupertinoButton(
                    padding: EdgeInsets.zero,
                    onPressed: onVisibilityToggle,
                    child: Icon(
                      obscureText
                          ? CupertinoIcons.eye
                          : CupertinoIcons.eye_slash,
                      size: 20,
                      color: brightness == Brightness.dark
                          ? CupertinoColors.systemGrey.darkColor
                          : CupertinoColors.systemGrey,
                    ),
                  )
                : null,
            decoration: BoxDecoration(
              color: brightness == Brightness.dark
                  ? CupertinoColors.systemGrey6.darkColor
                  : CupertinoColors.systemGrey6.color,
              borderRadius: BorderRadius.circular(8),
            ),
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
          ),
        ],
      ),
    );
  }
}
