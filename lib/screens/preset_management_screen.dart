import 'dart:convert';
import 'dart:io';
import 'dart:typed_data';

import 'package:cupertino_ui/cupertino_ui.dart';
import 'package:file_picker/file_picker.dart';
import 'package:path/path.dart' as path;
import 'package:url_launcher/url_launcher.dart';

import '../services/preset_repository.dart';
import '../services/prompt_service.dart';
import '../services/http_server_service.dart';
import '../models/preset_import_result.dart';
import '../models/preset_load_result.dart';
import '../models/prompt_preset.dart';
import '../l10n/app_localizations.dart';
import '../utils/file_save_utils.dart';
import '../utils/lumenflow_error_messages.dart';
import '../utils/preset_filter.dart';
import '../utils/preset_tags.dart';
import '../widgets/preset_avatar.dart';
import '../utils/token_estimator.dart';
import '../widgets/preset_metadata_fields.dart';
import '../widgets/preset_preview_dialog.dart';
import '../widgets/settings/settings_page_scaffold.dart';
import 'world_info_preview_screen.dart';

/// 预设管理界面
///
/// 显示内置预设和用户预设，支持导入XML文件作为新预设
class PresetManagementScreen extends StatefulWidget {
  final bool embedded;

  const PresetManagementScreen({super.key, this.embedded = false});

  @override
  State<PresetManagementScreen> createState() => _PresetManagementScreenState();
}

class _PresetManagementScreenState extends State<PresetManagementScreen> {
  final PromptService _promptService = PromptService();
  final PresetRepository _presetRepository = PresetRepository.instance;
  final HttpServerService _httpServerService = HttpServerService();

  List<PromptPreset> _builtInPresets = [];
  List<PromptPreset> _userPresets = [];
  List<PresetLoadIssue> _issues = const [];
  bool _showIssues = false;
  String? _filterLanguage;
  String? _filterTag;
  bool _isLoading = true;
  String? _errorMessage;

  // HTTP服务器状态
  bool _isHttpServerRunning = false;
  String? _httpServerUrl;

  @override
  void initState() {
    super.initState();
    _presetRepository.addListener(_onPresetsChanged);
    _loadPresets();
    _initHttpServerState();
  }

  void _onPresetsChanged() {
    if (!mounted) return;
    _applyRepositoryState();
  }

  void _applyRepositoryState() {
    final allPresets = _presetRepository.presets;
    final userPresets =
        allPresets.where((preset) => preset.id.startsWith('user_')).toList()
          ..sort((a, b) {
            final aTime =
                a.updatedAt ??
                a.createdAt ??
                DateTime.fromMillisecondsSinceEpoch(0);
            final bTime =
                b.updatedAt ??
                b.createdAt ??
                DateTime.fromMillisecondsSinceEpoch(0);
            return bTime.compareTo(aTime);
          });
    setState(() {
      _isLoading = _presetRepository.isLoading && allPresets.isEmpty;
      _builtInPresets = allPresets
          .where((preset) => !preset.id.startsWith('user_'))
          .toList();
      _userPresets = userPresets;
      _issues = _presetRepository.issues;
    });
  }

  /// 初始化HTTP服务器状态
  void _initHttpServerState() {
    // 设置初始状态
    _isHttpServerRunning = _httpServerService.isRunning;
    _httpServerUrl = _httpServerService.serverUrl;

    // 监听状态变化
    _httpServerService.isRunningNotifier.addListener(
      _updateHttpServerRunningState,
    );
    _httpServerService.serverUrlNotifier.addListener(_updateHttpServerUrlState);
  }

  /// 更新HTTP服务器运行状态
  void _updateHttpServerRunningState() {
    if (mounted) {
      setState(() {
        _isHttpServerRunning = _httpServerService.isRunningNotifier.value;
      });
    }
  }

  /// 更新HTTP服务器URL状态
  void _updateHttpServerUrlState() {
    if (mounted) {
      setState(() {
        _httpServerUrl = _httpServerService.serverUrlNotifier.value;
      });
    }
  }

  @override
  void dispose() {
    _presetRepository.removeListener(_onPresetsChanged);
    // 移除监听器
    _httpServerService.isRunningNotifier.removeListener(
      _updateHttpServerRunningState,
    );
    _httpServerService.serverUrlNotifier.removeListener(
      _updateHttpServerUrlState,
    );
    super.dispose();
  }

  /// 切换HTTP服务器状态
  Future<void> _toggleHttpServer() async {
    final l10n = AppLocalizations.of(context)!;
    try {
      await _httpServerService.toggle();
    } catch (e) {
      if (mounted) {
        _showErrorMessage(l10n.httpServerOperationFailed(e.toString()));
      }
    }
  }

  /// 加载预设列表
  Future<void> _loadPresets() async {
    if (!mounted) return;
    if (mounted) {
      setState(() {
        _isLoading = true;
        _errorMessage = null;
      });
    }

    try {
      await _presetRepository.ensureLoaded(force: true);
      if (mounted) {
        _applyRepositoryState();
      }
    } catch (e) {
      if (mounted) {
        final l10n = AppLocalizations.of(context)!;
        setState(() {
          _errorMessage = l10n.loadPresetsFailed(e.toString());
        });
      }
    } finally {
      if (mounted) {
        setState(() {
          _isLoading = false;
        });
      }
    }
  }

  /// 导入XML文件
  Future<void> _importXmlFile() async {
    if (!mounted) return;
    final l10n = AppLocalizations.of(context)!;
    try {
      final platformFile = await FilePicker.pickFile(
        type: FileType.custom,
        allowedExtensions: ['xml', 'txt', 'lumenflow'],
      );

      if (platformFile == null) return;

      if (platformFile.path == null || platformFile.path!.isEmpty) {
        if (mounted) {
          _showErrorMessage(l10n.filePathError);
        }
        return;
      }
      // 需要将PlatformFile转换为File
      // 由于FilePicker返回的是PlatformFile，我们需要使用其路径创建File对象
      final sourceFile = File(platformFile.path!);
      final extension = path.extension(sourceFile.path).toLowerCase();

      if (extension == '.lumenflow') {
        final bytes = await sourceFile.readAsBytes();
        final preview = await _promptService.inspectCharacterCardArchive(bytes);
        if (!mounted) return;
        if (!preview.validation.isValid) {
          await _showValidationErrors(preview.validation);
          return;
        }
        await _showImportDialog(
          sourceFile,
          preview.validation,
          isText: false,
          characterArchiveBytes: bytes,
          archivePreview: preview,
        );
        return;
      }

      final isText = extension == '.txt';
      final validation = isText
          ? await _promptService.validateTextFile(sourceFile)
          : await _promptService.validatePresetFile(sourceFile);
      if (!mounted) return;
      if (!validation.isValid) {
        await _showValidationErrors(validation);
        return;
      }

      // 显示导入对话框，允许用户编辑预设信息
      await _showImportDialog(sourceFile, validation, isText: isText);
    } catch (e) {
      if (mounted) {
        _showErrorMessage(
          l10n.importFailedError(lumenflowErrorMessage(e, l10n)),
        );
      }
    }
  }

  String _validationErrorText(
    PresetValidationError error,
    AppLocalizations l10n,
  ) {
    return switch (error) {
      PresetValidationError.emptyFile => l10n.presetImportErrorEmpty,
      PresetValidationError.fileTooLarge => l10n.presetImportErrorTooLarge,
      PresetValidationError.invalidUtf8 => l10n.presetImportErrorInvalidUtf8,
      PresetValidationError.invalidXml => l10n.presetImportErrorInvalidXml,
      PresetValidationError.invalidRoot => l10n.presetImportErrorInvalidRoot,
    };
  }

  Future<void> _showValidationErrors(PresetValidationResult validation) async {
    if (!mounted) return;
    final l10n = AppLocalizations.of(context)!;
    await showCupertinoDialog<void>(
      context: context,
      builder: (dialogContext) => CupertinoAlertDialog(
        title: Text(l10n.presetImportErrorTitle),
        content: Text(
          validation.errors
              .map((error) => _validationErrorText(error, l10n))
              .join('\n'),
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

  /// 显示导入对话框
  Future<PromptPreset?> _showImportDialog(
    File sourceFile,
    PresetValidationResult validation, {
    required bool isText,
    Uint8List? characterArchiveBytes,
    CharacterCardArchivePreview? archivePreview,
  }) async {
    if (!mounted) return null;
    final l10n = AppLocalizations.of(context)!;
    String? language = archivePreview?.language;
    String selectedIcon = archivePreview?.icon ?? 'person.fill';
    final nameController = TextEditingController(
      text:
          archivePreview?.name ??
          validation.extractedName ??
          path.basenameWithoutExtension(sourceFile.path),
    );
    final descriptionController = TextEditingController(
      text: archivePreview?.description ?? '',
    );
    final authorController = TextEditingController(
      text: archivePreview?.author ?? '',
    );
    final versionController = TextEditingController(
      text: archivePreview?.version ?? 'v1.0',
    );
    final tagsController = TextEditingController(
      text: archivePreview?.tags.join(', ') ?? '',
    );
    var isImporting = false;

    List<String> parsedTags() {
      return parsePresetTags(tagsController.text);
    }

    Future<PromptPreset?> import({required bool allowDuplicate}) async {
      try {
        if (characterArchiveBytes != null) {
          return await _presetRepository.importCharacterCardArchive(
            characterArchiveBytes,
            name: nameController.text,
            description: descriptionController.text,
            author: authorController.text,
            version: versionController.text,
            icon: selectedIcon,
            language: language ?? '',
            tags: parsedTags(),
            allowDuplicate: allowDuplicate,
          );
        }
        if (isText) {
          return await _presetRepository.importTextPreset(
            sourceFile,
            name: nameController.text,
            description: descriptionController.text,
            author: authorController.text,
            version: versionController.text,
            icon: selectedIcon,
            language: language,
            tags: parsedTags(),
            allowDuplicate: allowDuplicate,
          );
        }
        return await _presetRepository.importPreset(
          sourceFile,
          name: nameController.text,
          description: descriptionController.text,
          author: authorController.text,
          version: versionController.text,
          icon: selectedIcon,
          language: language,
          tags: parsedTags(),
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
          return import(allowDuplicate: true);
        }
        return null;
      }
    }

    final result = await showCupertinoModalPopup<PromptPreset?>(
      context: context,
      builder: (dialogContext) {
        return StatefulBuilder(
          builder: (sheetContext, setSheetState) {
            return CupertinoAlertDialog(
              title: Text(l10n.importPresetDialogTitle),
              content: SizedBox(
                width: 280,
                child: SingleChildScrollView(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      PresetMetadataFields(
                        nameController: nameController,
                        descriptionController: descriptionController,
                        authorController: authorController,
                        versionController: versionController,
                        tagsController: tagsController,
                        selectedIcon: selectedIcon,
                        language: language,
                        onIconChanged: (value) =>
                            setSheetState(() => selectedIcon = value),
                        onLanguageChanged: (value) =>
                            setSheetState(() => language = value),
                      ),
                      const SizedBox(height: 8),
                      Builder(
                        builder: (context) {
                          final tokens = TokenEstimator.estimate(
                            validation.content,
                          );
                          return Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                l10n.presetTokenEstimate(tokens),
                                style: const TextStyle(
                                  fontSize: 12,
                                  color: CupertinoColors.systemGrey,
                                ),
                              ),
                              if (tokens > 4000)
                                Text(
                                  tokens > 8000
                                      ? l10n.presetTokenStrongWarning
                                      : l10n.presetTokenWarning,
                                  style: TextStyle(
                                    fontSize: 12,
                                    color: tokens > 8000
                                        ? CupertinoColors.systemRed
                                        : CupertinoColors.systemOrange,
                                  ),
                                ),
                            ],
                          );
                        },
                      ),
                      if (validation.warnings.contains(
                        PresetValidationWarning.missingRoleName,
                      )) ...[
                        const SizedBox(height: 8),
                        Text(
                          l10n.presetImportWarningNameMissing,
                          style: const TextStyle(
                            fontSize: 12,
                            color: CupertinoColors.systemOrange,
                          ),
                        ),
                      ],
                      if (archivePreview?.worldInfoInvalid == true) ...[
                        const SizedBox(height: 8),
                        Text(
                          l10n.lumenflowWorldInfoInvalid,
                          style: const TextStyle(
                            fontSize: 12,
                            color: CupertinoColors.systemOrange,
                          ),
                        ),
                      ],
                      if (archivePreview?.avatarInvalid == true) ...[
                        const SizedBox(height: 8),
                        Text(
                          l10n.lumenflowAvatarInvalid,
                          style: const TextStyle(
                            fontSize: 12,
                            color: CupertinoColors.systemOrange,
                          ),
                        ),
                      ],
                    ],
                  ),
                ),
              ),
              actions: [
                CupertinoDialogAction(
                  child: Text(l10n.cancel),
                  onPressed: () => Navigator.pop(dialogContext),
                ),
                CupertinoDialogAction(
                  child: isImporting
                      ? const CupertinoActivityIndicator(radius: 7)
                      : Text(l10n.importButton),
                  onPressed: () async {
                    if (isImporting) return;
                    setSheetState(() => isImporting = true);
                    try {
                      final preset = await import(allowDuplicate: false);
                      if (preset != null && mounted) {
                        // ignore: use_build_context_synchronously
                        Navigator.pop(dialogContext, preset);
                      }
                    } on PresetValidationException catch (error) {
                      if (mounted) {
                        // ignore: use_build_context_synchronously
                        Navigator.pop(dialogContext);
                        await _showValidationErrors(error.validation);
                      }
                    } catch (error) {
                      if (mounted) {
                        // ignore: use_build_context_synchronously
                        Navigator.pop(dialogContext);
                        _showErrorMessage(
                          l10n.importFailedError(
                            lumenflowErrorMessage(error, l10n),
                          ),
                        );
                      }
                    } finally {
                      if (dialogContext.mounted) {
                        setSheetState(() => isImporting = false);
                      }
                    }
                  },
                ),
              ],
            );
          },
        );
      },
    );

    nameController.dispose();
    descriptionController.dispose();
    authorController.dispose();
    versionController.dispose();
    tagsController.dispose();
    return result;
  }

  /// 删除用户预设
  Future<void> _deleteUserPreset(PromptPreset preset) async {
    if (!mounted) return;
    final l10n = AppLocalizations.of(context)!;
    final confirmed = await showCupertinoModalPopup<bool>(
      context: context,
      builder: (context) => CupertinoAlertDialog(
        title: Text(l10n.deletePresetDialogTitle),
        content: Text(l10n.deletePresetConfirm(preset.name)),
        actions: [
          CupertinoDialogAction(
            child: Text(l10n.cancel),
            onPressed: () => Navigator.pop(context, false),
          ),
          CupertinoDialogAction(
            child: Text(l10n.delete),
            onPressed: () => Navigator.pop(context, true),
          ),
        ],
      ),
    );

    if (confirmed == true) {
      try {
        await _presetRepository.deletePreset(preset.id);
      } catch (e) {
        if (mounted) {
          _showErrorMessage(l10n.deleteFailedError(e.toString()));
        }
      }
    }
  }

  /// 显示错误消息
  void _showErrorMessage(String message) {
    showCupertinoSnackBar(
      context: context,
      message: message,
      duration: const Duration(seconds: 3),
    );
  }

  /// 打开角色卡生成器网页
  Future<void> _launchRoleCardGenerator() async {
    final l10n = AppLocalizations.of(context)!;

    if (!_isHttpServerRunning) {
      // 服务器未运行，询问是否启动
      final confirmed = await showCupertinoModalPopup<bool>(
        context: context,
        builder: (context) => CupertinoAlertDialog(
          title: Text(l10n.httpServerNotRunningTitle),
          content: Text(l10n.httpServerNotRunningMessage),
          actions: [
            CupertinoDialogAction(
              child: Text(l10n.cancel),
              onPressed: () => Navigator.pop(context, false),
            ),
            CupertinoDialogAction(
              child: Text(l10n.startServerButton),
              onPressed: () => Navigator.pop(context, true),
            ),
          ],
        ),
      );

      if (confirmed != true) {
        return; // 用户取消
      }

      // 启动服务器
      await _toggleHttpServer();

      // 等待服务器启动
      await Future.delayed(const Duration(milliseconds: 500));
    }

    // 现在服务器应该运行了，打开实际绑定的端口。
    final serverUrl = _httpServerUrl ?? _httpServerService.serverUrl;
    if (serverUrl == null) {
      _showErrorMessage(l10n.httpServerOperationFailed('server not running'));
      return;
    }
    final url = Uri.parse('$serverUrl/');
    try {
      if (!await launchUrl(url)) {
        throw Exception('Could not launch $url');
      }
    } catch (e) {
      if (mounted) {
        _showErrorMessage(l10n.openLinkFailed(e.toString()));
      }
    }
  }

  String _issuePresetName(PresetLoadIssue issue) {
    final all = [..._builtInPresets, ..._userPresets];
    for (final preset in all) {
      if (preset.id == issue.presetId) return preset.name;
    }
    return issue.message;
  }

  String _issueText(PresetLoadIssue issue, AppLocalizations l10n) {
    switch (issue.type) {
      case PresetIssueType.builtInMetaMissing:
        return l10n.presetIssueBuiltInMetaMissing(issue.message);
      case PresetIssueType.userJsonCorrupt:
        final backupName = issue.backupName;
        return backupName != null
            ? l10n.presetIssueUserJsonCorrupt(backupName)
            : l10n.presetIssueUserJsonCorruptNoBackup(issue.message);
      case PresetIssueType.userEntryInvalid:
        return l10n.presetIssueUserEntryInvalid(issue.message);
      case PresetIssueType.userJsonWriteFailed:
        return l10n.presetIssueUserJsonWriteFailed(issue.message);
      case PresetIssueType.userMigrationBackupFailed:
        return l10n.presetIssueUserMigrationBackupFailed(issue.message);
      case PresetIssueType.cardFileMissing:
        return l10n.presetIssueCardFileMissing(_issuePresetName(issue));
      case PresetIssueType.cardFileUnreadable:
        return l10n.presetIssueCardFileUnreadable(_issuePresetName(issue));
      case PresetIssueType.worldInfoInvalid:
        return l10n.presetIssueWorldInfoInvalid(_issuePresetName(issue));
    }
  }

  Widget _buildIssuesBanner(AppLocalizations l10n) {
    final warning = CupertinoColors.systemOrange.resolveFrom(context);
    return Container(
      margin: const EdgeInsets.fromLTRB(16, 12, 16, 0),
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
      decoration: BoxDecoration(
        color: warning.withValues(alpha: 0.12),
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: warning.withValues(alpha: 0.35), width: 0.5),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          GestureDetector(
            behavior: HitTestBehavior.opaque,
            onTap: () => setState(() => _showIssues = !_showIssues),
            child: Row(
              children: [
                Icon(
                  CupertinoIcons.exclamationmark_triangle,
                  size: 18,
                  color: warning,
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    '${l10n.presetIssuesTitle} · ${l10n.presetIssuesCount(_issues.length)}',
                    style: TextStyle(
                      fontSize: 13,
                      fontWeight: FontWeight.w500,
                      color: warning,
                    ),
                  ),
                ),
                Icon(
                  _showIssues
                      ? CupertinoIcons.chevron_up
                      : CupertinoIcons.chevron_down,
                  size: 14,
                  color: warning,
                ),
              ],
            ),
          ),
          if (_showIssues) ...[
            const SizedBox(height: 8),
            for (final issue in _issues)
              Padding(
                padding: const EdgeInsets.only(top: 4),
                child: Text(
                  '• ${_issueText(issue, l10n)}',
                  style: TextStyle(
                    fontSize: 12,
                    color: CupertinoColors.secondaryLabel.resolveFrom(context),
                  ),
                ),
              ),
          ],
        ],
      ),
    );
  }

  Widget _filterChip(String label, bool selected, VoidCallback onTap) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        margin: const EdgeInsets.only(right: 6),
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
        decoration: BoxDecoration(
          color: selected
              ? CupertinoColors.activeBlue.withAlpha(38)
              : CupertinoColors.systemGrey6.resolveFrom(context),
          borderRadius: BorderRadius.circular(14),
        ),
        child: Text(
          label,
          style: TextStyle(
            fontSize: 12,
            color: selected
                ? CupertinoColors.activeBlue
                : CupertinoColors.secondaryLabel.resolveFrom(context),
          ),
        ),
      ),
    );
  }

  Widget _buildFilterBar(AppLocalizations l10n) {
    final all = [..._builtInPresets, ..._userPresets];
    final languages =
        all
            .map((preset) => preset.language)
            .whereType<String>()
            .toSet()
            .toList()
          ..sort();
    final tags = all.expand((preset) => preset.tags).toSet().toList()..sort();
    if (languages.isEmpty && tags.isEmpty) {
      return const SizedBox.shrink();
    }

    return SingleChildScrollView(
      scrollDirection: Axis.horizontal,
      padding: const EdgeInsets.fromLTRB(16, 12, 16, 0),
      child: Row(
        children: [
          _filterChip(
            l10n.presetFilterAll,
            _filterLanguage == null && _filterTag == null,
            () => setState(() {
              _filterLanguage = null;
              _filterTag = null;
            }),
          ),
          for (final language in languages)
            _filterChip(
              language.toUpperCase(),
              _filterLanguage == language && _filterTag == null,
              () => setState(() {
                _filterLanguage = language;
                _filterTag = null;
              }),
            ),
          for (final tag in tags)
            _filterChip(
              '#$tag',
              _filterTag == tag,
              () => setState(() {
                _filterTag = tag;
                _filterLanguage = null;
              }),
            ),
        ],
      ),
    );
  }

  /// 为子部件添加分隔线
  List<Widget> _addDividers(List<Widget> children) {
    final List<Widget> dividedChildren = [];
    for (int i = 0; i < children.length; i++) {
      dividedChildren.add(children[i]);
      if (i < children.length - 1) {
        dividedChildren.add(
          Container(
            height: 0.5,
            margin: const EdgeInsets.symmetric(horizontal: 16),
            color: CupertinoColors.systemGrey4,
          ),
        );
      }
    }
    return dividedChildren;
  }

  Widget _buildSection(
    BuildContext context,
    String title,
    List<Widget> children,
  ) {
    final brightness = CupertinoTheme.of(context).brightness;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.fromLTRB(16, 20, 16, 8),
          child: Text(
            title,
            style: const TextStyle(
              fontSize: 13,
              color: CupertinoColors.systemGrey,
              fontWeight: FontWeight.w500,
            ),
          ),
        ),
        Container(
          margin: const EdgeInsets.symmetric(horizontal: 16),
          decoration: BoxDecoration(
            color: brightness == Brightness.dark
                ? CupertinoColors.systemBackground.darkColor
                : CupertinoColors.systemBackground.color,
            borderRadius: BorderRadius.circular(12),
            border: Border.all(color: CupertinoColors.systemGrey4, width: 0.5),
          ),
          child: Column(children: _addDividers(children)),
        ),
      ],
    );
  }

  /// 构建预设列表项
  Widget _buildPresetItem(PromptPreset preset, bool isUserPreset) {
    final l10n = AppLocalizations.of(context)!;
    final brightness = CupertinoTheme.of(context).brightness;
    final isDarkMode = brightness == Brightness.dark;
    final mutedColor = CupertinoColors.systemGrey.resolveFrom(context);

    return GestureDetector(
      onTap: () {
        // 可以查看详情或编辑
        _showPresetDetails(preset);
      },
      child: Container(
        padding: const EdgeInsets.all(16),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            PresetAvatar(
              preset: preset,
              size: 36,
              showBorder: true,
              iconColor: preset.isBroken
                  ? CupertinoColors.systemGrey2
                  : CupertinoColors.activeBlue,
            ),
            const SizedBox(width: 12),
            // 名称和描述
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    preset.name,
                    style: TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.w500,
                      color: preset.isBroken
                          ? mutedColor
                          : (isDarkMode
                                ? CupertinoColors.label.darkColor
                                : CupertinoColors.label.color),
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    preset.description,
                    style: TextStyle(
                      fontSize: 14,
                      color: preset.isBroken
                          ? CupertinoColors.systemGrey2
                          : (isDarkMode
                                ? CupertinoColors.systemGrey.darkColor
                                : CupertinoColors.systemGrey),
                    ),
                  ),
                  if (preset.isBroken) ...[
                    const SizedBox(height: 4),
                    Text(
                      l10n.presetBrokenLabel,
                      style: const TextStyle(
                        fontSize: 12,
                        color: CupertinoColors.systemRed,
                      ),
                    ),
                  ],
                  if (preset.language != null || preset.tags.isNotEmpty) ...[
                    const SizedBox(height: 4),
                    Wrap(
                      spacing: 6,
                      runSpacing: 4,
                      children: [
                        if (preset.language != null)
                          Text(
                            preset.language!.toUpperCase(),
                            style: TextStyle(fontSize: 11, color: mutedColor),
                          ),
                        for (final tag in preset.tags)
                          Text(
                            '#$tag',
                            style: TextStyle(fontSize: 11, color: mutedColor),
                          ),
                      ],
                    ),
                  ],
                ],
              ),
            ),
            // 删除按钮（仅用户预设）
            if (isUserPreset)
              CupertinoButton(
                padding: EdgeInsets.zero,
                onPressed: () => _deleteUserPreset(preset),
                child: const Icon(
                  CupertinoIcons.delete,
                  color: CupertinoColors.destructiveRed,
                ),
              ),
          ],
        ),
      ),
    );
  }

  void _showPresetDetails(PromptPreset preset) {
    showPresetPreviewDialog(
      context: context,
      preset: preset,
      onEdit: preset.id.startsWith('user_')
          ? () => _showEditPresetDialog(preset)
          : null,
      onDuplicate: () => _duplicatePreset(preset),
      onExport: () => _exportPreset(preset),
      onPreviewWorldInfo: preset.worldInfo == null
          ? null
          : () {
              Navigator.of(context).push(
                CupertinoPageRoute(
                  builder: (_) =>
                      WorldInfoPreviewScreen(info: preset.worldInfo!),
                ),
              );
            },
    );
  }

  Future<void> _showEditPresetDialog(PromptPreset preset) async {
    if (!mounted) return;
    final l10n = AppLocalizations.of(context)!;
    final nameController = TextEditingController(text: preset.name);
    final descriptionController = TextEditingController(
      text: preset.description,
    );
    final authorController = TextEditingController(text: preset.author);
    final versionController = TextEditingController(text: preset.version);
    final tagsController = TextEditingController(text: preset.tags.join(', '));
    var selectedIcon = preset.icon;
    var language = preset.language;

    await showCupertinoModalPopup<void>(
      context: context,
      builder: (dialogContext) => StatefulBuilder(
        builder: (sheetContext, setSheetState) => CupertinoAlertDialog(
          title: Text(l10n.presetEditTitle),
          content: SizedBox(
            width: 280,
            child: SingleChildScrollView(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  PresetMetadataFields(
                    nameController: nameController,
                    descriptionController: descriptionController,
                    authorController: authorController,
                    versionController: versionController,
                    tagsController: tagsController,
                    selectedIcon: selectedIcon,
                    language: language,
                    onIconChanged: (value) =>
                        setSheetState(() => selectedIcon = value),
                    onLanguageChanged: (value) =>
                        setSheetState(() => language = value),
                  ),
                ],
              ),
            ),
          ),
          actions: [
            CupertinoDialogAction(
              child: Text(l10n.cancel),
              onPressed: () => Navigator.pop(dialogContext),
            ),
            CupertinoDialogAction(
              child: Text(l10n.presetSave),
              onPressed: () async {
                final name = nameController.text.trim();
                try {
                  await _presetRepository.updatePreset(
                    preset.copyWith(
                      name: name.isEmpty ? preset.name : name,
                      description: descriptionController.text.trim(),
                      author: authorController.text.trim(),
                      version: versionController.text.trim().isEmpty
                          ? 'v1.0'
                          : versionController.text.trim(),
                      icon: selectedIcon,
                      language: language,
                      clearLanguage: language == null,
                      tags: parsePresetTags(tagsController.text),
                    ),
                  );
                  if (dialogContext.mounted) {
                    Navigator.pop(dialogContext);
                  }
                } catch (error) {
                  if (mounted) {
                    _showErrorMessage(l10n.importFailedError(error.toString()));
                  }
                }
              },
            ),
          ],
        ),
      ),
    );

    nameController.dispose();
    descriptionController.dispose();
    authorController.dispose();
    versionController.dispose();
    tagsController.dispose();
  }

  Future<void> _duplicatePreset(PromptPreset preset) async {
    final l10n = AppLocalizations.of(context)!;
    try {
      await _presetRepository.duplicatePreset(
        preset,
        name: '${preset.name}${l10n.presetDuplicateSuffix}',
      );
    } catch (error) {
      if (mounted) {
        _showErrorMessage(l10n.importFailedError(error.toString()));
      }
    }
  }

  Future<void> _exportPreset(PromptPreset preset) async {
    final l10n = AppLocalizations.of(context)!;
    final safeName = preset.name
        .replaceAll(RegExp(r'[^\w一-鿿-]'), '')
        .replaceAll(RegExp(r'\s+'), '_');

    try {
      final isText =
          preset.promptFile?.toLowerCase().endsWith('.txt') ??
          !preset.systemPrompt.trimLeft().startsWith('<system_instruction');
      if (!isText) {
        final bytes = await _promptService.exportCharacterCardArchive(preset);
        final fileName = '${safeName.isEmpty ? preset.id : safeName}.lumenflow';
        final result = await saveExportBytes(fileName: fileName, bytes: bytes);
        if (result.isCancelled) return;
        if (mounted) {
          _showErrorMessage('${l10n.presetExportSuccess}: ${result.filePath}');
        }
        return;
      }

      final content = preset.systemPrompt;
      if (content.trim().isEmpty) {
        _showErrorMessage(l10n.presetExportFailed);
        return;
      }
      final fileName =
          '${safeName.isEmpty ? preset.id : safeName}_${DateTime.now().millisecondsSinceEpoch}.txt';
      final result = await saveExportBytes(
        fileName: fileName,
        bytes: utf8.encode(content),
      );
      if (result.isCancelled) return;
      if (mounted) {
        _showErrorMessage('${l10n.presetExportSuccess}: ${result.filePath}');
      }
    } catch (error) {
      if (mounted) {
        _showErrorMessage(l10n.importFailedError(error.toString()));
      }
    }
  }

  /// 显示Cupertino风格的消息条
  void showCupertinoSnackBar({
    required BuildContext context,
    required String message,
    Duration duration = const Duration(seconds: 2),
  }) {
    final overlay = Overlay.of(context);
    final overlayEntry = OverlayEntry(
      builder: (context) => Positioned(
        top: MediaQuery.of(context).padding.top + 50,
        left: 16,
        right: 16,
        child: CupertinoAlertDialog(content: Text(message)),
      ),
    );

    overlay.insert(overlayEntry);
    Future.delayed(duration, () => overlayEntry.remove());
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final builtIn = filterPresets(
      _builtInPresets,
      language: _filterLanguage,
      tag: _filterTag,
    );
    final userPresets = filterPresets(
      _userPresets,
      language: _filterLanguage,
      tag: _filterTag,
    );
    final hasAnyPresets = _builtInPresets.isNotEmpty || _userPresets.isNotEmpty;
    final hasActiveFilter = _filterLanguage != null || _filterTag != null;

    return SettingsPageScaffold(
      title: l10n.presetManagement,
      embedded: widget.embedded,
      trailing: CupertinoButton(
        padding: EdgeInsets.zero,
        onPressed: _importXmlFile,
        child: const Icon(CupertinoIcons.add),
      ),
      child: _isLoading
          ? const Center(child: CupertinoActivityIndicator())
          : _errorMessage != null
          ? Center(child: Text(_errorMessage!))
          : ListView(
              children: [
                if (_issues.isNotEmpty) _buildIssuesBanner(l10n),
                if (hasAnyPresets) _buildFilterBar(l10n),
                // 内置预设部分
                if (builtIn.isNotEmpty)
                  _buildSection(
                    context,
                    l10n.builtInPresets,
                    builtIn
                        .map((preset) => _buildPresetItem(preset, false))
                        .toList(),
                  ),
                // 用户预设部分
                if (userPresets.isNotEmpty)
                  _buildSection(
                    context,
                    l10n.userPresets,
                    userPresets
                        .map((preset) => _buildPresetItem(preset, true))
                        .toList(),
                  ),
                if (hasAnyPresets &&
                    builtIn.isEmpty &&
                    userPresets.isEmpty &&
                    hasActiveFilter)
                  Padding(
                    padding: const EdgeInsets.all(32),
                    child: Text(
                      l10n.presetFilterNoResults,
                      textAlign: TextAlign.center,
                      style: TextStyle(
                        color: CupertinoColors.secondaryLabel.resolveFrom(
                          context,
                        ),
                      ),
                    ),
                  ),
                // 空状态
                if (!hasAnyPresets)
                  Padding(
                    padding: const EdgeInsets.all(32),
                    child: Column(
                      children: [
                        Icon(
                          CupertinoIcons.doc_text,
                          size: 64,
                          color: CupertinoColors.systemGrey3,
                        ),
                        const SizedBox(height: 16),
                        Text(
                          l10n.noPresetsAvailable,
                          style: TextStyle(
                            color: CupertinoColors.secondaryLabel.resolveFrom(
                              context,
                            ),
                          ),
                        ),
                        const SizedBox(height: 8),
                        Text(
                          l10n.importXmlHint,
                          style: TextStyle(
                            color: CupertinoColors.secondaryLabel.resolveFrom(
                              context,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                Padding(
                  padding: const EdgeInsets.symmetric(
                    vertical: 24,
                    horizontal: 16,
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // HTTP服务器开关行
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Row(
                            children: [
                              Transform.scale(
                                scale: 0.8,
                                child: CupertinoSwitch(
                                  value: _isHttpServerRunning,
                                  onChanged: (value) async {
                                    await _toggleHttpServer();
                                  },
                                ),
                              ),
                              const SizedBox(width: 8),
                              Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    l10n.httpServerSwitchLabel,
                                    style: TextStyle(
                                      fontSize: 14,
                                      fontWeight: FontWeight.w500,
                                      color:
                                          CupertinoTheme.of(context)
                                                  .brightness ==
                                              Brightness.dark
                                          ? CupertinoColors.label.darkColor
                                          : CupertinoColors.label.color,
                                    ),
                                  ),
                                  Text(
                                    _isHttpServerRunning
                                        ? (_httpServerUrl ??
                                              l10n.httpServerStatusRunning)
                                        : l10n.httpServerStatusStopped,
                                    style: TextStyle(
                                      fontSize: 12,
                                      color: _isHttpServerRunning
                                          ? CupertinoColors.systemGreen
                                          : CupertinoColors.systemRed,
                                    ),
                                  ),
                                ],
                              ),
                            ],
                          ),
                          if (_isHttpServerRunning && _httpServerUrl != null)
                            GestureDetector(
                              onTap: _launchRoleCardGenerator,
                              child: Text(
                                l10n.openGeneratorButton,
                                style: TextStyle(
                                  fontSize: 14,
                                  color: CupertinoColors.link,
                                  decoration: TextDecoration.underline,
                                ),
                              ),
                            ),
                        ],
                      ),
                      const SizedBox(height: 12),
                      // 链接说明
                      Text(
                        l10n.httpServerDescription,
                        style: TextStyle(
                          fontSize: 12,
                          color: CupertinoColors.secondaryLabel.resolveFrom(
                            context,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
    );
  }
}
