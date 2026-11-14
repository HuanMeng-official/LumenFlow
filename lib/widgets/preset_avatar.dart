import 'dart:io';

import 'package:cupertino_ui/cupertino_ui.dart';

import '../models/prompt_preset.dart';
import '../utils/preset_icons.dart';

/// 预设头像：有可读的 avatar.png 时显示图片，否则回退到预设图标。
class PresetAvatar extends StatelessWidget {
  const PresetAvatar({
    super.key,
    required this.preset,
    this.size = 32,
    this.iconColor,
    this.backgroundColor,
    this.showBorder = false,
  });

  final PromptPreset preset;
  final double size;
  final Color? iconColor;
  final Color? backgroundColor;
  final bool showBorder;

  @override
  Widget build(BuildContext context) {
    final avatarPath = preset.avatarPath;
    final hasUserAvatar =
        avatarPath != null &&
        avatarPath.isNotEmpty &&
        File(avatarPath).existsSync();
    final assetPath = !preset.isUserPreset && preset.hasAvatarFile
        ? 'assets/prompt/${preset.avatarFile}'
        : null;
    final hasImage = hasUserAvatar || assetPath != null;
    final cacheSize = (size * 3).round();

    Widget avatar;
    if (hasUserAvatar) {
      avatar = Image.file(
        File(avatarPath),
        width: size,
        height: size,
        fit: BoxFit.cover,
        cacheWidth: cacheSize,
        cacheHeight: cacheSize,
        errorBuilder: (context, error, stackTrace) =>
            _fallbackIcon(withBackground: true),
      );
    } else if (assetPath != null) {
      avatar = Image.asset(
        assetPath,
        width: size,
        height: size,
        fit: BoxFit.cover,
        cacheWidth: cacheSize,
        cacheHeight: cacheSize,
        errorBuilder: (context, error, stackTrace) =>
            _fallbackIcon(withBackground: true),
      );
    } else {
      avatar = _fallbackIcon();
    }

    return Container(
      width: size,
      height: size,
      clipBehavior: Clip.antiAlias,
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        // Keep transparent PNGs transparent; the color is only a fallback.
        color: hasImage ? null : backgroundColor,
        border: showBorder
            ? Border.all(
                color: CupertinoColors.systemGrey.withAlpha(3),
                width: 1,
              )
            : null,
      ),
      child: avatar,
    );
  }

  Widget _fallbackIcon({bool withBackground = false}) {
    final icon = Icon(
      presetIconForName(preset.icon),
      size: size * 0.56,
      color: iconColor ?? CupertinoColors.activeBlue,
    );
    if (withBackground && backgroundColor != null) {
      return Container(
        width: size,
        height: size,
        color: backgroundColor,
        alignment: Alignment.center,
        child: icon,
      );
    }
    return Center(child: icon);
  }
}
