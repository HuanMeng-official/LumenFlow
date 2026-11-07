import 'dart:io';
import 'dart:ui' show Size;

/// 桌面平台判定。
bool get isDesktopPlatform =>
    Platform.isWindows || Platform.isLinux || Platform.isMacOS;

/// 大号平板/桌面宽屏使用两栏布局。
bool useWideLayout(Size size) =>
    size.width >= 800 && size.shortestSide >= 600;

/// 桌面平台始终两栏；移动平台只有宽屏才两栏。
bool shouldUseDesktopHome({
  required bool desktopPlatform,
  required Size size,
}) =>
    desktopPlatform || useWideLayout(size);
