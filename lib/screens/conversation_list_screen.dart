import 'package:cupertino_ui/cupertino_ui.dart';
import 'package:intl/intl.dart';

import 'dart:async';
import 'dart:convert';
import 'dart:io';

import '../l10n/app_localizations.dart';
import '../models/conversation.dart';
import '../services/conversation_service.dart';
import '../services/preset_repository.dart';
import '../utils/app_theme.dart';
import '../utils/import_file_picker.dart';
import '../utils/lumenflow_error_messages.dart';
import '../utils/platform_utils.dart';
import '../widgets/desktop/desktop_popover.dart';

/// 桌面侧栏统一顶栏向会话列表分派操作（导入、刷新）的控制器。
class ConversationListController {
  Future<void> Function()? _importConversation;
  Future<void> Function()? _createNewConversation;

  void attach({
    required Future<void> Function() importConversation,
    required Future<void> Function() createNewConversation,
  }) {
    _importConversation = importConversation;
    _createNewConversation = createNewConversation;
  }

  void detach() {
    _importConversation = null;
    _createNewConversation = null;
  }

  Future<void> importConversation() =>
      _importConversation?.call() ?? Future.value();

  Future<void> createNewConversation() =>
      _createNewConversation?.call() ?? Future.value();
}

class ConversationListScreen extends StatefulWidget {
  final Function(String? conversationId) onConversationSelected;
  final bool embedded;
  final bool compact;
  final bool isRootTab;
  final bool showEmbeddedHeader;
  final int refreshToken;
  final String? selectedConversationId;
  final ConversationService? service;
  final ConversationListController? controller;

  const ConversationListScreen({
    super.key,
    required this.onConversationSelected,
    this.embedded = false,
    this.compact = false,
    this.isRootTab = false,
    this.showEmbeddedHeader = true,
    this.refreshToken = 0,
    this.selectedConversationId,
    this.service,
    this.controller,
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
    widget.controller?.attach(
      importConversation: _importConversation,
      createNewConversation: _createNewConversation,
    );
    _loadConversations();
  }

  @override
  void didUpdateWidget(covariant ConversationListScreen oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.controller != widget.controller) {
      oldWidget.controller?.detach();
      widget.controller?.attach(
        importConversation: _importConversation,
        createNewConversation: _createNewConversation,
      );
    }
    if (oldWidget.refreshToken != widget.refreshToken) {
      _loadConversations();
    }
  }

  @override
  void dispose() {
    widget.controller?.detach();
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
    if (!mounted) return;
    setState(() {
      _conversations.insert(0, conversation);
      _currentConversationId = conversation.id;
    });
    // 只传递对话 ID，由 ChatScreen 负责加载完整对话
    widget.onConversationSelected(conversation.id);
    if (!widget.embedded &&
        !widget.isRootTab &&
        mounted &&
        Navigator.of(context).canPop()) {
      Navigator.pop(context);
    }
  }

  Future<void> _importConversation() async {
    final l10n = AppLocalizations.of(context)!;

    try {
      const importExtensions = ['lumenflow', 'json'];
      final picked = await pickImportFile(
        allowedExtensions: importExtensions,
        dialogTitle: l10n.importConversation,
      );
      final path = picked?.path;
      if (picked == null || path == null) return;
      if (!hasAllowedImportExtension(picked.name, importExtensions)) {
        throw FormatException(l10n.conversationImportInvalid);
      }

      Future<bool> confirmPresetImport(String name) async {
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
      }

      final bytes = await File(path).readAsBytes();
      final lowerName = picked.name.toLowerCase();
      if (lowerName.endsWith('.lumenflow')) {
        await _conversationService.importConversationArchive(
          bytes: bytes,
          l10n: l10n,
          confirmPresetImport: confirmPresetImport,
        );
      } else if (lowerName.endsWith('.json')) {
        await _conversationService.importConversationFromJson(
          bytes: bytes,
          l10n: l10n,
          confirmPresetImport: confirmPresetImport,
        );
      } else {
        throw FormatException(l10n.conversationImportInvalid);
      }
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
          content: Text(lumenflowErrorMessage(e, l10n)),
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
      if (!widget.embedded &&
          !widget.isRootTab &&
          mounted &&
          Navigator.of(context).canPop()) {
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

    try {
      await showCupertinoDialog(
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
    } finally {
      controller.dispose();
    }
  }

  @override
  Widget build(BuildContext context) {
    final listBody = _buildListBody(context);

    if (widget.embedded) {
      return ColoredBox(
        color: AppTokens.sidebarBg(context),
        child: SafeArea(
          bottom: false,
          child: Column(
            children: [
              if (widget.showEmbeddedHeader) _buildEmbeddedHeader(context),
              Expanded(child: SafeArea(top: false, child: listBody)),
            ],
          ),
        ),
      );
    }

    final l10n = AppLocalizations.of(context)!;
    return CupertinoPageScaffold(
      backgroundColor: AppTokens.groupedBg(context),
      navigationBar: CupertinoNavigationBar(
        backgroundColor: AppTokens.bg(context),
        middle: Text(l10n.conversations),
        trailing: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            CupertinoButton(
              padding: EdgeInsets.zero,
              onPressed: _importConversation,
              child: const Icon(CupertinoIcons.folder_open, size: 21),
            ),
            CupertinoButton(
              padding: const EdgeInsets.only(left: 10),
              onPressed: _createNewConversation,
              child: const Icon(CupertinoIcons.square_pencil, size: 21),
            ),
          ],
        ),
        border: Border(
          bottom: BorderSide(
            color: AppTokens.separator(context),
            width: 0.5,
          ),
        ),
      ),
      child: SafeArea(child: listBody),
    );
  }

  Widget _buildEmbeddedHeader(BuildContext context) {
    return Container(
      height: 52,
      padding: const EdgeInsets.symmetric(horizontal: 14),
      decoration: BoxDecoration(
        border: Border(
          bottom: BorderSide(
            color: AppTokens.separator(context),
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
            child: Icon(
              CupertinoIcons.folder_open,
              size: 17,
              color: AppTokens.labelSecondary(context),
            ),
          ),
          const SizedBox(width: 4),
          CupertinoButton(
            padding: EdgeInsets.zero,
            minimumSize: const Size(28, 28),
            onPressed: _createNewConversation,
            child: Icon(
              CupertinoIcons.square_pencil,
              size: 18,
              color: AppTokens.accent(context),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildListBody(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final highlightId = widget.embedded
        ? (widget.selectedConversationId ?? _currentConversationId)
        : (widget.isRootTab ? null : _currentConversationId);

    final pinned = _conversations
        .where((c) => c.isPinned)
        .toList(growable: false);
    final recent = _conversations
        .where((c) => !c.isPinned)
        .toList(growable: false);

    return Column(
      children: [
        if (!_isLoading)
          Padding(
            padding: widget.embedded
                ? const EdgeInsets.fromLTRB(10, 10, 10, 6)
                : const EdgeInsets.fromLTRB(16, 12, 16, 6),
            child: CupertinoSearchTextField(
              controller: _searchController,
              onChanged: _onSearchChanged,
              placeholder: l10n.searchConversations,
              backgroundColor: AppTokens.fill(context),
              borderRadius: BorderRadius.circular(10),
              style: TextStyle(
                fontSize: widget.compact ? 13 : 15,
                color: AppTokens.label(context),
              ),
              placeholderStyle: TextStyle(
                fontSize: widget.compact ? 13 : 15,
                color: AppTokens.labelTertiary(context),
              ),
            ),
          ),
        Expanded(
          child: _isLoading
              ? const Center(child: CupertinoActivityIndicator())
              : _conversations.isEmpty
              ? _buildEmptyState()
              : widget.compact
              ? _buildCompactSidebarList(
                  context,
                  l10n,
                  pinned: pinned,
                  recent: recent,
                  highlightId: highlightId,
                )
              : _buildMobileGroupedList(
                  context,
                  l10n,
                  pinned: pinned,
                  recent: recent,
                  highlightId: highlightId,
                ),
        ),
      ],
    );
  }

  Widget _buildSectionTitle(BuildContext context, String title, bool compact) {
    return Padding(
      padding: EdgeInsets.fromLTRB(
        compact ? 12 : 24,
        compact ? 10 : 14,
        12,
        compact ? 4 : 6,
      ),
      child: Text(
        title,
        style: TextStyle(
          fontSize: compact ? 11.5 : 12.5,
          fontWeight: FontWeight.w600,
          color: AppTokens.labelTertiary(context),
        ),
      ),
    );
  }

  Widget _buildCompactSidebarList(
    BuildContext context,
    AppLocalizations l10n, {
    required List<Conversation> pinned,
    required List<Conversation> recent,
    required String? highlightId,
  }) {
    return ListView(
      padding: const EdgeInsets.fromLTRB(8, 2, 8, 12),
      children: [
        if (pinned.isNotEmpty) ...[
          _buildSectionTitle(context, l10n.pinnedConversations, true),
          for (final c in pinned)
            _buildCompactRow(context, c, c.id == highlightId),
        ],
        if (recent.isNotEmpty) ...[
          if (pinned.isNotEmpty)
            _buildSectionTitle(context, l10n.recentConversations, true),
          for (final c in recent)
            _buildCompactRow(context, c, c.id == highlightId),
        ],
      ],
    );
  }

  Widget _buildCompactRow(
    BuildContext context,
    Conversation conversation,
    bool isSelected,
  ) {
    final fontFallback =
        cjkFontFallbackForLocale(Localizations.maybeLocaleOf(context));

    return GestureDetector(
      behavior: HitTestBehavior.opaque,
      onTap: () => _selectConversation(conversation),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 120),
        margin: const EdgeInsets.symmetric(vertical: 1.5),
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
        decoration: BoxDecoration(
          color: isSelected
              ? AppTokens.rowActive(context)
              : CupertinoColors.transparent,
          borderRadius: BorderRadius.circular(AppTokens.radiusSm),
        ),
        child: Row(
          children: [
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    conversation.title,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: TextStyle(
                      fontSize: 13.5,
                      fontWeight: isSelected
                          ? FontWeight.w600
                          : FontWeight.w500,
                      fontFamilyFallback: fontFallback,
                      color: AppTokens.label(context),
                    ),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    conversation.messages.isNotEmpty
                        ? '${_formatDate(conversation.updatedAt)} · ${conversation.messages.length}'
                        : _formatDate(conversation.updatedAt),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: TextStyle(
                      fontSize: 11.5,
                      color: AppTokens.labelTertiary(context),
                    ),
                  ),
                ],
              ),
            ),
            if (conversation.isPinned)
              Padding(
                padding: const EdgeInsets.only(right: 4),
                child: Icon(
                  CupertinoIcons.pin_fill,
                  size: 12,
                  color: AppTokens.accent(context),
                ),
              ),
            Builder(
              builder: (buttonContext) => CupertinoButton(
                padding: const EdgeInsets.all(4),
                minimumSize: const Size(24, 24),
                onPressed: () => _showConversationOptions(
                  conversation,
                  anchorContext: buttonContext,
                ),
                child: Icon(
                  CupertinoIcons.ellipsis,
                  size: 15,
                  color: AppTokens.labelSecondary(context),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildMobileGroupedList(
    BuildContext context,
    AppLocalizations l10n, {
    required List<Conversation> pinned,
    required List<Conversation> recent,
    required String? highlightId,
  }) {
    Widget groupCard(List<Conversation> items) {
      return Container(
        margin: const EdgeInsets.symmetric(horizontal: 16),
        clipBehavior: Clip.antiAlias,
        decoration: BoxDecoration(
          color: AppTokens.elevatedSurface(context),
          borderRadius: BorderRadius.circular(AppTokens.radiusMd),
        ),
        child: Column(
          children: [
            for (var i = 0; i < items.length; i++) ...[
              _buildMobileRow(context, items[i], items[i].id == highlightId),
              if (i < items.length - 1)
                Container(
                  height: 0.5,
                  margin: const EdgeInsets.only(left: 70),
                  color: AppTokens.separator(context),
                ),
            ],
          ],
        ),
      );
    }

    return ListView(
      padding: const EdgeInsets.only(bottom: 24),
      children: [
        if (pinned.isNotEmpty) ...[
          _buildSectionTitle(context, l10n.pinnedConversations, false),
          groupCard(pinned),
        ],
        if (recent.isNotEmpty) ...[
          _buildSectionTitle(context, l10n.recentConversations, false),
          groupCard(recent),
        ],
      ],
    );
  }

  Widget _buildMobileRow(
    BuildContext context,
    Conversation conversation,
    bool isSelected,
  ) {
    final fontFallback =
        cjkFontFallbackForLocale(Localizations.maybeLocaleOf(context));
    final hasPreset =
        conversation.promptPresetEnabled &&
        conversation.promptPresetId.isNotEmpty;

    return GestureDetector(
      behavior: HitTestBehavior.opaque,
      onTap: () => _selectConversation(conversation),
      onLongPress: () => _showConversationOptions(conversation),
      child: Container(
        color: isSelected ? AppTokens.rowActive(context) : null,
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 11),
        child: Row(
          children: [
            Container(
              width: 42,
              height: 42,
              decoration: BoxDecoration(
                color: hasPreset
                    ? AppTokens.accentSoft(context)
                    : AppTokens.fill(context),
                shape: BoxShape.circle,
              ),
              child: Icon(
                hasPreset
                    ? CupertinoIcons.person_fill
                    : CupertinoIcons.chat_bubble_2_fill,
                size: 19,
                color: hasPreset
                    ? AppTokens.accent(context)
                    : AppTokens.labelSecondary(context),
              ),
            ),
            const SizedBox(width: 14),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Expanded(
                        child: Text(
                          conversation.title,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: TextStyle(
                            fontSize: 15.5,
                            fontWeight: FontWeight.w600,
                            fontFamilyFallback: fontFallback,
                            color: AppTokens.label(context),
                          ),
                        ),
                      ),
                      const SizedBox(width: 8),
                      Text(
                        _formatDate(conversation.updatedAt),
                        style: TextStyle(
                          fontSize: 12.5,
                          color: AppTokens.labelTertiary(context),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 3),
                  Row(
                    children: [
                      Expanded(
                        child: Text(
                          conversation.messages.isNotEmpty
                              ? '${conversation.messages.length} msgs'
                              : _formatDate(conversation.updatedAt),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: TextStyle(
                            fontSize: 13,
                            color: AppTokens.labelSecondary(context),
                          ),
                        ),
                      ),
                      if (conversation.isPinned)
                        Padding(
                          padding: const EdgeInsets.only(right: 4),
                          child: Icon(
                            CupertinoIcons.pin_fill,
                            size: 13,
                            color: AppTokens.accent(context),
                          ),
                        ),
                    ],
                  ),
                ],
              ),
            ),
            CupertinoButton(
              padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 4),
              minimumSize: const Size(28, 28),
              onPressed: () => _showConversationOptions(conversation),
              child: Icon(
                CupertinoIcons.ellipsis,
                size: 17,
                color: AppTokens.labelSecondary(context),
              ),
            ),
            if (widget.isRootTab)
              Icon(
                CupertinoIcons.chevron_right,
                size: 15,
                color: AppTokens.labelTertiary(context),
              ),
          ],
        ),
      ),
    );
  }

  Widget _buildEmptyState() {
    final l10n = AppLocalizations.of(context)!;
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              CupertinoIcons.chat_bubble_2,
              size: 52,
              color: AppTokens.labelTertiary(context),
            ),
            const SizedBox(height: 14),
            Text(
              _searchQuery.isEmpty ? l10n.noConversations : l10n.searchNoResults,
              textAlign: TextAlign.center,
              style: TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.w500,
                color: AppTokens.labelSecondary(context),
              ),
            ),
            if (_searchQuery.isEmpty) ...[
              const SizedBox(height: 6),
              Text(
                l10n.createNewConversation,
                textAlign: TextAlign.center,
                style: TextStyle(
                  fontSize: 13,
                  color: AppTokens.labelTertiary(context),
                ),
              ),
              const SizedBox(height: 20),
              CupertinoButton.filled(
                borderRadius: BorderRadius.circular(20),
                onPressed: _createNewConversation,
                child: Text(l10n.newConversation),
              ),
            ],
          ],
        ),
      ),
    );
  }

  void _showConversationOptions(
    Conversation conversation, {
    BuildContext? anchorContext,
  }) {
    final l10n = AppLocalizations.of(context)!;
    if (anchorContext != null && useWideLayout(MediaQuery.sizeOf(context))) {
      showDesktopPopoverMenu(
        anchorContext: anchorContext,
        items: [
          DesktopPopoverItem(
            label: l10n.editTitle,
            icon: CupertinoIcons.pencil,
            onTap: () => _editConversationTitle(conversation),
          ),
          DesktopPopoverItem(
            label: conversation.isPinned
                ? l10n.unpinConversation
                : l10n.pinConversation,
            icon: conversation.isPinned
                ? CupertinoIcons.pin_slash
                : CupertinoIcons.pin,
            onTap: () => _togglePinned(conversation),
          ),
          DesktopPopoverItem(
            label: l10n.exportConversation,
            icon: CupertinoIcons.arrow_down_doc,
            onTap: () => _showExportFormatDialog(conversation),
          ),
          DesktopPopoverItem(
            label: l10n.deleteConversation2,
            icon: CupertinoIcons.delete,
            isDestructive: true,
            isDividerBefore: true,
            onTap: () => _deleteConversation(conversation),
          ),
        ],
      );
      return;
    }

    showCupertinoModalPopup(
      context: context,
      builder: (context) {
        final primaryColor = AppTokens.accent(context);
        final destructiveColor = AppTokens.red(context);
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
          bytes = await _conversationService.exportConversationArchive(
            conversation.id,
            l10n,
            includeCharacter: includePresetSnapshot,
          );
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
