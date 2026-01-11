import 'package:flutter/cupertino.dart';
import '../../l10n/app_localizations.dart';

/// 设置页面下拉选择组件
///
/// 提供统一的下拉选择样式，包括：
/// - 标题和副标题
/// - 动态选择列表
/// - 禁用状态支持
class SettingsDropdownTile extends StatelessWidget {
  final String title;
  final String value;
  final Map<String, String> options;
  final String? subtitle;
  final ValueChanged<String?>? onChanged;

  const SettingsDropdownTile({
    super.key,
    required this.title,
    required this.value,
    required this.options,
    this.subtitle,
    this.onChanged,
  });

  @override
  Widget build(BuildContext context) {
    final currentLabel = options[value] ?? value;
    final brightness = CupertinoTheme.of(context).brightness;
    final isEnabled = onChanged != null;

    return Container(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            title,
            style: const TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.w500,
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
          const SizedBox(height: 12),
          CupertinoButton(
            padding: EdgeInsets.zero,
            onPressed: onChanged != null
                ? () {
                    showCupertinoModalPopup<void>(
                      context: context,
                      builder: (BuildContext context) {
                        final popupBrightness =
                            CupertinoTheme.of(context).brightness;
                        return CupertinoActionSheet(
                          title: Text(title),
                          message: subtitle != null ? Text(subtitle!) : null,
                          actions: [
                            for (final entry in options.entries)
                              CupertinoActionSheetAction(
                                onPressed: () {
                                  Navigator.pop(context);
                                  if (onChanged != null) {
                                    onChanged!(entry.key);
                                  }
                                },
                                child: Text(
                                  entry.value,
                                  style: TextStyle(
                                    color: value == entry.key
                                        ? (popupBrightness == Brightness.dark
                                            ? CupertinoColors
                                                .activeBlue.darkColor
                                            : CupertinoColors.activeBlue.color)
                                        : (popupBrightness == Brightness.dark
                                            ? CupertinoColors.label.darkColor
                                            : CupertinoColors.label.color),
                                  ),
                                ),
                              ),
                          ],
                          cancelButton: CupertinoActionSheetAction(
                            onPressed: () {
                              Navigator.pop(context);
                            },
                            child: Text(
                              AppLocalizations.of(context)!.cancel,
                              style: TextStyle(
                                color: popupBrightness == Brightness.dark
                                    ? CupertinoColors.systemRed.darkColor
                                    : CupertinoColors.systemRed.color,
                              ),
                            ),
                          ),
                        );
                      },
                    );
                  }
                : null,
            child: Container(
              width: double.infinity,
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
              decoration: BoxDecoration(
                color: isEnabled
                    ? (CupertinoTheme.of(context).brightness == Brightness.dark
                        ? CupertinoColors.systemGrey6.darkColor
                        : CupertinoColors.systemGrey6.color)
                    : (CupertinoTheme.of(context).brightness == Brightness.dark
                        ? CupertinoColors.tertiarySystemFill.darkColor
                        : CupertinoColors.tertiarySystemFill.color),
                borderRadius: BorderRadius.circular(8),
              ),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    currentLabel,
                    style: TextStyle(
                      fontSize: 16,
                      color: isEnabled
                          ? (brightness == Brightness.dark
                              ? CupertinoColors.label.darkColor
                              : CupertinoColors.label.color)
                          : (brightness == Brightness.dark
                              ? CupertinoColors.tertiaryLabel.darkColor
                              : CupertinoColors.tertiaryLabel.color),
                    ),
                  ),
                  Icon(
                    CupertinoIcons.chevron_down,
                    size: 18,
                    color: isEnabled
                        ? (brightness == Brightness.dark
                            ? CupertinoColors.systemGrey.darkColor
                            : CupertinoColors.systemGrey)
                        : (brightness == Brightness.dark
                            ? CupertinoColors.tertiaryLabel.darkColor
                            : CupertinoColors.tertiaryLabel.color),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}
