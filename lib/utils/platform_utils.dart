import 'dart:ui' show Size;

/// 大号平板/桌面宽屏使用两栏布局。
bool useWideLayout(Size size) =>
    size.width >= 800 && size.shortestSide >= 600;

/// 只有窗口足够宽时才使用两栏桌面布局。
///
/// 桌面窗口在刚创建或用户拖到很窄时也可能低于断点，此时退回单栏布局，
/// 避免固定宽度的侧边栏把聊天区挤到无法正常排版。
bool shouldUseDesktopHome({required Size size}) => useWideLayout(size);
