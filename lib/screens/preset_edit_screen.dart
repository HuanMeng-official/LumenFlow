import 'dart:io';
import 'dart:typed_data';

import 'package:cupertino_ui/cupertino_ui.dart';
import 'package:path/path.dart' as path;

import '../l10n/app_localizations.dart';
import '../models/preset_import_result.dart';
import '../models/prompt_preset.dart';
import '../services/preset_repository.dart';
import '../services/prompt_service.dart';
import '../utils/app_theme.dart';
import '../utils/lumenflow_error_messages.dart';
import '../utils/preset_tags.dart';
import '../utils/token_estimator.dart';
import '../widgets/preset_metadata_fields.dart';
import '../widgets/settings/settings_page_scaffold.dart';
import '../widgets/settings/settings_section.dart';

/// 全屏角色预设元数据编辑页（替换旧版 280px 窄弹窗）。
class PresetEditScreen extends StatefulWidget {
  const PresetEditScreen({
    super.key,
    required this.preset,
    this.previousPageTitle,
  });

  final PromptPreset preset;
  final String? previousPageTitle;

  @override
  State<PresetEditScreen> createState() => _PresetEditScreenState();
}

class _PresetEditScreenState extends State<PresetEditScreen> {
  final PresetRepository _presetRepository = PresetRepository.instance;
  late final TextEditingController _nameController = TextEditingController(
    text: widget.preset.name,
  );
  late final TextEditingController _descriptionController =
      TextEditingController(text: widget.preset.description);
  late final TextEditingController _authorController = TextEditingController(
    text: widget.preset.author,
  );
  late final TextEditingController _versionController = TextEditingController(
    text: widget.preset.version,
  );
  late final TextEditingController _tagsController = TextEditingController(
    text: widget.preset.tags.join(', '),
  );
  late String _selectedIcon = widget.preset.icon;
  late String? _language = widget.preset.language;
  bool _isSaving = false;

  @override
  void dispose() {
    _nameController.dispose();
    _descriptionController.dispose();
    _authorController.dispose();
    _versionController.dispose();
    _tagsController.dispose();
    super.dispose();
  }

  Future<void> _save() async {
    if (_isSaving) return;
    final l10n = AppLocalizations.of(context)!;
    setState(() => _isSaving = true);
    final trimmedName = _nameController.text.trim();
    try {
      await _presetRepository.updatePreset(
        widget.preset.copyWith(
          name: trimmedName.isEmpty ? widget.preset.name : trimmedName,
          description: _descriptionController.text.trim(),
          author: _authorController.text.trim(),
          version: _versionController.text.trim().isEmpty
              ? 'v1.0'
              : _versionController.text.trim(),
          icon: _selectedIcon,
          language: _language,
          clearLanguage: _language == null,
          tags: parsePresetTags(_tagsController.text),
        ),
      );
      if (mounted) {
        Navigator.of(context).pop(true);
      }
    } catch (error) {
      if (mounted) {
        await showCupertinoDialog<void>(
          context: context,
          builder: (dialogContext) => CupertinoAlertDialog(
            title: Text(l10n.error),
            content: Text(l10n.importFailedError(error.toString())),
            actions: [
              CupertinoDialogAction(
                child: Text(l10n.ok),
                onPressed: () => Navigator.pop(dialogContext),
              ),
            ],
          ),
        );
      }
    } finally {
      if (mounted) {
        setState(() => _isSaving = false);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;

    return SettingsPageScaffold(
      title: l10n.presetEditTitle,
      previousPageTitle: widget.previousPageTitle ?? widget.preset.name,
      trailing: CupertinoButton(
        padding: EdgeInsets.zero,
        onPressed: _isSaving ? null : _save,
        child: _isSaving
            ? const CupertinoActivityIndicator(radius: 8)
            : Text(
                l10n.presetSave,
                style: const TextStyle(fontWeight: FontWeight.w600),
              ),
      ),
      child: Center(
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 720),
          child: ListView(
            padding: const EdgeInsets.only(bottom: 32),
            children: [
              SettingsSection(
                title: l10n.presetEditTitle,
                children: [
                  Padding(
                    padding: const EdgeInsets.all(16),
                    child: PresetMetadataFields(
                      nameController: _nameController,
                      descriptionController: _descriptionController,
                      authorController: _authorController,
                      versionController: _versionController,
                      tagsController: _tagsController,
                      selectedIcon: _selectedIcon,
                      language: _language,
                      onIconChanged: (value) =>
                          setState(() => _selectedIcon = value),
                      onLanguageChanged: (value) =>
                          setState(() => _language = value),
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}

/// 全屏角色卡导入确认与元数据编辑页（替换旧版 280px 窄弹窗）。
class PresetImportScreen extends StatefulWidget {
  const PresetImportScreen({
    super.key,
    required this.sourceFile,
    required this.validation,
    required this.isText,
    this.characterArchiveBytes,
    this.archivePreview,
    this.onValidationError,
    this.previousPageTitle,
  });

  final File sourceFile;
  final PresetValidationResult validation;
  final bool isText;
  final Uint8List? characterArchiveBytes;
  final CharacterCardArchivePreview? archivePreview;
  final Future<void> Function(PresetValidationResult validation)?
  onValidationError;
  final String? previousPageTitle;

  @override
  State<PresetImportScreen> createState() => _PresetImportScreenState();
}

class _PresetImportScreenState extends State<PresetImportScreen> {
  final PresetRepository _presetRepository = PresetRepository.instance;
  late final TextEditingController _nameController = TextEditingController(
    text:
        widget.archivePreview?.name ??
        widget.validation.extractedName ??
        path.basenameWithoutExtension(widget.sourceFile.path),
  );
  late final TextEditingController _descriptionController =
      TextEditingController(
        text: widget.archivePreview?.description ?? '',
      );
  late final TextEditingController _authorController = TextEditingController(
    text: widget.archivePreview?.author ?? '',
  );
  late final TextEditingController _versionController = TextEditingController(
    text: widget.archivePreview?.version ?? 'v1.0',
  );
  late final TextEditingController _tagsController = TextEditingController(
    text: widget.archivePreview?.tags.join(', ') ?? '',
  );
  late String _selectedIcon = widget.archivePreview?.icon ?? 'person.fill';
  late String? _language = widget.archivePreview?.language;
  bool _isImporting = false;

  @override
  void dispose() {
    _nameController.dispose();
    _descriptionController.dispose();
    _authorController.dispose();
    _versionController.dispose();
    _tagsController.dispose();
    super.dispose();
  }

  Future<PromptPreset?> _runImport({required bool allowDuplicate}) async {
    final l10n = AppLocalizations.of(context)!;
    final tags = parsePresetTags(_tagsController.text);
    try {
      if (widget.characterArchiveBytes != null) {
        return await _presetRepository.importCharacterCardArchive(
          widget.characterArchiveBytes!,
          name: _nameController.text,
          description: _descriptionController.text,
          author: _authorController.text,
          version: _versionController.text,
          icon: _selectedIcon,
          language: _language ?? '',
          tags: tags,
          allowDuplicate: allowDuplicate,
        );
      }
      if (widget.isText) {
        return await _presetRepository.importTextPreset(
          widget.sourceFile,
          name: _nameController.text,
          description: _descriptionController.text,
          author: _authorController.text,
          version: _versionController.text,
          icon: _selectedIcon,
          language: _language,
          tags: tags,
          allowDuplicate: allowDuplicate,
        );
      }
      return await _presetRepository.importPreset(
        widget.sourceFile,
        name: _nameController.text,
        description: _descriptionController.text,
        author: _authorController.text,
        version: _versionController.text,
        icon: _selectedIcon,
        language: _language,
        tags: tags,
        allowDuplicate: allowDuplicate,
      );
    } on PresetDuplicateException catch (duplicate) {
      if (!mounted) return null;
      final confirmed = await showCupertinoDialog<bool>(
        context: context,
        builder: (duplicateContext) => CupertinoAlertDialog(
          title: Text(l10n.presetImportDuplicateTitle),
          content: Text(
            l10n.presetImportDuplicateMessage(duplicate.existing.name),
          ),
          actions: [
            CupertinoDialogAction(
              child: Text(l10n.cancel),
              onPressed: () => Navigator.pop(duplicateContext, false),
            ),
            CupertinoDialogAction(
              child: Text(l10n.presetImportAnyway),
              onPressed: () => Navigator.pop(duplicateContext, true),
            ),
          ],
        ),
      );
      if (confirmed == true) {
        return _runImport(allowDuplicate: true);
      }
      return null;
    }
  }

  Future<void> _submit() async {
    if (_isImporting) return;
    final l10n = AppLocalizations.of(context)!;
    setState(() => _isImporting = true);
    try {
      final preset = await _runImport(allowDuplicate: false);
      if (preset != null && mounted) {
        Navigator.of(context).pop(preset);
      }
    } on PresetValidationException catch (error) {
      if (mounted) {
        Navigator.of(context).pop();
        await widget.onValidationError?.call(error.validation);
      }
    } catch (error) {
      if (mounted) {
        await showCupertinoDialog<void>(
          context: context,
          builder: (dialogContext) => CupertinoAlertDialog(
            title: Text(l10n.error),
            content: Text(
              l10n.importFailedError(lumenflowErrorMessage(error, l10n)),
            ),
            actions: [
              CupertinoDialogAction(
                child: Text(l10n.ok),
                onPressed: () => Navigator.pop(dialogContext),
              ),
            ],
          ),
        );
      }
    } finally {
      if (mounted) {
        setState(() => _isImporting = false);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final tokens = TokenEstimator.estimate(widget.validation.content);
    final warnings = <String>[
      if (tokens > 4000)
        tokens > 8000 ? l10n.presetTokenStrongWarning : l10n.presetTokenWarning,
      if (widget.validation.warnings.contains(
        PresetValidationWarning.missingRoleName,
      ))
        l10n.presetImportWarningNameMissing,
      if (widget.archivePreview?.worldInfoInvalid == true)
        l10n.lumenflowWorldInfoInvalid,
      if (widget.archivePreview?.growthInvalid == true)
        l10n.lumenflowGrowthInvalid,
      if (widget.archivePreview?.avatarInvalid == true)
        l10n.lumenflowAvatarInvalid,
      if (widget.archivePreview?.illustrationInvalid == true)
        l10n.lumenflowIllustrationInvalid,
      if (widget.archivePreview?.stageImagesInvalid == true)
        l10n.lumenflowStageImagesInvalid,
    ];

    return SettingsPageScaffold(
      title: l10n.importPresetDialogTitle,
      previousPageTitle: widget.previousPageTitle ?? l10n.characters,
      trailing: CupertinoButton(
        padding: EdgeInsets.zero,
        onPressed: _isImporting ? null : _submit,
        child: _isImporting
            ? const CupertinoActivityIndicator(radius: 8)
            : Text(
                l10n.importButton,
                style: const TextStyle(fontWeight: FontWeight.w600),
              ),
      ),
      child: Center(
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 720),
          child: ListView(
            padding: const EdgeInsets.only(bottom: 32),
            children: [
              SettingsSection(
                title: l10n.importPresetDialogTitle,
                footer: l10n.presetTokenEstimate(tokens),
                children: [
                  Padding(
                    padding: const EdgeInsets.all(16),
                    child: PresetMetadataFields(
                      nameController: _nameController,
                      descriptionController: _descriptionController,
                      authorController: _authorController,
                      versionController: _versionController,
                      tagsController: _tagsController,
                      selectedIcon: _selectedIcon,
                      language: _language,
                      onIconChanged: (value) =>
                          setState(() => _selectedIcon = value),
                      onLanguageChanged: (value) =>
                          setState(() => _language = value),
                    ),
                  ),
                ],
              ),
              if (warnings.isNotEmpty)
                SettingsSection(
                  title: l10n.presetIssuesTitle,
                  children: [
                    for (final warning in warnings)
                      Padding(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 16,
                          vertical: 11,
                        ),
                        child: Text(
                          warning,
                          style: TextStyle(
                            fontSize: 13,
                            color: warning == l10n.presetTokenStrongWarning
                                ? AppTokens.red(context)
                                : CupertinoColors.systemOrange,
                          ),
                        ),
                      ),
                  ],
                ),
            ],
          ),
        ),
      ),
    );
  }
}
