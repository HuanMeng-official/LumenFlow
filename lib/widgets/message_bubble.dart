import 'dart:io';
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:flutter_markdown_plus/flutter_markdown_plus.dart';
import 'package:flutter/services.dart';
import '../l10n/app_localizations.dart';
import '../models/message.dart';
import '../models/attachment.dart';
import '../models/user_profile.dart';
import '../screens/image_preview_screen.dart';
import 'avatar_widget.dart';

class MessageBubble extends StatefulWidget {
  final Message message;
  final UserProfile? userProfile; // 外部传入的用户信息，避免重复加载

  const MessageBubble({
    super.key,
    required this.message,
    this.userProfile,
  });

  @override
  State<MessageBubble> createState() => _MessageBubbleState();
}

/// 消息气泡状态，支持缓存机制
///
/// 使用 AutomaticKeepAliveClientMixin 确保滚动时 widget 不会被销毁
/// 避免重复渲染 Markdown 和重新加载用户头像
class _MessageBubbleState extends State<MessageBubble> with AutomaticKeepAliveClientMixin {
  bool _isReasoningExpanded = false;

  // 使用外部传入的用户配置，避免每个气泡重复加载
  UserProfile? get _userProfile => widget.userProfile;

  // 复制消息到剪贴板
  Future<void> _copyMessageToClipboard() async {
    final l10n = AppLocalizations.of(context)!;

    try {
      // 构建要复制的文本内容
      String textToCopy = widget.message.content;

      // 如果有思考链内容，也一并复制
      if (widget.message.reasoningContent != null &&
          widget.message.reasoningContent!.isNotEmpty) {
        textToCopy = '${widget.message.reasoningContent}\n\n$textToCopy';
      }

      // 复制到剪贴板
      await Clipboard.setData(ClipboardData(text: textToCopy));

      // 显示成功提示
      if (mounted) {
        _showCopySuccessToast(l10n.copySuccess);
      }
    } catch (error) {
      // 显示错误提示
      if (mounted) {
        _showCopyErrorToast(l10n.copyError(error.toString()));
      }
    }
  }

  // 显示复制成功提示
  void _showCopySuccessToast(String message) {
    final l10n = AppLocalizations.of(context)!;
    // 使用 Cupertino 风格的提示
    showCupertinoDialog(
      context: context,
      builder: (context) => CupertinoAlertDialog(
        title: Text(l10n.copySuccessTitle),
        content: Text(message),
        actions: [
          CupertinoDialogAction(
            child: Text(l10n.ok),
            onPressed: () {
              Navigator.of(context).pop();
            },
          ),
        ],
      ),
    );
  }

  // 显示复制错误提示
  void _showCopyErrorToast(String message) {
    final l10n = AppLocalizations.of(context)!;
    // 使用 Cupertino 风格的提示
    showCupertinoDialog(
      context: context,
      builder: (context) => CupertinoAlertDialog(
        title: Text(l10n.copyFailedTitle),
        content: Text(message),
        actions: [
          CupertinoDialogAction(
            child: Text(l10n.ok),
            onPressed: () {
              Navigator.of(context).pop();
            },
          ),
        ],
      ),
    );
  }

  @override
  bool get wantKeepAlive => true;

  Widget _buildAttachment(Attachment attachment, Brightness brightness) {
    final isImage = attachment.type == AttachmentType.image;
    final hasLocalFile = attachment.filePath != null && attachment.filePath!.isNotEmpty;

    return GestureDetector(
      onTap: () {
        if (isImage && hasLocalFile) {
          _showImagePreview(attachment.filePath!);
        }
      },
      child: Container(
        margin: const EdgeInsets.only(bottom: 8),
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          color: widget.message.isUser
              ? CupertinoColors.systemBlue.withValues(alpha: 0.2)
              : (brightness == Brightness.dark
                  ? CupertinoColors.systemGrey5.darkColor
                  : CupertinoColors.systemGrey5.color),
          borderRadius: BorderRadius.circular(12),
          border: Border.all(
            color: widget.message.isUser
                ? CupertinoColors.systemBlue.withValues(alpha: 0.3)
                : (brightness == Brightness.dark
                    ? CupertinoColors.systemGrey4.darkColor
                    : CupertinoColors.systemGrey4.color),
            width: 1,
          ),
        ),
        child: Row(
          children: [
            if (isImage && hasLocalFile)
              _buildImageThumbnail(attachment.filePath!, brightness)
            else
              Icon(
                _getAttachmentIcon(attachment.type),
                size: 20,
                color: widget.message.isUser
                    ? CupertinoColors.systemBlue
                    : (brightness == Brightness.dark
                        ? CupertinoColors.systemGrey.darkColor
                        : CupertinoColors.systemGrey.color),
              ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    attachment.fileName,
                    style: TextStyle(
                      fontSize: 14,
                      fontWeight: FontWeight.w500,
                      color: widget.message.isUser
                          ? CupertinoColors.white
                          : (brightness == Brightness.dark
                              ? CupertinoColors.label.darkColor
                              : CupertinoColors.label.color),
                    ),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                  if (attachment.fileSize != null)
                    Text(
                      _formatFileSize(attachment.fileSize!),
                      style: TextStyle(
                        fontSize: 12,
                        color: widget.message.isUser
                            ? CupertinoColors.systemGrey4
                            : (brightness == Brightness.dark
                                ? CupertinoColors.systemGrey.darkColor
                                : CupertinoColors.systemGrey.color),
                      ),
                    ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildImageThumbnail(String filePath, Brightness brightness) {
    return Container(
      width: 48,
      height: 48,
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(8),
        border: Border.all(
          color: widget.message.isUser
              ? CupertinoColors.systemBlue.withValues(alpha: 0.3)
              : (brightness == Brightness.dark
                  ? CupertinoColors.systemGrey4.darkColor
                  : CupertinoColors.systemGrey4.color),
          width: 1,
        ),
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(8),
        child: Image.file(
          File(filePath),
          fit: BoxFit.cover,
          cacheWidth: 96, // 2x for retina displays
          cacheHeight: 96,
          errorBuilder: (context, error, stackTrace) {
            return Container(
              alignment: Alignment.center,
              child: Icon(
                _getAttachmentIcon(AttachmentType.image),
                size: 20,
                color: widget.message.isUser
                    ? CupertinoColors.systemBlue
                    : (brightness == Brightness.dark
                        ? CupertinoColors.systemGrey.darkColor
                        : CupertinoColors.systemGrey.color),
              ),
            );
          },
        ),
      ),
    );
  }

  void _showImagePreview(String filePath) {
    Navigator.of(context).push(
      CupertinoPageRoute(
        builder: (context) => ImagePreviewScreen(imagePath: filePath),
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

  String _formatFileSize(int bytes) {
    if (bytes < 1024) {
      return '$bytes B';
    } else if (bytes < 1024 * 1024) {
      return '${(bytes / 1024).toStringAsFixed(1)} KB';
    } else {
      return '${(bytes / (1024 * 1024)).toStringAsFixed(1)} MB';
    }
  }

  @override
  Widget build(BuildContext context) {
    super.build(context); // 必须调用，支持 AutomaticKeepAliveClientMixin

    final l10n = AppLocalizations.of(context)!;
    final Brightness brightness = CupertinoTheme.of(context).brightness!;

    // 根据消息类型和主题确定选择颜色
    final selectionColor = widget.message.isUser
        ? CupertinoColors.white.withValues(alpha: 0.4)
        : (brightness == Brightness.dark
            ? CupertinoColors.systemBlue.darkColor.withValues(alpha: 0.4)
            : CupertinoColors.systemBlue.color.withValues(alpha: 0.4));

    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        mainAxisAlignment: widget.message.isUser
            ? MainAxisAlignment.end
            : MainAxisAlignment.start,
        crossAxisAlignment: CrossAxisAlignment.end,
        children: [
          if (!widget.message.isUser) ...[
            Container(
              width: 32,
              height: 32,
              decoration: BoxDecoration(
                color: widget.message.status == MessageStatus.error
                    ? CupertinoColors.systemRed
                    : CupertinoColors.systemBlue,
                borderRadius: BorderRadius.circular(16),
              ),
              child: Icon(
                widget.message.status == MessageStatus.error
                    ? CupertinoIcons.exclamationmark
                    : CupertinoIcons.sparkles,
                color: CupertinoColors.white,
                size: 16,
              ),
            ),
            const SizedBox(width: 8),
          ],
          Flexible(
            child: Theme(
              data: Theme.of(context).copyWith(
                textSelectionTheme: TextSelectionThemeData(
                  selectionColor: selectionColor,
                ),
              ),
              child: Container(
                constraints: BoxConstraints(
                  maxWidth: MediaQuery.of(context).size.width * 0.75,
                ),
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                decoration: BoxDecoration(
                  color: widget.message.isUser
                      ? CupertinoColors.systemBlue.withValues(alpha: 0.85)
                      : (widget.message.status == MessageStatus.error
                          ? CupertinoColors.systemRed.withValues(alpha: 0.1)
                          : (brightness == Brightness.dark
                              ? CupertinoColors.systemGrey6.darkColor
                              : CupertinoColors.systemGrey6.color)),
                  borderRadius: BorderRadius.circular(20),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                  if (!widget.message.isUser &&
                      widget.message.reasoningContent != null &&
                      widget.message.reasoningContent!.isNotEmpty)
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        GestureDetector(
                          onTap: () {
                            setState(() {
                              _isReasoningExpanded = !_isReasoningExpanded;
                            });
                          },
                          child: AnimatedContainer(
                            duration: const Duration(milliseconds: 200),
                            curve: Curves.easeInOut,
                            width: double.infinity,
                            padding: const EdgeInsets.symmetric(
                                horizontal: 12, vertical: 8),
                            decoration: BoxDecoration(
                              color: brightness == Brightness.dark
                                  ? CupertinoColors.systemBlue.darkColor
                                      .withAlpha(31)
                                  : CupertinoColors.systemBlue.color
                                      .withAlpha(20),
                              borderRadius: BorderRadius.circular(12),
                              boxShadow: _isReasoningExpanded
                                  ? [
                                      BoxShadow(
                                        color: brightness == Brightness.dark
                                            ? CupertinoColors.black
                                                .withAlpha(77)
                                            : CupertinoColors.systemGrey
                                                .withAlpha(51),
                                        blurRadius: 6,
                                        offset: const Offset(0, 1),
                                      ),
                                    ]
                                  : null,
                            ),
                            child: Row(
                              mainAxisAlignment: MainAxisAlignment.spaceBetween,
                              children: [
                                Row(
                                  children: [
                                    Container(
                                      width: 24,
                                      height: 24,
                                      decoration: BoxDecoration(
                                        color: brightness == Brightness.dark
                                            ? CupertinoColors
                                                .systemBlue.darkColor
                                                .withAlpha(51)
                                            : CupertinoColors.systemBlue.color
                                                .withAlpha(38),
                                        shape: BoxShape.circle,
                                      ),
                                      child: Icon(
                                        CupertinoIcons.lightbulb,
                                        size: 14,
                                        color: brightness == Brightness.dark
                                            ? CupertinoColors
                                                .systemBlue.darkColor
                                            : CupertinoColors.systemBlue.color,
                                      ),
                                    ),
                                    const SizedBox(width: 10),
                                    Column(
                                      crossAxisAlignment:
                                          CrossAxisAlignment.start,
                                      children: [
                                        Text(
                                          l10n.thinkChain,
                                          style: TextStyle(
                                            fontSize: 14,
                                            fontWeight: FontWeight.w600,
                                            color: brightness == Brightness.dark
                                                ? CupertinoColors
                                                    .label.darkColor
                                                : CupertinoColors.label.color,
                                          ),
                                        ),
                                        const SizedBox(height: 1),
                                        Text(
                                          l10n.expandChain,
                                          style: TextStyle(
                                            fontSize: 12,
                                            fontWeight: FontWeight.w400,
                                            color: brightness == Brightness.dark
                                                ? CupertinoColors
                                                    .systemGrey.darkColor
                                                : CupertinoColors
                                                    .systemGrey.color,
                                          ),
                                        ),
                                      ],
                                    ),
                                  ],
                                ),
                                Container(
                                  width: 24,
                                  height: 24,
                                  decoration: BoxDecoration(
                                    color: brightness == Brightness.dark
                                        ? CupertinoColors.systemBlue.darkColor
                                            .withAlpha(51)
                                        : CupertinoColors.systemBlue.color
                                            .withAlpha(38),
                                    shape: BoxShape.circle,
                                  ),
                                  child: Icon(
                                    _isReasoningExpanded
                                        ? CupertinoIcons.chevron_up
                                        : CupertinoIcons.chevron_down,
                                    size: 12,
                                    color: brightness == Brightness.dark
                                        ? CupertinoColors.systemBlue.darkColor
                                        : CupertinoColors.systemBlue.color,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ),
                        AnimatedCrossFade(
                          duration: const Duration(milliseconds: 200),
                          crossFadeState: _isReasoningExpanded
                              ? CrossFadeState.showSecond
                              : CrossFadeState.showFirst,
                          firstChild: const SizedBox.shrink(),
                          secondChild: Container(
                            width: double.infinity,
                            margin: const EdgeInsets.only(top: 8),
                            padding: const EdgeInsets.all(12),
                            decoration: BoxDecoration(
                              color: brightness == Brightness.dark
                                  ? CupertinoColors.systemGrey6.darkColor
                                  : CupertinoColors.white,
                              borderRadius: BorderRadius.circular(12),
                              boxShadow: [
                                BoxShadow(
                                  color: brightness == Brightness.dark
                                      ? CupertinoColors.black.withAlpha(51)
                                      : CupertinoColors.systemGrey
                                          .withAlpha(38),
                                  blurRadius: 8,
                                  offset: const Offset(0, 2),
                                ),
                              ],
                            ),
                            child: SelectableRegion(
                              selectionControls: cupertinoTextSelectionControls,
                              child: MarkdownBody(
                                data: widget.message.reasoningContent!,
                                styleSheet: MarkdownStyleSheet(
                                  p: TextStyle(
                                    fontSize: 13,
                                    height: 1.6,
                                    color: brightness == Brightness.dark
                                        ? CupertinoColors.systemGrey2.darkColor
                                        : CupertinoColors.systemGrey.color,
                                  ),
                                  code: TextStyle(
                                    fontSize: 12,
                                    fontFamily: 'SF Mono',
                                    color: brightness == Brightness.dark
                                        ? CupertinoColors.white
                                        : CupertinoColors.black,
                                    backgroundColor: brightness == Brightness.dark
                                        ? CupertinoColors.systemGrey.darkColor
                                        : CupertinoColors.systemGrey5.color,
                                  ),
                                  codeblockPadding: const EdgeInsets.all(8),
                                  codeblockDecoration: BoxDecoration(
                                    color: brightness == Brightness.dark
                                        ? CupertinoColors.systemGrey.darkColor
                                        : CupertinoColors.systemGrey5.color,
                                    borderRadius: BorderRadius.circular(6),
                                  ),
                                  blockquote: TextStyle(
                                    fontSize: 13,
                                    fontStyle: FontStyle.italic,
                                    color: brightness == Brightness.dark
                                        ? CupertinoColors.systemGrey2.darkColor
                                        : CupertinoColors.systemGrey.color,
                                  ),
                                  blockquoteDecoration: BoxDecoration(
                                    color: brightness == Brightness.dark
                                        ? CupertinoColors.systemGrey5.darkColor
                                            .withAlpha(128)
                                        : CupertinoColors.systemGrey6.color,
                                    borderRadius: BorderRadius.circular(4),
                                    border: Border(
                                      left: BorderSide(
                                        color: brightness == Brightness.dark
                                            ? CupertinoColors
                                                .systemBlue.darkColor
                                            : CupertinoColors.systemBlue.color,
                                        width: 3,
                                      ),
                                    ),
                                  ),
                                  blockquotePadding: const EdgeInsets.only(
                                      left: 12, top: 6, bottom: 6, right: 6),
                                ),
                              ),
                            ),
                          ),
                        ),
                        const SizedBox(height: 12),
                      ],
                    ),
                  SelectableRegion(
                    selectionControls: cupertinoTextSelectionControls,
                    child: MarkdownBody(
                      data: widget.message.content,
                      styleSheet: MarkdownStyleSheet(
                        p: TextStyle(
                          color: widget.message.isUser
                              ? CupertinoColors.white
                              : (widget.message.status == MessageStatus.error
                                  ? (brightness == Brightness.dark
                                      ? CupertinoColors.systemRed.darkColor
                                      : CupertinoColors.systemRed.color)
                                  : (brightness == Brightness.dark
                                      ? CupertinoColors.label.darkColor
                                      : CupertinoColors.label.color)),
                          fontSize: 16,
                          height: 1.5,
                        ),
                        code: TextStyle(
                          color: brightness == Brightness.dark
                              ? CupertinoColors.white
                              : CupertinoColors.black,
                          fontSize: 16,
                          fontFamily: 'Courier',
                          backgroundColor: brightness == Brightness.dark
                              ? CupertinoColors.systemGrey.darkColor
                              : CupertinoColors.systemGrey5.color,
                        ),
                        codeblockPadding: const EdgeInsets.all(12),
                        codeblockDecoration: BoxDecoration(
                          color: brightness == Brightness.dark
                              ? CupertinoColors.systemGrey.darkColor
                              : CupertinoColors.systemGrey5.color,
                          borderRadius: BorderRadius.circular(8),
                        ),
                        h1: TextStyle(
                          color: widget.message.isUser
                              ? CupertinoColors.white
                              : (widget.message.status == MessageStatus.error
                                  ? (brightness == Brightness.dark
                                      ? CupertinoColors.systemRed.darkColor
                                      : CupertinoColors.systemRed.color)
                                  : (brightness == Brightness.dark
                                      ? CupertinoColors.label.darkColor
                                      : CupertinoColors.label.color)),
                          fontSize: 24,
                          fontWeight: FontWeight.bold,
                          height: 1.5,
                        ),
                        h2: TextStyle(
                          color: widget.message.isUser
                              ? CupertinoColors.white
                              : (widget.message.status == MessageStatus.error
                                  ? (brightness == Brightness.dark
                                      ? CupertinoColors.systemRed.darkColor
                                      : CupertinoColors.systemRed.color)
                                  : (brightness == Brightness.dark
                                      ? CupertinoColors.label.darkColor
                                      : CupertinoColors.label.color)),
                          fontSize: 22,
                          fontWeight: FontWeight.bold,
                          height: 1.5,
                        ),
                        h3: TextStyle(
                          color: widget.message.isUser
                              ? CupertinoColors.white
                              : (widget.message.status == MessageStatus.error
                                  ? (brightness == Brightness.dark
                                      ? CupertinoColors.systemRed.darkColor
                                      : CupertinoColors.systemRed.color)
                                  : (brightness == Brightness.dark
                                      ? CupertinoColors.label.darkColor
                                      : CupertinoColors.label.color)),
                          fontSize: 20,
                          fontWeight: FontWeight.bold,
                          height: 1.5,
                        ),
                        h4: TextStyle(
                          color: widget.message.isUser
                              ? CupertinoColors.white
                              : (widget.message.status == MessageStatus.error
                                  ? (brightness == Brightness.dark
                                      ? CupertinoColors.systemRed.darkColor
                                      : CupertinoColors.systemRed.color)
                                  : (brightness == Brightness.dark
                                      ? CupertinoColors.label.darkColor
                                      : CupertinoColors.label.color)),
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                          height: 1.5,
                        ),
                        h5: TextStyle(
                          color: widget.message.isUser
                              ? CupertinoColors.white
                              : (widget.message.status == MessageStatus.error
                                  ? (brightness == Brightness.dark
                                      ? CupertinoColors.systemRed.darkColor
                                      : CupertinoColors.systemRed.color)
                                  : (brightness == Brightness.dark
                                      ? CupertinoColors.label.darkColor
                                      : CupertinoColors.label.color)),
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                          height: 1.5,
                        ),
                        h6: TextStyle(
                          color: widget.message.isUser
                              ? CupertinoColors.white
                              : (widget.message.status == MessageStatus.error
                                  ? (brightness == Brightness.dark
                                      ? CupertinoColors.systemRed.darkColor
                                      : CupertinoColors.systemRed.color)
                                  : (brightness == Brightness.dark
                                      ? CupertinoColors.label.darkColor
                                      : CupertinoColors.label.color)),
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                          height: 1.5,
                        ),
                        a: TextStyle(
                          color: widget.message.isUser
                              ? CupertinoColors.label
                              : CupertinoColors.systemBlue,
                          fontSize: 16,
                          decoration: TextDecoration.underline,
                          height: 1.5,
                        ),
                        blockquote: TextStyle(
                          color: widget.message.isUser
                              ? CupertinoColors.label
                              : (widget.message.status == MessageStatus.error
                                  ? CupertinoColors.systemRed
                                  : CupertinoColors.systemGrey),
                          fontSize: 16,
                          fontStyle: FontStyle.italic,
                          height: 1.5,
                        ),
                        blockquoteDecoration: BoxDecoration(
                          color: widget.message.isUser
                              ? (brightness == Brightness.dark
                                  ? CupertinoColors.systemGrey6.darkColor
                                  : CupertinoColors.systemGrey6.color)
                              : (brightness == Brightness.dark
                                  ? CupertinoColors.systemGrey5.darkColor
                                  : CupertinoColors.systemGrey5.color),
                          borderRadius: BorderRadius.circular(4),
                          border: Border(
                            left: BorderSide(
                              color: widget.message.isUser
                                  ? CupertinoColors.systemBlue
                                  : CupertinoColors.systemGrey,
                              width: 4,
                            ),
                          ),
                        ),
                        blockquotePadding: const EdgeInsets.only(
                            left: 16, top: 8, bottom: 8, right: 8),
                        listBullet: TextStyle(
                          color: widget.message.isUser
                              ? CupertinoColors.white
                              : (widget.message.status == MessageStatus.error
                                  ? (brightness == Brightness.dark
                                      ? CupertinoColors.systemRed.darkColor
                                      : CupertinoColors.systemRed.color)
                                  : (brightness == Brightness.dark
                                      ? CupertinoColors.label.darkColor
                                      : CupertinoColors.label.color)),
                          fontSize: 16,
                          height: 1.5,
                        ),
                      ),
                    ),
                  ),
                  if (widget.message.attachments.isNotEmpty) ...[
                    const SizedBox(height: 8),
                    ...widget.message.attachments.map((attachment) =>
                        _buildAttachment(attachment, brightness)),
                  ],
                  const SizedBox(height: 4),
                  Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Text(
                        DateFormat('HH:mm').format(widget.message.timestamp),
                        style: TextStyle(
                          color: widget.message.isUser
                              ? CupertinoColors.white.withValues(alpha: 0.7)
                              : (brightness == Brightness.dark
                                  ? CupertinoColors.systemGrey.darkColor
                                  : CupertinoColors.systemGrey.color),
                          fontSize: 12,
                        ),
                      ),
                      const SizedBox(width: 8),
                      // 复制按钮
                      GestureDetector(
                        onTap: _copyMessageToClipboard,
                        child: Container(
                          padding: const EdgeInsets.symmetric(
                              horizontal: 6, vertical: 2),
                          decoration: BoxDecoration(
                            color: widget.message.isUser
                                ? CupertinoColors.white.withValues(alpha: 0.25)
                                : (brightness == Brightness.dark
                                    ? CupertinoColors.systemGrey5.darkColor
                                    : CupertinoColors.systemGrey5.color),
                            borderRadius: BorderRadius.circular(8),
                            border: Border.all(
                              color: widget.message.isUser
                                  ? CupertinoColors.white.withValues(alpha: 0.4)
                                  : (brightness == Brightness.dark
                                      ? CupertinoColors.systemGrey4.darkColor
                                      : CupertinoColors.systemGrey4.color),
                              width: 0.5,
                            ),
                          ),
                          child: Row(
                            children: [
                              Icon(
                                CupertinoIcons.doc_on_clipboard,
                                size: 10,
                                color: widget.message.isUser
                                    ? CupertinoColors.white
                                    : (brightness == Brightness.dark
                                        ? CupertinoColors.systemGrey.darkColor
                                        : CupertinoColors.systemGrey.color),
                              ),
                              const SizedBox(width: 4),
                              Text(
                                l10n.copyMessage,
                                style: TextStyle(
                                  fontSize: 10,
                                  color: widget.message.isUser
                                      ? CupertinoColors.white
                                      : (brightness == Brightness.dark
                                          ? CupertinoColors.systemGrey.darkColor
                                          : CupertinoColors.systemGrey.color),
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                      if (widget.message.status == MessageStatus.sending) ...[
                        const SizedBox(width: 4),
                        const SizedBox(
                          width: 12,
                          height: 12,
                          child: CupertinoActivityIndicator(),
                        ),
                      ],
                      if (widget.message.status == MessageStatus.error) ...[
                        const SizedBox(width: 4),
                        const Icon(
                          CupertinoIcons.exclamationmark_circle_fill,
                          size: 12,
                          color: CupertinoColors.systemRed,
                        ),
                      ],
                    ],
                  ),
                ],
              ),
              ),
            ),
          ),
          if (widget.message.isUser) ...[
            const SizedBox(width: 8),
            _userProfile != null
                ? AvatarWidget(
                    userProfile: _userProfile!,
                    size: 32,
                  )
                : Container(
                    width: 32,
                    height: 32,
                    decoration: BoxDecoration(
                      color: CupertinoColors.systemGrey4,
                      borderRadius: BorderRadius.circular(16),
                    ),
                    child: const Icon(
                      CupertinoIcons.person_fill,
                      color: CupertinoColors.label,
                      size: 16,
                    ),
                  ),
          ],
        ],
      ),
    );
  }
}
