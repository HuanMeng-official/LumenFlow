import 'dart:io';
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:flutter_markdown/flutter_markdown.dart';
import '../l10n/app_localizations.dart';
import '../models/message.dart';
import '../models/attachment.dart';
import '../models/user_profile.dart';
import '../services/user_service.dart';
import '../screens/image_preview_screen.dart';
import 'avatar_widget.dart';

class MessageBubble extends StatefulWidget {
  final Message message;

  const MessageBubble({super.key, required this.message});

  @override
  State<MessageBubble> createState() => _MessageBubbleState();
}

class _MessageBubbleState extends State<MessageBubble> {
  final UserService _userService = UserService();
  UserProfile? _userProfile;
  bool _isReasoningExpanded = false;

  @override
  void initState() {
    super.initState();
    if (widget.message.isUser) {
      _loadUserProfile();
    }
  }

  Future<void> _loadUserProfile() async {
    final profile = await _userService.getUserProfile();
    if (mounted) {
      setState(() {
        _userProfile = profile;
      });
    }
  }

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
                              ? CupertinoColors.systemGrey4
                              : (brightness == Brightness.dark
                                  ? CupertinoColors.systemGrey.darkColor
                                  : CupertinoColors.systemGrey.color),
                          fontSize: 12,
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
