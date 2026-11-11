import 'dart:io';

import 'package:cupertino_ui/cupertino_ui.dart';
import 'package:material_ui/material_ui.dart';
import 'package:file_picker/file_picker.dart';

import '../l10n/app_localizations.dart';
import '../services/file_service.dart';
import '../services/ai_service.dart';
import '../models/attachment.dart';
import '../models/prompt_preset.dart';
import '../utils/app_theme.dart';
import '../utils/preset_icons.dart';
import 'attachment_preview_chip.dart';
import 'preset_unavailable_dialog.dart';

class ChatInput extends StatefulWidget {
  final Function(String, List<Attachment>) onSendMessage;
  final Function()? onStopGenerating;
  final Function(List<Attachment>)? onAttachmentsSelected;
  final bool enabled;
  final bool thinkingMode;
  final Function(bool)? onThinkingModeChanged;
  final bool promptPresetEnabled;
  final Function(bool)? onPromptPresetEnabledChanged;
  final String currentPresetId;
  final Function(String)? onPresetSelected;
  final List<PromptPreset> presets;
  final bool currentPresetUnavailable;
  final Function()? onShowModelSelector;
  final String currentModelName;
  final bool isGenerating;

  const ChatInput({
    super.key,
    required this.onSendMessage,
    this.onStopGenerating,
    this.onAttachmentsSelected,
    this.enabled = true,
    this.thinkingMode = false,
    this.onThinkingModeChanged,
    this.promptPresetEnabled = false,
    this.onPromptPresetEnabledChanged,
    this.currentPresetId = '',
    this.onPresetSelected,
    this.presets = const [],
    this.currentPresetUnavailable = false,
    this.onShowModelSelector,
    this.currentModelName = '',
    this.isGenerating = false,
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
      // 如果正在生成，按钮应该始终可点击（用于停止）
      if (widget.isGenerating) {
        _canSend = true;
      } else {
        _canSend =
            (_controller.text.trim().isNotEmpty || _attachments.isNotEmpty) &&
            widget.enabled;
      }
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
    if (oldWidget.enabled != widget.enabled ||
        oldWidget.isGenerating != widget.isGenerating) {
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
      builder: (context) {
        final primaryColor = CupertinoTheme.of(context).primaryColor;
        return CupertinoActionSheet(
          title: Text(l10n.selectPresetRole),
          message: Text(l10n.selectPresetRoleMessage),
          actions: [
            for (final preset in widget.presets)
              CupertinoActionSheetAction(
                onPressed: () {
                  if (preset.isBroken) {
                    Navigator.pop(context);
                    showCupertinoDialog<void>(
                      context: this.context,
                      builder: (dialogContext) => CupertinoAlertDialog(
                        title: Text(preset.name),
                        content: Text(
                          l10n.presetBrokenReason(
                            preset.brokenReason ?? l10n.presetBrokenLabel,
                          ),
                        ),
                        actions: [
                          CupertinoDialogAction(
                            child: Text(l10n.ok),
                            onPressed: () => Navigator.pop(dialogContext),
                          ),
                        ],
                      ),
                    );
                    return;
                  }
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
                      presetIconForName(preset.icon),
                      size: 20,
                      color: preset.isBroken
                          ? CupertinoColors.systemGrey2
                          : primaryColor,
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            children: [
                              Flexible(
                                child: Text(
                                  preset.name,
                                  style: TextStyle(
                                    fontSize: 16,
                                    fontWeight: FontWeight.w500,
                                    color: preset.isBroken
                                        ? CupertinoColors.systemGrey2
                                        : null,
                                  ),
                                  overflow: TextOverflow.ellipsis,
                                ),
                              ),
                              const SizedBox(width: 4),
                              Flexible(
                                child: Text(
                                  preset.author.isNotEmpty ? preset.author : '',
                                  style: TextStyle(
                                    fontSize: 14,
                                    color: CupertinoColors.systemGrey,
                                  ),
                                  overflow: TextOverflow.ellipsis,
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 2),
                          Text(
                            preset.description,
                            style: TextStyle(
                              fontSize: 14,
                              color: preset.isBroken
                                  ? CupertinoColors.systemGrey2
                                  : CupertinoColors.systemGrey,
                            ),
                          ),
                          if (preset.isBroken) ...[
                            const SizedBox(height: 2),
                            Text(
                              l10n.presetBrokenLabel,
                              style: const TextStyle(
                                fontSize: 12,
                                color: CupertinoColors.systemRed,
                              ),
                            ),
                          ],
                        ],
                      ),
                    ),
                    const SizedBox(width: 8),
                    Text(
                      preset.version.isNotEmpty ? preset.version : 'v1.0',
                      style: TextStyle(
                        fontSize: 12,
                        color: CupertinoColors.systemGrey2,
                      ),
                      overflow: TextOverflow.ellipsis,
                    ),
                    if (widget.currentPresetId == preset.id)
                      const SizedBox(width: 8),
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
        );
      },
    );
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
        author: '',
        version: '',
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
      final files = await FilePicker.pickFiles(type: FileType.any);

      if (files.isNotEmpty) {
        int totalSize = 0;
        final oversizedFiles = <String>[];

        for (final platformFile in files) {
          if (platformFile.path != null) {
            final file = File(platformFile.path!);
            if (await file.exists()) {
              final stat = await file.stat();
              totalSize += stat.size;

              if (stat.size > AIService.maxFileSizeForBase64) {
                oversizedFiles.add(
                  '${platformFile.name} (${_formatFileSize(stat.size)})',
                );
              }
            }
          }
        }

        if (totalSize > AIService.maxTotalAttachmentsSize) {
          if (!mounted) return;
          final l10n = AppLocalizations.of(context);
          if (l10n != null) {
            _showErrorDialog(
              l10n.fileTooLarge,
              l10n.fileTooLargeMessage(
                _formatFileSize(totalSize),
                _formatFileSize(AIService.maxTotalAttachmentsSize),
              ),
            );
          }
          return;
        }

        if (oversizedFiles.isNotEmpty) {
          if (!mounted) return;
          final l10n = AppLocalizations.of(context);
          if (l10n != null) {
            final proceed = await _showWarningDialog(
              l10n.fileTooLargeWarning,
              l10n.fileTooLargeWarningMessage(
                _formatFileSize(AIService.maxFileSizeForBase64),
                oversizedFiles.join('\n'),
              ),
            );
            if (!proceed) {
              return;
            }
          }
        }

        final attachments = <Attachment>[];

        for (final platformFile in files) {
          if (platformFile.path != null) {
            final file = File(platformFile.path!);
            try {
              final attachment = await _fileService.saveFileAndCreateAttachment(
                file,
              );
              if (attachment != null) {
                attachments.add(attachment);
              }
            } catch (_) {
              // Skip files that cannot be saved.
            }
          }
        }

        if (attachments.isNotEmpty) {
          final newAttachments = List<Attachment>.from(_attachments)
            ..addAll(attachments);
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
      if (!mounted) return;
      final l10n = AppLocalizations.of(context);
      if (l10n != null) {
        _showErrorDialog(
          l10n.selectFileFailed,
          l10n.selectFileFailedMessage(
            e.toString().replaceAll('Exception: ', ''),
          ),
        );
      }
    }
  }

  Future<void> _sendMessage() async {
    if (!_canSend) return;

    if (widget.isGenerating) {
      // 正在生成时，点击按钮停止生成
      if (widget.onStopGenerating != null) {
        widget.onStopGenerating!();
      }
      return;
    }

    // 发送前校验角色预设；不可用时中止并保留输入框草稿。
    if (widget.promptPresetEnabled &&
        widget.currentPresetId.isNotEmpty &&
        widget.currentPresetUnavailable) {
      final l10n = AppLocalizations.of(context)!;
      final disableAndSend = await showPresetUnavailableDialog(context, l10n);
      if (!disableAndSend) return;
      widget.onPromptPresetEnabledChanged?.call(false);
    }

    // 正常发送消息
    final attachmentsToSend = List<Attachment>.from(_attachments);
    widget.onSendMessage(_controller.text, attachmentsToSend);
    _controller.clear();
    _updateAttachments([]);
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
          top: BorderSide(color: CupertinoColors.systemGrey4, width: 0.5),
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
                children: _attachments
                    .map(
                      (attachment) => AttachmentPreviewChip(
                        attachment: attachment,
                        sizeLabel: _formatFileSize(attachment.fileSize ?? 0),
                        onRemove: () => _removeAttachment(attachment),
                      ),
                    )
                    .toList(),
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
                  padding: const EdgeInsets.symmetric(
                    horizontal: 12,
                    vertical: 2,
                  ),
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
                        hintText: widget.enabled
                            ? l10n.messageInputPlaceholder
                            : l10n.configureApiSettingsFirst,
                      ),
                      style: TextStyle(
                        fontSize: 17,
                        color: brightness == Brightness.dark
                            ? CupertinoColors.white
                            : CupertinoColors.black,
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
                        ? (widget.isGenerating
                              ? CupertinoColors
                                    .systemRed // 生成中显示红色
                              : CupertinoColors.systemBlue) // 正常发送显示蓝色
                        : (brightness == Brightness.dark
                              ? CupertinoColors.systemGrey5.darkColor
                              : CupertinoColors.systemGrey4),
                    borderRadius: BorderRadius.circular(18),
                  ),
                  child: Icon(
                    widget.isGenerating
                        ? CupertinoIcons
                              .stop // 生成中显示停止图标
                        : CupertinoIcons.arrow_up, // 正常发送显示向上箭头
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
              // 显示已开启的工具按钮（可以多个同时显示）
              if (widget.thinkingMode) ...[
                _buildThinkingModeButton(),
                const SizedBox(width: 8),
              ],
              if (widget.promptPresetEnabled &&
                  widget.currentPresetId.isNotEmpty) ...[
                _buildPresetModeButton(),
                const SizedBox(width: 8),
              ],
              // 工具菜单按钮（始终显示）
              CupertinoButton(
                padding: EdgeInsets.zero,
                onPressed: widget.enabled ? _showToolMenu : null,
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
                    CupertinoIcons.add,
                    size: 20,
                    color: widget.enabled
                        ? (brightness == Brightness.dark
                              ? CupertinoColors.systemGrey.darkColor
                              : CupertinoColors.systemGrey)
                        : (brightness == Brightness.dark
                              ? CupertinoColors.systemGrey4.darkColor
                              : CupertinoColors.systemGrey4),
                  ),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  /// 构建思考模式按钮
  Widget _buildThinkingModeButton() {
    final l10n = AppLocalizations.of(context)!;
    final brightness = CupertinoTheme.of(context).brightness;

    return CupertinoButton(
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
    );
  }

  /// 构建角色扮演按钮
  Widget _buildPresetModeButton() {
    final l10n = AppLocalizations.of(context)!;
    final brightness = CupertinoTheme.of(context).brightness;

    return CupertinoButton(
      padding: EdgeInsets.zero,
      onPressed: widget.enabled ? _showPresetMenu : null,
      child: Container(
        height: 34,
        padding: const EdgeInsets.symmetric(horizontal: 12),
        alignment: Alignment.center,
        decoration: BoxDecoration(
          color: widget.enabled
              ? (widget.currentPresetUnavailable
                    ? CupertinoColors.systemRed
                          .resolveFrom(context)
                          .withAlpha(38)
                    : widget.promptPresetEnabled
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
              color: !widget.enabled
                  ? (brightness == Brightness.dark
                        ? CupertinoColors.systemGrey4.darkColor
                        : CupertinoColors.systemGrey4)
                  : widget.currentPresetUnavailable
                  ? CupertinoColors.systemRed.resolveFrom(context)
                  : (widget.promptPresetEnabled
                        ? (brightness == Brightness.dark
                              ? CupertinoColors.systemBlue.darkColor
                              : CupertinoColors.systemBlue.color)
                        : (brightness == Brightness.dark
                              ? CupertinoColors.systemGrey.darkColor
                              : CupertinoColors.systemGrey)),
            ),
            const SizedBox(width: 8),
            Text(
              widget.promptPresetEnabled && widget.currentPresetId.isNotEmpty
                  ? (widget.currentPresetUnavailable
                        ? l10n.presetUnavailableBadge
                        : _getPresetName(widget.currentPresetId))
                  : l10n.rolePlay,
              style: TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.w500,
                color: widget.enabled
                    ? (widget.currentPresetUnavailable
                          ? CupertinoColors.systemRed.resolveFrom(context)
                          : widget.promptPresetEnabled
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
    );
  }

  /// 显示工具选择菜单
  void _showToolMenu() {
    final l10n = AppLocalizations.of(context)!;

    showCupertinoModalPopup(
      context: context,
      builder: (context) => CupertinoActionSheet(
        actions: [
          // 深度思考选项
          if (widget.onThinkingModeChanged != null)
            CupertinoActionSheetAction(
              onPressed: () {
                Navigator.pop(context);
                widget.onThinkingModeChanged!(!widget.thinkingMode);
              },
              child: _buildActionSheetItem(
                icon: CupertinoIcons.lightbulb,
                title: l10n.deepThinking,
                isActive: widget.thinkingMode,
              ),
            ),

          // 角色扮演选项
          if (widget.onPromptPresetEnabledChanged != null)
            CupertinoActionSheetAction(
              onPressed: () {
                Navigator.pop(context);
                // 不立即启用角色扮演模式，等用户选择预设后再启用
                Future.microtask(() => _showPresetMenu());
              },
              child: _buildActionSheetItem(
                icon: CupertinoIcons.person_fill,
                title:
                    widget.promptPresetEnabled &&
                        widget.currentPresetId.isNotEmpty
                    ? _getPresetName(widget.currentPresetId)
                    : l10n.rolePlay,
                isActive:
                    widget.promptPresetEnabled &&
                    widget.currentPresetId.isNotEmpty,
              ),
            ),

          // 模型选择选项
          if (widget.onShowModelSelector != null)
            CupertinoActionSheetAction(
              onPressed: () {
                Navigator.pop(context);
                Future.microtask(() => widget.onShowModelSelector!());
              },
              child: _buildActionSheetItem(
                icon: CupertinoIcons.cube_box,
                title: widget.currentModelName.isEmpty
                    ? l10n.model
                    : widget.currentModelName,
                isActive: widget.currentModelName.isNotEmpty,
              ),
            ),
        ],
        cancelButton: CupertinoActionSheetAction(
          child: Text(l10n.cancel),
          onPressed: () => Navigator.pop(context),
        ),
      ),
    );
  }

  /// 构建ActionSheet菜单项
  Widget _buildActionSheetItem({
    required IconData icon,
    required String title,
    required bool isActive,
  }) {
    final brightness = CupertinoTheme.of(context).brightness;
    final locale = Localizations.maybeLocaleOf(context);
    final fontFamily = appFontFamilyForLocale(locale);

    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        Icon(
          icon,
          size: 20,
          color: isActive
              ? (brightness == Brightness.dark
                    ? CupertinoColors.systemBlue.darkColor
                    : CupertinoColors.systemBlue.color)
              : (brightness == Brightness.dark
                    ? CupertinoColors.systemGrey.darkColor
                    : CupertinoColors.systemGrey),
        ),
        const SizedBox(width: 12),
        Text(
          title,
          style: TextStyle(
            fontSize: 17,
            fontWeight: isActive ? FontWeight.w600 : FontWeight.w400,
            fontFamily: fontFamily,
            fontFamilyFallback: cjkFontFallbackForLocale(locale),
            color: brightness == Brightness.dark
                ? CupertinoColors.white
                : CupertinoColors.black,
          ),
        ),
      ],
    );
  }

  @override
  void dispose() {
    _controller.dispose();
    _scrollController.dispose();
    super.dispose();
  }
}
