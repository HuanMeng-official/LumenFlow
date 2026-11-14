import 'package:cupertino_ui/cupertino_ui.dart';

import '../l10n/app_localizations.dart';
import '../utils/app_theme.dart';
import '../utils/preset_sections.dart';
import 'read_only_markdown.dart';

/// 只读的角色卡段落列表：按标签分组，正文按 Markdown 渲染。
class PresetSectionsView extends StatelessWidget {
  const PresetSectionsView({
    super.key,
    required this.sections,
    this.showLabels = true,
    this.emptyText = '—',
  });

  final List<PresetSection> sections;
  final bool showLabels;
  final String emptyText;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final fallback = cjkFontFallbackForLocale(
      Localizations.maybeLocaleOf(context),
    );
    final surface = CupertinoColors.systemGrey6.resolveFrom(context);
    final labelColor = CupertinoColors.label.resolveFrom(context);

    if (sections.isEmpty) {
      return Container(
        width: double.infinity,
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          color: surface,
          borderRadius: BorderRadius.circular(10),
        ),
        child: Text(emptyText),
      );
    }

    return Column(
      children: [
        for (final section in sections)
          Container(
            width: double.infinity,
            margin: const EdgeInsets.only(bottom: 10),
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: surface,
              borderRadius: BorderRadius.circular(10),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                if (showLabels &&
                    presetSectionLabel(section.tag, l10n) != null) ...[
                  Text(
                    presetSectionLabel(section.tag, l10n)!,
                    style: TextStyle(
                      fontSize: 14,
                      fontWeight: FontWeight.w600,
                      color: labelColor,
                      fontFamilyFallback: fallback,
                    ),
                  ),
                  const SizedBox(height: 6),
                ],
                ReadOnlyMarkdown(data: section.text),
              ],
            ),
          ),
      ],
    );
  }
}
