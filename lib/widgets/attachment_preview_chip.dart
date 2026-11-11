import 'dart:io';

import 'package:cupertino_ui/cupertino_ui.dart';

import '../models/attachment.dart';

/// 输入框上方的待发送附件预览。
///
/// 所有颜色都按当前 Brightness 解析，避免暗色模式下出现浅色底 + 浅色文字。
class AttachmentPreviewChip extends StatelessWidget {
  const AttachmentPreviewChip({
    super.key,
    required this.attachment,
    required this.sizeLabel,
    required this.onRemove,
  });

  final Attachment attachment;
  final String sizeLabel;
  final VoidCallback onRemove;

  @override
  Widget build(BuildContext context) {
    final isDark = CupertinoTheme.of(context).brightness == Brightness.dark;
    final surface = isDark
        ? CupertinoColors.systemGrey6.darkColor
        : CupertinoColors.systemGrey6.color;
    final secondary = isDark
        ? CupertinoColors.systemGrey.darkColor
        : CupertinoColors.systemGrey.color;
    final border = isDark
        ? CupertinoColors.systemGrey4.darkColor
        : CupertinoColors.systemGrey4.color;
    final label = isDark
        ? CupertinoColors.label.darkColor
        : CupertinoColors.label.color;

    final isImage = attachment.type == AttachmentType.image;
    final hasLocalFile =
        attachment.filePath != null && attachment.filePath!.isNotEmpty;

    return Container(
      key: const ValueKey('attachment-preview-surface'),
      margin: const EdgeInsets.only(right: 8, bottom: 8),
      padding: const EdgeInsets.all(8),
      decoration: BoxDecoration(
        color: surface,
        borderRadius: BorderRadius.circular(12),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          if (isImage && hasLocalFile)
            _buildImageThumbnail(attachment.filePath!, border, secondary)
          else
            Icon(
              _getAttachmentIcon(attachment.type),
              size: 16,
              color: secondary,
            ),
          const SizedBox(width: 8),
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              SizedBox(
                width: MediaQuery.of(context).size.width * 0.15,
                child: Text(
                  attachment.fileName,
                  overflow: TextOverflow.ellipsis,
                  style: TextStyle(fontSize: 12, color: label),
                ),
              ),
              Text(sizeLabel, style: TextStyle(fontSize: 10, color: secondary)),
            ],
          ),
          const SizedBox(width: 8),
          CupertinoButton(
            padding: EdgeInsets.zero,
            onPressed: onRemove,
            child: Icon(CupertinoIcons.xmark, size: 14, color: secondary),
          ),
        ],
      ),
    );
  }

  Widget _buildImageThumbnail(
    String filePath,
    Color borderColor,
    Color fallbackColor,
  ) {
    return Container(
      width: 40,
      height: 40,
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(6),
        border: Border.all(color: borderColor, width: 1),
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(6),
        child: Image.file(
          File(filePath),
          fit: BoxFit.cover,
          cacheWidth: 80,
          cacheHeight: 80,
          errorBuilder: (context, error, stackTrace) {
            return Container(
              alignment: Alignment.center,
              child: Icon(
                _getAttachmentIcon(AttachmentType.image),
                size: 16,
                color: fallbackColor,
              ),
            );
          },
        ),
      ),
    );
  }

  IconData _getAttachmentIcon(AttachmentType type) {
    switch (type) {
      case AttachmentType.image:
        return CupertinoIcons.photo;
      case AttachmentType.document:
        return CupertinoIcons.doc;
      case AttachmentType.audio:
        return CupertinoIcons.music_note;
      case AttachmentType.video:
        return CupertinoIcons.videocam;
      case AttachmentType.other:
        return CupertinoIcons.paperclip;
    }
  }
}
