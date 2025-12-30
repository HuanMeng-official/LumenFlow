import 'dart:io';
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:file_picker/file_picker.dart';
import '../l10n/app_localizations.dart';
import '../services/file_service.dart';
import '../services/ai_service.dart';
import '../models/attachment.dart';
import '../models/prompt_preset.dart';

class ChatInput extends StatefulWidget {
  final Function(String, List<Attachment>) onSendMessage;
  final Function(List<Attachment>)? onAttachmentsSelected;
  final bool enabled;
  final bool thinkingMode;
  final Function(bool)? onThinkingModeChanged;
  final bool promptPresetEnabled;
  final Function(bool)? onPromptPresetEnabledChanged;
  final String currentPresetId;
  final Function(String)? onPresetSelected;
  final List<PromptPreset> presets;

  const ChatInput({
    super.key,
    required this.onSendMessage,
    this.onAttachmentsSelected,
    this.enabled = true,
    this.thinkingMode = false,
    this.onThinkingModeChanged,
    this.promptPresetEnabled = false,
    this.onPromptPresetEnabledChanged,
    this.currentPresetId = '',
    this.onPresetSelected,
    this.presets = const [],
  });

  @override
  State<ChatInput> createState() => _ChatInputState();
}

class _ChatInputState extends State<ChatInput> {
  final TextEditingController _controller = TextEditingController();
  final ScrollController _scrollController = ScrollController();
  final FileService _fileService = FileService();
  bool _canSend = false;
  List<Attachment> _attachments = [];

  @override
  void initState() {
    super.initState();
    _controller.addListener(_onTextChanged);
  }

  void _onTextChanged() {
    setState(() {
      _canSend = (_controller.text.trim().isNotEmpty || _attachments.isNotEmpty) && widget.enabled;
    });
  }

  void _updateAttachments(List<Attachment> newAttachments) {
    setState(() {
      _attachments = newAttachments;
    });
    _onTextChanged();
  }

  void _removeAttachment(Attachment attachment) {
    final newAttachments = List<Attachment>.from(_attachments);
    newAttachments.remove(attachment);
    _updateAttachments(newAttachments);
  }

  @override
  void didUpdateWidget(ChatInput oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.enabled != widget.enabled) {
      _onTextChanged();
    }
  }

  String _formatFileSize(int bytes) {
    if (bytes < 1024) {
      return '$bytes B';
    } else if (bytes < 1024 * 1024) {
      return '${(bytes / 1024).toStringAsFixed(1)} KB';
    } else if (bytes < 1024 * 1024 * 1024) {
      return '${(bytes / (1024 * 1024)).toStringAsFixed(1)} MB';
    } else {
      return '${(bytes / (1024 * 1024 * 1024)).toStringAsFixed(1)} GB';
    }
  }

  /// 显示预设提示词选择菜单
  void _showPresetMenu() {
    if (!widget.enabled || widget.presets.isEmpty) return;

    final l10n = AppLocalizations.of(context)!;
    showCupertinoModalPopup(
      context: context,
      builder: (context) => CupertinoActionSheet(
        title: Text(l10n.selectPresetRole),
        message: Text(l10n.selectPresetRoleMessage),
        actions: [
          for (final preset in widget.presets)
            CupertinoActionSheetAction(
              onPressed: () {
                Navigator.pop(context);
                if (widget.onPresetSelected != null) {
                  widget.onPresetSelected!(preset.id);
                }
                // 如果未启用预设模式，自动启用
                if (!widget.promptPresetEnabled &&
                    widget.onPromptPresetEnabledChanged != null) {
                  widget.onPromptPresetEnabledChanged!(true);
                }
              },
              child: Row(
                children: [
                  Icon(
                    _getIconForPreset(preset.icon),
                    size: 20,
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          preset.name,
                          style: const TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                        const SizedBox(height: 2),
                        Text(
                          preset.description,
                          style: TextStyle(
                            fontSize: 14,
                            color: CupertinoColors.systemGrey,
                          ),
                        ),
                      ],
                    ),
                  ),
                  if (widget.currentPresetId == preset.id)
                    const Icon(
                      CupertinoIcons.checkmark_alt,
                      color: CupertinoColors.systemBlue,
                    ),
                ],
              ),
            ),
          CupertinoActionSheetAction(
            isDestructiveAction: true,
            onPressed: () {
              Navigator.pop(context);
              if (widget.onPromptPresetEnabledChanged != null) {
                widget.onPromptPresetEnabledChanged!(false);
              }
            },
            child: Text(l10n.closePresetMode),
          ),
        ],
        cancelButton: CupertinoActionSheetAction(
          onPressed: () => Navigator.pop(context),
          child: Text(l10n.cancel),
        ),
      ),
    );
  }

  /// 根据图标名称获取IconData
  IconData _getIconForPreset(String iconName) {
    switch (iconName) {
      case 'globe':
        return CupertinoIcons.globe;
      case 'pencil':
        return CupertinoIcons.pencil;
      case 'doc.fill':
        return CupertinoIcons.doc_fill;
      case 'chevron.left.slash.chevron.right':
        return CupertinoIcons.chevron_left_slash_chevron_right;
      default:
        return CupertinoIcons.person_fill;
    }
  }

  /// 根据预设ID获取预设名称
  String _getPresetName(String presetId) {
    final l10n = AppLocalizations.of(context)!;
    final preset = widget.presets.firstWhere(
      (preset) => preset.id == presetId,
      orElse: () => PromptPreset(
        id: '',
        name: l10n.rolePlay,
        description: '',
        systemPrompt: '',
      ),
    );
    return preset.name;
  }

  void _showErrorDialog(String title, String message) {
    final l10n = AppLocalizations.of(context)!;
    showCupertinoDialog(
      context: context,
      builder: (context) => CupertinoAlertDialog(
        title: Text(title),
        content: Text(message),
        actions: [
          CupertinoDialogAction(
            child: Text(l10n.ok),
            onPressed: () => Navigator.pop(context),
          ),
        ],
      ),
    );
  }

  Future<bool> _showWarningDialog(String title, String message) async {
    final l10n = AppLocalizations.of(context)!;
    final result = await showCupertinoDialog<bool>(
      context: context,
      builder: (context) => CupertinoAlertDialog(
        title: Text(title),
        content: Text(message),
        actions: [
          CupertinoDialogAction(
            child: Text(l10n.cancel),
            onPressed: () => Navigator.pop(context, false),
          ),
          CupertinoDialogAction(
            child: Text(l10n.continueAction),
            onPressed: () => Navigator.pop(context, true),
          ),
        ],
      ),
    );
    return result ?? false;
  }

  Future<void> _pickFile() async {
    if (!widget.enabled) return;

    try {
      final FilePickerResult? result = await FilePicker.platform.pickFiles(
        allowMultiple: true,
        type: FileType.any,
      );

      if (result != null && result.files.isNotEmpty) {
        int totalSize = 0;
        final oversizedFiles = <String>[];

        for (final platformFile in result.files) {
          if (platformFile.path != null) {
            final file = File(platformFile.path!);
            if (await file.exists()) {
              final stat = await file.stat();
              totalSize += stat.size;

              if (stat.size > AIService.maxFileSizeForBase64) {
                oversizedFiles.add(
                    '${platformFile.name} (${_formatFileSize(stat.size)})');
              }
            }
          }
        }

        if (totalSize > AIService.maxTotalAttachmentsSize) {
          if (!mounted) return;
          final l10n = AppLocalizations.of(context);
          if (l10n != null) {
            _showErrorDialog(l10n.fileTooLarge,
                l10n.fileTooLargeMessage(_formatFileSize(totalSize), _formatFileSize(AIService.maxTotalAttachmentsSize)));
          }
          return;
        }

        if (oversizedFiles.isNotEmpty) {
          if (!mounted) return;
          final l10n = AppLocalizations.of(context);
          if (l10n != null) {
            final proceed = await _showWarningDialog(l10n.fileTooLargeWarning,
                l10n.fileTooLargeWarningMessage(_formatFileSize(AIService.maxFileSizeForBase64), oversizedFiles.join('\n')));
            if (!proceed) {
              return;
            }
          }
        }

        final attachments = <Attachment>[];

        for (final platformFile in result.files) {
          if (platformFile.path != null) {
            final file = File(platformFile.path!);
            try {
              final attachment =
                  await _fileService.saveFileAndCreateAttachment(file);
              if (attachment != null) {
                attachments.add(attachment);
              }
            } catch (e) {
              debugPrint('Error processing file ${platformFile.name}: $e');
            }
          }
        }

        if (attachments.isNotEmpty) {
          final newAttachments = List<Attachment>.from(_attachments)..addAll(attachments);
          _updateAttachments(newAttachments);

          if (widget.onAttachmentsSelected != null) {
            widget.onAttachmentsSelected!(attachments);
          }
        } else {
          if (!mounted) return;
          final l10n = AppLocalizations.of(context);
          if (l10n != null) {
            _showErrorDialog(l10n.noValidFiles, l10n.noValidFilesMessage);
          }
        }
      }
    } catch (e) {
      debugPrint('Error picking file: $e');
      if (!mounted) return;
      final l10n = AppLocalizations.of(context);
      if (l10n != null) {
        _showErrorDialog(
            l10n.selectFileFailed, l10n.selectFileFailedMessage(e.toString().replaceAll('Exception: ', '')));
      }
    }
  }

  void _sendMessage() {
    if (_canSend) {
      final attachmentsToSend = List<Attachment>.from(_attachments);
      widget.onSendMessage(_controller.text, attachmentsToSend);
      _controller.clear();
      _updateAttachments([]);
    }
  }

  Widget _buildAttachmentPreview(Attachment attachment) {
    final isImage = attachment.type == AttachmentType.image;
    final hasLocalFile = attachment.filePath != null && attachment.filePath!.isNotEmpty;

    return Container(
      margin: const EdgeInsets.only(right: 8, bottom: 8),
      padding: const EdgeInsets.all(8),
      decoration: BoxDecoration(
        color: CupertinoColors.systemGrey6,
        borderRadius: BorderRadius.circular(12),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          if (isImage && hasLocalFile)
            _buildImageThumbnail(attachment.filePath!)
          else
            Icon(
              _getAttachmentIcon(attachment.type),
              size: 16,
              color: CupertinoColors.systemGrey,
            ),
          const SizedBox(width: 8),
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              SizedBox(
                width: 120,
                child: Text(
                  attachment.fileName,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(fontSize: 12),
                ),
              ),
              Text(
                _formatFileSize(attachment.fileSize ?? 0),
                style: TextStyle(
                  fontSize: 10,
                  color: CupertinoColors.systemGrey,
                ),
              ),
            ],
          ),
          const SizedBox(width: 8),
          CupertinoButton(
            padding: EdgeInsets.zero,
            onPressed: () => _removeAttachment(attachment),
            child: const Icon(
              CupertinoIcons.xmark,
              size: 14,
              color: CupertinoColors.systemGrey,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildImageThumbnail(String filePath) {
    return Container(
      width: 40,
      height: 40,
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(6),
        border: Border.all(
          color: CupertinoColors.systemGrey4,
          width: 1,
        ),
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
                color: CupertinoColors.systemGrey,
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

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final brightness = CupertinoTheme.of(context).brightness;
    return Container(
      padding: const EdgeInsets.fromLTRB(16, 16, 16, 8),
      decoration: BoxDecoration(
        color: brightness == Brightness.dark
            ? CupertinoColors.systemBackground.darkColor
            : CupertinoColors.systemBackground.color,
        border: Border(
          top: BorderSide(
            color: CupertinoColors.systemGrey4,
            width: 0.5,
          ),
        ),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          // 附件预览区域
          if (_attachments.isNotEmpty)
            Container(
              padding: const EdgeInsets.only(bottom: 8),
              child: Wrap(
                children: _attachments.map(_buildAttachmentPreview).toList(),
              ),
            ),
          // 输入区域
          Row(
            children: [
              CupertinoButton(
                padding: EdgeInsets.zero,
                onPressed: widget.enabled ? _pickFile : null,
                child: Container(
                  width: 36,
                  height: 36,
                  decoration: BoxDecoration(
                    color: widget.enabled
                        ? (brightness == Brightness.dark
                            ? CupertinoColors.systemGrey6.darkColor
                            : CupertinoColors.systemGrey6.color)
                        : (brightness == Brightness.dark
                            ? CupertinoColors.systemGrey5.darkColor
                            : CupertinoColors.systemGrey5.color),
                    borderRadius: BorderRadius.circular(18),
                  ),
                  child: Icon(
                    CupertinoIcons.paperclip,
                    color: widget.enabled
                        ? (brightness == Brightness.dark
                            ? CupertinoColors.systemGrey.darkColor
                            : CupertinoColors.systemGrey)
                        : (brightness == Brightness.dark
                            ? CupertinoColors.systemGrey4.darkColor
                            : CupertinoColors.systemGrey4),
                    size: 20,
                  ),
                ),
              ),
              const SizedBox(width: 8),
              Expanded(
                child: Container(
                  padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 2),
                  decoration: BoxDecoration(
                    color: widget.enabled
                        ? (brightness == Brightness.dark
                            ? CupertinoColors.systemGrey6.darkColor
                            : CupertinoColors.systemGrey6.color)
                        : (brightness == Brightness.dark
                            ? CupertinoColors.systemGrey5.darkColor
                            : CupertinoColors.systemGrey5.color),
                    borderRadius: BorderRadius.circular(18),
                  ),
                  child: Material(
                    color: Colors.transparent,
                    child: TextField(
                      controller: _controller,
                      scrollController: _scrollController,
                      enabled: widget.enabled,
                      minLines: 1,
                      maxLines: 10,
                      keyboardType: TextInputType.multiline,
                      textInputAction: TextInputAction.newline,
                      scrollPhysics: const AlwaysScrollableScrollPhysics(),
                      decoration: InputDecoration(
                        border: InputBorder.none,
                        focusedBorder: InputBorder.none,
                        contentPadding: const EdgeInsets.symmetric(vertical: 8), 
                        isDense: true, 
                        hintStyle: TextStyle(
                          color: brightness == Brightness.dark
                              ? CupertinoColors.systemGrey.darkColor
                              : CupertinoColors.systemGrey,
                          fontSize: 17,
                          height: 1.2,
                        ),
                        hintText: widget.enabled ? l10n.messageInputPlaceholder : l10n.configureApiSettingsFirst,
                      ),
                      style: const TextStyle(
                        fontSize: 17,
                        color: CupertinoColors.label,
                        height: 1.5,
                        textBaseline: TextBaseline.alphabetic,
                      ),
                      cursorColor: CupertinoColors.activeBlue,
                      scrollPadding: const EdgeInsets.all(20),
                    ),
                  ),
                ),
              ),
              const SizedBox(width: 8),
              CupertinoButton(
                padding: EdgeInsets.zero,
                onPressed: _canSend ? _sendMessage : null,
                child: Container(
                  width: 36,
                  height: 36,
                  decoration: BoxDecoration(
                    color: _canSend
                        ? CupertinoColors.systemBlue
                        : (brightness == Brightness.dark
                            ? CupertinoColors.systemGrey5.darkColor
                            : CupertinoColors.systemGrey4),
                    borderRadius: BorderRadius.circular(18),
                  ),
                  child: Icon(
                    CupertinoIcons.arrow_up,
                    color: _canSend
                        ? CupertinoColors.white
                        : (brightness == Brightness.dark
                            ? CupertinoColors.systemGrey.darkColor
                            : CupertinoColors.systemGrey),
                    size: 20,
                  ),
                ),
              ),
            ],
          ),
          // 功能开关区域
          const SizedBox(height: 4),
          Row(
            mainAxisAlignment: MainAxisAlignment.start,
            children: [
              // 思考模式按钮
              if (widget.onThinkingModeChanged != null) ...[
                CupertinoButton(
                  padding: EdgeInsets.zero,
                  onPressed: widget.enabled
                      ? () => widget.onThinkingModeChanged!(!widget.thinkingMode)
                      : null,
                  child: Container(
                    height: 34,
                    padding: const EdgeInsets.symmetric(horizontal: 12),
                    alignment: Alignment.center,
                    decoration: BoxDecoration(
                      color: widget.enabled
                          ? (widget.thinkingMode
                              ? (brightness == Brightness.dark
                                  ? CupertinoColors.systemBlue.darkColor.withAlpha(51)
                                  : CupertinoColors.systemBlue.color.withAlpha(38))
                              : (brightness == Brightness.dark
                                  ? CupertinoColors.systemGrey6.darkColor
                                  : CupertinoColors.systemGrey6.color))
                          : (brightness == Brightness.dark
                              ? CupertinoColors.systemGrey5.darkColor
                              : CupertinoColors.systemGrey5.color),
                      borderRadius: BorderRadius.circular(20),
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(
                          CupertinoIcons.lightbulb,
                          size: 19,
                          color: widget.enabled
                              ? (widget.thinkingMode
                                  ? (brightness == Brightness.dark
                                      ? CupertinoColors.systemBlue.darkColor
                                      : CupertinoColors.systemBlue.color)
                                  : (brightness == Brightness.dark
                                      ? CupertinoColors.systemGrey.darkColor
                                      : CupertinoColors.systemGrey))
                              : (brightness == Brightness.dark
                                  ? CupertinoColors.systemGrey4.darkColor
                                  : CupertinoColors.systemGrey4),
                        ),
                        const SizedBox(width: 8),
                        Text(
                          l10n.deepThinking,
                          style: TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.w500,
                            color: widget.enabled
                                ? (widget.thinkingMode
                                    ? (brightness == Brightness.dark
                                        ? CupertinoColors.systemBlue.darkColor
                                        : CupertinoColors.systemBlue.color)
                                    : (brightness == Brightness.dark
                                        ? CupertinoColors.systemGrey.darkColor
                                        : CupertinoColors.systemGrey))
                                : (brightness == Brightness.dark
                                    ? CupertinoColors.systemGrey4.darkColor
                                    : CupertinoColors.systemGrey4),
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
                const SizedBox(width: 8),
              ],
              // 预设提示词按钮
              if (widget.onPromptPresetEnabledChanged != null) ...[
                CupertinoButton(
                  padding: EdgeInsets.zero,
                  onPressed: widget.enabled ? _showPresetMenu : null,
                  child: Container(
                    height: 34,
                    padding: const EdgeInsets.symmetric(horizontal: 12),
                    alignment: Alignment.center,
                    // 【修正】将 decoration 移到 child 之前，解决 lint 错误
                    decoration: BoxDecoration(
                      color: widget.enabled
                          ? (widget.promptPresetEnabled
                              ? (brightness == Brightness.dark
                                  ? CupertinoColors.systemBlue.darkColor.withAlpha(51)
                                  : CupertinoColors.systemBlue.color.withAlpha(38))
                              : (brightness == Brightness.dark
                                  ? CupertinoColors.systemGrey6.darkColor
                                  : CupertinoColors.systemGrey6.color))
                          : (brightness == Brightness.dark
                              ? CupertinoColors.systemGrey5.darkColor
                              : CupertinoColors.systemGrey5.color),
                      borderRadius: BorderRadius.circular(20),
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(
                          CupertinoIcons.person_fill,
                          size: 19,
                          color: widget.enabled
                              ? (widget.promptPresetEnabled
                                  ? (brightness == Brightness.dark
                                      ? CupertinoColors.systemBlue.darkColor
                                      : CupertinoColors.systemBlue.color)
                                  : (brightness == Brightness.dark
                                      ? CupertinoColors.systemGrey.darkColor
                                      : CupertinoColors.systemGrey))
                              : (brightness == Brightness.dark
                                  ? CupertinoColors.systemGrey4.darkColor
                                  : CupertinoColors.systemGrey4),
                        ),
                        const SizedBox(width: 8),
                        Text(
                          widget.promptPresetEnabled && widget.currentPresetId.isNotEmpty
                              ? _getPresetName(widget.currentPresetId)
                              : l10n.rolePlay,
                          style: TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.w500,
                            color: widget.enabled
                                ? (widget.promptPresetEnabled
                                    ? (brightness == Brightness.dark
                                        ? CupertinoColors.systemBlue.darkColor
                                        : CupertinoColors.systemBlue.color)
                                    : (brightness == Brightness.dark
                                        ? CupertinoColors.systemGrey.darkColor
                                        : CupertinoColors.systemGrey))
                                : (brightness == Brightness.dark
                                    ? CupertinoColors.systemGrey4.darkColor
                                    : CupertinoColors.systemGrey4),
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
                const SizedBox(width: 8),
              ],
              // 预留位置给未来其他功能
              // 可以在这里添加更多开关或按钮
            ],
          ),
        ],
      ),
    );
  }

  @override
  void dispose() {
    _controller.dispose();
    _scrollController.dispose();
    super.dispose();
  }
}
