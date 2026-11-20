import 'package:cupertino_ui/cupertino_ui.dart';

import '../l10n/app_localizations.dart';
import '../models/world_info.dart';
import '../services/world_info_service.dart';
import '../widgets/read_only_markdown.dart';

/// 只读的世界书激活预览。
///
/// 编辑世界书请使用生成器网页；这里只用于查看背景、测试激活结果和 token 占用。
class WorldInfoPreviewScreen extends StatefulWidget {
  const WorldInfoPreviewScreen({
    super.key,
    required this.info,
    this.initialText = '',
  });

  final WorldInfo info;
  final String initialText;

  @override
  State<WorldInfoPreviewScreen> createState() => _WorldInfoPreviewScreenState();
}

class _WorldInfoPreviewScreenState extends State<WorldInfoPreviewScreen> {
  late final TextEditingController _controller;
  late WorldInfoActivation _activation;

  @override
  void initState() {
    super.initState();
    _controller = TextEditingController(text: widget.initialText);
    _activation = WorldInfoService.activate(widget.info, widget.initialText);
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  void _run() {
    FocusScope.of(context).unfocus();
    setState(() {
      _activation = WorldInfoService.activate(widget.info, _controller.text);
    });
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final secondary = CupertinoColors.secondaryLabel.resolveFrom(context);

    return CupertinoPageScaffold(
      navigationBar: CupertinoNavigationBar(
        middle: Text(l10n.worldInfoPreview),
      ),
      child: SafeArea(
        child: ListView(
          padding: const EdgeInsets.fromLTRB(16, 16, 16, 32),
          children: [
            if (widget.info.name.trim().isNotEmpty ||
                widget.info.description.trim().isNotEmpty) ...[
              if (widget.info.name.trim().isNotEmpty)
                Text(
                  widget.info.name,
                  style: const TextStyle(
                    fontSize: 20,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              if (widget.info.name.trim().isNotEmpty &&
                  widget.info.description.trim().isNotEmpty)
                const SizedBox(height: 4),
              if (widget.info.description.trim().isNotEmpty)
                Text(
                  widget.info.description,
                  style: TextStyle(fontSize: 13, height: 1.4, color: secondary),
                ),
              const SizedBox(height: 20),
            ],
            _sectionTitle(l10n.worldInfoBackground, secondary),
            _Surface(
              child: ReadOnlyMarkdown(
                data: widget.info.background.trim().isEmpty
                    ? '—'
                    : widget.info.background,
              ),
            ),
            const SizedBox(height: 24),
            _sectionTitle(l10n.worldInfoTestText, secondary),
            CupertinoTextField(
              controller: _controller,
              minLines: 3,
              maxLines: 6,
              padding: const EdgeInsets.all(12),
              placeholder: l10n.worldInfoTestText,
              textInputAction: TextInputAction.newline,
            ),
            const SizedBox(height: 12),
            CupertinoButton.filled(
              onPressed: _run,
              child: Text(l10n.worldInfoRun),
            ),
            const SizedBox(height: 20),
            Text(
              l10n.worldInfoTokens(
                _activation.backgroundTokens,
                _activation.entryTokens,
                _activation.totalTokens,
              ),
              style: TextStyle(fontSize: 13, color: secondary),
            ),
            const SizedBox(height: 24),
            _sectionTitle(
              '${l10n.worldInfoMatched} (${_activation.matched.length})',
              secondary,
            ),
            if (_activation.matched.isEmpty)
              _Surface(
                child: Text(
                  l10n.worldInfoNoMatches,
                  style: TextStyle(color: secondary),
                ),
              )
            else
              for (final item in _activation.matched) ...[
                const SizedBox(height: 10),
                _MatchedEntryCard(item: item, secondaryColor: secondary),
              ],
            if (_activation.skipDetails.isNotEmpty) ...[
              const SizedBox(height: 24),
              _sectionTitle(
                '${l10n.worldInfoUnmatched} (${_activation.skipDetails.length})',
                secondary,
              ),
              for (final detail in _activation.skipDetails)
                Padding(
                  padding: const EdgeInsets.only(bottom: 8),
                  child: Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Expanded(
                        child: Text(
                          '• ${detail.entry.title.trim().isEmpty ? detail.entry.id : detail.entry.title}',
                          style: TextStyle(fontSize: 14, color: secondary),
                        ),
                      ),
                      const SizedBox(width: 12),
                      Flexible(
                        child: Text(
                          _skipReasonLabel(detail.reason, l10n),
                          textAlign: TextAlign.end,
                          style: TextStyle(
                            fontSize: 12,
                            color: CupertinoColors.systemOrange.resolveFrom(
                              context,
                            ),
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
            ],
          ],
        ),
      ),
    );
  }

  Widget _sectionTitle(String text, Color color) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Text(
        text,
        style: TextStyle(
          fontSize: 13,
          fontWeight: FontWeight.w600,
          color: color,
        ),
      ),
    );
  }
}

class _Surface extends StatelessWidget {
  const _Surface({required this.child});

  final Widget child;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: CupertinoColors.systemGrey6.resolveFrom(context),
        borderRadius: BorderRadius.circular(10),
      ),
      child: child,
    );
  }
}

class _MatchedEntryCard extends StatelessWidget {
  const _MatchedEntryCard({required this.item, required this.secondaryColor});

  final ActivatedWorldInfoEntry item;
  final Color secondaryColor;

  @override
  Widget build(BuildContext context) {
    final entry = item.entry;
    final l10n = AppLocalizations.of(context)!;
    final title = entry.title.trim().isEmpty ? entry.id : entry.title;
    final meta = <String>[
      _categoryLabel(entry.category, l10n),
      _matchLabel(entry.match, l10n),
      '${l10n.worldInfoEntryPositionLabel} '
          '${_positionLabel(entry.position, l10n)}'
          '${entry.position == 'at_depth' ? ' ${entry.depth}' : ''}',
      '${l10n.worldInfoEntryPriorityLabel} ${entry.priority}',
      if (entry.tags.isNotEmpty)
        '${l10n.presetTagsLabel} ${entry.tags.join(', ')}',
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

    return _Surface(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Expanded(
                child: Text(
                  title,
                  style: const TextStyle(
                    fontSize: 15,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
              Text(
                '${item.tokens} tokens',
                style: TextStyle(fontSize: 12, color: secondaryColor),
              ),
            ],
          ),
          const SizedBox(height: 4),
          Text(
            item.matchedKey,
            style: TextStyle(fontSize: 12, color: secondaryColor),
          ),
          const SizedBox(height: 2),
          Text(
            meta.join(' · '),
            style: TextStyle(fontSize: 11, color: secondaryColor),
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

String _categoryLabel(WorldInfoCategory category, AppLocalizations l10n) {
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

String _matchLabel(WorldInfoMatchMode match, AppLocalizations l10n) {
  return switch (match) {
    WorldInfoMatchMode.substring => l10n.worldInfoMatchSubstring,
    WorldInfoMatchMode.word => l10n.worldInfoMatchWord,
    WorldInfoMatchMode.regex => l10n.worldInfoMatchRegex,
  };
}

String _positionLabel(String position, AppLocalizations l10n) {
  return switch (position) {
    'before_preset' => l10n.worldInfoPositionBeforePreset,
    'after_preset' => l10n.worldInfoPositionAfterPreset,
    'at_depth' => l10n.worldInfoPositionAtDepth,
    _ => l10n.worldInfoPositionSystem,
  };
}

String _skipReasonLabel(WorldInfoSkipReason reason, AppLocalizations l10n) {
  return switch (reason) {
    WorldInfoSkipReason.disabled => l10n.worldInfoSkipDisabled,
    WorldInfoSkipReason.noPrimaryKey => l10n.worldInfoSkipNoPrimaryKey,
    WorldInfoSkipReason.missingSecondaryKey =>
      l10n.worldInfoSkipMissingSecondaryKey,
    WorldInfoSkipReason.cooldown => l10n.worldInfoSkipCooldown,
    WorldInfoSkipReason.probability => l10n.worldInfoSkipProbability,
    WorldInfoSkipReason.group => l10n.worldInfoSkipGroup,
    WorldInfoSkipReason.budget => l10n.worldInfoSkipBudget,
    WorldInfoSkipReason.stageLocked => l10n.worldInfoSkipStageLocked,
    WorldInfoSkipReason.metricLocked => l10n.worldInfoSkipMetricLocked,
  };
}
