import 'package:flutter/cupertino.dart';

/// 设置页面滑块组件
///
/// 提供统一的滑块样式，包括：
/// - 标题和当前值显示
/// - 副标题说明
/// - 自定义范围和刻度
class SettingsSliderTile extends StatelessWidget {
  final String title;
  final double value;
  final String? subtitle;
  final double min;
  final double max;
  final int? divisions;
  final String valueSuffix;
  final int decimalPlaces;
  final bool showValueInRow;
  final ValueChanged<double> onChanged;

  const SettingsSliderTile({
    super.key,
    required this.title,
    required this.value,
    this.subtitle,
    required this.min,
    required this.max,
    this.divisions,
    this.valueSuffix = '',
    this.decimalPlaces = 1,
    this.showValueInRow = false,
    required this.onChanged,
  });

  @override
  Widget build(BuildContext context) {
    final brightness = CupertinoTheme.of(context).brightness;

    return Container(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          if (showValueInRow)
            Row(
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
                const SizedBox(width: 8),
                Text(
                  '(${value.toStringAsFixed(decimalPlaces)}$valueSuffix)',
                  style: TextStyle(
                    fontSize: 14,
                    color: brightness == Brightness.dark
                        ? CupertinoColors.systemGrey.darkColor
                        : CupertinoColors.systemGrey,
                  ),
                ),
              ],
            )
          else
            Text(
              '$title (${value.toStringAsFixed(decimalPlaces)}$valueSuffix)',
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
          const SizedBox(height: 12),
          CupertinoSlider(
            value: value,
            min: min,
            max: max,
            divisions: divisions,
            onChanged: onChanged,
          ),
        ],
      ),
    );
  }
}
