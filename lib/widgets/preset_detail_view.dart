import 'package:cupertino_ui/cupertino_ui.dart';

import '../l10n/app_localizations.dart';
import '../models/character_growth.dart';
import '../models/prompt_preset.dart';
import '../services/preset_repository.dart';
import '../utils/app_theme.dart';
import '../utils/preset_illustration.dart';
import '../utils/preset_sections.dart';
import '../utils/token_estimator.dart';
import 'preset_avatar.dart';
import 'preset_sections_view.dart';
import 'world_info_activation_panel.dart';

/// 角色卡完整详情视图：桌面端双栏立绘分屏、移动端顶部立绘横幅与内嵌三标签。
class PresetDetailView extends StatefulWidget {
  const PresetDetailView({
    super.key,
    required this.preset,
    this.wide = false,
    this.showHeaderActions = true,
    this.onStartChat,
    this.onEdit,
    this.onDuplicate,
    this.onExport,
    this.onDelete,
  });

  final PromptPreset preset;
  final bool wide;
  final bool showHeaderActions;
  final VoidCallback? onStartChat;
  final VoidCallback? onEdit;
  final VoidCallback? onDuplicate;
  final VoidCallback? onExport;
  final VoidCallback? onDelete;

  @override
  State<PresetDetailView> createState() => _PresetDetailViewState();
}

class _PresetDetailViewState extends State<PresetDetailView> {
  int _tabIndex = 0;
  bool _revealSpoilers = false;
  String? _previewStageId;

  PromptPreset get _preset => widget.preset;

  String? get _effectivePreviewStageId =>
      _previewStageId ?? _preset.growthConfig?.initialStage.id;

  @override
  void didUpdateWidget(covariant PresetDetailView oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.preset.id != widget.preset.id) {
      _revealSpoilers = false;
      _previewStageId = null;
      if (_tabIndex > 0 && widget.preset.worldInfo == null) {
        _tabIndex = 0;
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;

    if (!widget.wide) {
      return SingleChildScrollView(
        padding: const EdgeInsets.fromLTRB(16, 12, 16, 28),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _illustrationPanel(context, l10n, wide: false),
            const SizedBox(height: 16),
            _details(context, l10n),
          ],
        ),
      );
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        if (widget.showHeaderActions) _desktopHeader(context, l10n),
        Expanded(
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              SizedBox(
                width: 310,
                child: Padding(
                  padding: const EdgeInsets.fromLTRB(20, 20, 0, 20),
                  child: _illustrationPanel(context, l10n, wide: true),
                ),
              ),
              Expanded(
                child: SingleChildScrollView(
                  padding: const EdgeInsets.fromLTRB(24, 20, 24, 28),
                  child: _details(context, l10n),
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _desktopHeader(BuildContext context, AppLocalizations l10n) {
    final fontFallback =
        cjkFontFallbackForLocale(Localizations.maybeLocaleOf(context));

    return Container(
      height: 52,
      padding: const EdgeInsets.symmetric(horizontal: 20),
      decoration: BoxDecoration(
        color: AppTokens.bg(context),
        border: Border(
          bottom: BorderSide(
            color: AppTokens.separator(context),
            width: 0.5,
          ),
        ),
      ),
      child: Row(
        children: [
          PresetAvatar(
            preset: _preset,
            stageId: _effectivePreviewStageId,
            size: 26,
          ),
          const SizedBox(width: 10),
          Expanded(
            child: Text(
              _preset.name,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: TextStyle(
                fontSize: 15,
                fontWeight: FontWeight.w600,
                fontFamilyFallback: fontFallback,
                color: AppTokens.label(context),
              ),
            ),
          ),
          if (widget.onEdit != null)
            _headerIconTextButton(
              context,
              label: l10n.editPreset,
              onPressed: widget.onEdit!,
            ),
          if (widget.onDuplicate != null)
            _headerIconTextButton(
              context,
              label: l10n.presetDuplicate,
              onPressed: widget.onDuplicate!,
            ),
          if (widget.onExport != null)
            _headerIconTextButton(
              context,
              label: l10n.exportAction,
              onPressed: widget.onExport!,
            ),
          if (widget.onDelete != null)
            CupertinoButton(
              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
              minimumSize: const Size(0, 32),
              onPressed: widget.onDelete,
              child: Text(
                l10n.delete,
                style: TextStyle(
                  fontSize: 13,
                  color: AppTokens.red(context),
                ),
              ),
            ),
          if (widget.onStartChat != null) ...[
            const SizedBox(width: 8),
            CupertinoButton(
              padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 6),
              minimumSize: const Size(0, 32),
              color: AppTokens.accent(context),
              borderRadius: BorderRadius.circular(16),
              onPressed: widget.onStartChat,
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  const Icon(
                    CupertinoIcons.chat_bubble_text_fill,
                    size: 13,
                    color: CupertinoColors.white,
                  ),
                  const SizedBox(width: 5),
                  Text(
                    l10n.startChat,
                    style: const TextStyle(
                      fontSize: 13,
                      fontWeight: FontWeight.w600,
                      color: CupertinoColors.white,
                    ),
                  ),
                ],
              ),
            ),
          ],
        ],
      ),
    );
  }

  Widget _headerIconTextButton(
    BuildContext context, {
    required String label,
    required VoidCallback onPressed,
  }) {
    return CupertinoButton(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
      minimumSize: const Size(0, 32),
      onPressed: onPressed,
      child: Text(
        label,
        style: TextStyle(
          fontSize: 13,
          color: AppTokens.accent(context),
        ),
      ),
    );
  }

  Widget _illustrationPanel(
    BuildContext context,
    AppLocalizations l10n, {
    required bool wide,
  }) {
    final provider = presetIllustrationProvider(
      _preset,
      stageId: _effectivePreviewStageId,
    );
    final panel = ClipRRect(
      borderRadius: BorderRadius.circular(14),
      child: Container(
        decoration: BoxDecoration(
          color: AppTokens.fillSoft(context),
          borderRadius: BorderRadius.circular(14),
          border: Border.all(
            color: AppTokens.separator(context),
            width: 0.5,
          ),
        ),
        child: Stack(
          fit: StackFit.expand,
          children: [
            if (provider != null)
              Image(
                image: provider,
                fit: wide ? BoxFit.contain : BoxFit.cover,
                alignment: wide ? Alignment.center : Alignment.topCenter,
                errorBuilder: (context, error, stackTrace) =>
                    _illustrationPlaceholder(context, l10n),
              )
            else
              _illustrationPlaceholder(context, l10n),
            if (provider != null)
              Positioned(
                right: 12,
                bottom: 12,
                child: CupertinoButton(
                  padding: EdgeInsets.zero,
                  onPressed: () => _showFullIllustration(context, provider),
                  child: Container(
                    width: 36,
                    height: 36,
                    decoration: BoxDecoration(
                      color: AppTokens.elevatedSurface(context)
                          .withValues(alpha: 0.85),
                      shape: BoxShape.circle,
                      border: Border.all(
                        color: AppTokens.separator(context),
                        width: 0.5,
                      ),
                    ),
                    child: Icon(
                      CupertinoIcons.fullscreen,
                      size: 17,
                      color: AppTokens.label(context),
                    ),
                  ),
                ),
              ),
          ],
        ),
      ),
    );

    return wide ? panel : SizedBox(height: 300, child: panel);
  }

  Widget _illustrationPlaceholder(BuildContext context, AppLocalizations l10n) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            PresetAvatar(
              preset: _preset,
              stageId: _effectivePreviewStageId,
              size: 68,
              showBorder: true,
            ),
            const SizedBox(height: 12),
            Text(
              _preset.name,
              textAlign: TextAlign.center,
              style: TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.w600,
                color: AppTokens.label(context),
              ),
            ),
            const SizedBox(height: 4),
            Text(
              l10n.presetDetailNoIllustration,
              style: TextStyle(
                fontSize: 12,
                color: AppTokens.labelSecondary(context),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _showFullIllustration(
    BuildContext context,
    ImageProvider provider,
  ) {
    return showGeneralDialog<void>(
      context: context,
      barrierDismissible: true,
      barrierLabel: AppLocalizations.of(context)!.cancel,
      barrierColor: CupertinoColors.black,
      pageBuilder: (dialogContext, _, _) {
        return SizedBox.expand(
          child: ColoredBox(
            color: AppTokens.bg(dialogContext),
            child: Stack(
              children: [
                Positioned.fill(
                  child: InteractiveViewer(
                    minScale: 0.8,
                    maxScale: 4,
                    child: Image(
                      image: provider,
                      fit: BoxFit.contain,
                    ),
                  ),
                ),
                Positioned(
                  top: MediaQuery.paddingOf(dialogContext).top + 12,
                  right: 16,
                  child: CupertinoButton(
                    padding: EdgeInsets.zero,
                    onPressed: () => Navigator.of(dialogContext).pop(),
                    child: Icon(
                      CupertinoIcons.xmark_circle_fill,
                      size: 30,
                      color: AppTokens.accent(dialogContext),
                    ),
                  ),
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  Widget _details(BuildContext context, AppLocalizations l10n) {
    final sections = parsePresetSections(_preset.systemPrompt);
    final fallback =
        cjkFontFallbackForLocale(Localizations.maybeLocaleOf(context));
    final tokenCount = TokenEstimator.estimate(_preset.systemPrompt);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        if (_preset.description.trim().isNotEmpty) ...[
          Text(
            _preset.description,
            style: TextStyle(
              fontSize: widget.wide ? 20 : 18,
              height: 1.35,
              fontWeight: FontWeight.w700,
              fontFamilyFallback: fallback,
              color: AppTokens.label(context),
            ),
          ),
          const SizedBox(height: 16),
        ],
        _metaCard(context, l10n, fallback, tokenCount),
        if (_preset.hasGrowth ||
            (_preset.worldInfo?.entries.any(
                  (e) => e.unlock?.hiddenUntilUnlocked == true,
                ) ??
                false)) ...[
          const SizedBox(height: 10),
          _spoilerToggleCard(context, l10n, fallback),
        ],
        if (tokenCount > 4000) ...[
          const SizedBox(height: 10),
          _warningBanner(
            context,
            tokenCount > 8000
                ? l10n.presetTokenStrongWarning
                : l10n.presetTokenWarning,
            tokenCount > 8000 ? AppTokens.red(context) : CupertinoColors.systemOrange,
          ),
        ],
        if (_preset.isBroken) ...[
          const SizedBox(height: 10),
          _warningBanner(
            context,
            '${l10n.presetBrokenLabel} · '
            '${l10n.presetBrokenReason(_preset.brokenReason ?? l10n.presetBrokenLabel)}',
            AppTokens.red(context),
          ),
        ],
        const SizedBox(height: 18),
        SizedBox(
          width: double.infinity,
          child: CupertinoSlidingSegmentedControl<int>(
            groupValue: _tabIndex,
            children: {
              0: Padding(
                padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 4),
                child: Text(
                  l10n.presetOverview,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(fontSize: 13),
                ),
              ),
              1: Padding(
                padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 4),
                child: Text(
                  l10n.worldInfo,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(fontSize: 13),
                ),
              ),
              2: Padding(
                padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 4),
                child: Text(
                  l10n.worldInfoTriggerTest,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(fontSize: 13),
                ),
              ),
            },
            onValueChanged: (value) {
              if (value != null) setState(() => _tabIndex = value);
            },
          ),
        ),
        const SizedBox(height: 16),
        switch (_tabIndex) {
          1 => _worldInfoTab(context, l10n),
          2 => _triggerTestTab(context, l10n),
          _ => _overviewTab(context, l10n, sections, fallback),
        },
      ],
    );
  }

  Widget _metaCard(
    BuildContext context,
    AppLocalizations l10n,
    List<String> fallback,
    int tokenCount,
  ) {
    final secondary = AppTokens.labelSecondary(context);
    final labelColor = AppTokens.label(context);
    final rows = <(String, String, Color?)>[
      (
        l10n.authorLabel.replaceFirst(RegExp(r'[:：]\s*$'), ''),
        _preset.author.trim().isEmpty ? '—' : _preset.author,
        null,
      ),
      (
        l10n.versionLabel.replaceFirst(RegExp(r'[:：]\s*$'), ''),
        _preset.version,
        null,
      ),
      if (_preset.language != null)
        (
          l10n.presetLanguageLabel.replaceFirst(RegExp(r'[:：]\s*$'), ''),
          _preset.language!.toUpperCase(),
          null,
        ),
      if (_preset.tags.isNotEmpty)
        (
          l10n.presetTagsLabel,
          _preset.tags.map((tag) => '#$tag').join(' '),
          null,
        ),
      (
        l10n.presetLengthLabel,
        l10n.presetTokenEstimate(tokenCount),
        tokenCount > 4000 ? CupertinoColors.systemOrange : null,
      ),
      if (_preset.growthConfig != null)
        (
          l10n.growthBadgeLabel,
          _preset.growthConfig!.hasBranching
              ? l10n.growthStageSummaryBranching(
                  _preset.growthConfig!.stages.length,
                )
              : l10n.growthStageSummary(_preset.growthConfig!.stages.length),
          AppTokens.accent(context),
        ),
    ];

    return Container(
      decoration: BoxDecoration(
        color: AppTokens.elevatedSurface(context),
        borderRadius: BorderRadius.circular(AppTokens.radiusMd),
        border: Border.all(
          color: AppTokens.separator(context),
          width: 0.5,
        ),
      ),
      child: Column(
        children: [
          for (var i = 0; i < rows.length; i++) ...[
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    rows[i].$1,
                    style: TextStyle(fontSize: 13.5, color: secondary),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Text(
                      rows[i].$2,
                      textAlign: TextAlign.right,
                      style: TextStyle(
                        fontSize: 13.5,
                        color: rows[i].$3 ?? labelColor,
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
                margin: const EdgeInsets.only(left: 14),
                color: AppTokens.separator(context),
              ),
          ],
        ],
      ),
    );
  }

  Widget _spoilerToggleCard(
    BuildContext context,
    AppLocalizations l10n,
    List<String> fallback,
  ) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
      decoration: BoxDecoration(
        color: AppTokens.elevatedSurface(context),
        borderRadius: BorderRadius.circular(AppTokens.radiusMd),
        border: Border.all(
          color: AppTokens.separator(context),
          width: 0.5,
        ),
      ),
      child: Row(
        children: [
          Expanded(
            child: Text(
              l10n.growthSpoilerToggle,
              style: TextStyle(
                fontSize: 13.5,
                color: AppTokens.label(context),
                fontFamilyFallback: fallback,
              ),
            ),
          ),
          const SizedBox(width: 12),
          CupertinoSwitch(
            value: _revealSpoilers,
            onChanged: (value) => setState(() {
              _revealSpoilers = value;
              if (!value) {
                _previewStageId = null;
              }
            }),
          ),
        ],
      ),
    );
  }

  Widget _overviewTab(
    BuildContext context,
    AppLocalizations l10n,
    List<PresetSection> sections,
    List<String> fallback,
  ) {
    final growth = _preset.growthConfig;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        PresetSectionsView(sections: sections),
        if (growth != null) ...[
          const SizedBox(height: 16),
          _growthOverviewCard(context, l10n, growth, fallback),
        ],
      ],
    );
  }

  Widget _growthOverviewCard(
    BuildContext context,
    AppLocalizations l10n,
    CharacterGrowthConfig growth,
    List<String> fallback,
  ) {
    final secondary = AppTokens.labelSecondary(context);
    final accent = AppTokens.accent(context);
    final visibleStages = _revealSpoilers
        ? growth.stages
        : <GrowthStage>[growth.initialStage];

    return Container(
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
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Expanded(
                child: Text(
                  l10n.growthStagesOverview,
                  style: TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.w600,
                    color: AppTokens.label(context),
                    fontFamilyFallback: fallback,
                  ),
                ),
              ),
              Text(
                growth.hasBranching
                    ? l10n.growthStageSummaryBranching(growth.stages.length)
                    : l10n.growthStageSummary(growth.stages.length),
                style: TextStyle(
                  fontSize: 12,
                  color: accent,
                  fontWeight: FontWeight.w600,
                  fontFamilyFallback: fallback,
                ),
              ),
            ],
          ),
          const SizedBox(height: 10),
          for (var i = 0; i < visibleStages.length; i++) ...[
            GestureDetector(
              behavior: HitTestBehavior.opaque,
              onTap: _revealSpoilers
                  ? () => setState(() => _previewStageId = visibleStages[i].id)
                  : null,
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Padding(
                    padding: const EdgeInsets.only(top: 5),
                    child: Container(
                      width: 7,
                      height: 7,
                      decoration: BoxDecoration(
                        color: visibleStages[i].id == _effectivePreviewStageId
                            ? accent
                            : visibleStages[i].isEnding
                            ? CupertinoColors.systemPurple.resolveFrom(context)
                            : secondary.withValues(alpha: 0.6),
                        shape: BoxShape.circle,
                      ),
                    ),
                  ),
                  const SizedBox(width: 9),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Wrap(
                          spacing: 6,
                          crossAxisAlignment: WrapCrossAlignment.center,
                          children: [
                            Text(
                              visibleStages[i].name,
                              style: TextStyle(
                                fontSize: 13.5,
                                fontWeight: FontWeight.w600,
                                color:
                                    _revealSpoilers &&
                                        visibleStages[i].id ==
                                            _effectivePreviewStageId
                                    ? accent
                                    : AppTokens.label(context),
                                fontFamilyFallback: fallback,
                              ),
                            ),
                            if (visibleStages[i].isEnding)
                              Container(
                                padding: const EdgeInsets.symmetric(
                                  horizontal: 6,
                                  vertical: 1,
                                ),
                                decoration: BoxDecoration(
                                  color: CupertinoColors.systemPurple
                                      .resolveFrom(context)
                                      .withValues(alpha: 0.14),
                                  borderRadius: BorderRadius.circular(5),
                                ),
                                child: Text(
                                  l10n.growthEndingBadge,
                                  style: TextStyle(
                                    fontSize: 10.5,
                                    fontWeight: FontWeight.w600,
                                    color: CupertinoColors.systemPurple
                                        .resolveFrom(context),
                                    fontFamilyFallback: fallback,
                                  ),
                                ),
                              ),
                          ],
                        ),
                        if (visibleStages[i].summary.trim().isNotEmpty) ...[
                          const SizedBox(height: 2),
                          Text(
                            visibleStages[i].summary.trim(),
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
            ),
            if (i < visibleStages.length - 1) const SizedBox(height: 10),
          ],
          const SizedBox(height: 10),
          Text(
            l10n.growthPlaythroughNote,
            style: TextStyle(
              fontSize: 12,
              height: 1.35,
              color: AppTokens.labelTertiary(context),
              fontFamilyFallback: fallback,
            ),
          ),
        ],
      ),
    );
  }

  Widget _worldInfoTab(BuildContext context, AppLocalizations l10n) {
    final info = _preset.worldInfo;
    if (info == null) {
      return Container(
        width: double.infinity,
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: AppTokens.fillSoft(context),
          borderRadius: BorderRadius.circular(AppTokens.radiusMd),
        ),
        child: Text(
          l10n.presetDetailNoWorldInfo,
          style: TextStyle(color: AppTokens.labelSecondary(context)),
        ),
      );
    }

    final visibleEntries = info.entries
        .where(
          (entry) =>
              _revealSpoilers || entry.unlock?.hiddenUntilUnlocked != true,
        )
        .toList(growable: false);
    final hiddenCount = info.entries.length - visibleEntries.length;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        if (info.name.trim().isNotEmpty) ...[
          Text(
            info.name,
            style: TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.w600,
              color: AppTokens.label(context),
            ),
          ),
          const SizedBox(height: 4),
        ],
        if (info.description.trim().isNotEmpty) ...[
          Text(
            info.description,
            style: TextStyle(
              fontSize: 13,
              color: AppTokens.labelSecondary(context),
            ),
          ),
          const SizedBox(height: 12),
        ],
        if (info.background.trim().isNotEmpty) ...[
          Text(
            l10n.worldInfoBackground,
            style: TextStyle(
              fontSize: 14,
              fontWeight: FontWeight.w600,
              color: AppTokens.label(context),
            ),
          ),
          const SizedBox(height: 8),
          PresetSectionsView(
            sections: [PresetSection(text: info.background)],
            showLabels: false,
            emptyText: '—',
          ),
          const SizedBox(height: 10),
        ],
        Text(
          l10n.presetDetailWorldInfoStats(
            info.entries.length,
            info.scanDepth,
            info.budgetTokens,
          ),
          style: TextStyle(
            fontSize: 12,
            color: AppTokens.labelSecondary(context),
          ),
        ),
        if (visibleEntries.isNotEmpty || hiddenCount > 0)
          const SizedBox(height: 12),
        for (final entry in visibleEntries) ...[
          WorldInfoEntryPreviewCard(entry: entry),
          const SizedBox(height: 8),
        ],
        if (hiddenCount > 0)
          Container(
            width: double.infinity,
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
            decoration: BoxDecoration(
              color: AppTokens.fillSoft(context),
              borderRadius: BorderRadius.circular(AppTokens.radiusMd),
            ),
            child: Row(
              children: [
                Icon(
                  CupertinoIcons.lock_fill,
                  size: 13,
                  color: AppTokens.labelTertiary(context),
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    l10n.growthHiddenLoreCount(hiddenCount),
                    style: TextStyle(
                      fontSize: 12.5,
                      color: AppTokens.labelSecondary(context),
                    ),
                  ),
                ),
              ],
            ),
          ),
      ],
    );
  }

  Widget _triggerTestTab(BuildContext context, AppLocalizations l10n) {
    final info = _preset.worldInfo;
    if (info == null) {
      return Container(
        width: double.infinity,
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: AppTokens.fillSoft(context),
          borderRadius: BorderRadius.circular(AppTokens.radiusMd),
        ),
        child: Text(
          l10n.presetDetailNoWorldInfo,
          style: TextStyle(color: AppTokens.labelSecondary(context)),
        ),
      );
    }
    return WorldInfoTriggerTester(
      info: info,
      growthConfig: _preset.growthConfig,
    );
  }

  Widget _warningBanner(BuildContext context, String text, Color color) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 9),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.10),
        borderRadius: BorderRadius.circular(AppTokens.radiusSm),
      ),
      child: Text(text, style: TextStyle(fontSize: 12.5, color: color)),
    );
  }
}

/// 移动端 Push 进入的角色卡全屏详情页（带 `< 角色` 返回、更多菜单和底部 `开始对话` 按钮）。
class PresetDetailPage extends StatefulWidget {
  const PresetDetailPage({
    super.key,
    required this.preset,
    this.onStartChat,
    this.onEdit,
    this.onDuplicate,
    this.onExport,
    this.onDelete,
  });

  final PromptPreset preset;
  final VoidCallback? onStartChat;
  final Future<void> Function(PromptPreset preset)? onEdit;
  final Future<void> Function(PromptPreset preset)? onDuplicate;
  final Future<void> Function(PromptPreset preset)? onExport;
  final Future<bool> Function(PromptPreset preset)? onDelete;

  @override
  State<PresetDetailPage> createState() => _PresetDetailPageState();
}

class _PresetDetailPageState extends State<PresetDetailPage> {
  final PresetRepository _repository = PresetRepository.instance;
  late PromptPreset _preset = widget.preset;

  @override
  void initState() {
    super.initState();
    _repository.addListener(_syncFromRepo);
  }

  @override
  void dispose() {
    _repository.removeListener(_syncFromRepo);
    super.dispose();
  }

  void _syncFromRepo() {
    final match = _repository.presets.where((p) => p.id == _preset.id);
    if (match.isNotEmpty && mounted) {
      setState(() => _preset = match.first);
    }
  }

  Future<void> _showMoreMenu() async {
    final l10n = AppLocalizations.of(context)!;
    await showCupertinoModalPopup<void>(
      context: context,
      builder: (sheetContext) => CupertinoActionSheet(
        actions: [
          if (_preset.isUserPreset && widget.onEdit != null)
            CupertinoActionSheetAction(
              onPressed: () {
                Navigator.pop(sheetContext);
                widget.onEdit!(_preset);
              },
              child: Text(l10n.editPreset),
            ),
          if (widget.onDuplicate != null)
            CupertinoActionSheetAction(
              onPressed: () {
                Navigator.pop(sheetContext);
                widget.onDuplicate!(_preset);
              },
              child: Text(l10n.presetDuplicate),
            ),
          if (widget.onExport != null)
            CupertinoActionSheetAction(
              onPressed: () {
                Navigator.pop(sheetContext);
                widget.onExport!(_preset);
              },
              child: Text(l10n.presetExport),
            ),
          if (_preset.isUserPreset && widget.onDelete != null)
            CupertinoActionSheetAction(
              isDestructiveAction: true,
              onPressed: () async {
                Navigator.pop(sheetContext);
                final deleted = await widget.onDelete!(_preset);
                if (deleted && mounted) {
                  Navigator.of(context).pop();
                }
              },
              child: Text(l10n.delete),
            ),
        ],
        cancelButton: CupertinoActionSheetAction(
          onPressed: () => Navigator.pop(sheetContext),
          child: Text(l10n.cancel),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;

    return CupertinoPageScaffold(
      backgroundColor: AppTokens.bg(context),
      navigationBar: CupertinoNavigationBar(
        backgroundColor: AppTokens.bg(context),
        previousPageTitle: l10n.characters,
        middle: Text(_preset.name, maxLines: 1, overflow: TextOverflow.ellipsis),
        trailing: CupertinoButton(
          padding: EdgeInsets.zero,
          onPressed: _showMoreMenu,
          child: const Icon(CupertinoIcons.ellipsis),
        ),
        border: Border(
          bottom: BorderSide(
            color: AppTokens.separator(context),
            width: 0.5,
          ),
        ),
      ),
      child: Column(
        children: [
          Expanded(
            child: SafeArea(
              bottom: widget.onStartChat == null,
              child: PresetDetailView(
                preset: _preset,
                wide: false,
                showHeaderActions: false,
              ),
            ),
          ),
          if (widget.onStartChat != null)
            Container(
              padding: const EdgeInsets.fromLTRB(16, 10, 16, 10),
              decoration: BoxDecoration(
                color: AppTokens.bg(context),
                border: Border(
                  top: BorderSide(
                    color: AppTokens.separator(context),
                    width: 0.5,
                  ),
                ),
              ),
              child: SafeArea(
                top: false,
                child: SizedBox(
                  width: double.infinity,
                  child: CupertinoButton.filled(
                    borderRadius: BorderRadius.circular(22),
                    onPressed: () {
                      Navigator.of(context).pop();
                      widget.onStartChat!();
                    },
                    child: Text(l10n.startChat),
                  ),
                ),
              ),
            ),
        ],
      ),
    );
  }
}
