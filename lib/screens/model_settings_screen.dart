import 'package:flutter/cupertino.dart';
import '../l10n/app_localizations.dart';
import '../services/settings_service.dart';
import '../widgets/settings/settings_input_tile.dart';
import '../widgets/settings/settings_section.dart';
import '../widgets/settings/settings_slider_tile.dart';

/// 模型设置页面
///
/// 管理模型相关配置：
/// - 模型名称
/// - 最大Token数
/// - 温度控制
/// - 系统提示词
class ModelSettingsScreen extends StatefulWidget {
  const ModelSettingsScreen({super.key});

  @override
  State<ModelSettingsScreen> createState() => _ModelSettingsScreenState();
}

class _ModelSettingsScreenState extends State<ModelSettingsScreen> {
  final SettingsService _settingsService = SettingsService();
  final TextEditingController _modelController = TextEditingController();
  final TextEditingController _maxTokensController = TextEditingController();
  final TextEditingController _customSystemPromptController =
      TextEditingController();
  bool _isLoading = true;
  bool _isSaving = false;
  double _temperature = SettingsService.defaultTemperature;

  @override
  void initState() {
    super.initState();
    _loadSettings();
  }

  @override
  void dispose() {
    _modelController.dispose();
    _maxTokensController.dispose();
    _customSystemPromptController.dispose();
    super.dispose();
  }

  Future<void> _loadSettings() async {
    // 优先使用当前平台的默认模型（如果已配置）
    final currentPlatform = await _settingsService.getCurrentPlatform();
    String model;
    if (currentPlatform != null && currentPlatform.isConfigured && currentPlatform.defaultModel.isNotEmpty) {
      model = currentPlatform.defaultModel;
    } else {
      model = await _settingsService.getModel();
    }

    final temperature = await _settingsService.getTemperature();
    final maxTokens = await _settingsService.getMaxTokens();
    final customPrompt = await _settingsService.getCustomSystemPrompt();

    setState(() {
      _modelController.text = model;
      _temperature = temperature;
      _maxTokensController.text = maxTokens.toString();
      _customSystemPromptController.text = customPrompt;
      _isLoading = false;
    });
  }

  Future<void> _save() async {
    setState(() {
      _isSaving = true;
    });

    try {
      final newModel = _modelController.text.trim();
      await _settingsService.setModel(newModel);

      // 同步更新当前平台的默认模型（如果已配置）
      final currentPlatform = await _settingsService.getCurrentPlatform();
      if (currentPlatform != null && currentPlatform.isConfigured && newModel.isNotEmpty) {
        await _settingsService.updatePlatformModels(
          currentPlatform.id,
          currentPlatform.availableModels,
          newDefaultModel: newModel,
        );
      }

      await _settingsService.setTemperature(_temperature);
      await _settingsService.setMaxTokens(
          int.tryParse(_maxTokensController.text) ??
              SettingsService.defaultMaxTokens);
      await _settingsService
          .setCustomSystemPrompt(_customSystemPromptController.text.trim());

      if (mounted) {
        final l10n = AppLocalizations.of(context)!;
        showCupertinoDialog(
          context: context,
          builder: (context) => CupertinoAlertDialog(
            title: Text(l10n.saveSuccess),
            content: Text(l10n.settingsSaved),
            actions: [
              CupertinoDialogAction(
                child: Text(l10n.ok),
                onPressed: () => Navigator.pop(context),
              ),
            ],
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        final l10n = AppLocalizations.of(context)!;
        showCupertinoDialog(
          context: context,
          builder: (context) => CupertinoAlertDialog(
            title: Text(l10n.saveFailed),
            content: Text(l10n.saveError(e.toString())),
            actions: [
              CupertinoDialogAction(
                child: Text(l10n.ok),
                onPressed: () => Navigator.pop(context),
              ),
            ],
          ),
        );
      }
    } finally {
      setState(() {
        _isSaving = false;
      });
    }
  }

  void _showModelHelp() {
    final l10n = AppLocalizations.of(context)!;
    showCupertinoDialog(
      context: context,
      builder: (context) => CupertinoAlertDialog(
        title: Text(l10n.commonModels),
        content: Text(l10n.commonModelsContent),
        actions: [
          CupertinoDialogAction(
            child: Text(l10n.ok),
            onPressed: () => Navigator.pop(context),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;

    if (_isLoading) {
      return CupertinoPageScaffold(
        navigationBar: CupertinoNavigationBar(
          middle: Text(l10n.modelSettings),
        ),
        child: const Center(child: CupertinoActivityIndicator()),
      );
    }

    return CupertinoPageScaffold(
      navigationBar: CupertinoNavigationBar(
        middle: Text(l10n.modelSettings),
        trailing: _isSaving
            ? const CupertinoActivityIndicator()
            : CupertinoButton(
                padding: EdgeInsets.zero,
                onPressed: _save,
                child: Text(l10n.save),
              ),
      ),
      child: SafeArea(
        child: ListView(
          children: [
            SettingsSection(
              title: l10n.modelSettings,
              children: [
                SettingsInputTile(
                  title: l10n.model,
                  controller: _modelController,
                  placeholder: l10n.modelPlaceholder,
                  subtitle: l10n.modelDesc,
                  showHelpButton: true,
                  onHelpPressed: _showModelHelp,
                ),
                SettingsInputTile(
                  title: l10n.maxTokens,
                  controller: _maxTokensController,
                  placeholder: l10n.maxTokensPlaceholder,
                  subtitle: l10n.maxTokensDesc,
                  keyboardType: TextInputType.number,
                ),
                SettingsInputTile(
                  title: l10n.systemPrompt,
                  controller: _customSystemPromptController,
                  placeholder: l10n.systemPromptPlaceholder,
                  subtitle: l10n.systemPromptDesc,
                  maxLines: 5,
                ),
              ],
            ),
            SettingsSection(
              title: l10n.temperature,
              children: [
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
                    setState(() {
                      _temperature = value;
                    });
                  },
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}
