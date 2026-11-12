import 'package:cupertino_ui/cupertino_ui.dart';
import 'package:intl/intl.dart';

import '../l10n/app_localizations.dart';
import '../models/conversation.dart';
import '../models/conversation_memory.dart';
import '../models/memory_note.dart';
import '../models/message.dart';
import '../models/prompt_preset.dart';
import '../models/roleplay_memory.dart';
import '../services/conversation_service.dart';
import '../utils/app_theme.dart';

/// 只读的会话记忆查看器。
///
/// 记忆本身是后台自动维护的；这个页面只把当前存储的内容展示出来，方便确认
/// AI 到底记住了什么。不提供编辑、删除或重新整理入口。
class MemoryViewerScreen extends StatefulWidget {
  const MemoryViewerScreen({
    super.key,
    required this.conversationId,
    this.conversationService,
    this.roleplayMode = false,
    this.preset,
  });

  final String conversationId;
  final ConversationService? conversationService;
  final bool roleplayMode;
  final PromptPreset? preset;

  @override
  State<MemoryViewerScreen> createState() => _MemoryViewerScreenState();
}

class _MemoryViewerScreenState extends State<MemoryViewerScreen> {
  late final ConversationService _conversationService;
  Conversation? _conversation;
  ConversationMemory? _memory;
  List<MemoryNote> _pendingNotes = const [];
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _conversationService = widget.conversationService ?? ConversationService();
    _load();
  }

  Future<void> _load() async {
    try {
      final conversation = await _conversationService.getConversationById(
        widget.conversationId,
      );
      final memory = await _conversationService.getConversationMemory(
        widget.conversationId,
      );
      final pendingNotes = await _conversationService.getMemoryNotes(
        widget.conversationId,
        onlyPending: true,
      );
      if (!mounted) return;
      setState(() {
        _conversation = conversation;
        _memory = memory;
        _pendingNotes = pendingNotes;
        _isLoading = false;
      });
    } catch (_) {
      if (!mounted) return;
      setState(() {
        _isLoading = false;
      });
    }
  }

  Future<void> _reload() async {
    if (_isLoading) return;
    setState(() {
      _isLoading = true;
    });
    await _load();
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final memory = _memory;

    return CupertinoPageScaffold(
      navigationBar: CupertinoNavigationBar(
        middle: Text(
          widget.roleplayMode
              ? l10n.memoryViewerRoleplayTitle
              : l10n.memoryViewerTitle,
        ),
        trailing: CupertinoButton(
          padding: EdgeInsets.zero,
          onPressed: _isLoading ? null : _reload,
          child: const Icon(CupertinoIcons.refresh),
        ),
      ),
      child: SafeArea(
        child: _isLoading
            ? const Center(child: CupertinoActivityIndicator())
            : widget.roleplayMode
            ? _buildRoleplay(
                context,
                l10n,
                memory ?? ConversationMemory.empty(),
                _pendingNotes,
              )
            : ((memory == null || memory.isEmpty) && _pendingNotes.isEmpty)
            ? _buildEmpty(context, l10n)
            : _buildContent(
                context,
                l10n,
                memory ?? ConversationMemory.empty(),
                _pendingNotes,
              ),
      ),
    );
  }

  Widget _buildEmpty(BuildContext context, AppLocalizations l10n) {
    final fallback = cjkFontFallbackForLocale(
      Localizations.maybeLocaleOf(context),
    );
    return Center(
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 36),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              CupertinoIcons.square_stack_3d_up,
              size: 56,
              color: CupertinoColors.systemGrey.resolveFrom(context),
            ),
            const SizedBox(height: 16),
            Text(
              l10n.memoryViewerEmptyTitle,
              textAlign: TextAlign.center,
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.w600,
                fontFamilyFallback: fallback,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              l10n.memoryViewerEmptyDesc,
              textAlign: TextAlign.center,
              style: TextStyle(
                fontSize: 14,
                height: 1.45,
                color: CupertinoColors.systemGrey.resolveFrom(context),
                fontFamilyFallback: fallback,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildContent(
    BuildContext context,
    AppLocalizations l10n,
    ConversationMemory memory,
    List<MemoryNote> pendingNotes,
  ) {
    final fallback = cjkFontFallbackForLocale(
      Localizations.maybeLocaleOf(context),
    );
    final children = <Widget>[];

    final updatedAt = memory.updatedAt;
    if (updatedAt != null) {
      children.add(
        Padding(
          padding: const EdgeInsets.only(left: 4, bottom: 12),
          child: Text(
            l10n.memoryViewerUpdatedAt(
              DateFormat.yMMMd().add_Hm().format(updatedAt.toLocal()),
            ),
            style: TextStyle(
              fontSize: 12,
              color: CupertinoColors.systemGrey.resolveFrom(context),
              fontFamilyFallback: fallback,
            ),
          ),
        ),
      );
    }

    final summary = memory.summary.trim();
    if (summary.isNotEmpty) {
      children.add(
        _section(
          context,
          l10n.memoryViewerSummary,
          _bodyText(context, summary, fallback),
        ),
      );
    }

    final emotionalState = memory.emotionalState.trim();
    if (emotionalState.isNotEmpty) {
      children.add(
        _section(
          context,
          l10n.memoryViewerEmotionalState,
          _bodyText(context, emotionalState, fallback),
        ),
      );
    }

    if (pendingNotes.isNotEmpty) {
      children.add(
        _section(
          context,
          l10n.memoryViewerPendingNotes,
          Column(
            children: [
              for (final note in pendingNotes)
                _noteTile(context, l10n, note, fallback),
            ],
          ),
        ),
      );
    }

    if (memory.activeFacts.isNotEmpty) {
      children.add(
        _section(
          context,
          l10n.memoryViewerFacts,
          Column(
            children: [
              for (final fact in memory.activeFacts)
                _factTile(context, fact, fallback),
            ],
          ),
        ),
      );
    }

    if (memory.supersededFacts.isNotEmpty) {
      children.add(
        _section(
          context,
          l10n.memoryViewerSupersededFacts,
          Column(
            children: [
              for (final fact in memory.supersededFacts)
                _factTile(context, fact, fallback, superseded: true),
            ],
          ),
        ),
      );
    }

    if (memory.visibleRejected.isNotEmpty) {
      children.add(
        _section(
          context,
          l10n.memoryViewerRejected,
          Column(
            children: [
              for (final entry in memory.visibleRejected)
                _rejectedTile(context, l10n, entry, fallback),
            ],
          ),
        ),
      );
    }

    children.add(
      Padding(
        padding: const EdgeInsets.fromLTRB(4, 4, 4, 24),
        child: Text(
          l10n.memoryViewerLocalOnly,
          style: TextStyle(
            fontSize: 12,
            height: 1.4,
            color: CupertinoColors.systemGrey.resolveFrom(context),
            fontFamilyFallback: fallback,
          ),
        ),
      ),
    );

    return ListView(
      padding: const EdgeInsets.fromLTRB(16, 16, 16, 8),
      children: children,
    );
  }

  Widget _buildRoleplay(
    BuildContext context,
    AppLocalizations l10n,
    ConversationMemory memory,
    List<MemoryNote> pendingNotes,
  ) {
    final fallback = cjkFontFallbackForLocale(
      Localizations.maybeLocaleOf(context),
    );
    final roleplay = memory.roleplay;
    final conversation = _conversation;
    final messages = conversation?.messages ?? const <Message>[];
    final name = _characterName(l10n, conversation);
    final description = _characterDescription();
    final stats = l10n.memoryViewerRoleplayStats(
      messages.length,
      _conversationMinutes(messages),
    );
    final primary = CupertinoTheme.of(context).primaryColor;
    final mood = (roleplay?.mood.trim().isNotEmpty ?? false)
        ? roleplay!.mood
        : memory.emotionalState;

    final newFactIds = roleplay?.newFactIds.toSet() ?? const <String>{};
    final newFacts = memory.activeFacts
        .where((fact) => newFactIds.contains(fact.id))
        .toList(growable: false);
    final otherFacts = memory.activeFacts
        .where((fact) => !newFactIds.contains(fact.id))
        .toList(growable: false);

    final children = <Widget>[
      _characterCard(context, name, description, stats, primary, fallback),
      Padding(
        padding: const EdgeInsets.only(bottom: 12),
        child: Row(
          children: [
            _statCard(
              context,
              l10n.memoryViewerRoleplayMood,
              mood,
              fallback,
            ),
            const SizedBox(width: 12),
            _statCard(
              context,
              l10n.memoryViewerRoleplayRelationship,
              roleplay?.relationshipStage ?? '',
              fallback,
            ),
          ],
        ),
      ),
      Padding(
        padding: const EdgeInsets.only(bottom: 12),
        child: Row(
          children: [
            _statCard(
              context,
              l10n.memoryViewerRoleplayScene,
              roleplay?.scene ?? '',
              fallback,
            ),
            const SizedBox(width: 12),
            _statCard(
              context,
              l10n.memoryViewerRoleplayStoryTime,
              roleplay?.storyTime ?? '',
              fallback,
            ),
          ],
        ),
      ),
    ];

    if (roleplay?.intimacy != null) {
      children.add(_intimacyCard(context, l10n, roleplay!, fallback));
    }

    final summary = memory.summary.trim();
    if (summary.isNotEmpty) {
      children.add(
        _roleplayCard(
          context,
          title: l10n.memoryViewerSummary,
          child: _bodyText(context, summary, fallback),
        ),
      );
    }

    if (newFacts.isNotEmpty) {
      children.add(
        _roleplayCard(
          context,
          title: l10n.memoryViewerRoleplayNewMemories,
          child: Column(
            children: [
              for (final fact in newFacts)
                _roleplayFactRow(context, l10n, fact, fallback),
            ],
          ),
        ),
      );
    }

    if (otherFacts.isNotEmpty) {
      children.add(
        _roleplayCard(
          context,
          title: l10n.memoryViewerFacts,
          child: Column(
            children: [
              for (final fact in otherFacts)
                _roleplayFactRow(context, l10n, fact, fallback),
            ],
          ),
        ),
      );
    }

    if (memory.visibleRejected.isNotEmpty) {
      children.add(
        _roleplayCard(
          context,
          title: l10n.memoryViewerRejected,
          child: Column(
            children: [
              for (final entry in memory.visibleRejected)
                _rejectedTile(context, l10n, entry, fallback),
            ],
          ),
        ),
      );
    }

    final unresolved = roleplay?.unresolved.trim() ?? '';
    if (unresolved.isNotEmpty) {
      children.add(
        _roleplayCard(
          context,
          title: l10n.memoryViewerRoleplayUnresolved,
          child: _bodyText(context, unresolved, fallback),
        ),
      );
    }

    if (pendingNotes.isNotEmpty) {
      children.add(
        _roleplayCard(
          context,
          title: l10n.memoryViewerPendingNotes,
          child: Column(
            children: [
              for (final note in pendingNotes)
                _noteTile(context, l10n, note, fallback),
            ],
          ),
        ),
      );
    }

    if (memory.isEmpty && pendingNotes.isEmpty) {
      children.add(
        _roleplayCard(
          context,
          child: _bodyText(
            context,
            l10n.memoryViewerRoleplayEmptyHint,
            fallback,
          ),
        ),
      );
    }

    children.add(
      Padding(
        padding: const EdgeInsets.fromLTRB(4, 4, 4, 16),
        child: Text(
          l10n.memoryViewerLocalOnly,
          style: TextStyle(
            fontSize: 12,
            height: 1.4,
            color: CupertinoColors.systemGrey.resolveFrom(context),
            fontFamilyFallback: fallback,
          ),
        ),
      ),
    );

    return ListView(
      padding: const EdgeInsets.fromLTRB(16, 16, 16, 8),
      children: children,
    );
  }

  String _characterName(AppLocalizations l10n, Conversation? conversation) {
    final presetName = widget.preset?.name.trim() ?? '';
    if (presetName.isNotEmpty) return presetName;
    final title = conversation?.title.trim() ?? '';
    if (title.isNotEmpty) return title;
    return l10n.aiAssistant;
  }

  String _characterDescription() {
    final preset = widget.preset;
    if (preset == null) return '';
    final description = preset.description.trim();
    if (description.isNotEmpty) return description;
    return preset.tags.where((tag) => tag.trim().isNotEmpty).join(' · ');
  }

  int _conversationMinutes(List<Message> messages) {
    if (messages.length < 2) return 0;
    final seconds = messages.last.timestamp
        .difference(messages.first.timestamp)
        .inSeconds;
    if (seconds <= 0) return 0;
    return (seconds / 60).ceil().clamp(1, 999);
  }

  Widget _characterCard(
    BuildContext context,
    String name,
    String description,
    String stats,
    Color primary,
    List<String> fallback,
  ) {
    final initial = name.trim().isEmpty
        ? '?'
        : String.fromCharCode(name.trim().runes.first);
    return _roleplayCard(
      context,
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            width: 72,
            height: 72,
            alignment: Alignment.center,
            decoration: BoxDecoration(color: primary, shape: BoxShape.circle),
            child: Text(
              initial,
              style: TextStyle(
                color: CupertinoColors.white,
                fontSize: 30,
                fontWeight: FontWeight.w600,
                fontFamilyFallback: fallback,
              ),
            ),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  name,
                  style: TextStyle(
                    fontSize: 22,
                    fontWeight: FontWeight.w700,
                    fontFamilyFallback: fallback,
                  ),
                ),
                if (description.isNotEmpty) ...[
                  const SizedBox(height: 4),
                  Text(
                    description,
                    style: TextStyle(
                      fontSize: 14,
                      height: 1.35,
                      color: CupertinoColors.systemGrey.resolveFrom(context),
                      fontFamilyFallback: fallback,
                    ),
                  ),
                ],
                const SizedBox(height: 6),
                Text(
                  stats,
                  style: TextStyle(
                    fontSize: 12,
                    color: CupertinoColors.systemGrey.resolveFrom(context),
                    fontFamilyFallback: fallback,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _roleplayCard(
    BuildContext context, {
    String? title,
    required Widget child,
  }) {
    final fallback = cjkFontFallbackForLocale(
      Localizations.maybeLocaleOf(context),
    );
    return Container(
      width: double.infinity,
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: CupertinoColors.systemGrey6.resolveFrom(context),
        borderRadius: BorderRadius.circular(16),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          if (title != null) ...[
            Text(
              title,
              style: TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.w600,
                fontFamilyFallback: fallback,
              ),
            ),
            const SizedBox(height: 10),
          ],
          child,
        ],
      ),
    );
  }

  Widget _statCard(
    BuildContext context,
    String label,
    String value,
    List<String> fallback,
  ) {
    return Expanded(
      child: Container(
        padding: const EdgeInsets.all(14),
        decoration: BoxDecoration(
          color: CupertinoColors.systemGrey6.resolveFrom(context),
          borderRadius: BorderRadius.circular(16),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              label,
              style: TextStyle(
                fontSize: 13,
                color: CupertinoColors.systemGrey.resolveFrom(context),
                fontFamilyFallback: fallback,
              ),
            ),
            const SizedBox(height: 6),
            Text(
              value.trim().isEmpty ? '—' : value.trim(),
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.w600,
                fontFamilyFallback: fallback,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _intimacyCard(
    BuildContext context,
    AppLocalizations l10n,
    RoleplayMemory roleplay,
    List<String> fallback,
  ) {
    final intimacy = roleplay.intimacy!;
    final previous = roleplay.previousIntimacy;
    final String value;
    if (previous == null || previous == intimacy) {
      value = '$intimacy';
    } else {
      final delta = intimacy - previous;
      value = '$previous → $intimacy (${delta > 0 ? '+$delta' : '$delta'})';
    }
    final note = roleplay.intimacyNote.trim();
    final primary = CupertinoTheme.of(context).primaryColor;

    return _roleplayCard(
      context,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Expanded(
                child: Text(
                  l10n.memoryViewerRoleplayIntimacy,
                  style: TextStyle(
                    fontSize: 13,
                    color: CupertinoColors.systemGrey.resolveFrom(context),
                    fontFamilyFallback: fallback,
                  ),
                ),
              ),
              Text(
                value,
                style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.w600,
                  fontFamilyFallback: fallback,
                ),
              ),
            ],
          ),
          const SizedBox(height: 10),
          LayoutBuilder(
            builder: (context, constraints) {
              return Container(
                height: 8,
                decoration: BoxDecoration(
                  color: CupertinoColors.systemGrey4.resolveFrom(context),
                  borderRadius: BorderRadius.circular(4),
                ),
                child: Align(
                  alignment: Alignment.centerLeft,
                  child: Container(
                    width:
                        constraints.maxWidth *
                        (intimacy / 100).clamp(0.0, 1.0),
                    decoration: BoxDecoration(
                      color: primary,
                      borderRadius: BorderRadius.circular(4),
                    ),
                  ),
                ),
              );
            },
          ),
          if (note.isNotEmpty) ...[
            const SizedBox(height: 10),
            Text(
              note,
              style: TextStyle(
                fontSize: 14,
                height: 1.4,
                fontFamilyFallback: fallback,
              ),
            ),
          ],
        ],
      ),
    );
  }

  Widget _roleplayFactRow(
    BuildContext context,
    AppLocalizations l10n,
    MemoryFact fact,
    List<String> fallback,
  ) {
    final quote = fact.quote?.trim() ?? '';
    final text = quote.isNotEmpty ? quote : fact.text.trim();
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _factKindBadge(context, l10n, fact.kind, fallback),
          const SizedBox(width: 8),
          Expanded(
            child: Text(
              text,
              style: TextStyle(
                fontSize: 15,
                height: 1.35,
                fontFamilyFallback: fallback,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _factKindBadge(
    BuildContext context,
    AppLocalizations l10n,
    MemoryFactKind kind,
    List<String> fallback,
  ) {
    final (String label, CupertinoDynamicColor color) = switch (kind) {
      MemoryFactKind.agreement => (
        l10n.memoryKindAgreement,
        CupertinoColors.systemPink,
      ),
      MemoryFactKind.rule => (l10n.memoryKindRule, CupertinoColors.systemOrange),
      MemoryFactKind.fact => (l10n.memoryKindFact, CupertinoColors.systemBlue),
      MemoryFactKind.decision => (
        l10n.memoryKindDecision,
        CupertinoColors.activeGreen,
      ),
    };
    return _badge(context, label, color, fallback);
  }

  Widget _badge(
    BuildContext context,
    String label,
    CupertinoDynamicColor color,
    List<String> fallback,
  ) {
    final resolved = color.resolveFrom(context);
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
      decoration: BoxDecoration(
        color: resolved.withValues(alpha: 0.14),
        borderRadius: BorderRadius.circular(8),
      ),
      child: Text(
        label,
        style: TextStyle(
          fontSize: 12,
          color: resolved,
          fontFamilyFallback: fallback,
        ),
      ),
    );
  }

  Widget _section(BuildContext context, String title, Widget child) {
    final fallback = cjkFontFallbackForLocale(
      Localizations.maybeLocaleOf(context),
    );
    return Padding(
      padding: const EdgeInsets.only(bottom: 16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Padding(
            padding: const EdgeInsets.only(left: 4, bottom: 6),
            child: Text(
              title,
              style: TextStyle(
                fontSize: 13,
                fontWeight: FontWeight.w600,
                color: CupertinoColors.systemGrey.resolveFrom(context),
                fontFamilyFallback: fallback,
              ),
            ),
          ),
          Container(
            width: double.infinity,
            padding: const EdgeInsets.all(14),
            decoration: BoxDecoration(
              color: CupertinoColors.systemGrey6.resolveFrom(context),
              borderRadius: BorderRadius.circular(12),
            ),
            child: child,
          ),
        ],
      ),
    );
  }

  Widget _bodyText(BuildContext context, String text, List<String> fallback) {
    return Text(
      text,
      style: TextStyle(
        fontSize: 15,
        height: 1.45,
        fontFamilyFallback: fallback,
      ),
    );
  }

  Widget _noteTile(
    BuildContext context,
    AppLocalizations l10n,
    MemoryNote note,
    List<String> fallback,
  ) {
    final quote = note.quote?.trim() ?? '';
    final text = quote.isNotEmpty ? quote : note.text.trim();
    final reason = note.reason?.trim() ?? '';
    return Padding(
      padding: const EdgeInsets.only(bottom: 10),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              _kindBadge(context, l10n, note.kind, fallback),
              const SizedBox(width: 8),
              Expanded(
                child: Text(
                  text,
                  style: TextStyle(
                    fontSize: 15,
                    height: 1.35,
                    fontFamilyFallback: fallback,
                  ),
                ),
              ),
            ],
          ),
          if (reason.isNotEmpty) ...[
            const SizedBox(height: 3),
            Text(
              reason,
              style: TextStyle(
                fontSize: 13,
                height: 1.35,
                color: CupertinoColors.systemGrey.resolveFrom(context),
                fontFamilyFallback: fallback,
              ),
            ),
          ],
        ],
      ),
    );
  }

  Widget _kindBadge(
    BuildContext context,
    AppLocalizations l10n,
    MemoryNoteKind kind,
    List<String> fallback,
  ) {
    final (String label, CupertinoDynamicColor color) = switch (kind) {
      MemoryNoteKind.agreement => (
        l10n.memoryKindAgreement,
        CupertinoColors.systemPink,
      ),
      MemoryNoteKind.fact => (l10n.memoryKindFact, CupertinoColors.systemBlue),
      MemoryNoteKind.decision => (
        l10n.memoryKindDecision,
        CupertinoColors.activeGreen,
      ),
      MemoryNoteKind.emotion => (
        l10n.memoryKindEmotion,
        CupertinoColors.systemOrange,
      ),
      MemoryNoteKind.rejected => (
        l10n.memoryKindRejected,
        CupertinoColors.systemRed,
      ),
    };
    return _badge(context, label, color, fallback);
  }

  Widget _factTile(
    BuildContext context,
    MemoryFact fact,
    List<String> fallback, {
    bool superseded = false,
  }) {
    final quote = fact.quote?.trim() ?? '';
    final text = quote.isNotEmpty ? '“$quote”' : fact.text.trim();
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Padding(
            padding: const EdgeInsets.only(top: 2),
            child: Icon(
              superseded
                  ? CupertinoIcons.xmark
                  : CupertinoIcons.checkmark_alt,
              size: 15,
              color: superseded
                  ? CupertinoColors.systemGrey.resolveFrom(context)
                  : CupertinoColors.activeGreen.resolveFrom(context),
            ),
          ),
          const SizedBox(width: 8),
          Expanded(
            child: Text(
              text,
              style: TextStyle(
                fontSize: 15,
                height: 1.35,
                fontFamilyFallback: fallback,
                decoration: superseded ? TextDecoration.lineThrough : null,
                color: superseded
                    ? CupertinoColors.systemGrey.resolveFrom(context)
                    : null,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _rejectedTile(
    BuildContext context,
    AppLocalizations l10n,
    RejectedProposal entry,
    List<String> fallback,
  ) {
    final reopened = entry.status == RejectedStatus.reopened;
    final reason = entry.reason.trim();
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Expanded(
                child: Text(
                  entry.proposal,
                  style: TextStyle(
                    fontSize: 15,
                    height: 1.35,
                    fontWeight: FontWeight.w500,
                    fontFamilyFallback: fallback,
                  ),
                ),
              ),
              if (reopened) ...[
                const SizedBox(width: 8),
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 6,
                    vertical: 2,
                  ),
                  decoration: BoxDecoration(
                    color: CupertinoColors.systemOrange
                        .resolveFrom(context)
                        .withValues(alpha: 0.14),
                    borderRadius: BorderRadius.circular(6),
                  ),
                  child: Text(
                    l10n.memoryViewerReopened,
                    style: TextStyle(
                      fontSize: 11,
                      color: CupertinoColors.systemOrange.resolveFrom(context),
                      fontFamilyFallback: fallback,
                    ),
                  ),
                ),
              ],
            ],
          ),
          if (reason.isNotEmpty) ...[
            const SizedBox(height: 2),
            Text(
              reason,
              style: TextStyle(
                fontSize: 13,
                height: 1.35,
                color: CupertinoColors.systemGrey.resolveFrom(context),
                fontFamilyFallback: fallback,
              ),
            ),
          ],
        ],
      ),
    );
  }
}
