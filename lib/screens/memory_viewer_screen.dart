import 'package:cupertino_ui/cupertino_ui.dart';
import 'package:intl/intl.dart';

import '../l10n/app_localizations.dart';
import '../models/conversation_memory.dart';
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
  });

  final String conversationId;
  final ConversationService? conversationService;

  @override
  State<MemoryViewerScreen> createState() => _MemoryViewerScreenState();
}

class _MemoryViewerScreenState extends State<MemoryViewerScreen> {
  late final ConversationService _conversationService;
  ConversationMemory? _memory;
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _conversationService = widget.conversationService ?? ConversationService();
    _load();
  }

  Future<void> _load() async {
    try {
      final memory = await _conversationService.getConversationMemory(
        widget.conversationId,
      );
      if (!mounted) return;
      setState(() {
        _memory = memory;
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
        middle: Text(l10n.memoryViewerTitle),
        trailing: CupertinoButton(
          padding: EdgeInsets.zero,
          onPressed: _isLoading ? null : _reload,
          child: const Icon(CupertinoIcons.refresh),
        ),
      ),
      child: SafeArea(
        child: _isLoading
            ? const Center(child: CupertinoActivityIndicator())
            : (memory == null || memory.isEmpty)
            ? _buildEmpty(context, l10n)
            : _buildContent(context, l10n, memory),
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
