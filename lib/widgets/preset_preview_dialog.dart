import 'dart:math' as math;

import 'package:cupertino_ui/cupertino_ui.dart';
import 'package:path/path.dart' as path;

import '../l10n/app_localizations.dart';
import '../models/prompt_preset.dart';
import '../utils/app_theme.dart';
import '../utils/preset_sections.dart';
import '../utils/token_estimator.dart';
import 'preset_sections_view.dart';
import 'read_only_markdown.dart';

/// 打开角色卡预览对话框。
Future<void> showPresetPreviewDialog({
  required BuildContext context,
  required PromptPreset preset,
  VoidCallback? onEdit,
  VoidCallback? onPreviewWorldInfo,
  required VoidCallback onDuplicate,
  required VoidCallback onExport,
}) {
  final l10n = AppLocalizations.of(context)!;
  return showGeneralDialog<void>(
    context: context,
    barrierDismissible: true,
    barrierLabel: l10n.cancel,
    barrierColor: CupertinoColors.black.withValues(alpha: 0.42),
    transitionDuration: const Duration(milliseconds: 180),
    pageBuilder: (dialogContext, animation, secondaryAnimation) {
      return PresetPreviewDialog(
        preset: preset,
        onEdit: onEdit,
        onPreviewWorldInfo: onPreviewWorldInfo,
        onDuplicate: onDuplicate,
        onExport: onExport,
      );
    },
    transitionBuilder: (context, animation, secondaryAnimation, child) {
      final curved = CurvedAnimation(
        parent: animation,
        curve: Curves.easeOutCubic,
        reverseCurve: Curves.easeInCubic,
      );
      return FadeTransition(
        opacity: curved,
        child: ScaleTransition(
          scale: Tween<double>(begin: 0.97, end: 1).animate(curved),
          child: child,
        ),
      );
    },
  );
}

class PresetPreviewDialog extends StatefulWidget {
  const PresetPreviewDialog({
    super.key,
    required this.preset,
    this.onEdit,
    this.onPreviewWorldInfo,
    required this.onDuplicate,
    required this.onExport,
  });

  final PromptPreset preset;
  final VoidCallback? onEdit;
  final VoidCallback? onPreviewWorldInfo;
  final VoidCallback onDuplicate;
  final VoidCallback onExport;

  @override
  State<PresetPreviewDialog> createState() => _PresetPreviewDialogState();
}

class _PresetPreviewDialogState extends State<PresetPreviewDialog> {
  var _tabIndex = 0;

  PromptPreset get _preset => widget.preset;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final media = MediaQuery.sizeOf(context);
    final wide = media.width >= 900;
    final width = math.min(media.width - (wide ? 64 : 24), 1160.0);
    final height = math.min(media.height * 0.9, 820.0);
    final surface = CupertinoColors.systemBackground.resolveFrom(context);

    return SafeArea(
      child: Center(
        child: SizedBox(
          width: width,
          height: height,
          child: Container(
            clipBehavior: Clip.antiAlias,
            decoration: BoxDecoration(
              color: surface,
              borderRadius: BorderRadius.circular(18),
              boxShadow: [
                BoxShadow(
                  color: CupertinoColors.black.withValues(alpha: 0.16),
                  blurRadius: 30,
                  offset: const Offset(0, 12),
                ),
              ],
            ),
            child: Column(
              children: [
                _header(context, l10n),
                Container(
                  height: 0.5,
                  color: CupertinoColors.separator.resolveFrom(context),
                ),
                Expanded(
                  child: wide
                      ? Row(
                          crossAxisAlignment: CrossAxisAlignment.stretch,
                          children: [
                            Expanded(
                              flex: 5,
                              child: _illustrationPanel(context, wide: true),
                            ),
                            Expanded(
                              flex: 6,
                              child: SingleChildScrollView(
                                padding: const EdgeInsets.fromLTRB(
                                  24,
                                  20,
                                  24,
                                  20,
                                ),
                                child: _details(context, l10n),
                              ),
                            ),
                          ],
                        )
                      : SingleChildScrollView(
                          child: Column(
                            children: [
                              Padding(
                                padding: const EdgeInsets.fromLTRB(
                                  12,
                                  12,
                                  12,
                                  0,
                                ),
                                child: _illustrationPanel(context, wide: false),
                              ),
                              Padding(
                                padding: const EdgeInsets.fromLTRB(
                                  16,
                                  16,
                                  16,
                                  16,
                                ),
                                child: _details(context, l10n),
                              ),
                            ],
                          ),
                        ),
                ),
                Container(
                  height: 0.5,
                  color: CupertinoColors.separator.resolveFrom(context),
                ),
                _footer(context, l10n),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _header(BuildContext context, AppLocalizations l10n) {
    return SizedBox(
      width: double.infinity,
      height: 58,
      child: Stack(
        alignment: Alignment.center,
        children: [
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 64),
            child: Text(
              _preset.name,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              textAlign: TextAlign.center,
              style: const TextStyle(fontSize: 17, fontWeight: FontWeight.w600),
            ),
          ),
          Positioned(
            right: 10,
            top: 13,
            child: CupertinoButton(
              padding: EdgeInsets.zero,
              onPressed: () => Navigator.of(context).pop(),
              child: const Icon(
                CupertinoIcons.xmark_circle_fill,
                size: 28,
                color: CupertinoColors.activeBlue,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _illustrationPanel(BuildContext context, {required bool wide}) {
    final asset = _illustrationAsset();
    final panel = Padding(
      padding: EdgeInsets.fromLTRB(
        wide ? 20 : 0,
        wide ? 20 : 0,
        0,
        wide ? 20 : 0,
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(14),
        child: Container(
          color: CupertinoColors.systemGrey6.resolveFrom(context),
          child: Stack(
            fit: StackFit.expand,
            children: [
              if (asset != null)
                Image.asset(
                  asset,
                  fit: wide ? BoxFit.contain : BoxFit.cover,
                  alignment: wide ? Alignment.center : Alignment.topCenter,
                  errorBuilder: (context, error, stackTrace) =>
                      _illustrationPlaceholder(context),
                )
              else
                _illustrationPlaceholder(context),
              if (asset != null)
                Positioned(
                  right: 12,
                  bottom: 12,
                  child: _illustrationButton(
                    context,
                    icon: CupertinoIcons.fullscreen,
                    onTap: () => _showIllustration(context, asset),
                  ),
                ),
            ],
          ),
        ),
      ),
    );

    // 宽布局由 Row 拉伸撑满高度；窄布局给固定高度的横幅。
    return wide ? panel : SizedBox(height: 320, child: panel);
  }

  Widget _illustrationPlaceholder(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    return Center(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          const Icon(
            CupertinoIcons.photo,
            size: 34,
            color: CupertinoColors.systemGrey,
          ),
          const SizedBox(height: 8),
          Text(
            l10n.presetDetailNoIllustration,
            style: const TextStyle(
              fontSize: 12,
              color: CupertinoColors.systemGrey,
            ),
          ),
        ],
      ),
    );
  }

  Widget _illustrationButton(
    BuildContext context, {
    required IconData icon,
    required VoidCallback onTap,
  }) {
    return CupertinoButton(
      padding: EdgeInsets.zero,
      onPressed: onTap,
      child: Container(
        width: 38,
        height: 38,
        decoration: BoxDecoration(
          color: CupertinoColors.systemBackground
              .resolveFrom(context)
              .withValues(alpha: 0.78),
          shape: BoxShape.circle,
        ),
        child: Icon(
          icon,
          size: 19,
          color: CupertinoColors.label.resolveFrom(context),
        ),
      ),
    );
  }

  Future<void> _showIllustration(BuildContext context, String asset) {
    return showGeneralDialog<void>(
      context: context,
      barrierDismissible: true,
      barrierLabel: AppLocalizations.of(context)!.cancel,
      barrierColor: CupertinoColors.black,
      pageBuilder: (dialogContext, animation, secondaryAnimation) {
        return SizedBox.expand(
          child: ColoredBox(
            color: CupertinoColors.systemBackground.resolveFrom(dialogContext),
            child: Stack(
              children: [
                Positioned.fill(
                  child: InteractiveViewer(
                    minScale: 0.8,
                    maxScale: 4,
                    child: Image.asset(
                      asset,
                      fit: BoxFit.contain,
                      errorBuilder: (context, error, stackTrace) =>
                          const Center(
                            child: Icon(
                              CupertinoIcons.photo,
                              size: 42,
                              color: CupertinoColors.systemGrey,
                            ),
                          ),
                    ),
                  ),
                ),
                Positioned(
                  top: MediaQuery.paddingOf(dialogContext).top + 12,
                  right: 16,
                  child: CupertinoButton(
                    padding: EdgeInsets.zero,
                    onPressed: () => Navigator.of(dialogContext).pop(),
                    child: const Icon(
                      CupertinoIcons.xmark_circle_fill,
                      size: 30,
                      color: CupertinoColors.activeBlue,
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
    final overview = sections
        .where((section) => section.tag != 'example_dialogue')
        .toList(growable: false);
    final examples = sections
        .where((section) => section.tag == 'example_dialogue')
        .toList(growable: false);
    final fallback = cjkFontFallbackForLocale(
      Localizations.maybeLocaleOf(context),
    );
    final tokenCount = TokenEstimator.estimate(_preset.systemPrompt);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        if (_preset.description.trim().isNotEmpty)
          Text(
            _preset.description,
            style: TextStyle(
              fontSize: 22,
              height: 1.3,
              fontWeight: FontWeight.w700,
              fontFamilyFallback: fallback,
            ),
          ),
        if (_preset.description.trim().isNotEmpty) const SizedBox(height: 16),
        _infoCard(context, l10n, fallback, tokenCount),
        if (tokenCount > 4000) ...[
          const SizedBox(height: 10),
          _warning(
            context,
            tokenCount > 8000
                ? l10n.presetTokenStrongWarning
                : l10n.presetTokenWarning,
            tokenCount > 8000
                ? CupertinoColors.systemRed
                : CupertinoColors.systemOrange,
          ),
        ],
        if (_preset.isBroken) ...[
          const SizedBox(height: 10),
          _warning(
            context,
            '${l10n.presetBrokenLabel} · '
            '${l10n.presetBrokenReason(_preset.brokenReason ?? l10n.presetBrokenLabel)}',
            CupertinoColors.systemRed,
          ),
        ],
        const SizedBox(height: 16),
        _tabBar(context, l10n),
        const SizedBox(height: 16),
        switch (_tabIndex) {
          1 => _worldInfoTab(context, l10n),
          2 => _exampleTab(context, l10n, examples),
          _ => PresetSectionsView(sections: overview),
        },
      ],
    );
  }

  Widget _infoCard(
    BuildContext context,
    AppLocalizations l10n,
    List<String> fallback,
    int tokenCount,
  ) {
    final secondary = CupertinoColors.secondaryLabel.resolveFrom(context);
    final labelColor = CupertinoColors.label.resolveFrom(context);
    final rows = <Widget>[];

    void addRow(Widget row) {
      if (rows.isNotEmpty) {
        rows.add(
          Container(
            height: 0.5,
            color: CupertinoColors.separator.resolveFrom(context),
          ),
        );
      }
      rows.add(row);
    }

    void addTextRow(String label, String value, {Color? valueColor}) {
      addRow(
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 11),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(label, style: TextStyle(fontSize: 14, color: secondary)),
              const SizedBox(width: 12),
              Expanded(
                child: Text(
                  value,
                  textAlign: TextAlign.right,
                  style: TextStyle(
                    fontSize: 14,
                    color: valueColor ?? labelColor,
                    fontFamilyFallback: fallback,
                  ),
                ),
              ),
            ],
          ),
        ),
      );
    }

    addTextRow(
      _withoutColon(l10n.authorLabel),
      _preset.author.trim().isEmpty ? '—' : _preset.author,
    );
    addTextRow(_withoutColon(l10n.versionLabel), _preset.version);
    if (_preset.language != null) {
      addTextRow(
        _withoutColon(l10n.presetLanguageLabel),
        _preset.language!.toUpperCase(),
      );
    }
    if (_preset.tags.isNotEmpty) {
      addTextRow(
        l10n.presetTagsLabel,
        _preset.tags.map((tag) => '#$tag').join(' '),
      );
    }

    addTextRow(
      l10n.presetLengthLabel,
      l10n.presetTokenEstimate(tokenCount),
      valueColor: tokenCount > 4000 ? CupertinoColors.systemOrange : null,
    );

    return Container(
      decoration: BoxDecoration(
        color: CupertinoColors.systemGrey6.resolveFrom(context),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Column(children: rows),
    );
  }

  String _withoutColon(String value) {
    return value.replaceFirst(RegExp(r'[:：]\s*$'), '');
  }

  Widget _tabBar(BuildContext context, AppLocalizations l10n) {
    final tabs = [
      l10n.presetDetailOverview,
      l10n.worldInfo,
      l10n.presetDetailExample,
    ];
    final background = CupertinoColors.systemGrey5.resolveFrom(context);
    final selected = CupertinoColors.systemBackground.resolveFrom(context);
    final secondary = CupertinoColors.secondaryLabel.resolveFrom(context);

    return Container(
      padding: const EdgeInsets.all(4),
      decoration: BoxDecoration(
        color: background,
        borderRadius: BorderRadius.circular(12),
      ),
      child: Row(
        children: [
          for (var index = 0; index < tabs.length; index++)
            Expanded(
              child: GestureDetector(
                onTap: () => setState(() => _tabIndex = index),
                child: AnimatedContainer(
                  duration: const Duration(milliseconds: 160),
                  padding: const EdgeInsets.symmetric(vertical: 9),
                  decoration: BoxDecoration(
                    color: _tabIndex == index
                        ? selected
                        : CupertinoColors.transparent,
                    borderRadius: BorderRadius.circular(9),
                    boxShadow: _tabIndex == index
                        ? [
                            BoxShadow(
                              color: CupertinoColors.black.withValues(
                                alpha: 0.06,
                              ),
                              blurRadius: 4,
                              offset: const Offset(0, 1),
                            ),
                          ]
                        : null,
                  ),
                  child: Text(
                    tabs[index],
                    textAlign: TextAlign.center,
                    style: TextStyle(
                      fontSize: 14,
                      fontWeight: _tabIndex == index
                          ? FontWeight.w600
                          : FontWeight.w500,
                      color: _tabIndex == index
                          ? CupertinoColors.label.resolveFrom(context)
                          : secondary,
                    ),
                  ),
                ),
              ),
            ),
        ],
      ),
    );
  }

  Widget _worldInfoTab(BuildContext context, AppLocalizations l10n) {
    final info = _preset.worldInfo;
    if (info == null) {
      return _emptyState(context, l10n.presetDetailNoWorldInfo);
    }

    final secondary = CupertinoColors.secondaryLabel.resolveFrom(context);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        if (info.name.trim().isNotEmpty) ...[
          Text(
            info.name,
            style: const TextStyle(fontSize: 17, fontWeight: FontWeight.w600),
          ),
          const SizedBox(height: 4),
        ],
        if (info.description.trim().isNotEmpty) ...[
          Text(
            info.description,
            style: TextStyle(fontSize: 13, color: secondary),
          ),
          const SizedBox(height: 14),
        ],
        Row(
          children: [
            Expanded(
              child: Text(
                l10n.worldInfoBackground,
                style: const TextStyle(
                  fontSize: 15,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ),
            if (widget.onPreviewWorldInfo != null)
              CupertinoButton(
                padding: EdgeInsets.zero,
                onPressed: () {
                  Navigator.of(context).pop();
                  widget.onPreviewWorldInfo!();
                },
                child: Text(l10n.worldInfoPreview),
              ),
          ],
        ),
        const SizedBox(height: 8),
        PresetSectionsView(
          sections: [
            if (info.background.trim().isNotEmpty)
              PresetSection(text: info.background),
          ],
          showLabels: false,
          emptyText: '—',
        ),
        const SizedBox(height: 10),
        Text(
          l10n.presetDetailWorldInfoStats(
            info.entries.length,
            info.scanDepth,
            info.budgetTokens,
          ),
          style: TextStyle(
            fontSize: 12,
            color: CupertinoColors.secondaryLabel.resolveFrom(context),
          ),
        ),
        if (info.entries.isNotEmpty) const SizedBox(height: 12),
        for (final entry in info.entries)
          Container(
            width: double.infinity,
            margin: const EdgeInsets.only(bottom: 8),
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: CupertinoColors.systemGrey6.resolveFrom(context),
              borderRadius: BorderRadius.circular(10),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  entry.title.isEmpty ? entry.id : entry.title,
                  style: const TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.w600,
                  ),
                ),
                if (entry.keys.isNotEmpty) ...[
                  const SizedBox(height: 4),
                  Text(
                    entry.keys.join(' · '),
                    style: TextStyle(
                      fontSize: 12,
                      color: CupertinoColors.secondaryLabel.resolveFrom(
                        context,
                      ),
                    ),
                  ),
                ],
                if (entry.content.trim().isNotEmpty) ...[
                  const SizedBox(height: 6),
                  ReadOnlyMarkdown(data: entry.content),
                ],
              ],
            ),
          ),
      ],
    );
  }

  Widget _exampleTab(
    BuildContext context,
    AppLocalizations l10n,
    List<PresetSection> examples,
  ) {
    if (examples.isEmpty) {
      return _emptyState(context, l10n.presetDetailNoExample);
    }
    return PresetSectionsView(sections: examples, showLabels: false);
  }

  Widget _emptyState(BuildContext context, String text) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: CupertinoColors.systemGrey6.resolveFrom(context),
        borderRadius: BorderRadius.circular(10),
      ),
      child: Text(text),
    );
  }

  Widget _warning(BuildContext context, String text, Color color) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(10),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(8),
      ),
      child: Text(text, style: TextStyle(fontSize: 12, color: color)),
    );
  }

  Widget _footer(BuildContext context, AppLocalizations l10n) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 10, 16, 14),
      child: Wrap(
        alignment: WrapAlignment.center,
        crossAxisAlignment: WrapCrossAlignment.center,
        spacing: 8,
        runSpacing: 4,
        children: [
          if (widget.onEdit != null)
            CupertinoButton(
              onPressed: () => _closeThen(widget.onEdit!),
              child: Text(l10n.presetEditTitle),
            ),
          CupertinoButton.filled(
            onPressed: () => _closeThen(widget.onDuplicate),
            child: Text(l10n.presetDuplicate),
          ),
          CupertinoButton(
            onPressed: () => _closeThen(widget.onExport),
            child: Text(l10n.presetExport),
          ),
        ],
      ),
    );
  }

  void _closeThen(VoidCallback action) {
    Navigator.of(context).pop();
    action();
  }

  String? _illustrationAsset() {
    if (_preset.isUserPreset) return null;
    final promptFile = _preset.promptFile;
    if (promptFile == null || promptFile.isEmpty) return null;
    final base = path.basenameWithoutExtension(promptFile).toLowerCase();
    return 'assets/prompt/characters/img/illustration/$base.png';
  }
}
