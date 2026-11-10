import 'package:cupertino_ui/cupertino_ui.dart';

import '../l10n/app_localizations.dart';
import '../utils/preset_icons.dart';

/// 导入与编辑预设共用的元数据表单。
class PresetMetadataFields extends StatelessWidget {
  const PresetMetadataFields({
    super.key,
    required this.nameController,
    required this.descriptionController,
    required this.authorController,
    required this.versionController,
    required this.tagsController,
    required this.selectedIcon,
    required this.language,
    required this.onIconChanged,
    required this.onLanguageChanged,
  });

  final TextEditingController nameController;
  final TextEditingController descriptionController;
  final TextEditingController authorController;
  final TextEditingController versionController;
  final TextEditingController tagsController;
  final String selectedIcon;
  final String? language;
  final ValueChanged<String> onIconChanged;
  final ValueChanged<String?> onLanguageChanged;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final muted = CupertinoColors.systemGrey.resolveFrom(context);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        CupertinoTextField(
          controller: nameController,
          placeholder: l10n.presetNamePlaceholder,
        ),
        const SizedBox(height: 8),
        CupertinoTextField(
          controller: descriptionController,
          placeholder: l10n.descriptionPlaceholder,
        ),
        const SizedBox(height: 8),
        CupertinoTextField(
          controller: authorController,
          placeholder: l10n.authorPlaceholder,
        ),
        const SizedBox(height: 8),
        CupertinoTextField(
          controller: versionController,
          placeholder: l10n.presetVersionPlaceholder,
        ),
        const SizedBox(height: 12),
        Text(l10n.presetIconLabel, style: const TextStyle(fontSize: 12)),
        const SizedBox(height: 4),
        Wrap(
          spacing: 8,
          runSpacing: 8,
          children: [
            for (final iconName in presetIconNames)
              GestureDetector(
                onTap: () => onIconChanged(iconName),
                child: Container(
                  width: 32,
                  height: 32,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    color: selectedIcon == iconName
                        ? CupertinoColors.activeBlue.withAlpha(38)
                        : CupertinoColors.systemGrey6.resolveFrom(context),
                    border: Border.all(
                      color: selectedIcon == iconName
                          ? CupertinoColors.activeBlue
                          : CupertinoColors.systemGrey4,
                      width: 0.5,
                    ),
                  ),
                  child: Icon(
                    presetIconForName(iconName),
                    size: 17,
                    color: selectedIcon == iconName
                        ? CupertinoColors.activeBlue
                        : muted,
                  ),
                ),
              ),
          ],
        ),
        const SizedBox(height: 12),
        Text(l10n.presetLanguageLabel, style: const TextStyle(fontSize: 12)),
        const SizedBox(height: 4),
        Wrap(
          spacing: 6,
          runSpacing: 6,
          children: [
            for (final locale in <String?>[
              null,
              'zh',
              'en',
              'ja',
              'ko',
              'es',
              'lzh',
            ])
              GestureDetector(
                onTap: () => onLanguageChanged(locale),
                child: Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 8,
                    vertical: 4,
                  ),
                  decoration: BoxDecoration(
                    color: language == locale
                        ? CupertinoColors.activeBlue.withAlpha(38)
                        : CupertinoColors.systemGrey6.resolveFrom(context),
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: Text(
                    locale ?? l10n.presetLanguageAny,
                    style: TextStyle(
                      fontSize: 12,
                      color: language == locale
                          ? CupertinoColors.activeBlue
                          : muted,
                    ),
                  ),
                ),
              ),
          ],
        ),
        const SizedBox(height: 8),
        CupertinoTextField(
          controller: tagsController,
          placeholder: l10n.presetTagsPlaceholder,
        ),
      ],
    );
  }
}
