import 'package:cupertino_ui/cupertino_ui.dart';

import '../../utils/app_theme.dart';

/// 桌面端就地弹出菜单项定义。
class DesktopPopoverItem {
  final String label;
  final IconData? icon;
  final bool selected;
  final bool isDestructive;
  final bool isDividerBefore;
  final VoidCallback onTap;

  const DesktopPopoverItem({
    required this.label,
    required this.onTap,
    this.icon,
    this.selected = false,
    this.isDestructive = false,
    this.isDividerBefore = false,
  });
}

/// 在触发组件下方就地展开的 macOS 风格 Popover 菜单，替代宽屏下突兀的底部 ActionSheet。
Future<void> showDesktopPopoverMenu({
  required BuildContext anchorContext,
  required List<DesktopPopoverItem> items,
  double width = 236,
  bool alignRight = false,
  bool preferAbove = false,
}) async {
  final renderBox = anchorContext.findRenderObject() as RenderBox?;
  final overlayBox =
      Overlay.of(anchorContext).context.findRenderObject() as RenderBox?;
  if (renderBox == null || overlayBox == null) return;

  final offset = renderBox.localToGlobal(Offset.zero, ancestor: overlayBox);
  final anchorSize = renderBox.size;
  final screenSize = overlayBox.size;

  final rawLeft = alignRight
      ? offset.dx + anchorSize.width - width
      : offset.dx;
  final left = rawLeft.clamp(
    12.0,
    (screenSize.width - width - 12.0).clamp(12.0, double.infinity),
  );
  final spaceBelow = screenSize.height - (offset.dy + anchorSize.height + 12);
  final openAbove = preferAbove || spaceBelow < 200 && offset.dy > spaceBelow;
  final top = (offset.dy + anchorSize.height + 6).clamp(
    12.0,
    (screenSize.height - 160.0).clamp(12.0, double.infinity),
  );
  final bottom = (screenSize.height - offset.dy + 6).clamp(
    12.0,
    (screenSize.height - 160.0).clamp(12.0, double.infinity),
  );
  final maxHeight = openAbove
      ? (offset.dy - 24).clamp(120.0, 380.0)
      : (screenSize.height - top - 24).clamp(120.0, 380.0);

  await showCupertinoDialog<void>(
    context: anchorContext,
    barrierDismissible: true,
    barrierColor: CupertinoColors.black.withValues(alpha: 0.01),
    builder: (dialogContext) {
      final isDark = AppTokens.isDark(dialogContext);
      return Stack(
        children: [
          Positioned.fill(
            child: GestureDetector(
              behavior: HitTestBehavior.translucent,
              onTap: () => Navigator.of(dialogContext).pop(),
            ),
          ),
          Positioned(
            left: left,
            top: openAbove ? null : top,
            bottom: openAbove ? bottom : null,
            width: width,
            child: ConstrainedBox(
              constraints: BoxConstraints(
                maxHeight: maxHeight,
              ),
              child: Container(
                padding: const EdgeInsets.all(6),
                decoration: BoxDecoration(
                  color: AppTokens.elevatedSurface(dialogContext),
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(
                    color: AppTokens.separator(dialogContext),
                    width: 0.5,
                  ),
                  boxShadow: [
                    BoxShadow(
                      color: CupertinoColors.black.withValues(
                        alpha: isDark ? 0.50 : 0.14,
                      ),
                      blurRadius: 28,
                      offset: const Offset(0, 10),
                    ),
                  ],
                ),
                child: SingleChildScrollView(
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      for (final item in items) ...[
                        if (item.isDividerBefore)
                          Container(
                            height: 0.5,
                            margin: const EdgeInsets.symmetric(
                              horizontal: 6,
                              vertical: 4,
                            ),
                            color: AppTokens.separator(dialogContext),
                          ),
                        _PopoverMenuRow(
                          item: item,
                          onSelect: () {
                            Navigator.of(dialogContext).pop();
                            item.onTap();
                          },
                        ),
                      ],
                    ],
                  ),
                ),
              ),
            ),
          ),
        ],
      );
    },
  );
}

class _PopoverMenuRow extends StatefulWidget {
  final DesktopPopoverItem item;
  final VoidCallback onSelect;

  const _PopoverMenuRow({required this.item, required this.onSelect});

  @override
  State<_PopoverMenuRow> createState() => _PopoverMenuRowState();
}

class _PopoverMenuRowState extends State<_PopoverMenuRow> {
  bool _hovered = false;

  @override
  Widget build(BuildContext context) {
    final textColor = widget.item.isDestructive
        ? AppTokens.red(context)
        : widget.item.selected
            ? AppTokens.accent(context)
            : AppTokens.label(context);

    return MouseRegion(
      onEnter: (_) => setState(() => _hovered = true),
      onExit: (_) => setState(() => _hovered = false),
      child: GestureDetector(
        onTap: widget.onSelect,
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
          decoration: BoxDecoration(
            color: _hovered
                ? AppTokens.fill(context)
                : widget.item.selected
                    ? AppTokens.accentSoft(context)
                    : CupertinoColors.transparent,
            borderRadius: BorderRadius.circular(8),
          ),
          child: Row(
            children: [
              if (widget.item.icon != null) ...[
                Icon(widget.item.icon, size: 16, color: textColor),
                const SizedBox(width: 8),
              ],
              Expanded(
                child: Text(
                  widget.item.label,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: TextStyle(
                    fontSize: 13.5,
                    fontWeight: widget.item.selected
                        ? FontWeight.w600
                        : FontWeight.w400,
                    color: textColor,
                  ),
                ),
              ),
              if (widget.item.selected)
                Icon(
                  CupertinoIcons.checkmark,
                  size: 14,
                  color: AppTokens.accent(context),
                ),
            ],
          ),
        ),
      ),
    );
  }
}
