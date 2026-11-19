import 'dart:io';

import 'package:cupertino_ui/cupertino_ui.dart';
import 'package:file_picker/file_picker.dart';

import '../l10n/app_localizations.dart';
import '../services/file_service.dart';
import '../services/ai_service.dart';
import '../models/attachment.dart';
import '../models/prompt_preset.dart';
import '../utils/app_theme.dart';
import '../utils/platform_utils.dart';
import 'desktop/desktop_popover.dart';
import 'preset_avatar.dart';
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
  final FocusNode _focusNode = FocusNode();
  final FileService _fileService = FileService();
  bool _canSend = false;
  bool _isFocused = false;
  List<Attachment> _attachments = [];

  @override
  void initState() {
    super.initState();
    _controller.addListener(_onTextChanged);
    _focusNode.addListener(_onFocusChanged);
  }

  void _onFocusChanged() {
    if (mounted) {
      setState(() => _isFocused = _focusNode.hasFocus);
    }
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
  void _showPresetMenu({BuildContext? anchorContext}) {
    if (!widget.enabled || widget.presets.isEmpty) return;

    final l10n = AppLocalizations.of(context)!;
    void handlePresetTap(PromptPreset preset) {
      if (preset.isBroken) {
        showCupertinoDialog<void>(
          context: context,
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
      widget.onPresetSelected?.call(preset.id);
      if (!widget.promptPresetEnabled) {
        widget.onPromptPresetEnabledChanged?.call(true);
      }
    }

    if (anchorContext != null && useWideLayout(MediaQuery.sizeOf(context))) {
      showDesktopPopoverMenu(
        anchorContext: anchorContext,
        preferAbove: true,
        width: 260,
        items: [
          for (final preset in widget.presets)
            DesktopPopoverItem(
              label: preset.isBroken
                  ? '${preset.name} (${l10n.presetBrokenLabel})'
                  : preset.name,
              icon: preset.isBroken
                  ? CupertinoIcons.exclamationmark_triangle
                  : CupertinoIcons.person_fill,
              selected:
                  widget.promptPresetEnabled &&
                  widget.currentPresetId == preset.id,
              onTap: () => handlePresetTap(preset),
            ),
          if (widget.promptPresetEnabled)
            DesktopPopoverItem(
              label: l10n.closePresetMode,
              icon: CupertinoIcons.xmark_circle,
              isDestructive: true,
              isDividerBefore: true,
              onTap: () => widget.onPromptPresetEnabledChanged?.call(false),
            ),
        ],
      );
      return;
    }

    showCupertinoModalPopup(
      context: context,
      builder: (sheetContext) {
        final primaryColor = AppTokens.accent(sheetContext);
        return CupertinoActionSheet(
          title: Text(l10n.selectPresetRole),
          message: Text(l10n.selectPresetRoleMessage),
          actions: [
            for (final preset in widget.presets)
              CupertinoActionSheetAction(
                onPressed: () {
                  Navigator.pop(sheetContext);
                  handlePresetTap(preset);
                },
                child: Row(
                  children: [
                    PresetAvatar(
                      preset: preset,
                      size: 28,
                      iconColor: preset.isBroken
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
                              if (preset.author.isNotEmpty) ...[
                                const SizedBox(width: 4),
                                Flexible(
                                  child: Text(
                                    preset.author,
                                    style: const TextStyle(
                                      fontSize: 13,
                                      color: CupertinoColors.systemGrey,
                                    ),
                                    overflow: TextOverflow.ellipsis,
                                  ),
                                ),
                              ],
                            ],
                          ),
                          const SizedBox(height: 2),
                          Text(
                            preset.description,
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: TextStyle(
                              fontSize: 13,
                              color: preset.isBroken
                                  ? CupertinoColors.systemGrey2
                                  : CupertinoColors.systemGrey,
                            ),
                          ),
                          if (preset.isBroken)
                            Text(
                              l10n.presetBrokenLabel,
                              style: TextStyle(
                                fontSize: 12,
                                color: AppTokens.red(sheetContext),
                              ),
                            ),
                        ],
                      ),
                    ),
                    const SizedBox(width: 8),
                    if (widget.promptPresetEnabled &&
                        widget.currentPresetId == preset.id)
                      Icon(
                        CupertinoIcons.checkmark_alt,
                        color: primaryColor,
                      ),
                  ],
                ),
              ),
            if (widget.promptPresetEnabled)
              CupertinoActionSheetAction(
                isDestructiveAction: true,
                onPressed: () {
                  Navigator.pop(sheetContext);
                  widget.onPromptPresetEnabledChanged?.call(false);
                },
                child: Text(l10n.closePresetMode),
              ),
          ],
          cancelButton: CupertinoActionSheetAction(
            onPressed: () => Navigator.pop(sheetContext),
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
                displayName: platformFile.name,
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
    final fontFallback =
        cjkFontFallbackForLocale(Localizations.maybeLocaleOf(context));
    final accent = AppTokens.accent(context);
    final isWide = useWideLayout(MediaQuery.sizeOf(context));

    return SafeArea(
      top: false,
      child: Center(
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: AppTokens.chatMaxWidth),
          child: Padding(
            padding: EdgeInsets.fromLTRB(
              isWide ? 20 : 12,
              6,
              isWide ? 20 : 12,
              isWide ? 14 : 10,
            ),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                if (_attachments.isNotEmpty)
                  Padding(
                    padding: const EdgeInsets.only(bottom: 8),
                    child: Wrap(
                      spacing: 6,
                      runSpacing: 6,
                      children: _attachments
                          .map(
                            (attachment) => AttachmentPreviewChip(
                              attachment: attachment,
                              sizeLabel:
                                  _formatFileSize(attachment.fileSize ?? 0),
                              onRemove: () => _removeAttachment(attachment),
                            ),
                          )
                          .toList(),
                    ),
                  ),
                AnimatedContainer(
                  duration: const Duration(milliseconds: 140),
                  decoration: BoxDecoration(
                    color: AppTokens.sidebarBg(context),
                    borderRadius: BorderRadius.circular(
                      AppTokens.radiusComposer,
                    ),
                    border: Border.all(
                      color: _isFocused
                          ? accent.withValues(alpha: 0.72)
                          : AppTokens.separator(context),
                      width: _isFocused ? 1.0 : 0.5,
                    ),
                  ),
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      CupertinoTextField(
                        controller: _controller,
                        focusNode: _focusNode,
                        scrollController: _scrollController,
                        enabled: widget.enabled,
                        minLines: 1,
                        maxLines: 8,
                        keyboardType: TextInputType.multiline,
                        textInputAction: TextInputAction.newline,
                        padding: const EdgeInsets.fromLTRB(16, 13, 16, 8),
                        decoration: const BoxDecoration(
                          color: CupertinoColors.transparent,
                        ),
                        placeholder: widget.enabled
                            ? l10n.messageInputPlaceholder
                            : l10n.configureApiSettingsFirst,
                        placeholderStyle: TextStyle(
                          fontSize: 15.5,
                          height: 1.4,
                          fontFamilyFallback: fontFallback,
                          color: AppTokens.labelTertiary(context),
                        ),
                        style: TextStyle(
                          fontSize: 15.5,
                          height: 1.45,
                          fontFamilyFallback: fontFallback,
                          color: AppTokens.label(context),
                        ),
                        cursorColor: accent,
                      ),
                      Padding(
                        padding: const EdgeInsets.fromLTRB(10, 0, 10, 9),
                        child: Row(
                          children: [
                            Expanded(
                              child: SingleChildScrollView(
                                scrollDirection: Axis.horizontal,
                                child: Row(
                                  mainAxisSize: MainAxisSize.min,
                                  children: [
                                    CupertinoButton(
                                      padding: EdgeInsets.zero,
                                      minimumSize: const Size(32, 32),
                                      onPressed:
                                          widget.enabled ? _pickFile : null,
                                      child: Container(
                                        width: 30,
                                        height: 30,
                                        decoration: BoxDecoration(
                                          color: AppTokens.fill(context),
                                          shape: BoxShape.circle,
                                        ),
                                        child: Icon(
                                          CupertinoIcons.plus,
                                          size: 16,
                                          color: widget.enabled
                                              ? AppTokens.labelSecondary(
                                                  context,
                                                )
                                              : AppTokens.labelTertiary(
                                                  context,
                                                ),
                                        ),
                                      ),
                                    ),
                                    if (widget.onThinkingModeChanged != null) ...[
                                      const SizedBox(width: 6),
                                      _buildThinkingPill(context, l10n),
                                    ],
                                    if (widget.onPromptPresetEnabledChanged !=
                                            null &&
                                        widget.presets.isNotEmpty) ...[
                                      const SizedBox(width: 6),
                                      _buildPresetPill(context, l10n),
                                    ],
                                  ],
                                ),
                              ),
                            ),
                            const SizedBox(width: 8),
                            CupertinoButton(
                              padding: EdgeInsets.zero,
                              minimumSize: const Size(32, 32),
                              onPressed: _canSend ? _sendMessage : null,
                              child: Container(
                                width: 32,
                                height: 32,
                                decoration: BoxDecoration(
                                  color: _canSend
                                      ? (widget.isGenerating
                                          ? AppTokens.red(context)
                                          : accent)
                                      : AppTokens.fill(context),
                                  shape: BoxShape.circle,
                                ),
                                child: Icon(
                                  widget.isGenerating
                                      ? CupertinoIcons.stop_fill
                                      : CupertinoIcons.arrow_up,
                                  size: widget.isGenerating ? 14 : 17,
                                  color: _canSend
                                      ? CupertinoColors.white
                                      : AppTokens.labelTertiary(context),
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildThinkingPill(BuildContext context, AppLocalizations l10n) {
    final active = widget.thinkingMode;
    final fgColor = !widget.enabled
        ? AppTokens.labelTertiary(context)
        : (active ? AppTokens.accent(context) : AppTokens.labelSecondary(context));

    return CupertinoButton(
      padding: EdgeInsets.zero,
      minimumSize: const Size(0, 30),
      onPressed: widget.enabled && widget.onThinkingModeChanged != null
          ? () => widget.onThinkingModeChanged!(!widget.thinkingMode)
          : null,
      child: Container(
        height: 30,
        padding: const EdgeInsets.symmetric(horizontal: 11),
        decoration: BoxDecoration(
          color: active ? AppTokens.accentSoft(context) : AppTokens.fillSoft(context),
          borderRadius: BorderRadius.circular(15),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(CupertinoIcons.lightbulb, size: 14.5, color: fgColor),
            const SizedBox(width: 5),
            Text(
              l10n.deepThinking,
              style: TextStyle(
                fontSize: 12.5,
                fontWeight: active ? FontWeight.w600 : FontWeight.w500,
                color: fgColor,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildPresetPill(BuildContext context, AppLocalizations l10n) {
    final active =
        widget.promptPresetEnabled && widget.currentPresetId.isNotEmpty;
    final unavailable = active && widget.currentPresetUnavailable;
    final fgColor = !widget.enabled
        ? AppTokens.labelTertiary(context)
        : unavailable
        ? AppTokens.red(context)
        : (active
              ? AppTokens.accent(context)
              : AppTokens.labelSecondary(context));
    final bgColor = unavailable
        ? AppTokens.red(context).withValues(alpha: 0.14)
        : (active
              ? AppTokens.accentSoft(context)
              : AppTokens.fillSoft(context));
    final label = active
        ? (unavailable
              ? l10n.presetUnavailableBadge
              : _getPresetName(widget.currentPresetId))
        : l10n.rolePlay;

    return Builder(
      builder: (pillContext) => CupertinoButton(
        padding: EdgeInsets.zero,
        minimumSize: const Size(0, 30),
        onPressed: widget.enabled
            ? () => _showPresetMenu(anchorContext: pillContext)
            : null,
        child: Container(
          height: 30,
          constraints: const BoxConstraints(maxWidth: 168),
          padding: const EdgeInsets.symmetric(horizontal: 11),
          decoration: BoxDecoration(
            color: bgColor,
            borderRadius: BorderRadius.circular(15),
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(CupertinoIcons.person_fill, size: 14, color: fgColor),
              const SizedBox(width: 5),
              Flexible(
                child: Text(
                  label,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: TextStyle(
                    fontSize: 12.5,
                    fontWeight: active ? FontWeight.w600 : FontWeight.w500,
                    color: fgColor,
                  ),
                ),
              ),
              const SizedBox(width: 3),
              Icon(CupertinoIcons.chevron_down, size: 11, color: fgColor),
            ],
          ),
        ),
      ),
    );
  }

  @override
  void dispose() {
    _focusNode.removeListener(_onFocusChanged);
    _focusNode.dispose();
    _controller.dispose();
    _scrollController.dispose();
    super.dispose();
  }
}
