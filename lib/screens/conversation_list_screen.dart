import 'package:cupertino_ui/cupertino_ui.dart';
import 'package:file_picker/file_picker.dart';
import 'package:intl/intl.dart';
import 'package:material_ui/material_ui.dart' as material;

import 'dart:async';
import 'dart:convert';
import 'dart:io';

import '../l10n/app_localizations.dart';
import '../models/conversation.dart';
import '../services/conversation_service.dart';
import '../services/preset_repository.dart';

class ConversationListScreen extends StatefulWidget {
  final Function(String? conversationId) onConversationSelected;
  final bool embedded;
  final bool compact;
  final int refreshToken;
  final String? selectedConversationId;
  final ConversationService? service;

  const ConversationListScreen({
    super.key,
    required this.onConversationSelected,
    this.embedded = false,
    this.compact = false,
    this.refreshToken = 0,
    this.selectedConversationId,
    this.service,
  });

  @override
  State<ConversationListScreen> createState() => _ConversationListScreenState();
}

class _ConversationListScreenState extends State<ConversationListScreen> {
  late final ConversationService _conversationService;
  List<Conversation> _conversations = [];
  String? _currentConversationId;
  bool _isLoading = true;
  bool _isSelecting = false; // 防止重复选择对话
  final TextEditingController _searchController = TextEditingController();
  String _searchQuery = '';
  Timer? _searchTimer;
  int _loadGeneration = 0;

  @override
  void initState() {
    super.initState();
    _conversationService = widget.service ?? ConversationService();
    _loadConversations();
  }

  @override
  void didUpdateWidget(covariant ConversationListScreen oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.refreshToken != widget.refreshToken) {
      _loadConversations();
    }
  }

  @override
  void dispose() {
    _searchTimer?.cancel();
    _searchController.dispose();
    super.dispose();
  }

  Future<void> _loadConversations() async {
    final generation = ++_loadGeneration;
    final query = _searchQuery.trim();
    final conversations = query.isEmpty
        ? await _conversationService.loadConversations()
        : await _conversationService.searchConversations(query);
    final currentId = await _conversationService.getCurrentConversationId();

    if (!mounted || generation != _loadGeneration) return;
    setState(() {
      _conversations = conversations;
      _currentConversationId = currentId;
      _isLoading = false;
    });
  }

  void _onSearchChanged(String value) {
    _searchTimer?.cancel();
    final query = value.trim();
    if (query == _searchQuery) return;

    setState(() {
      _searchQuery = query;
    });

    if (query.isEmpty) {
      _loadConversations();
      return;
    }

    _searchTimer = Timer(const Duration(milliseconds: 250), _loadConversations);
  }

  Future<void> _createNewConversation() async {
    final l10n = AppLocalizations.of(context)!;
    final conversation = await _conversationService.createNewConversation(
      title: l10n.newConversation,
    );
    setState(() {
      _conversations.insert(0, conversation);
      _currentConversationId = conversation.id;
    });
    // 只传递对话 ID，由 ChatScreen 负责加载完整对话
    widget.onConversationSelected(conversation.id);
    if (!widget.embedded && mounted) {
      Navigator.pop(context);
    }
  }

  Future<void> _importConversation() async {
    final l10n = AppLocalizations.of(context)!;

    try {
      final picked = await FilePicker.pickFile(
        type: FileType.custom,
        allowedExtensions: ['lumenflow', 'zip'],
        dialogTitle: l10n.importConversation,
      );
      final path = picked?.path;
      if (path == null) return;

      final bytes = await File(path).readAsBytes();
      await _conversationService.importConversationFromLumenflow(
        bytes: bytes,
        l10n: l10n,
        confirmPresetImport: (name) async {
          if (!mounted) return false;
          final confirmed = await showCupertinoDialog<bool>(
            context: context,
            builder: (dialogContext) => CupertinoAlertDialog(
              title: Text(l10n.importPresetSnapshotTitle),
              content: Text(l10n.importPresetSnapshotMessage(name)),
              actions: [
                CupertinoDialogAction(
                  child: Text(l10n.cancel),
                  onPressed: () => Navigator.pop(dialogContext, false),
                ),
                CupertinoDialogAction(
                  isDefaultAction: true,
                  child: Text(l10n.importButton),
                  onPressed: () => Navigator.pop(dialogContext, true),
                ),
              ],
            ),
          );
          return confirmed == true;
        },
      );
      // 会话快照可能在导入时创建/重映射了角色预设，刷新共享仓库，
      // 否则聊天页会继续显示“角色不可用”。
      await PresetRepository.instance.ensureLoaded(force: true);
      await _loadConversations();

      if (!mounted) return;
      showCupertinoDialog(
        context: context,
        builder: (context) => CupertinoAlertDialog(
          title: Text(l10n.importSuccess),
          content: Text(l10n.conversationImportSuccess),
          actions: [
            CupertinoDialogAction(
              child: Text(l10n.ok),
              onPressed: () => Navigator.pop(context),
            ),
          ],
        ),
      );
    } catch (e) {
      if (!mounted) return;
      showCupertinoDialog(
        context: context,
        builder: (context) => CupertinoAlertDialog(
          title: Text(l10n.conversationImportFailed),
          content: Text(e.toString()),
          actions: [
            CupertinoDialogAction(
              child: Text(l10n.ok),
              onPressed: () => Navigator.pop(context),
            ),
          ],
        ),
      );
    }
  }

  Future<void> _selectConversation(Conversation conversation) async {
    // 防止重复选择
    if (_isSelecting) {
      return;
    }

    _isSelecting = true;

    try {
      await _conversationService.setCurrentConversationId(conversation.id);
      setState(() {
        _currentConversationId = conversation.id;
      });
      // 只传递对话 ID，由 ChatScreen 负责加载完整对话
      widget.onConversationSelected(conversation.id);
      if (!widget.embedded && mounted) {
        Navigator.pop(context);
      }
    } finally {
      _isSelecting = false;
    }
  }

  Future<void> _deleteConversation(Conversation conversation) async {
    final l10n = AppLocalizations.of(context)!;
    showCupertinoDialog(
      context: context,
      builder: (context) => CupertinoAlertDialog(
        title: Text(l10n.deleteConversation),
        content: Text(l10n.deleteConversationConfirm(conversation.title)),
        actions: [
          CupertinoDialogAction(
            child: Text(l10n.cancel),
            onPressed: () => Navigator.pop(context),
          ),
          CupertinoDialogAction(
            isDestructiveAction: true,
            child: Text(l10n.delete),
            onPressed: () async {
              final wasCurrent = conversation.id == _currentConversationId;
              Navigator.pop(context);
              await _conversationService.deleteConversation(conversation.id);
              await _loadConversations();

              if (wasCurrent) {
                widget.onConversationSelected(null);
              }
            },
          ),
        ],
      ),
    );
  }

  Future<void> _togglePinned(Conversation conversation) async {
    await _conversationService.setConversationPinned(
      conversation.id,
      !conversation.isPinned,
    );
    await _loadConversations();
  }

  Future<void> _editConversationTitle(Conversation conversation) async {
    final l10n = AppLocalizations.of(context)!;
    final TextEditingController controller = TextEditingController(
      text: conversation.title,
    );

    showCupertinoDialog(
      context: context,
      builder: (dialogContext) => CupertinoAlertDialog(
        title: Text(l10n.editConversationTitle),
        content: Padding(
          padding: const EdgeInsets.only(top: 16),
          child: SizedBox(
            width: MediaQuery.of(dialogContext).size.width * 0.8,
            child: CupertinoTextField(
              controller: controller,
              placeholder: l10n.enterConversationTitle,
            ),
          ),
        ),
        actions: [
          CupertinoDialogAction(
            child: Text(l10n.cancel),
            onPressed: () => Navigator.pop(dialogContext),
          ),
          CupertinoDialogAction(
            child: Text(l10n.save),
            onPressed: () async {
              if (controller.text.trim().isNotEmpty) {
                await _conversationService.updateConversationTitle(
                  conversation.id,
                  controller.text.trim(),
                );
                await _loadConversations();
              }
              if (dialogContext.mounted) {
                Navigator.pop(dialogContext);
              }
            },
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final brightness = CupertinoTheme.of(context).brightness;
    final listBody = _buildListBody(context);

    if (widget.embedded) {
      return ColoredBox(
        color: brightness == Brightness.dark
            ? CupertinoColors.systemGrey6.darkColor
            : CupertinoColors.systemGrey6.color,
        child: SafeArea(
          bottom: false,
          child: Column(
            children: [
              _buildEmbeddedHeader(context),
              Expanded(child: SafeArea(top: false, child: listBody)),
            ],
          ),
        ),
      );
    }

    final l10n = AppLocalizations.of(context)!;
    return CupertinoPageScaffold(
      navigationBar: CupertinoNavigationBar(
        middle: Text(l10n.conversations),
        trailing: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            CupertinoButton(
              padding: EdgeInsets.zero,
              onPressed: _importConversation,
              child: const Icon(CupertinoIcons.folder_open),
            ),
            CupertinoButton(
              padding: EdgeInsets.zero,
              onPressed: _createNewConversation,
              child: const Icon(CupertinoIcons.add),
            ),
          ],
        ),
      ),
      child: SafeArea(child: listBody),
    );
  }

  Widget _buildEmbeddedHeader(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Container(
          height: 52,
          padding: const EdgeInsets.symmetric(horizontal: 14),
          decoration: BoxDecoration(
            border: Border(
              bottom: BorderSide(
                color: CupertinoColors.systemGrey4.resolveFrom(context),
                width: 0.5,
              ),
            ),
          ),
          child: Row(
            children: [
              const Expanded(
                child: Text(
                  'LumenFlow',
                  style: TextStyle(fontSize: 15, fontWeight: FontWeight.w700),
                ),
              ),
              CupertinoButton(
                padding: EdgeInsets.zero,
                minimumSize: const Size(28, 28),
                onPressed: _importConversation,
                child: const Icon(CupertinoIcons.folder_open, size: 18),
              ),
            ],
          ),
        ),
        Padding(
          padding: const EdgeInsets.fromLTRB(12, 20, 12, 6),
          child: GestureDetector(
            behavior: HitTestBehavior.opaque,
            onTap: _createNewConversation,
            child: Container(
              height: 30,
              alignment: Alignment.center,
              decoration: BoxDecoration(
                color: CupertinoTheme.of(context).primaryColor,
                borderRadius: BorderRadius.circular(7),
              ),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  const Icon(
                    CupertinoIcons.add,
                    size: 13,
                    color: CupertinoColors.white,
                  ),
                  const SizedBox(width: 5),
                  Text(
                    l10n.newConversation,
                    style: const TextStyle(
                      color: CupertinoColors.white,
                      fontSize: 12.5,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildListBody(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final brightness = CupertinoTheme.of(context).brightness;
    final searchBackground = widget.embedded
        ? (brightness == Brightness.dark
              ? CupertinoColors.systemGrey5.darkColor
              : CupertinoColors.systemGrey5.color)
        : (brightness == Brightness.dark
              ? CupertinoColors.systemGrey6.darkColor
              : CupertinoColors.systemGrey6.color);
    final searchIconColor = brightness == Brightness.dark
        ? CupertinoColors.systemGrey.darkColor
        : CupertinoColors.systemGrey;
    final highlightId = widget.embedded
        ? (widget.selectedConversationId ?? _currentConversationId)
        : _currentConversationId;

    return Column(
      children: [
        if (!_isLoading)
          Padding(
            padding: widget.embedded
                ? const EdgeInsets.fromLTRB(12, 4, 12, 20)
                : const EdgeInsets.fromLTRB(16, 8, 16, 4),
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 10),
              decoration: BoxDecoration(
                color: searchBackground,
                borderRadius: BorderRadius.circular(10),
              ),
              child: material.Material(
                color: material.Colors.transparent,
                child: Row(
                  children: [
                    Icon(
                      CupertinoIcons.search,
                      size: 18,
                      color: searchIconColor,
                    ),
                    const SizedBox(width: 8),
                    Expanded(
                      child: material.TextField(
                        controller: _searchController,
                        onChanged: _onSearchChanged,
                        style: const TextStyle(fontSize: 16),
                        cursorColor: CupertinoTheme.of(context).primaryColor,
                        decoration: material.InputDecoration(
                          border: material.InputBorder.none,
                          focusedBorder: material.InputBorder.none,
                          enabledBorder: material.InputBorder.none,
                          hintText: l10n.searchConversations,
                          hintStyle: TextStyle(color: searchIconColor),
                          isDense: true,
                          contentPadding: const EdgeInsets.symmetric(
                            vertical: 10,
                          ),
                        ),
                      ),
                    ),
                    if (_searchQuery.isNotEmpty)
                      GestureDetector(
                        onTap: () {
                          _searchController.clear();
                          _onSearchChanged('');
                        },
                        child: Padding(
                          padding: const EdgeInsets.all(4),
                          child: Icon(
                            CupertinoIcons.xmark_circle_fill,
                            size: 16,
                            color: searchIconColor,
                          ),
                        ),
                      ),
                  ],
                ),
              ),
            ),
          ),
        Expanded(
          child: _isLoading
              ? const Center(child: CupertinoActivityIndicator())
              : _conversations.isEmpty
              ? _buildEmptyState()
              : ListView.builder(
                  itemCount: _conversations.length,
                  itemBuilder: (context, index) {
                    final conversation = _conversations[index];
                    final isCurrentConversation =
                        conversation.id == highlightId;
                    final primaryColor = CupertinoTheme.of(context)
                        .primaryColor;

                    return Container(
                      color: isCurrentConversation
                          ? CupertinoColors.systemBlue.withValues(alpha: 0.1)
                          : null,
                      child: CupertinoListTile(
                        title: Text(
                          conversation.title,
                          style: TextStyle(
                            fontSize: widget.compact ? 13 : null,
                            fontWeight: isCurrentConversation
                                ? FontWeight.w600
                                : FontWeight.normal,
                          ),
                        ),
                        subtitle: Text(
                          _formatDate(conversation.updatedAt),
                          style: TextStyle(
                            fontSize: widget.compact ? 10.5 : 13,
                            color: CupertinoColors.systemGrey,
                          ),
                        ),
                        leading: widget.compact
                            ? null
                            : Container(
                                width: 40,
                                height: 40,
                                decoration: BoxDecoration(
                                  color: isCurrentConversation
                                      ? CupertinoColors.systemBlue
                                      : CupertinoColors.systemGrey5,
                                  borderRadius: BorderRadius.circular(20),
                                ),
                                child: Icon(
                                  CupertinoIcons.chat_bubble_2,
                                  color: isCurrentConversation
                                      ? CupertinoColors.white
                                      : CupertinoColors.systemGrey,
                                  size: 20,
                                ),
                              ),
                        trailing: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            if (conversation.isPinned)
                              Padding(
                                padding: const EdgeInsets.only(right: 6),
                                child: Icon(
                                  CupertinoIcons.pin_fill,
                                  size: 14,
                                  color: primaryColor,
                                ),
                              ),
                            if (!widget.compact &&
                                conversation.messages.isNotEmpty)
                              Text(
                                '${conversation.messages.length}',
                                style: const TextStyle(
                                  fontSize: 12,
                                  color: CupertinoColors.systemGrey,
                                ),
                              ),
                            const SizedBox(width: 8),
                            CupertinoButton(
                              padding: EdgeInsets.zero,
                              child: const Icon(
                                CupertinoIcons.ellipsis,
                                size: 20,
                                color: CupertinoColors.systemGrey,
                              ),
                              onPressed: () =>
                                  _showConversationOptions(conversation),
                            ),
                          ],
                        ),
                        onTap: () => _selectConversation(conversation),
                      ),
                    );
                  },
                ),
        ),
      ],
    );
  }

  Widget _buildEmptyState() {
    final l10n = AppLocalizations.of(context)!;
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          const Icon(
            CupertinoIcons.chat_bubble_2,
            size: 64,
            color: CupertinoColors.systemGrey3,
          ),
          const SizedBox(height: 16),
          Text(
            _searchQuery.isEmpty ? l10n.noConversations : l10n.searchNoResults,
            style: const TextStyle(
              fontSize: 18,
              color: CupertinoColors.systemGrey,
            ),
          ),
          if (_searchQuery.isEmpty) ...[
            const SizedBox(height: 8),
            Text(
              l10n.createNewConversation,
              style: const TextStyle(
                fontSize: 14,
                color: CupertinoColors.systemGrey2,
              ),
            ),
            const SizedBox(height: 24),
            CupertinoButton.filled(
              onPressed: _createNewConversation,
              child: Text(l10n.newConversation),
            ),
          ],
        ],
      ),
    );
  }

  void _showConversationOptions(Conversation conversation) {
    final l10n = AppLocalizations.of(context)!;
    showCupertinoModalPopup(
      context: context,
      builder: (context) {
        final primaryColor = CupertinoTheme.of(context).primaryColor;
        final destructiveColor = CupertinoColors.systemRed.resolveFrom(context);
        return CupertinoActionSheet(
          title: Text(conversation.title),
          actions: [
            CupertinoActionSheetAction(
              child: Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(CupertinoIcons.pencil, size: 20, color: primaryColor),
                  const SizedBox(width: 8),
                  Text(l10n.editTitle),
                ],
              ),
              onPressed: () {
                Navigator.pop(context);
                _editConversationTitle(conversation);
              },
            ),
            CupertinoActionSheetAction(
              child: Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(
                    conversation.isPinned
                        ? CupertinoIcons.pin_slash
                        : CupertinoIcons.pin,
                    size: 20,
                    color: primaryColor,
                  ),
                  const SizedBox(width: 8),
                  Text(
                    conversation.isPinned
                        ? l10n.unpinConversation
                        : l10n.pinConversation,
                  ),
                ],
              ),
              onPressed: () {
                Navigator.pop(context);
                _togglePinned(conversation);
              },
            ),
            CupertinoActionSheetAction(
              child: Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(
                    CupertinoIcons.arrow_down_doc,
                    size: 20,
                    color: primaryColor,
                  ),
                  const SizedBox(width: 8),
                  Text(l10n.exportConversation),
                ],
              ),
              onPressed: () {
                Navigator.pop(context);
                _showExportFormatDialog(conversation);
              },
            ),
            CupertinoActionSheetAction(
              isDestructiveAction: true,
              child: Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(
                    CupertinoIcons.delete,
                    size: 20,
                    color: destructiveColor,
                  ),
                  const SizedBox(width: 8),
                  Text(l10n.deleteConversation2),
                ],
              ),
              onPressed: () {
                Navigator.pop(context);
                _deleteConversation(conversation);
              },
            ),
          ],
          cancelButton: CupertinoActionSheetAction(
            child: Text(l10n.cancel),
            onPressed: () => Navigator.pop(context),
          ),
        );
      },
    );
  }

  void _showExportFormatDialog(Conversation conversation) {
    final l10n = AppLocalizations.of(context)!;
    var includePresetCard = false;
    showCupertinoModalPopup(
      context: context,
      builder: (context) => StatefulBuilder(
        builder: (context, setSheetState) {
          void export(String format) {
            Navigator.pop(context);
            _exportConversation(
              conversation,
              format,
              includePresetSnapshot:
                  includePresetCard &&
                  (format == 'json' || format == 'lumenflow'),
            );
          }

          return CupertinoActionSheet(
            title: Text(l10n.exportFormat),
            message: Text(l10n.includePresetCardHint),
            actions: [
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 16),
                child: Row(
                  children: [
                    Expanded(child: Text(l10n.includePresetCard)),
                    CupertinoSwitch(
                      value: includePresetCard,
                      onChanged: (value) =>
                          setSheetState(() => includePresetCard = value),
                    ),
                  ],
                ),
              ),
              CupertinoActionSheetAction(
                child: Text(l10n.exportFormatTxt),
                onPressed: () => export('txt'),
              ),
              CupertinoActionSheetAction(
                child: Text(l10n.exportFormatJson),
                onPressed: () => export('json'),
              ),
              CupertinoActionSheetAction(
                child: Text(l10n.exportFormatLumenflow),
                onPressed: () => export('lumenflow'),
              ),
              CupertinoActionSheetAction(
                child: Text(l10n.exportFormatPdf),
                onPressed: () => export('pdf'),
              ),
            ],
            cancelButton: CupertinoActionSheetAction(
              child: Text(l10n.cancel),
              onPressed: () => Navigator.pop(context),
            ),
          );
        },
      ),
    );
  }

  Future<void> _exportConversation(
    Conversation conversation,
    String format, {
    bool includePresetSnapshot = false,
  }) async {
    final l10n = AppLocalizations.of(context)!;
    try {
      List<int> bytes;
      String fileName;
      String extension;

      switch (format) {
        case 'txt':
          final text = await _conversationService.exportConversationToText(
            conversation.id,
            l10n,
          );
          bytes = utf8.encode(text);
          extension = 'txt';
          break;
        case 'json':
          final jsonData = await _conversationService.exportConversationToJson(
            conversation.id,
            l10n,
            includePresetSnapshot: includePresetSnapshot,
          );
          final jsonString = jsonEncode(jsonData);
          bytes = utf8.encode(jsonString);
          extension = 'json';
          break;
        case 'lumenflow':
          final lumenflowData = await _conversationService
              .exportConversationToLumenflow(
                conversation.id,
                l10n,
                includePresetSnapshot: includePresetSnapshot,
              );
          final jsonString = jsonEncode(lumenflowData);
          bytes = utf8.encode(jsonString);
          extension = 'lumenflow';
          break;
        case 'pdf':
          bytes = await _conversationService.exportConversationToPdf(
            conversation.id,
            l10n,
          );
          extension = 'pdf';
          break;
        default:
          throw Exception('不支持的导出格式: $format');
      }

      // 生成文件名
      final safeTitle = conversation.title
          .replaceAll(RegExp(r'[^\w\s-]'), '')
          .replaceAll(' ', '_');
      fileName =
          '${safeTitle}_${DateTime.now().toIso8601String().substring(0, 10)}.$extension';

      // 保存文件
      final result = await _conversationService.saveExportFile(fileName, bytes);
      final filePath = result['filePath']!;
      final locationType = result['locationType']!;

      // 用户取消了保存
      if (locationType == 'cancelled') {
        return;
      }

      // 显示成功消息
      if (mounted) {
        final String content;
        if (locationType == 'saved') {
          content = l10n.exportSaved;
        } else {
          // 根据位置类型获取本地化的目录名称
          String locationName;
          switch (locationType) {
            case 'external':
              locationName = l10n.externalStorageDirectory;
              break;
            case 'app':
              locationName = l10n.appDocumentsDirectory;
              break;
            default:
              locationName = l10n.downloadDirectory;
          }
          content = l10n.exportLocation(locationName, filePath);
        }

        showCupertinoDialog(
          context: context,
          builder: (context) => CupertinoAlertDialog(
            title: Text(l10n.exportConversationSuccess),
            content: Text(content),
            actions: [
              CupertinoDialogAction(
                child: Text(l10n.ok),
                onPressed: () => Navigator.pop(context),
              ),
            ],
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        showCupertinoDialog(
          context: context,
          builder: (context) => CupertinoAlertDialog(
            title: Text(l10n.exportConversationFailed),
            content: Text(l10n.exportConversationError(e.toString())),
            actions: [
              CupertinoDialogAction(
                child: Text(l10n.ok),
                onPressed: () => Navigator.pop(context),
              ),
            ],
          ),
        );
      }
    }
  }

  String _formatDate(DateTime date) {
    final l10n = AppLocalizations.of(context)!;
    final now = DateTime.now();
    final difference = now.difference(date);

    if (difference.inDays == 0) {
      return DateFormat('HH:mm').format(date);
    } else if (difference.inDays == 1) {
      return l10n.yesterday;
    } else if (difference.inDays < 7) {
      return l10n.daysAgo(difference.inDays);
    } else {
      return DateFormat('MM/dd').format(date);
    }
  }
}
