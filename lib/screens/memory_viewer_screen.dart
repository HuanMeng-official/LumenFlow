import 'package:cupertino_ui/cupertino_ui.dart';
import 'package:intl/intl.dart';

import '../l10n/app_localizations.dart';
import '../models/character_growth.dart';
import '../models/conversation.dart';
import '../models/conversation_memory.dart';
import '../models/memory_note.dart';
import '../models/message.dart';
import '../models/prompt_preset.dart';
import '../models/roleplay_memory.dart';
import '../services/character_growth_engine.dart';
import '../services/conversation_service.dart';
import '../utils/app_theme.dart';
import '../utils/platform_utils.dart';
import '../widgets/desktop/desktop_popover.dart';
import '../widgets/preset_avatar.dart';

/// 会话记忆查看器与单会话成长面板。
///
/// 普通记忆由后台自动维护；成长型角色卡可在此查看阶段、成长指标、里程碑，
/// 并支持手动切换阶段、锁定自动成长或重置本会话成长进度。
class MemoryViewerScreen extends StatefulWidget {
  const MemoryViewerScreen({
    super.key,
    required this.conversationId,
    this.conversationService,
    this.roleplayMode = false,
    this.preset,
    this.embedded = false,
    this.memoryCompressionEnabled = true,
    this.revision = 0,
    this.onMemoryChanged,
  });

  final String conversationId;
  final ConversationService? conversationService;
  final bool roleplayMode;
  final PromptPreset? preset;
  final bool embedded;
  final bool memoryCompressionEnabled;
  final int revision;
  final VoidCallback? onMemoryChanged;

  @override
  State<MemoryViewerScreen> createState() => _MemoryViewerScreenState();
}

class _MemoryViewerScreenState extends State<MemoryViewerScreen> {
  late final ConversationService _conversationService;
  Conversation? _conversation;
  ConversationMemory? _memory;
  List<MemoryNote> _pendingNotes = const [];
  bool _isLoading = true;
  int _milestoneCounter = 0;

  @override
  void initState() {
    super.initState();
    _conversationService = widget.conversationService ?? ConversationService();
    _load();
  }

  @override
  void didUpdateWidget(covariant MemoryViewerScreen oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.conversationId != widget.conversationId ||
        oldWidget.roleplayMode != widget.roleplayMode ||
        oldWidget.preset?.id != widget.preset?.id) {
      _reload();
    } else if (oldWidget.revision != widget.revision) {
      _load();
    }
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
    final body = _isLoading
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
          );

    if (widget.embedded) {
      return body;
    }

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
      child: SafeArea(child: body),
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
      padding: widget.embedded
          ? const EdgeInsets.fromLTRB(12, 12, 12, 8)
          : const EdgeInsets.fromLTRB(16, 16, 16, 8),
      children: children,
    );
  }

  Future<void> _saveRoleplayGrowth(RoleplayMemory nextRoleplay) async {
    final base = _memory ?? ConversationMemory.empty();
    final updated = base.copyWith(
      roleplay: nextRoleplay,
      updatedAt: DateTime.now(),
    );
    await _conversationService.saveConversationMemory(
      widget.conversationId,
      updated,
    );
    if (!mounted) return;
    setState(() {
      _memory = updated;
    });
    widget.onMemoryChanged?.call();
  }

  Future<void> _showStagePicker(
    BuildContext context,
    AppLocalizations l10n,
    CharacterGrowthConfig config,
    RoleplayMemory currentRoleplay, {
    BuildContext? anchorContext,
  }) async {
    final currentStage = CharacterGrowthEngine.currentStage(
      config,
      currentRoleplay,
    );
    void selectStage(GrowthStage stage) {
      if (stage.id == currentStage.id) return;
      final next = CharacterGrowthEngine.applyManualStageSwitch(
        config: config,
        current: currentRoleplay,
        targetStageId: stage.id,
        reason: l10n.growthManualSwitchReason,
        nextMilestoneId: () =>
            'ms_manual_${DateTime.now().microsecondsSinceEpoch}_${_milestoneCounter++}',
      );
      _saveRoleplayGrowth(next);
    }

    if (anchorContext != null &&
        anchorContext.mounted &&
        useWideLayout(MediaQuery.sizeOf(context))) {
      await showDesktopPopoverMenu(
        anchorContext: anchorContext,
        alignRight: true,
        width: 240,
        items: [
          for (final stage in config.stages)
            DesktopPopoverItem(
              label: stage.isEnding
                  ? '${stage.name} · ${l10n.growthEndingBadge}'
                  : stage.name,
              selected: stage.id == currentStage.id,
              onTap: () => selectStage(stage),
            ),
        ],
      );
      return;
    }

    await showCupertinoModalPopup<void>(
      context: context,
      builder: (sheetContext) => CupertinoActionSheet(
        title: Text(l10n.growthSwitchStageTitle),
        actions: [
          for (final stage in config.stages)
            CupertinoActionSheetAction(
              onPressed: () {
                Navigator.pop(sheetContext);
                selectStage(stage);
              },
              child: Text(
                '${stage.name}'
                '${stage.isEnding ? ' · ${l10n.growthEndingBadge}' : ''}'
                '${stage.id == currentStage.id ? ' ✓' : ''}',
              ),
            ),
        ],
        cancelButton: CupertinoActionSheetAction(
          onPressed: () => Navigator.pop(sheetContext),
          child: Text(l10n.cancel),
        ),
      ),
    );
  }

  Future<void> _confirmResetGrowth(
    BuildContext context,
    AppLocalizations l10n,
    CharacterGrowthConfig config,
    RoleplayMemory currentRoleplay,
  ) async {
    final confirmed = await showCupertinoDialog<bool>(
      context: context,
      builder: (dialogContext) => CupertinoAlertDialog(
        title: Text(l10n.growthResetTitle),
        content: Text(l10n.growthResetConfirm),
        actions: [
          CupertinoDialogAction(
            onPressed: () => Navigator.pop(dialogContext, false),
            child: Text(l10n.cancel),
          ),
          CupertinoDialogAction(
            isDestructiveAction: true,
            onPressed: () => Navigator.pop(dialogContext, true),
            child: Text(l10n.confirm),
          ),
        ],
      ),
    );
    if (confirmed != true) return;
    final reset = CharacterGrowthEngine.resetGrowth(config, currentRoleplay);
    await _saveRoleplayGrowth(reset);
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
    final growthConfig = widget.preset?.growthConfig;
    final roleplay = growthConfig != null
        ? CharacterGrowthEngine.ensureInitialized(memory.roleplay, growthConfig)
        : memory.roleplay;
    final currentStage = growthConfig != null
        ? CharacterGrowthEngine.currentStage(growthConfig, roleplay)
        : null;
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
      _characterCard(
        context,
        l10n,
        name,
        description,
        stats,
        primary,
        fallback,
        growthConfig: growthConfig,
        currentStage: currentStage,
        growthLocked: roleplay?.growthLocked ?? false,
      ),
      if (growthConfig != null && !widget.memoryCompressionEnabled)
        Container(
          width: double.infinity,
          margin: const EdgeInsets.only(bottom: 12),
          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
          decoration: BoxDecoration(
            color: CupertinoColors.systemOrange
                .resolveFrom(context)
                .withValues(alpha: 0.12),
            borderRadius: BorderRadius.circular(12),
          ),
          child: Text(
            l10n.growthMemoryCompressionOffHint,
            style: TextStyle(
              fontSize: 12.5,
              height: 1.45,
              color: CupertinoColors.systemOrange.resolveFrom(context),
              fontFamilyFallback: fallback,
            ),
          ),
        ),
      _statusOverviewCard(
        context,
        rows: [
          (l10n.memoryViewerRoleplayMood, mood),
          if (growthConfig == null)
            (
              l10n.memoryViewerRoleplayRelationship,
              roleplay?.relationshipStage ?? '',
            ),
          (l10n.memoryViewerRoleplayScene, roleplay?.scene ?? ''),
          (l10n.memoryViewerRoleplayStoryTime, roleplay?.storyTime ?? ''),
        ],
        fallback: fallback,
      ),
    ];

    final customNickname = roleplay?.customNickname.trim() ?? '';
    if (customNickname.isNotEmpty) {
      children.add(
        _roleplayCard(
          context,
          title: l10n.growthCustomNickname,
          child: _bodyText(context, customNickname, fallback),
        ),
      );
    }

    final characterState = roleplay?.characterState.trim() ?? '';
    if (characterState.isNotEmpty) {
      children.add(
        _roleplayCard(
          context,
          title: l10n.memoryViewerRoleplayCharacterState,
          child: _bodyText(context, characterState, fallback),
        ),
      );
    }

    if (growthConfig != null && roleplay != null) {
      children.add(
        _growthMetricsCard(context, l10n, growthConfig, roleplay, fallback),
      );
      children.add(
        _growthMilestonesCard(context, l10n, growthConfig, roleplay, fallback),
      );
      children.add(
        _growthControlsCard(context, l10n, growthConfig, roleplay, fallback),
      );
    } else if (roleplay?.intimacy != null) {
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

    if (memory.isEmpty && pendingNotes.isEmpty && growthConfig == null) {
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
          growthConfig != null
              ? '${l10n.growthPlaythroughNote}\n${l10n.memoryViewerLocalOnly}'
              : l10n.memoryViewerLocalOnly,
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
      padding: widget.embedded
          ? const EdgeInsets.fromLTRB(12, 12, 12, 8)
          : const EdgeInsets.fromLTRB(16, 16, 16, 8),
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
    AppLocalizations l10n,
    String name,
    String description,
    String stats,
    Color primary,
    List<String> fallback, {
    CharacterGrowthConfig? growthConfig,
    GrowthStage? currentStage,
    bool growthLocked = false,
  }) {
    final preset = widget.preset;
    final initial = name.trim().isEmpty
        ? '?'
        : String.fromCharCode(name.trim().runes.first);
    final stageIndex = (growthConfig != null && currentStage != null)
        ? growthConfig.stageIndex(currentStage.id)
        : -1;
    final avatarSize = widget.embedded ? 52.0 : 64.0;
    final titleFontSize = widget.embedded ? 18.0 : 21.0;
    final secondaryColor = AppTokens.labelSecondary(context);
    final stageSummary = currentStage?.summary.trim() ?? '';

    return _roleplayCard(
      context,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              if (preset != null)
                PresetAvatar(
                  preset: preset,
                  stageId: currentStage?.id,
                  size: avatarSize,
                  iconColor: CupertinoColors.white,
                  backgroundColor: primary,
                )
              else
                Container(
                  width: avatarSize,
                  height: avatarSize,
                  alignment: Alignment.center,
                  decoration: BoxDecoration(
                    color: primary,
                    shape: BoxShape.circle,
                  ),
                  child: Text(
                    initial,
                    style: TextStyle(
                      color: CupertinoColors.white,
                      fontSize: widget.embedded ? 22 : 26,
                      fontWeight: FontWeight.w600,
                      fontFamilyFallback: fallback,
                    ),
                  ),
                ),
              const SizedBox(width: 14),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      name,
                      style: TextStyle(
                        fontSize: titleFontSize,
                        fontWeight: FontWeight.w700,
                        fontFamilyFallback: fallback,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      stats,
                      style: TextStyle(
                        fontSize: 12.5,
                        color: secondaryColor,
                        fontFamilyFallback: fallback,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
          if (description.isNotEmpty) ...[
            const SizedBox(height: 12),
            Text(
              description,
              style: TextStyle(
                fontSize: 13.5,
                height: 1.48,
                color: secondaryColor,
                fontFamilyFallback: fallback,
              ),
            ),
          ],
          if (currentStage != null && growthConfig != null) ...[
            const SizedBox(height: 12),
            Wrap(
              spacing: 6,
              runSpacing: 6,
              children: [
                _pillBadge(
                  context,
                  stageIndex >= 0
                      ? 'Stage ${stageIndex + 1}/${growthConfig.stages.length} · ${currentStage.name}'
                      : currentStage.name,
                  primary,
                  fallback,
                ),
                if (currentStage.isEnding)
                  _pillBadge(
                    context,
                    l10n.growthEndingBadge,
                    CupertinoColors.systemPurple.resolveFrom(context),
                    fallback,
                  ),
                if (growthLocked)
                  _pillBadge(
                    context,
                    l10n.growthLockedBadge,
                    CupertinoColors.systemOrange.resolveFrom(context),
                    fallback,
                  ),
              ],
            ),
            if (stageSummary.isNotEmpty) ...[
              const SizedBox(height: 8),
              Text(
                stageSummary,
                style: TextStyle(
                  fontSize: 12.5,
                  height: 1.48,
                  color: secondaryColor,
                  fontFamilyFallback: fallback,
                ),
              ),
            ],
          ],
        ],
      ),
    );
  }

  Widget _pillBadge(
    BuildContext context,
    String text,
    Color color,
    List<String> fallback,
  ) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.14),
        borderRadius: BorderRadius.circular(8),
      ),
      child: Text(
        text,
        style: TextStyle(
          fontSize: 11.5,
          fontWeight: FontWeight.w600,
          color: color,
          fontFamilyFallback: fallback,
        ),
      ),
    );
  }

  Widget _growthMetricsCard(
    BuildContext context,
    AppLocalizations l10n,
    CharacterGrowthConfig config,
    RoleplayMemory roleplay,
    List<String> fallback,
  ) {
    final primary = CupertinoTheme.of(context).primaryColor;
    final intimacy = (roleplay.intimacy ?? config.initialIntimacy).clamp(
      0,
      100,
    );
    final prevIntimacy = roleplay.previousIntimacy;
    final intimacyLabel = config.intimacyLabel.trim().isNotEmpty
        ? config.intimacyLabel.trim()
        : l10n.memoryViewerRoleplayIntimacy;
    final visibleMetrics = config.metrics
        .where((metric) => !metric.hidden)
        .toList(growable: false);

    return _roleplayCard(
      context,
      title: l10n.growthMetricsSection,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _metricBarRow(
            context,
            label: intimacyLabel,
            description: roleplay.intimacyNote.trim().isNotEmpty
                ? roleplay.intimacyNote.trim()
                : config.intimacyDescription.trim(),
            value: intimacy,
            previous: prevIntimacy,
            min: 0,
            max: 100,
            color: primary,
            fallback: fallback,
          ),
          for (final metric in visibleMetrics) ...[
            Padding(
              padding: const EdgeInsets.symmetric(vertical: 14),
              child: Container(
                height: 0.5,
                color: AppTokens.separator(context),
              ),
            ),
            _metricBarRow(
              context,
              label: metric.name,
              description: metric.description.trim(),
              value: (roleplay.customMetrics[metric.id] ?? metric.initial)
                  .clamp(metric.min, metric.max),
              previous: roleplay.previousCustomMetrics[metric.id],
              min: metric.min,
              max: metric.max,
              color: AppTokens.accent(context),
              fallback: fallback,
            ),
          ],
        ],
      ),
    );
  }

  Widget _metricBarRow(
    BuildContext context, {
    required String label,
    required String description,
    required int value,
    required int? previous,
    required int min,
    required int max,
    required Color color,
    required List<String> fallback,
  }) {
    final String formatted;
    if (previous == null || previous == value) {
      formatted = '$value';
    } else {
      final delta = value - previous;
      formatted = '$previous → $value (${delta > 0 ? '+$delta' : '$delta'})';
    }
    final ratio = max > min ? ((value - min) / (max - min)).clamp(0.0, 1.0) : 0.0;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Expanded(
              child: Text(
                label,
                style: TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.w600,
                  color: AppTokens.label(context),
                  fontFamilyFallback: fallback,
                ),
              ),
            ),
            Text(
              formatted,
              style: TextStyle(
                fontSize: 14,
                fontWeight: FontWeight.w600,
                color: AppTokens.label(context),
                fontFamilyFallback: fallback,
              ),
            ),
          ],
        ),
        const SizedBox(height: 8),
        LayoutBuilder(
          builder: (context, constraints) {
            return Container(
              height: 7,
              decoration: BoxDecoration(
                color: CupertinoColors.systemGrey4.resolveFrom(context),
                borderRadius: BorderRadius.circular(4),
              ),
              child: Align(
                alignment: Alignment.centerLeft,
                child: Container(
                  width: constraints.maxWidth * ratio,
                  decoration: BoxDecoration(
                    color: color,
                    borderRadius: BorderRadius.circular(4),
                  ),
                ),
              ),
            );
          },
        ),
        if (description.isNotEmpty) ...[
          const SizedBox(height: 8),
          Text(
            description,
            style: TextStyle(
              fontSize: 12.5,
              height: 1.5,
              color: AppTokens.labelSecondary(context),
              fontFamilyFallback: fallback,
            ),
          ),
        ],
      ],
    );
  }

  Widget _growthMilestonesCard(
    BuildContext context,
    AppLocalizations l10n,
    CharacterGrowthConfig config,
    RoleplayMemory roleplay,
    List<String> fallback,
  ) {
    final milestones = roleplay.milestones;
    final primary = CupertinoTheme.of(context).primaryColor;
    final secondary = CupertinoColors.systemGrey.resolveFrom(context);

    return _roleplayCard(
      context,
      title: l10n.growthMilestonesSection,
      child: milestones.isEmpty
          ? Text(
              l10n.growthMilestonesEmpty,
              style: TextStyle(
                fontSize: 13.5,
                height: 1.4,
                color: secondary,
                fontFamilyFallback: fallback,
              ),
            )
          : Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                for (var i = 0; i < milestones.length; i++) ...[
                  Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Padding(
                        padding: const EdgeInsets.only(top: 5),
                        child: Container(
                          width: 8,
                          height: 8,
                          decoration: BoxDecoration(
                            color: i == milestones.length - 1
                                ? primary
                                : secondary.withValues(alpha: 0.55),
                            shape: BoxShape.circle,
                          ),
                        ),
                      ),
                      const SizedBox(width: 10),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              milestones[i].title,
                              style: TextStyle(
                                fontSize: 14,
                                fontWeight: FontWeight.w600,
                                color: AppTokens.label(context),
                                fontFamilyFallback: fallback,
                              ),
                            ),
                            const SizedBox(height: 2),
                            Text(
                              '${config.stageById(milestones[i].fromStageId)?.name ?? milestones[i].fromStageId} → '
                              '${config.stageById(milestones[i].toStageId)?.name ?? milestones[i].toStageId}',
                              style: TextStyle(
                                fontSize: 12,
                                color: primary,
                                fontFamilyFallback: fallback,
                              ),
                            ),
                            if (milestones[i].reason.trim().isNotEmpty) ...[
                              const SizedBox(height: 3),
                              Text(
                                milestones[i].reason.trim(),
                                style: TextStyle(
                                  fontSize: 12.5,
                                  height: 1.35,
                                  color: secondary,
                                  fontFamilyFallback: fallback,
                                ),
                              ),
                            ],
                          ],
                        ),
                      ),
                    ],
                  ),
                  if (i < milestones.length - 1) const SizedBox(height: 12),
                ],
              ],
            ),
    );
  }

  Widget _growthControlsCard(
    BuildContext context,
    AppLocalizations l10n,
    CharacterGrowthConfig config,
    RoleplayMemory roleplay,
    List<String> fallback,
  ) {
    final currentStage = CharacterGrowthEngine.currentStage(config, roleplay);
    final separator = AppTokens.separator(context);
    final secondary = CupertinoColors.systemGrey.resolveFrom(context);

    return _roleplayCard(
      context,
      title: l10n.growthControlsSection,
      child: Column(
        children: [
          Builder(
            builder: (anchorContext) => GestureDetector(
              behavior: HitTestBehavior.opaque,
              onTap: () => _showStagePicker(
                context,
                l10n,
                config,
                roleplay,
                anchorContext: anchorContext,
              ),
              child: Padding(
                padding: const EdgeInsets.symmetric(vertical: 6),
                child: Row(
                  children: [
                    Text(
                      l10n.growthSwitchStage,
                      style: TextStyle(
                        fontSize: 14,
                        color: AppTokens.label(context),
                        fontFamilyFallback: fallback,
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Text(
                        currentStage.name,
                        textAlign: TextAlign.right,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: TextStyle(
                          fontSize: 13.5,
                          color: secondary,
                          fontFamilyFallback: fallback,
                        ),
                      ),
                    ),
                    const SizedBox(width: 4),
                    Icon(
                      CupertinoIcons.chevron_right,
                      size: 14,
                      color: secondary,
                    ),
                  ],
                ),
              ),
            ),
          ),
          Container(
            height: 0.5,
            margin: const EdgeInsets.symmetric(vertical: 8),
            color: separator,
          ),
          Row(
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      l10n.growthLockAuto,
                      style: TextStyle(
                        fontSize: 14.5,
                        color: AppTokens.label(context),
                        fontFamilyFallback: fallback,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      l10n.growthLockAutoDesc,
                      style: TextStyle(
                        fontSize: 12.5,
                        height: 1.45,
                        color: secondary,
                        fontFamilyFallback: fallback,
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 12),
              CupertinoSwitch(
                value: roleplay.growthLocked,
                onChanged: (value) {
                  final next = CharacterGrowthEngine.setGrowthLocked(
                    config,
                    roleplay,
                    value,
                  );
                  _saveRoleplayGrowth(next);
                },
              ),
            ],
          ),
          Container(
            height: 0.5,
            margin: const EdgeInsets.symmetric(vertical: 8),
            color: separator,
          ),
          GestureDetector(
            behavior: HitTestBehavior.opaque,
            onTap: () => _confirmResetGrowth(context, l10n, config, roleplay),
            child: Padding(
              padding: const EdgeInsets.symmetric(vertical: 6),
              child: Row(
                children: [
                  Text(
                    l10n.growthResetAction,
                    style: TextStyle(
                      fontSize: 14.5,
                      color: AppTokens.red(context),
                      fontFamilyFallback: fallback,
                    ),
                  ),
                ],
              ),
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
      padding: EdgeInsets.all(widget.embedded ? 13 : 16),
      decoration: BoxDecoration(
        color: AppTokens.elevatedSurface(context),
        borderRadius: BorderRadius.circular(AppTokens.radiusLg),
        border: Border.all(
          color: AppTokens.separator(context),
          width: 0.5,
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          if (title != null) ...[
            Text(
              title,
              style: TextStyle(
                fontSize: widget.embedded ? 14.5 : 16,
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

  Widget _statusOverviewCard(
    BuildContext context, {
    required List<(String, String)> rows,
    required List<String> fallback,
  }) {
    final secondary = AppTokens.labelSecondary(context);
    final labelColor = AppTokens.label(context);
    final separator = AppTokens.separator(context);

    return Container(
      width: double.infinity,
      margin: const EdgeInsets.only(bottom: 12),
      padding: EdgeInsets.symmetric(
        horizontal: widget.embedded ? 14 : 16,
        vertical: 4,
      ),
      decoration: BoxDecoration(
        color: AppTokens.elevatedSurface(context),
        borderRadius: BorderRadius.circular(AppTokens.radiusLg),
        border: Border.all(
          color: separator,
          width: 0.5,
        ),
      ),
      child: Column(
        children: [
          for (var i = 0; i < rows.length; i++) ...[
            Padding(
              padding: const EdgeInsets.symmetric(vertical: 10),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    rows[i].$1,
                    style: TextStyle(
                      fontSize: 13.5,
                      color: secondary,
                      fontFamilyFallback: fallback,
                    ),
                  ),
                  const SizedBox(width: 16),
                  Expanded(
                    child: Text(
                      rows[i].$2.trim().isEmpty ? '—' : rows[i].$2.trim(),
                      textAlign: TextAlign.right,
                      style: TextStyle(
                        fontSize: 13.5,
                        height: 1.4,
                        fontWeight: FontWeight.w500,
                        color: rows[i].$2.trim().isEmpty
                            ? AppTokens.labelTertiary(context)
                            : labelColor,
                        fontFamilyFallback: fallback,
                      ),
                    ),
                  ),
                ],
              ),
            ),
            if (i < rows.length - 1)
              Container(
                height: 0.5,
                color: separator,
              ),
          ],
        ],
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
                        constraints.maxWidth * (intimacy / 100).clamp(0.0, 1.0),
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
      MemoryFactKind.rule => (
        l10n.memoryKindRule,
        CupertinoColors.systemOrange,
      ),
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
              color: AppTokens.elevatedSurface(context),
              borderRadius: BorderRadius.circular(AppTokens.radiusMd),
              border: Border.all(
                color: AppTokens.separator(context),
                width: 0.5,
              ),
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
              superseded ? CupertinoIcons.xmark : CupertinoIcons.checkmark_alt,
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
