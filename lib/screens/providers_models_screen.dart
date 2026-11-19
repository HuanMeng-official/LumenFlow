import 'dart:async';

import 'package:cupertino_ui/cupertino_ui.dart';
import 'package:flutter_svg/flutter_svg.dart';

import '../l10n/app_localizations.dart';
import '../models/ai_platform.dart';
import '../services/platform_model_fetcher.dart';
import '../services/settings_service.dart';
import '../utils/app_theme.dart';
import '../utils/platform_utils.dart';
import '../widgets/desktop/desktop_popover.dart';
import '../widgets/settings/settings_input_tile.dart';
import '../widgets/settings/settings_page_scaffold.dart';
import '../widgets/settings/settings_section.dart';
import '../widgets/settings/settings_slider_tile.dart';

/// 统一的「供应商与模型」设置页，合并原平台管理、API 设置与模型参数。
///
/// 桌面与移动端均在原地展开配置表单与模型列表，取消多层 AlertDialog 嵌套。
class ProvidersModelsScreen extends StatefulWidget {
  final bool embedded;
  final String? previousPageTitle;

  const ProvidersModelsScreen({
    super.key,
    this.embedded = false,
    this.previousPageTitle,
  });

  @override
  State<ProvidersModelsScreen> createState() => _ProvidersModelsScreenState();
}

class _ProvidersModelsScreenState extends State<ProvidersModelsScreen> {
  final SettingsService _settingsService = SettingsService();
  final GlobalKey _defaultModelAnchorKey = GlobalKey();

  List<AIPlatform> _platforms = [];
  String? _currentPlatformId;
  String? _selectedPlatformId;
  bool _isLoading = true;
  bool _obscureApiKey = true;
  bool _isAddingPlatform = false;
  bool _isRefreshingModels = false;
  String _newPlatformType = 'openai';

  late final TextEditingController _nameController;
  late final TextEditingController _endpointController;
  late final TextEditingController _apiKeyController;
  late final TextEditingController _customModelController;
  late final TextEditingController _maxTokensController;
  late final TextEditingController _systemPromptController;
  late final TextEditingController _newNameController;
  late final TextEditingController _newEndpointController;
  late final TextEditingController _newApiKeyController;

  double _temperature = SettingsService.defaultTemperature;
  Timer? _saveDebounce;

  static const List<String> _availablePlatformTypes = [
    'openai',
    'gemini',
    'claude',
    'grok',
    'deepseek',
    'kimi',
    'zhipu',
    'minimax',
    'xiaomimimo',
    'siliconflow',
    'openrouter',
    'lmstudio',
    'other',
  ];

  @override
  void initState() {
    super.initState();
    _nameController = TextEditingController();
    _endpointController = TextEditingController();
    _apiKeyController = TextEditingController();
    _customModelController = TextEditingController();
    _maxTokensController = TextEditingController();
    _systemPromptController = TextEditingController();
    _newNameController = TextEditingController();
    _newEndpointController = TextEditingController();
    _newApiKeyController = TextEditingController();
    _loadData();
  }

  @override
  void dispose() {
    _saveDebounce?.cancel();
    _nameController.dispose();
    _endpointController.dispose();
    _apiKeyController.dispose();
    _customModelController.dispose();
    _maxTokensController.dispose();
    _systemPromptController.dispose();
    _newNameController.dispose();
    _newEndpointController.dispose();
    _newApiKeyController.dispose();
    super.dispose();
  }

  Future<void> _loadData() async {
    await _settingsService.migrateLegacySettings();
    final platforms = await _settingsService.getPlatforms();
    final currentId = await _settingsService.getCurrentPlatformId();
    final temperature = await _settingsService.getTemperature();
    final maxTokens = await _settingsService.getMaxTokens();
    final systemPrompt = await _settingsService.getCustomSystemPrompt();

    if (!mounted) return;
    setState(() {
      _platforms = platforms;
      _currentPlatformId = currentId;
      _selectedPlatformId = (_selectedPlatformId != null &&
              platforms.any((p) => p.id == _selectedPlatformId))
          ? _selectedPlatformId
          : (platforms.any((p) => p.id == currentId)
              ? currentId
              : (platforms.isNotEmpty ? platforms.first.id : null));
      _temperature = temperature;
      _maxTokensController.text = maxTokens.toString();
      _systemPromptController.text = systemPrompt;
      _syncSelectedControllers();
      _isLoading = false;
    });
  }

  AIPlatform? get _selectedPlatform {
    if (_platforms.isEmpty) return null;
    try {
      return _platforms.firstWhere((p) => p.id == _selectedPlatformId);
    } catch (_) {
      return _platforms.first;
    }
  }

  void _syncSelectedControllers() {
    final p = _selectedPlatform;
    if (p == null) return;
    _nameController.text = p.name;
    _endpointController.text = p.endpoint;
    _apiKeyController.text = p.apiKey;
  }

  void _selectPlatform(AIPlatform platform) {
    setState(() {
      _selectedPlatformId = platform.id;
      _isAddingPlatform = false;
      _syncSelectedControllers();
    });
  }

  void _schedulePlatformSave() {
    _saveDebounce?.cancel();
    _saveDebounce = Timer(const Duration(milliseconds: 250), () async {
      final selected = _selectedPlatform;
      if (selected == null) return;
      final updated = selected.copyWith(
        name: _nameController.text.trim().isEmpty
            ? selected.name
            : _nameController.text.trim(),
        endpoint: _endpointController.text.trim(),
        apiKey: _apiKeyController.text.trim(),
      );
      await _settingsService.savePlatform(updated);
      if (selected.id == _currentPlatformId) {
        await _settingsService.setApiEndpoint(updated.endpoint);
        await _settingsService.setApiKey(updated.apiKey);
      }
      if (!mounted) return;
      setState(() {
        final idx = _platforms.indexWhere((p) => p.id == updated.id);
        if (idx >= 0) _platforms[idx] = updated;
      });
    });
  }

  Future<void> _setActivePlatform(AIPlatform platform) async {
    await _settingsService.setCurrentPlatformId(platform.id);
    if (!mounted) return;
    setState(() {
      _currentPlatformId = platform.id;
    });
  }

  Future<void> _setDefaultModel(AIPlatform platform, String model) async {
    final updatedList = platform.availableModels.contains(model)
        ? platform.availableModels
        : [...platform.availableModels, model];
    await _settingsService.updatePlatformModels(
      platform.id,
      updatedList,
      newDefaultModel: model,
    );
    if (platform.id == _currentPlatformId) {
      await _settingsService.setModel(model);
    }
    await _loadData();
  }

  Future<void> _addCustomModel(AIPlatform platform) async {
    final modelId = _customModelController.text.trim();
    if (modelId.isEmpty) return;
    _customModelController.clear();
    final updated = <String>{...platform.availableModels, modelId}.toList();
    final newDefault =
        platform.defaultModel.isEmpty ? modelId : platform.defaultModel;
    await _settingsService.updatePlatformModels(
      platform.id,
      updated,
      newDefaultModel: newDefault,
    );
    if (platform.id == _currentPlatformId && newDefault == modelId) {
      await _settingsService.setModel(modelId);
    }
    await _loadData();
  }

  Future<void> _removeModel(AIPlatform platform, String model) async {
    final updated =
        platform.availableModels.where((m) => m != model).toList();
    final newDefault = platform.defaultModel == model
        ? (updated.isNotEmpty ? updated.first : '')
        : platform.defaultModel;
    await _settingsService.updatePlatformModels(
      platform.id,
      updated,
      newDefaultModel: newDefault,
    );
    if (platform.id == _currentPlatformId && newDefault.isNotEmpty) {
      await _settingsService.setModel(newDefault);
    }
    await _loadData();
  }

  Future<void> _refreshModels(AIPlatform platform) async {
    final l10n = AppLocalizations.of(context)!;
    if (platform.apiKey.trim().isEmpty && _apiKeyController.text.trim().isEmpty) {
      _showNotice(l10n.error, l10n.configureApiKeyFirst);
      return;
    }

    final livePlatform = platform.copyWith(
      endpoint: _endpointController.text.trim(),
      apiKey: _apiKeyController.text.trim(),
    );
    await _settingsService.savePlatform(livePlatform);

    setState(() => _isRefreshingModels = true);
    try {
      final models = await fetchPlatformModelsFromApi(livePlatform);
      if (!mounted) return;
      final newDefault = models.contains(livePlatform.defaultModel)
          ? livePlatform.defaultModel
          : (models.isNotEmpty ? models.first : '');
      await _settingsService.updatePlatformModels(
        livePlatform.id,
        models,
        newDefaultModel: newDefault,
      );
      if (livePlatform.id == _currentPlatformId && newDefault.isNotEmpty) {
        await _settingsService.setModel(newDefault);
      }
      await _loadData();
      if (mounted) _showNotice(l10n.refreshModels, l10n.modelsRefreshed);
    } catch (e) {
      if (mounted) {
        _showNotice(l10n.error, l10n.refreshModelsError(e.toString()));
      }
    } finally {
      if (mounted) setState(() => _isRefreshingModels = false);
    }
  }

  Future<void> _createNewPlatform() async {
    final name = _newNameController.text.trim();
    final endpoint = _newEndpointController.text.trim();
    if (name.isEmpty || endpoint.isEmpty) return;

    final defaults = AIPlatform.createDefaultPlatform(_newPlatformType);
    final created = AIPlatform(
      id: '${_newPlatformType}_${DateTime.now().millisecondsSinceEpoch}',
      name: name,
      type: _newPlatformType,
      endpoint: endpoint,
      apiKey: _newApiKeyController.text.trim(),
      availableModels: defaults.availableModels,
      defaultModel: defaults.defaultModel,
      enabled: true,
      icon: _newPlatformType,
    );
    await _settingsService.savePlatform(created);
    await _settingsService.setCurrentPlatformId(created.id);
    _newNameController.clear();
    _newEndpointController.clear();
    _newApiKeyController.clear();
    setState(() {
      _selectedPlatformId = created.id;
      _isAddingPlatform = false;
    });
    await _loadData();
  }

  Future<void> _deletePlatform(AIPlatform platform) async {
    final l10n = AppLocalizations.of(context)!;
    final confirmed = await showCupertinoDialog<bool>(
      context: context,
      builder: (dialogContext) => CupertinoAlertDialog(
        title: Text(l10n.deletePlatform),
        content: Text(l10n.deletePlatformConfirm(platform.name)),
        actions: [
          CupertinoDialogAction(
            child: Text(l10n.cancel),
            onPressed: () => Navigator.pop(dialogContext, false),
          ),
          CupertinoDialogAction(
            isDestructiveAction: true,
            child: Text(l10n.delete),
            onPressed: () => Navigator.pop(dialogContext, true),
          ),
        ],
      ),
    );
    if (confirmed != true) return;
    await _settingsService.deletePlatform(platform.id);
    _selectedPlatformId = null;
    await _loadData();
  }

  Future<void> _pickDefaultModel(AIPlatform platform) async {
    final l10n = AppLocalizations.of(context)!;
    final models = platform.availableModels;
    if (models.isEmpty) return;

    final useWide = useWideLayout(MediaQuery.sizeOf(context));
    if (useWide && _defaultModelAnchorKey.currentContext != null) {
      await showDesktopPopoverMenu(
        anchorContext: _defaultModelAnchorKey.currentContext!,
        width: 280,
        alignRight: true,
        items: [
          for (final model in models)
            DesktopPopoverItem(
              label: model,
              selected: model == platform.defaultModel,
              onTap: () => _setDefaultModel(platform, model),
            ),
        ],
      );
      return;
    }

    await showCupertinoModalPopup<void>(
      context: context,
      builder: (sheetContext) => CupertinoActionSheet(
        title: Text(l10n.defaultModelLabel),
        actions: [
          for (final model in models)
            CupertinoActionSheetAction(
              onPressed: () {
                Navigator.pop(sheetContext);
                _setDefaultModel(platform, model);
              },
              child: Text(
                model,
                style: TextStyle(
                  color: model == platform.defaultModel
                      ? AppTokens.accent(sheetContext)
                      : AppTokens.label(sheetContext),
                  fontWeight: model == platform.defaultModel
                      ? FontWeight.w600
                      : FontWeight.w400,
                ),
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

  void _showNotice(String title, String message) {
    final l10n = AppLocalizations.of(context)!;
    showCupertinoDialog<void>(
      context: context,
      builder: (dialogContext) => CupertinoAlertDialog(
        title: Text(title),
        content: Text(message),
        actions: [
          CupertinoDialogAction(
            child: Text(l10n.ok),
            onPressed: () => Navigator.pop(dialogContext),
          ),
        ],
      ),
    );
  }

  String _svgPathForType(String type) {
    final normalized = _availablePlatformTypes.contains(type) ? type : 'other';
    return 'assets/platform/$normalized.svg';
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    if (_isLoading) {
      return SettingsPageScaffold(
        title: l10n.providersAndModels,
        previousPageTitle: widget.previousPageTitle,
        embedded: widget.embedded,
        child: const Center(child: CupertinoActivityIndicator()),
      );
    }

    final selected = _selectedPlatform;
    final useWide = useWideLayout(MediaQuery.sizeOf(context));

    return SettingsPageScaffold(
      title: l10n.providersAndModels,
      previousPageTitle: widget.previousPageTitle,
      embedded: widget.embedded,
      child: ListView(
        padding: const EdgeInsets.only(bottom: 32),
        children: [
          SettingsSection(
            title: l10n.platformAndModel,
            children: [
              Padding(
                padding: const EdgeInsets.all(12),
                child: LayoutBuilder(
                  builder: (context, constraints) {
                    final columns = useWide
                        ? (constraints.maxWidth / 150).floor().clamp(3, 5)
                        : 2;
                    const spacing = 8.0;
                    final tileWidth =
                        (constraints.maxWidth - spacing * (columns - 1)) /
                            columns;

                    return Wrap(
                      spacing: spacing,
                      runSpacing: spacing,
                      children: [
                        for (final p in _platforms)
                          _PlatformGridChip(
                            width: tileWidth,
                            platform: p,
                            svgPath: _svgPathForType(p.type),
                            isSelected: !_isAddingPlatform &&
                                selected?.id == p.id,
                            isCurrent: p.id == _currentPlatformId,
                            onTap: () => _selectPlatform(p),
                          ),
                        GestureDetector(
                          onTap: () {
                            final defaults = AIPlatform.createDefaultPlatform(
                              _newPlatformType,
                            );
                            _newNameController.text = defaults.name;
                            _newEndpointController.text = defaults.endpoint;
                            setState(() {
                              _isAddingPlatform = !_isAddingPlatform;
                            });
                          },
                          child: Container(
                            width: tileWidth,
                            height: 44,
                            padding: const EdgeInsets.symmetric(horizontal: 10),
                            decoration: BoxDecoration(
                              color: _isAddingPlatform
                                  ? AppTokens.accentSoft(context)
                                  : AppTokens.fillSoft(context),
                              borderRadius: BorderRadius.circular(10),
                              border: Border.all(
                                color: _isAddingPlatform
                                    ? AppTokens.accent(context)
                                    : CupertinoColors.transparent,
                                width: 1,
                              ),
                            ),
                            child: Row(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                Icon(
                                  CupertinoIcons.add,
                                  size: 16,
                                  color: AppTokens.accent(context),
                                ),
                                const SizedBox(width: 6),
                                Flexible(
                                  child: Text(
                                    l10n.addPlatform,
                                    maxLines: 1,
                                    overflow: TextOverflow.ellipsis,
                                    style: TextStyle(
                                      fontSize: 13,
                                      fontWeight: FontWeight.w500,
                                      color: AppTokens.accent(context),
                                    ),
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ),
                      ],
                    );
                  },
                ),
              ),
            ],
          ),

          if (_isAddingPlatform) _buildAddPlatformSection(l10n),

          if (selected != null && !_isAddingPlatform) ...[
            SettingsSection(
              title: '${selected.name} · ${l10n.apiType}',
              children: [
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 16,
                    vertical: 12,
                  ),
                  child: Row(
                    children: [
                      Expanded(
                        child: Text(
                          l10n.enablePlatform,
                          style: TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.w500,
                            color: AppTokens.label(context),
                          ),
                        ),
                      ),
                      CupertinoSwitch(
                        value: selected.id == _currentPlatformId,
                        onChanged: (value) {
                          if (value) _setActivePlatform(selected);
                        },
                      ),
                    ],
                  ),
                ),
                SettingsInputTile(
                  title: l10n.platformNamePlaceholder,
                  controller: _nameController,
                  placeholder: l10n.platformNamePlaceholder,
                  onChanged: (_) => _schedulePlatformSave(),
                ),
                SettingsInputTile(
                  title: l10n.apiEndpoint,
                  controller: _endpointController,
                  placeholder: l10n.apiEndpointPlaceholder,
                  keyboardType: TextInputType.url,
                  showHelpButton: true,
                  onHelpPressed: () => _showNotice(
                    l10n.commonApiEndpoints,
                    l10n.commonApiEndpointsContent,
                  ),
                  onChanged: (_) => _schedulePlatformSave(),
                ),
                SettingsInputTile(
                  title: l10n.apiKey,
                  controller: _apiKeyController,
                  placeholder: l10n.apiKeyPlaceholder,
                  obscureText: _obscureApiKey,
                  showVisibilityToggle: true,
                  onVisibilityToggle: () =>
                      setState(() => _obscureApiKey = !_obscureApiKey),
                  onChanged: (_) => _schedulePlatformSave(),
                ),
                if (_platforms.length > 1)
                  CupertinoButton(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 16,
                      vertical: 13,
                    ),
                    onPressed: () => _deletePlatform(selected),
                    child: Align(
                      alignment: Alignment.centerLeft,
                      child: Text(
                        l10n.deletePlatform,
                        style: TextStyle(
                          fontSize: 15.5,
                          color: AppTokens.red(context),
                        ),
                      ),
                    ),
                  ),
              ],
            ),

            SettingsSection(
              title: l10n.availableModels,
              children: [
                GestureDetector(
                  key: _defaultModelAnchorKey,
                  behavior: HitTestBehavior.opaque,
                  onTap: () => _pickDefaultModel(selected),
                  child: Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 16,
                      vertical: 13,
                    ),
                    child: Row(
                      children: [
                        Text(
                          l10n.defaultModelLabel,
                          style: TextStyle(
                            fontSize: 15.5,
                            fontWeight: FontWeight.w500,
                            color: AppTokens.label(context),
                          ),
                        ),
                        const SizedBox(width: 16),
                        Expanded(
                          child: Row(
                            mainAxisAlignment: MainAxisAlignment.end,
                            children: [
                              Flexible(
                                child: Text(
                                  selected.defaultModel.isEmpty
                                      ? l10n.noModelSelected
                                      : selected.defaultModel,
                                  textAlign: TextAlign.right,
                                  maxLines: 1,
                                  overflow: TextOverflow.ellipsis,
                                  style: TextStyle(
                                    fontSize: 14,
                                    color: AppTokens.accent(context),
                                  ),
                                ),
                              ),
                              const SizedBox(width: 4),
                              Icon(
                                CupertinoIcons.chevron_up_chevron_down,
                                size: 14,
                                color: AppTokens.labelSecondary(context),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
                for (final model in selected.availableModels)
                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 16,
                      vertical: 10,
                    ),
                    child: Row(
                      children: [
                        Expanded(
                          child: GestureDetector(
                            behavior: HitTestBehavior.opaque,
                            onTap: () => _setDefaultModel(selected, model),
                            child: Text(
                              model,
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                              style: TextStyle(
                                fontSize: 14.5,
                                fontWeight: model == selected.defaultModel
                                    ? FontWeight.w600
                                    : FontWeight.w400,
                                color: model == selected.defaultModel
                                    ? AppTokens.accent(context)
                                    : AppTokens.label(context),
                              ),
                            ),
                          ),
                        ),
                        if (selected.availableModels.length > 1)
                          CupertinoButton(
                            padding: const EdgeInsets.all(4),
                            minimumSize: const Size(32, 32),
                            onPressed: () => _removeModel(selected, model),
                            child: Icon(
                              CupertinoIcons.minus_circle,
                              size: 18,
                              color: AppTokens.red(context),
                            ),
                          ),
                      ],
                    ),
                  ),
                Padding(
                  padding: const EdgeInsets.fromLTRB(16, 10, 16, 12),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      Row(
                        children: [
                          Expanded(
                            child: CupertinoTextField(
                              controller: _customModelController,
                              placeholder: l10n.modelPlaceholder,
                              padding: const EdgeInsets.symmetric(
                                horizontal: 12,
                                vertical: 9,
                              ),
                              decoration: BoxDecoration(
                                color: AppTokens.fillSoft(context),
                                borderRadius: BorderRadius.circular(8),
                              ),
                              onSubmitted: (_) => _addCustomModel(selected),
                            ),
                          ),
                          const SizedBox(width: 8),
                          CupertinoButton(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 14,
                              vertical: 9,
                            ),
                            color: AppTokens.accent(context),
                            borderRadius: BorderRadius.circular(8),
                            onPressed: () => _addCustomModel(selected),
                            child: Text(
                              l10n.add,
                              style: const TextStyle(
                                fontSize: 14,
                                color: CupertinoColors.white,
                              ),
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 10),
                      CupertinoButton(
                        padding: const EdgeInsets.symmetric(vertical: 8),
                        color: AppTokens.fillSoft(context),
                        borderRadius: BorderRadius.circular(8),
                        onPressed: _isRefreshingModels
                            ? null
                            : () => _refreshModels(selected),
                        child: _isRefreshingModels
                            ? const CupertinoActivityIndicator()
                            : Text(
                                l10n.refreshModels,
                                style: TextStyle(
                                  fontSize: 14,
                                  fontWeight: FontWeight.w500,
                                  color: AppTokens.accent(context),
                                ),
                              ),
                      ),
                    ],
                  ),
                ),
              ],
            ),

            SettingsSection(
              title: l10n.modelSettings,
              children: [
                SettingsInputTile(
                  title: l10n.maxTokens,
                  controller: _maxTokensController,
                  placeholder: l10n.maxTokensPlaceholder,
                  subtitle: l10n.maxTokensDesc,
                  keyboardType: TextInputType.number,
                  onChanged: (value) {
                    final parsed = int.tryParse(value.trim());
                    if (parsed != null && parsed > 0) {
                      _settingsService.setMaxTokens(parsed);
                    }
                  },
                ),
                SettingsSliderTile(
                  title: l10n.temperature,
                  value: _temperature,
                  subtitle: l10n.temperatureDesc,
                  min: 0.0,
                  max: 2.0,
                  divisions: 20,
                  decimalPlaces: 1,
                  showValueInRow: true,
                  onChanged: (value) {
                    setState(() => _temperature = value);
                    _settingsService.setTemperature(value);
                  },
                ),
                SettingsInputTile(
                  title: l10n.systemPrompt,
                  controller: _systemPromptController,
                  placeholder: l10n.systemPromptPlaceholder,
                  subtitle: l10n.systemPromptDesc,
                  maxLines: 4,
                  onChanged: (value) {
                    _settingsService.setCustomSystemPrompt(value);
                  },
                ),
              ],
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildAddPlatformSection(AppLocalizations l10n) {
    return SettingsSection(
      title: l10n.addPlatform,
      children: [
        Padding(
          padding: const EdgeInsets.fromLTRB(16, 12, 16, 4),
          child: Wrap(
            spacing: 8,
            runSpacing: 8,
            children: [
              for (final type in _availablePlatformTypes)
                GestureDetector(
                  onTap: () {
                    final defaults = AIPlatform.createDefaultPlatform(type);
                    setState(() {
                      _newPlatformType = type;
                      _newNameController.text = defaults.name;
                      _newEndpointController.text = defaults.endpoint;
                    });
                  },
                  child: Container(
                    width: 40,
                    height: 40,
                    padding: const EdgeInsets.all(8),
                    decoration: BoxDecoration(
                      color: _newPlatformType == type
                          ? AppTokens.accentSoft(context)
                          : AppTokens.fillSoft(context),
                      borderRadius: BorderRadius.circular(10),
                      border: Border.all(
                        color: _newPlatformType == type
                            ? AppTokens.accent(context)
                            : CupertinoColors.transparent,
                      ),
                    ),
                    child: SvgPicture.asset(
                      _svgPathForType(type),
                      colorFilter: ColorFilter.mode(
                        _newPlatformType == type
                            ? AppTokens.accent(context)
                            : AppTokens.label(context),
                        BlendMode.srcIn,
                      ),
                    ),
                  ),
                ),
            ],
          ),
        ),
        SettingsInputTile(
          title: l10n.platformNamePlaceholder,
          controller: _newNameController,
          placeholder: l10n.platformNamePlaceholder,
        ),
        SettingsInputTile(
          title: l10n.apiEndpoint,
          controller: _newEndpointController,
          placeholder: l10n.endpointPlaceholder,
          keyboardType: TextInputType.url,
        ),
        SettingsInputTile(
          title: l10n.apiKey,
          controller: _newApiKeyController,
          placeholder: l10n.apiKeyPlaceholder,
          obscureText: true,
        ),
        Padding(
          padding: const EdgeInsets.all(16),
          child: Row(
            children: [
              Expanded(
                child: CupertinoButton(
                  color: AppTokens.fill(context),
                  borderRadius: BorderRadius.circular(10),
                  padding: const EdgeInsets.symmetric(vertical: 11),
                  onPressed: () => setState(() => _isAddingPlatform = false),
                  child: Text(
                    l10n.cancel,
                    style: TextStyle(color: AppTokens.label(context)),
                  ),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: CupertinoButton(
                  color: AppTokens.accent(context),
                  borderRadius: BorderRadius.circular(10),
                  padding: const EdgeInsets.symmetric(vertical: 11),
                  onPressed: _createNewPlatform,
                  child: Text(
                    l10n.addPlatform,
                    style: const TextStyle(color: CupertinoColors.white),
                  ),
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }
}

class _PlatformGridChip extends StatelessWidget {
  final double width;
  final AIPlatform platform;
  final String svgPath;
  final bool isSelected;
  final bool isCurrent;
  final VoidCallback onTap;

  const _PlatformGridChip({
    required this.width,
    required this.platform,
    required this.svgPath,
    required this.isSelected,
    required this.isCurrent,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final fg = isSelected
        ? AppTokens.accent(context)
        : AppTokens.label(context);

    return GestureDetector(
      onTap: onTap,
      child: Container(
        width: width,
        height: 44,
        padding: const EdgeInsets.symmetric(horizontal: 10),
        decoration: BoxDecoration(
          color: isSelected
              ? AppTokens.accentSoft(context)
              : AppTokens.fillSoft(context),
          borderRadius: BorderRadius.circular(10),
          border: Border.all(
            color: isSelected
                ? AppTokens.accent(context)
                : CupertinoColors.transparent,
            width: 1,
          ),
        ),
        child: Row(
          children: [
            SizedBox(
              width: 18,
              height: 18,
              child: SvgPicture.asset(
                svgPath,
                colorFilter: ColorFilter.mode(fg, BlendMode.srcIn),
              ),
            ),
            const SizedBox(width: 8),
            Expanded(
              child: Text(
                platform.name,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: TextStyle(
                  fontSize: 13,
                  fontWeight: isSelected ? FontWeight.w600 : FontWeight.w500,
                  color: fg,
                ),
              ),
            ),
            if (isCurrent)
              Icon(
                CupertinoIcons.checkmark_alt_circle_fill,
                size: 14,
                color: AppTokens.green(context),
              ),
          ],
        ),
      ),
    );
  }
}
