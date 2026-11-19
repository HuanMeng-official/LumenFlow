import 'package:cupertino_ui/cupertino_ui.dart';

import '../l10n/app_localizations.dart';
import '../models/world_info.dart';
import '../services/world_info_service.dart';
import '../utils/app_theme.dart';
import 'read_only_markdown.dart';

String worldInfoCategoryLabel(
  WorldInfoCategory category,
  AppLocalizations l10n,
) {
  return switch (category) {
    WorldInfoCategory.character => l10n.worldInfoCategoryCharacter,
    WorldInfoCategory.location => l10n.worldInfoCategoryLocation,
    WorldInfoCategory.item => l10n.worldInfoCategoryItem,
    WorldInfoCategory.rule => l10n.worldInfoCategoryRule,
    WorldInfoCategory.event => l10n.worldInfoCategoryEvent,
    WorldInfoCategory.lore => l10n.worldInfoCategoryLore,
    WorldInfoCategory.other => l10n.worldInfoCategoryOther,
  };
}

String worldInfoMatchLabel(WorldInfoMatchMode match, AppLocalizations l10n) {
  return switch (match) {
    WorldInfoMatchMode.substring => l10n.worldInfoMatchSubstring,
    WorldInfoMatchMode.word => l10n.worldInfoMatchWord,
    WorldInfoMatchMode.regex => l10n.worldInfoMatchRegex,
  };
}

String worldInfoPositionLabel(String position, AppLocalizations l10n) {
  return switch (position) {
    'before_preset' => l10n.worldInfoPositionBeforePreset,
    'after_preset' => l10n.worldInfoPositionAfterPreset,
    'at_depth' => l10n.worldInfoPositionAtDepth,
    _ => l10n.worldInfoPositionSystem,
  };
}

String worldInfoSkipReasonLabel(
  WorldInfoSkipReason reason,
  AppLocalizations l10n,
) {
  return switch (reason) {
    WorldInfoSkipReason.disabled => l10n.worldInfoSkipDisabled,
    WorldInfoSkipReason.noPrimaryKey => l10n.worldInfoSkipNoPrimaryKey,
    WorldInfoSkipReason.missingSecondaryKey =>
      l10n.worldInfoSkipMissingSecondaryKey,
    WorldInfoSkipReason.cooldown => l10n.worldInfoSkipCooldown,
    WorldInfoSkipReason.probability => l10n.worldInfoSkipProbability,
    WorldInfoSkipReason.group => l10n.worldInfoSkipGroup,
    WorldInfoSkipReason.budget => l10n.worldInfoSkipBudget,
  };
}

/// 静态世界书条目只读卡片（角色详情「世界书」标签页与 Inspector 抽屉共用）。
class WorldInfoEntryPreviewCard extends StatelessWidget {
  const WorldInfoEntryPreviewCard({
    super.key,
    required this.entry,
    this.compact = false,
  });

  final WorldInfoEntry entry;
  final bool compact;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final secondary = AppTokens.labelSecondary(context);
    final title = entry.title.trim().isEmpty ? entry.id : entry.title;

    return Container(
      width: double.infinity,
      padding: EdgeInsets.all(compact ? 11 : 13),
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
                  title,
                  style: TextStyle(
                    fontSize: compact ? 13.5 : 14.5,
                    fontWeight: FontWeight.w600,
                    color: AppTokens.label(context),
                  ),
                ),
              ),
              if (!entry.enabled)
                Text(
                  l10n.worldInfoSkipDisabled,
                  style: TextStyle(
                    fontSize: 11,
                    color: AppTokens.labelTertiary(context),
                  ),
                ),
            ],
          ),
          if (entry.keys.isNotEmpty) ...[
            const SizedBox(height: 4),
            Text(
              entry.keys.join(' · '),
              style: TextStyle(fontSize: 12, color: secondary),
            ),
          ],
          if (!compact && entry.content.trim().isNotEmpty) ...[
            const SizedBox(height: 8),
            ReadOnlyMarkdown(data: entry.content),
          ],
        ],
      ),
    );
  }
}

/// 命中的世界书激活条目卡片。
class ActivatedWorldInfoEntryCard extends StatelessWidget {
  const ActivatedWorldInfoEntryCard({super.key, required this.item});

  final ActivatedWorldInfoEntry item;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final entry = item.entry;
    final secondary = AppTokens.labelSecondary(context);
    final title = entry.title.trim().isEmpty ? entry.id : entry.title;
    final meta = <String>[
      worldInfoCategoryLabel(entry.category, l10n),
      worldInfoMatchLabel(entry.match, l10n),
      '${worldInfoPositionLabel(entry.position, l10n)}'
          '${entry.position == 'at_depth' ? ' ${entry.depth}' : ''}',
      '${l10n.worldInfoEntryPriorityLabel} ${entry.priority}',
      if (entry.tags.isNotEmpty) entry.tags.map((t) => '#$t').join(' '),
      if (entry.group.trim().isNotEmpty)
        '${l10n.worldInfoEntryGroupLabel} ${entry.group.trim()}',
      if (entry.probability < 100)
        '${l10n.worldInfoEntryProbabilityLabel} ${entry.probability}%',
      if (entry.sticky > 0) '${l10n.worldInfoEntryStickyLabel} ${entry.sticky}',
      if (entry.cooldown > 0)
        '${l10n.worldInfoEntryCooldownLabel} ${entry.cooldown}',
      if (item.viaRecursion)
        '${l10n.worldInfoEntryRecursionLabel} ${item.recursionLevel}',
    ];

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(13),
      decoration: BoxDecoration(
        color: AppTokens.elevatedSurface(context),
        borderRadius: BorderRadius.circular(AppTokens.radiusMd),
        border: Border.all(
          color: AppTokens.accent(context).withValues(alpha: 0.25),
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
                  title,
                  style: TextStyle(
                    fontSize: 14.5,
                    fontWeight: FontWeight.w600,
                    color: AppTokens.label(context),
                  ),
                ),
              ),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 2),
                decoration: BoxDecoration(
                  color: AppTokens.accentSoft(context),
                  borderRadius: BorderRadius.circular(6),
                ),
                child: Text(
                  '${item.tokens} tokens',
                  style: TextStyle(
                    fontSize: 11,
                    fontWeight: FontWeight.w600,
                    color: AppTokens.accent(context),
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 4),
          Text(
            item.matchedKey,
            style: TextStyle(fontSize: 12, color: AppTokens.green(context)),
          ),
          const SizedBox(height: 2),
          Text(
            meta.join(' · '),
            style: TextStyle(fontSize: 11, color: secondary),
          ),
          const SizedBox(height: 8),
          ReadOnlyMarkdown(
            data: entry.content.trim().isEmpty ? '—' : entry.content,
          ),
        ],
      ),
    );
  }
}

/// 嵌入式世界书触发测试面板。
class WorldInfoTriggerTester extends StatefulWidget {
  const WorldInfoTriggerTester({
    super.key,
    required this.info,
    this.compact = false,
  });

  final WorldInfo info;
  final bool compact;

  @override
  State<WorldInfoTriggerTester> createState() => _WorldInfoTriggerTesterState();
}

class _WorldInfoTriggerTesterState extends State<WorldInfoTriggerTester> {
  final TextEditingController _controller = TextEditingController();
  late WorldInfoActivation _activation;

  @override
  void initState() {
    super.initState();
    _runActivation();
  }

  @override
  void didUpdateWidget(covariant WorldInfoTriggerTester oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.info != widget.info) {
      _runActivation();
    }
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  void _runActivation() {
    _activation = WorldInfoService.activate(widget.info, _controller.text);
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final secondary = AppTokens.labelSecondary(context);
    final fontFallback =
        cjkFontFallbackForLocale(Localizations.maybeLocaleOf(context));

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        CupertinoTextField(
          controller: _controller,
          placeholder: l10n.worldInfoTestText,
          minLines: widget.compact ? 2 : 3,
          maxLines: widget.compact ? 4 : 5,
          padding: const EdgeInsets.all(12),
          decoration: BoxDecoration(
            color: AppTokens.elevatedSurface(context),
            borderRadius: BorderRadius.circular(AppTokens.radiusMd),
            border: Border.all(
              color: AppTokens.separator(context),
              width: 0.5,
            ),
          ),
          style: TextStyle(
            fontSize: 14,
            fontFamilyFallback: fontFallback,
            color: AppTokens.label(context),
          ),
          onChanged: (_) => setState(_runActivation),
        ),
        const SizedBox(height: 10),
        Text(
          l10n.worldInfoTokens(
            _activation.backgroundTokens,
            _activation.entryTokens,
            _activation.totalTokens,
          ),
          style: TextStyle(fontSize: 12, color: secondary),
        ),
        const SizedBox(height: 14),
        Text(
          '${l10n.worldInfoMatched} (${_activation.matched.length})',
          style: TextStyle(
            fontSize: 13,
            fontWeight: FontWeight.w600,
            color: AppTokens.label(context),
          ),
        ),
        const SizedBox(height: 8),
        if (_activation.matched.isEmpty)
          Container(
            width: double.infinity,
            padding: const EdgeInsets.all(14),
            decoration: BoxDecoration(
              color: AppTokens.fillSoft(context),
              borderRadius: BorderRadius.circular(AppTokens.radiusMd),
            ),
            child: Text(
              l10n.worldInfoNoMatches,
              style: TextStyle(fontSize: 13, color: secondary),
            ),
          )
        else
          for (final item in _activation.matched) ...[
            ActivatedWorldInfoEntryCard(item: item),
            const SizedBox(height: 8),
          ],
        if (_activation.skipDetails.isNotEmpty) ...[
          const SizedBox(height: 12),
          Text(
            '${l10n.worldInfoUnmatched} (${_activation.skipDetails.length})',
            style: TextStyle(
              fontSize: 13,
              fontWeight: FontWeight.w600,
              color: AppTokens.labelSecondary(context),
            ),
          ),
          const SizedBox(height: 8),
          Container(
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
                for (var i = 0; i < _activation.skipDetails.length; i++) ...[
                  Padding(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 13,
                      vertical: 10,
                    ),
                    child: Row(
                      children: [
                        Expanded(
                          child: Text(
                            _activation.skipDetails[i].entry.title.trim().isEmpty
                                ? _activation.skipDetails[i].entry.id
                                : _activation.skipDetails[i].entry.title,
                            style: TextStyle(
                              fontSize: 13.5,
                              color: AppTokens.label(context),
                            ),
                          ),
                        ),
                        const SizedBox(width: 8),
                        Text(
                          worldInfoSkipReasonLabel(
                            _activation.skipDetails[i].reason,
                            l10n,
                          ),
                          style: TextStyle(fontSize: 12, color: secondary),
                        ),
                      ],
                    ),
                  ),
                  if (i < _activation.skipDetails.length - 1)
                    Container(
                      height: 0.5,
                      margin: const EdgeInsets.only(left: 13),
                      color: AppTokens.separator(context),
                    ),
                ],
              ],
            ),
          ),
        ],
      ],
    );
  }
}
