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
    this.showBorder = false,
  });

  final PromptPreset preset;
  final double size;
  final Color? iconColor;
  final bool showBorder;

  @override
  Widget build(BuildContext context) {
    final avatarPath = preset.avatarPath;
    final hasAvatar =
        avatarPath != null &&
        avatarPath.isNotEmpty &&
        File(avatarPath).existsSync();

    return Container(
      width: size,
      height: size,
      clipBehavior: Clip.antiAlias,
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        border: showBorder
            ? Border.all(
                color: CupertinoColors.systemGrey.withAlpha(3),
                width: 1,
              )
            : null,
      ),
      child: hasAvatar
          ? Image.file(
              File(avatarPath),
              width: size,
              height: size,
              fit: BoxFit.cover,
              errorBuilder: (context, error, stackTrace) => _fallbackIcon(),
            )
          : _fallbackIcon(),
    );
  }

  Widget _fallbackIcon() {
    return Center(
      child: Icon(
        presetIconForName(preset.icon),
        size: size * 0.56,
        color: iconColor ?? CupertinoColors.activeBlue,
      ),
    );
  }
}
