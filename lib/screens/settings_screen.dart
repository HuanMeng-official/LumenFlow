import 'dart:convert';
import 'dart:io';
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import '../l10n/app_localizations.dart';
import 'package:file_picker/file_picker.dart';
import 'package:path_provider/path_provider.dart';
import '../services/settings_service.dart';
import '../utils/app_theme.dart';
import 'user_profile_screen.dart';
import 'about_screen.dart';
import 'platform_settings_screen.dart';

/// 应用设置界面，配置AI API参数和用户偏好
///
/// 主要功能：
/// - 配置API端点、密钥和模型
/// - 调整温度、最大token数等生成参数
/// - 管理对话历史设置
/// - 设置自定义系统提示词
/// - 切换API类型（OpenAI/Gemini/DeepSeek）
class SettingsScreen extends StatefulWidget {
  const SettingsScreen({super.key});

  @override
  State<SettingsScreen> createState() => _SettingsScreenState();
}

/// SettingsScreen的状态类，管理所有设置相关的状态和业务逻辑
///
/// 状态变量:
/// - 多个TextEditingController用于输入框控制
/// - 温度、启用历史等设置值
/// - 加载状态、保存状态、API密钥显示状态
/// - API类型（OpenAI/Gemini/DeepSeek）
///
/// 生命周期:
/// - initState: 初始化时加载现有设置
/// - dispose: 清理TextEditingController资源
class _SettingsScreenState extends State<SettingsScreen>
    with WidgetsBindingObserver {
  final SettingsService _settingsService = SettingsService();
  final TextEditingController _endpointController = TextEditingController();
  final TextEditingController _apiKeyController = TextEditingController();
  final TextEditingController _modelController = TextEditingController();
  final TextEditingController _maxTokensController = TextEditingController();
  final TextEditingController _historyContextLengthController =
      TextEditingController();
  final TextEditingController _customSystemPromptController =
      TextEditingController();

  double _temperature = SettingsService.defaultTemperature;
  bool _enableHistory = SettingsService.defaultEnableHistory;
  bool _isLoading = true;
  bool _obscureApiKey = true;
  bool _isSaving = false;
  String _apiType = SettingsService.defaultApiType;
  bool _darkMode = SettingsService.defaultDarkMode;
  bool _followSystemTheme = SettingsService.defaultFollowSystemTheme;
  String _appTheme = SettingsService.defaultAppTheme;
  bool _thinkingMode = SettingsService.defaultThinkingMode;
  bool _autoTitleEnabled = SettingsService.defaultAutoTitleEnabled;
  int _autoTitleRounds = SettingsService.defaultAutoTitleRounds;
  String _locale = SettingsService.defaultLocale;

  @override
  void initState() {
    super.initState();
    // 添加观察者监听系统主题变化
    WidgetsBinding.instance.addObserver(this);

    /// 初始化时加载现有的设置值到状态变量和控制器中
    _loadSettings();
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    _endpointController.dispose();
    _apiKeyController.dispose();
    _modelController.dispose();
    _maxTokensController.dispose();
    _historyContextLengthController.dispose();
    _customSystemPromptController.dispose();
    super.dispose();
  }

  @override
  void didChangePlatformBrightness() {
    if (_followSystemTheme) {
      setState(() {});
      _updateAppBrightness();
    }
    super.didChangePlatformBrightness();
  }

  /// 从设置服务加载所有配置值
  ///
  /// 异步获取所有设置项，更新对应的控制器和状态变量
  /// 设置加载完成后更新_isLoading状态
  Future<void> _loadSettings() async {
    final endpoint = await _settingsService.getApiEndpoint();
    final apiKey = await _settingsService.getApiKey();
    final model = await _settingsService.getModel();
    final temperature = await _settingsService.getTemperature();
    final maxTokens = await _settingsService.getMaxTokens();
    final enableHistory = await _settingsService.getEnableHistory();
    final historyContextLength =
        await _settingsService.getHistoryContextLength();
    final customPrompt = await _settingsService.getCustomSystemPrompt();
    final apiType = await _settingsService.getApiType();
    final darkMode = await _settingsService.getDarkMode();
    final followSystemTheme = await _settingsService.getFollowSystemTheme();
    final appTheme = await _settingsService.getAppTheme();
    final thinkingMode = await _settingsService.getThinkingMode();
    final autoTitleEnabled = await _settingsService.getAutoTitleEnabled();
    final autoTitleRounds = await _settingsService.getAutoTitleRounds();
    final locale = await _settingsService.getLocale();

    setState(() {
      _endpointController.text = endpoint;
      _apiKeyController.text = apiKey;
      _modelController.text = model;
      _temperature = temperature;
      _maxTokensController.text = maxTokens.toString();
      _enableHistory = enableHistory;
      _historyContextLengthController.text = historyContextLength.toString();
      _customSystemPromptController.text = customPrompt;
      _apiType = apiType;
      _darkMode = darkMode;
      _followSystemTheme = followSystemTheme;
      _appTheme = appTheme;
      _thinkingMode = thinkingMode;
      _autoTitleEnabled = autoTitleEnabled;
      _autoTitleRounds = autoTitleRounds;
      _locale = locale;
      _isLoading = false;
    });
  }

  void _updateApiDefaults(String apiType) {
    setState(() {
      if (apiType == 'gemini') {
        _endpointController.text =
            'https://generativelanguage.googleapis.com/v1beta/models/gemini-2.5-flash:generateContent';
        _modelController.text = 'gemini-2.5-flash';
      } else if (apiType == 'deepseek') {
        _endpointController.text = 'https://api.deepseek.com';
        _modelController.text = 'deepseek-chat';
      } else if (apiType == 'claude') {
        _endpointController.text = 'https://api.anthropic.com';
        _modelController.text = 'claude-sonnet-4-5';
      } else {
        _endpointController.text = SettingsService.defaultEndpoint;
        _modelController.text = SettingsService.defaultModel;
      }
    });
  }

  Future<void> _saveSettings() async {
    setState(() {
      _isSaving = true;
    });

    try {
      await _settingsService.setApiEndpoint(_endpointController.text.trim());
      await _settingsService.setApiKey(_apiKeyController.text.trim());
      await _settingsService.setModel(_modelController.text.trim());
      await _settingsService.setTemperature(_temperature);
      await _settingsService.setMaxTokens(
          int.tryParse(_maxTokensController.text) ??
              SettingsService.defaultMaxTokens);
      await _settingsService.setEnableHistory(_enableHistory);
      await _settingsService.setHistoryContextLength(
          int.tryParse(_historyContextLengthController.text) ??
              SettingsService.defaultHistoryContextLength);
      await _settingsService
          .setCustomSystemPrompt(_customSystemPromptController.text.trim());
      await _settingsService.setApiType(_apiType);
      await _settingsService.setDarkMode(_darkMode);
      await _settingsService.setFollowSystemTheme(_followSystemTheme);
      await _settingsService.setAppTheme(_appTheme);
      await _settingsService.setThinkingMode(_thinkingMode);
      await _settingsService.setAutoTitleEnabled(_autoTitleEnabled);
      await _settingsService.setAutoTitleRounds(_autoTitleRounds);
      await _settingsService.setLocale(_locale);

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

  void _resetToDefaults() {
    final l10n = AppLocalizations.of(context)!;
    showCupertinoDialog(
      context: context,
      builder: (context) => CupertinoAlertDialog(
        title: Text(l10n.resetSettings),
        content: Text(l10n.resetSettingsConfirm),
        actions: [
          CupertinoDialogAction(
            child: Text(l10n.cancel),
            onPressed: () => Navigator.pop(context),
          ),
          CupertinoDialogAction(
            isDestructiveAction: true,
            child: Text(l10n.resetToDefault),
            onPressed: () {
              Navigator.pop(context);
              setState(() {
                _endpointController.text = SettingsService.defaultEndpoint;
                _apiKeyController.clear();
                _modelController.text = SettingsService.defaultModel;
                _temperature = SettingsService.defaultTemperature;
                _maxTokensController.text =
                    SettingsService.defaultMaxTokens.toString();
                _enableHistory = SettingsService.defaultEnableHistory;
                _historyContextLengthController.text =
                    SettingsService.defaultHistoryContextLength.toString();
                _customSystemPromptController.text =
                    SettingsService.defaultCustomSystemPrompt.toString();
                _apiType = SettingsService.defaultApiType;
                _darkMode = SettingsService.defaultDarkMode;
                _followSystemTheme = SettingsService.defaultFollowSystemTheme;
                _appTheme = SettingsService.defaultAppTheme;
              });
            },
          ),
        ],
      ),
    );
  }

  Future<void> _exportSettings() async {
    final l10n = AppLocalizations.of(context)!;
    try {
      final settings = await _settingsService.exportSettingsToJson();
      if (settings.isEmpty) {
        throw Exception('设置数据为空，无法导出');
      }

      final jsonString = jsonEncode(settings);
      if (jsonString.isEmpty) {
        throw Exception('JSON编码结果为空');
      }

      final bytes = utf8.encode(jsonString);
      if (bytes.isEmpty) {
        throw Exception('字节数据为空，无法保存文件');
      }

      // 优先尝试保存到下载目录
      Directory? targetDir = await getDownloadsDirectory();
      String locationName = l10n.downloadDirectory;

      // 如果下载目录不可用，尝试外部存储目录
      if (targetDir == null) {
        targetDir = await getExternalStorageDirectory();
        locationName = l10n.externalStorageDirectory;
      }

      // 如果外部存储目录也不可用，使用应用文档目录
      if (targetDir == null) {
        targetDir = await getApplicationDocumentsDirectory();
        locationName = l10n.appDocumentsDirectory;
      }

      // 确保目录存在
      if (!await targetDir.exists()) {
        await targetDir.create(recursive: true);
      }

      // 生成文件名
      final fileName = 'lumenflow_settings_${DateTime.now().toIso8601String().substring(0, 10)}.json';
      final targetFile = File('${targetDir.path}/$fileName');

      // 保存文件
      await targetFile.writeAsBytes(bytes);

      if (mounted) {
        showCupertinoDialog(
          context: context,
          builder: (context) => CupertinoAlertDialog(
            title: Text(l10n.exportSuccess),
            content: Text(l10n.exportLocation(locationName, targetFile.path)),
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
        showCupertinoDialog(
          context: context,
          builder: (context) => CupertinoAlertDialog(
            title: Text(l10n.exportFailed),
            content: Text(l10n.exportError(e.toString())),
            actions: [
              CupertinoDialogAction(
                child: Text(l10n.ok),
                onPressed: () => Navigator.pop(context),
              ),
            ],
          ),
        );
      }
    }
  }

  Future<void> _importSettings() async {
    try {
      final FilePickerResult? result = await FilePicker.platform.pickFiles(
        type: FileType.custom,
        allowedExtensions: ['json'],
        dialogTitle: AppLocalizations.of(context)!.importSettings,
        allowMultiple: false,
      );

      if (result != null && result.files.isNotEmpty) {
        final file = File(result.files.single.path!);
        final jsonString = await file.readAsString();
        final settings = jsonDecode(jsonString) as Map<String, dynamic>;

        // 显示确认对话框
        if (!mounted) return;
        final l10n = AppLocalizations.of(context)!;
        final bool? confirmed = await showCupertinoDialog<bool>(
          context: context,
          builder: (context) => CupertinoAlertDialog(
            title: Text(l10n.importSettings),
            content: Text(l10n.importSettingsConfirm),
            actions: [
              CupertinoDialogAction(
                child: Text(l10n.cancel),
                onPressed: () => Navigator.pop(context, false),
              ),
              CupertinoDialogAction(
                isDestructiveAction: true,
                child: Text(l10n.importSettings),
                onPressed: () => Navigator.pop(context, true),
              ),
            ],
          ),
        );

        if (confirmed == true) {
          await _settingsService.importSettingsFromJson(settings);
          // 重新加载设置以更新UI
          await _loadSettings();

          if (mounted) {
            showCupertinoDialog(
              context: context,
              builder: (context) => CupertinoAlertDialog(
                title: Text(l10n.importSuccess),
                content: Text(l10n.settingsImported),
                actions: [
                  CupertinoDialogAction(
                    child: Text(l10n.ok),
                    onPressed: () => Navigator.pop(context),
                  ),
                ],
              ),
            );
          }
        }
      }
    } catch (e) {
      if (mounted) {
        final l10n = AppLocalizations.of(context)!;
        showCupertinoDialog(
          context: context,
          builder: (context) => CupertinoAlertDialog(
            title: Text(l10n.importFailed),
            content: Text(l10n.importError(e.toString())),
            actions: [
              CupertinoDialogAction(
                child: Text(l10n.ok),
                onPressed: () => Navigator.pop(context),
              ),
            ],
          ),
        );
      }
    }
  }

  void _openPlatformSettings() async {
    await Navigator.push(
      context,
      CupertinoPageRoute(
        builder: (context) => const PlatformSettingsScreen(),
      ),
    );
    // 返回后重新加载设置，以反映平台切换带来的变化
    _loadSettings();
  }

  void _openAbout() {
    Navigator.push(
      context,
      CupertinoPageRoute(
        builder: (context) => const AboutScreen(),
      ),
    );
  }

  void _updateAppBrightness() {
    Brightness brightness;
    if (_followSystemTheme) {
      brightness = MediaQuery.of(context).platformBrightness;
    } else {
      brightness = _appTheme == 'dark' ? Brightness.dark : Brightness.light;
    }
    appBrightness.value = brightness;
  }

  void _showEndpointHelp() {
    final l10n = AppLocalizations.of(context)!;
    showCupertinoDialog(
      context: context,
      builder: (context) => CupertinoAlertDialog(
        title: Text(l10n.commonApiEndpoints),
        content: Text(l10n.commonApiEndpointsContent),
        actions: [
          CupertinoDialogAction(
            child: Text(l10n.ok),
            onPressed: () => Navigator.pop(context),
          ),
        ],
      ),
    );
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
          middle: Text(l10n.settings),
        ),
        child: const Center(child: CupertinoActivityIndicator()),
      );
    }

    return CupertinoPageScaffold(
      navigationBar: CupertinoNavigationBar(
        middle: Text(l10n.settings),
        trailing: _isSaving
            ? const CupertinoActivityIndicator()
            : CupertinoButton(
                padding: EdgeInsets.zero,
                onPressed: _saveSettings,
                child: Text(l10n.save),
              ),
      ),
      child: SafeArea(
        child: ListView(
          children: [
            _buildSection(
              l10n.userInfo,
              [
                _buildNavigationTile(
                  l10n.userProfile,
                  subtitle: l10n.userProfileDesc,
                  icon: CupertinoIcons.person_crop_circle,
                  onTap: () {
                    Navigator.push(
                      context,
                      CupertinoPageRoute(
                        builder: (context) => const UserProfileScreen(),
                      ),
                    );
                  },
                ),
                _buildNavigationTile(
                  l10n.platformAndModel,
                  subtitle: l10n.platformAndModelDesc,
                  icon: CupertinoIcons.cube_box,
                  onTap: _openPlatformSettings,
                ),
              ],
            ),
            _buildSection(
              l10n.basicSettings,
              [
                _buildDropdownTile(
                  l10n.apiType,
                  value: _apiType,
                  options: {
                    'openai': l10n.openaiApi,
                    'gemini': l10n.geminiApi,
                    'claude': l10n.claudeApi,
                    'deepseek': l10n.deepseekApi,
                  },
                  subtitle: l10n.apiTypeDesc,
                  onChanged: (newValue) {
                    if (newValue != null) {
                      setState(() {
                        _apiType = newValue;
                      });
                      _updateApiDefaults(newValue);
                    }
                  },
                ),
                _buildInputTile(
                  l10n.apiEndpoint,
                  controller: _endpointController,
                  placeholder: l10n.apiEndpointPlaceholder,
                  subtitle: l10n.apiEndpointDesc,
                  showHelpButton: true,
                  onHelpPressed: _showEndpointHelp,
                  keyboardType: TextInputType.url,
                ),
                _buildInputTile(
                  l10n.apiKey,
                  controller: _apiKeyController,
                  placeholder: l10n.apiKeyPlaceholder,
                  subtitle: l10n.apiKeyDesc,
                  obscureText: _obscureApiKey,
                  showVisibilityToggle: true,
                  onVisibilityToggle: () {
                    setState(() {
                      _obscureApiKey = !_obscureApiKey;
                    });
                  },
                ),
              ],
            ),
            _buildSection(
              l10n.modelSettings,
              [
                _buildInputTile(
                  l10n.model,
                  controller: _modelController,
                  placeholder: l10n.modelPlaceholder,
                  subtitle: l10n.modelDesc,
                  showHelpButton: true,
                  onHelpPressed: _showModelHelp,
                ),
                _buildInputTile(
                  l10n.maxTokens,
                  controller: _maxTokensController,
                  placeholder: l10n.maxTokensPlaceholder,
                  subtitle: l10n.maxTokensDesc,
                  keyboardType: TextInputType.number,
                ),
                _buildInputTile(
                  l10n.systemPrompt,
                  controller: _customSystemPromptController,
                  placeholder: l10n.systemPromptPlaceholder,
                  subtitle: l10n.systemPromptDesc,
                  keyboardType: TextInputType.multiline,
                ),
                _buildSliderTile(
                  l10n.temperature,
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
            _buildSection(
              l10n.historyConversation,
              [
                _buildSwitchTile(
                  l10n.enableHistory,
                  value: _enableHistory,
                  subtitle: l10n.enableHistoryDesc,
                  onChanged: (value) {
                    setState(() {
                      _enableHistory = value;
                    });
                  },
                ),
                if (_enableHistory)
                  _buildInputTile(
                    l10n.historyRounds,
                    controller: _historyContextLengthController,
                    placeholder: l10n.historyRoundsPlaceholder,
                    subtitle: l10n.historyRoundsDesc,
                    keyboardType: TextInputType.number,
                  ),
              ],
            ),
            _buildSection(
              l10n.conversationTitle,
              [
                _buildSwitchTile(
                  l10n.autoGenerateTitle,
                  value: _autoTitleEnabled,
                  subtitle: l10n.autoGenerateTitleDesc,
                  onChanged: (value) {
                    setState(() {
                      _autoTitleEnabled = value;
                    });
                  },
                ),
                if (_autoTitleEnabled)
                  _buildSliderTile(
                    l10n.generateTiming,
                    value: _autoTitleRounds.toDouble(),
                    subtitle: l10n.generateTimingDesc,
                    min: 1,
                    max: 10,
                    divisions: 9,
                    decimalPlaces: 0,
                    valueSuffix: ' ${l10n.rounds}',
                    showValueInRow: true,
                    onChanged: (value) {
                      setState(() {
                        _autoTitleRounds = value.toInt();
                      });
                    },
                  ),
              ],
            ),
            _buildSection(
              l10n.appearance,
              [
                _buildSwitchTile(
                  l10n.followSystem,
                  value: _followSystemTheme,
                  subtitle: l10n.followSystemDesc,
                  onChanged: (value) async {
                    setState(() {
                      _followSystemTheme = value;
                    });
                    await _settingsService.setFollowSystemTheme(value);
                    _updateAppBrightness();
                  },
                ),
                _buildDropdownTile(
                  l10n.appColor,
                  value: _followSystemTheme
                      ? (MediaQuery.of(context).platformBrightness ==
                              Brightness.dark
                          ? 'dark'
                          : 'light')
                      : _appTheme,
                  options: {
                    'light': l10n.lightMode,
                    'dark': l10n.darkMode,
                  },
                  subtitle: _followSystemTheme
                      ? l10n.followSystemSetting(
                          MediaQuery.of(context).platformBrightness == Brightness.dark
                              ? l10n.darkMode
                              : l10n.lightMode)
                      : l10n.selectColorMode,
                  onChanged: _followSystemTheme
                      ? null
                      : (newValue) async {
                          if (newValue != null) {
                            setState(() {
                              _appTheme = newValue;
                            });
                            await _settingsService.setAppTheme(newValue);
                            _updateAppBrightness();
                          }
                        },
                ),
              ],
            ),
            _buildSection(
              l10n.language,
              [
                _buildDropdownTile(
                  l10n.interfaceLanguage,
                  value: _locale,
                  options: {
                    'zh': '简体中文',
                    'en': 'English',
                  },
                  subtitle: l10n.selectInterfaceLanguage,
                  onChanged: (newValue) {
                    if (newValue != null) {
                      setState(() {
                        _locale = newValue;
                      });
                    }
                  },
                ),
              ],
            ),
            _buildSection(
              l10n.others,
              [
                _buildActionTile(
                  l10n.exportSettings,
                  icon: CupertinoIcons.arrow_down_doc,
                  onTap: _exportSettings,
                  isDestructive: false,
                ),
                _buildActionTile(
                  l10n.importSettings,
                  icon: CupertinoIcons.arrow_up_doc,
                  onTap: _importSettings,
                  isDestructive: false,
                ),
                _buildActionTile(
                  l10n.about,
                  icon: CupertinoIcons.info_circle,
                  onTap: _openAbout,
                  isDestructive: false,
                ),
                _buildActionTile(
                  l10n.resetToDefault,
                  icon: CupertinoIcons.refresh,
                  onTap: _resetToDefaults,
                  isDestructive: true,
                ),
              ],
            ),
            Container(
              margin: const EdgeInsets.all(16),
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: CupertinoTheme.of(context).brightness == Brightness.dark
                    ? CupertinoColors.systemGrey6.darkColor
                    : CupertinoColors.systemGrey6.color,
                borderRadius: BorderRadius.circular(12),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    l10n.usageInstructions,
                    style: const TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    l10n.usageInstructionsContent,
                    style: const TextStyle(
                      fontSize: 14,
                      color: CupertinoColors.systemGrey,
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildSection(String title, List<Widget> children) {
    final brightness = CupertinoTheme.of(context).brightness;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.fromLTRB(16, 20, 16, 8),
          child: Text(
            title,
            style: TextStyle(
              fontSize: 13,
              color: brightness == Brightness.dark
                  ? CupertinoColors.systemGrey.darkColor
                  : CupertinoColors.systemGrey,
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
            border: Border.all(
              color: CupertinoColors.systemGrey4,
              width: 0.5,
            ),
          ),
          child: Column(
            children: _addDividers(children),
          ),
        ),
      ],
    );
  }

  List<Widget> _addDividers(List<Widget> children) {
    final List<Widget> dividedChildren = [];
    for (int i = 0; i < children.length; i++) {
      dividedChildren.add(children[i]);
      if (i < children.length - 1) {
        dividedChildren.add(
          const Divider(
            height: 1,
            thickness: 0.5,
            color: CupertinoColors.systemGrey4,
            indent: 16,
            endIndent: 16,
          ),
        );
      }
    }
    return dividedChildren;
  }

  Widget _buildNavigationTile(
    String title, {
    String? subtitle,
    required IconData icon,
    required VoidCallback onTap,
  }) {
    final brightness = CupertinoTheme.of(context).brightness;
    return CupertinoListTile(
      leading: Icon(
        icon,
        color: CupertinoColors.systemBlue,
      ),
      title: Text(
        title,
        style: TextStyle(
          color: brightness == Brightness.dark
              ? CupertinoColors.label.darkColor
              : CupertinoColors.label.color,
        ),
      ),
      subtitle: subtitle != null
          ? Text(
              subtitle,
              style: TextStyle(
                fontSize: 13,
                color: brightness == Brightness.dark
                    ? CupertinoColors.systemGrey.darkColor
                    : CupertinoColors.systemGrey,
              ),
            )
          : null,
      trailing: const Icon(CupertinoIcons.chevron_right),
      onTap: onTap,
    );
  }

  Widget _buildInputTile(
    String title, {
    required TextEditingController controller,
    required String placeholder,
    String? subtitle,
    bool obscureText = false,
    bool showVisibilityToggle = false,
    bool showHelpButton = false,
    TextInputType? keyboardType,
    VoidCallback? onVisibilityToggle,
    VoidCallback? onHelpPressed,
  }) {
    final brightness = CupertinoTheme.of(context).brightness;
    return Container(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Expanded(
                child: Text(
                  title,
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.w500,
                    color: brightness == Brightness.dark
                        ? CupertinoColors.label.darkColor
                        : CupertinoColors.label.color,
                  ),
                ),
              ),
              if (showHelpButton)
                CupertinoButton(
                  padding: EdgeInsets.zero,
                  onPressed: onHelpPressed,
                  child: const Icon(
                    CupertinoIcons.question_circle,
                    size: 20,
                    color: CupertinoColors.systemBlue,
                  ),
                ),
            ],
          ),
          if (subtitle != null) ...[
            const SizedBox(height: 4),
            Text(
              subtitle,
              style: TextStyle(
                fontSize: 13,
                color: brightness == Brightness.dark
                    ? CupertinoColors.systemGrey.darkColor
                    : CupertinoColors.systemGrey,
              ),
            ),
          ],
          const SizedBox(height: 12),
          CupertinoTextField(
            controller: controller,
            placeholder: placeholder,
            obscureText: obscureText,
            keyboardType: keyboardType,
            suffix: showVisibilityToggle
                ? CupertinoButton(
                    padding: EdgeInsets.zero,
                    onPressed: onVisibilityToggle,
                    child: Icon(
                      obscureText
                          ? CupertinoIcons.eye
                          : CupertinoIcons.eye_slash,
                      size: 20,
                      color: brightness == Brightness.dark
                          ? CupertinoColors.systemGrey.darkColor
                          : CupertinoColors.systemGrey,
                    ),
                  )
                : null,
            decoration: BoxDecoration(
              color: brightness == Brightness.dark
                  ? CupertinoColors.systemGrey6.darkColor
                  : CupertinoColors.systemGrey6.color,
              borderRadius: BorderRadius.circular(8),
            ),
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
          ),
        ],
      ),
    );
  }

  Widget _buildSliderTile(
    String title, {
    required double value,
    String? subtitle,
    required double min,
    required double max,
    int? divisions,
    String valueSuffix = '',
    int decimalPlaces = 1,
    bool showValueInRow = false,
    required ValueChanged<double> onChanged,
  }) {
    final brightness = CupertinoTheme.of(context).brightness;
    return Container(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          if (showValueInRow)
            Row(
              children: [
                Text(
                  title,
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.w500,
                    color: brightness == Brightness.dark
                        ? CupertinoColors.label.darkColor
                        : CupertinoColors.label.color,
                  ),
                ),
                const SizedBox(width: 8),
                Text(
                  '(${value.toStringAsFixed(decimalPlaces)}$valueSuffix)',
                  style: TextStyle(
                    fontSize: 14,
                    color: brightness == Brightness.dark
                        ? CupertinoColors.systemGrey.darkColor
                        : CupertinoColors.systemGrey,
                  ),
                ),
              ],
            )
          else
            Text(
              '$title (${value.toStringAsFixed(decimalPlaces)}$valueSuffix)',
              style: TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.w500,
                color: brightness == Brightness.dark
                    ? CupertinoColors.label.darkColor
                    : CupertinoColors.label.color,
              ),
            ),
          if (subtitle != null) ...[
            const SizedBox(height: 4),
            Text(
              subtitle,
              style: TextStyle(
                fontSize: 13,
                color: brightness == Brightness.dark
                    ? CupertinoColors.systemGrey.darkColor
                    : CupertinoColors.systemGrey,
              ),
            ),
          ],
          const SizedBox(height: 12),
          CupertinoSlider(
            value: value,
            min: min,
            max: max,
            divisions: divisions,
            onChanged: onChanged,
          ),
        ],
      ),
    );
  }

  Widget _buildSwitchTile(
    String title, {
    required bool value,
    String? subtitle,
    required ValueChanged<bool> onChanged,
  }) {
    final brightness = CupertinoTheme.of(context).brightness;
    return Container(
      padding: const EdgeInsets.all(16),
      child: Row(
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.w500,
                    color: brightness == Brightness.dark
                        ? CupertinoColors.label.darkColor
                        : CupertinoColors.label.color,
                  ),
                ),
                if (subtitle != null) ...[
                  const SizedBox(height: 4),
                  Text(
                    subtitle,
                    style: TextStyle(
                      fontSize: 13,
                      color: brightness == Brightness.dark
                          ? CupertinoColors.systemGrey.darkColor
                          : CupertinoColors.systemGrey,
                    ),
                  ),
                ],
              ],
            ),
          ),
          const SizedBox(width: 16),
          CupertinoSwitch(
            value: value,
            onChanged: onChanged,
          ),
        ],
      ),
    );
  }

  Widget _buildActionTile(
    String title, {
    required IconData icon,
    required VoidCallback onTap,
    bool isDestructive = false,
  }) {
    final brightness = CupertinoTheme.of(context).brightness;
    return CupertinoListTile(
      leading: Icon(
        icon,
        color: isDestructive
            ? CupertinoColors.systemRed
            : CupertinoColors.systemBlue,
      ),
      title: Text(
        title,
        style: TextStyle(
          color: isDestructive
              ? CupertinoColors.systemRed
              : (brightness == Brightness.dark
                  ? CupertinoColors.label.darkColor
                  : CupertinoColors.label.color),
        ),
      ),
      trailing: const Icon(CupertinoIcons.chevron_right),
      onTap: onTap,
    );
  }

  Widget _buildDropdownTile(
    String title, {
    required String value,
    required Map<String, String> options,
    String? subtitle,
    ValueChanged<String?>? onChanged,
  }) {
    final currentLabel = options[value] ?? value;
    final brightness = CupertinoTheme.of(context).brightness;
    final isEnabled = onChanged != null;

    return Container(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            title,
            style: const TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.w500,
            ),
          ),
          if (subtitle != null) ...[
            const SizedBox(height: 4),
            Text(
              subtitle,
              style: TextStyle(
                fontSize: 13,
                color: brightness == Brightness.dark
                    ? CupertinoColors.systemGrey.darkColor
                    : CupertinoColors.systemGrey,
              ),
            ),
          ],
          const SizedBox(height: 12),
          CupertinoButton(
            padding: EdgeInsets.zero,
            onPressed: onChanged != null
                ? () {
                    showCupertinoModalPopup<void>(
                      context: context,
                      builder: (BuildContext context) {
                        final popupBrightness =
                            CupertinoTheme.of(context).brightness;
                        return CupertinoActionSheet(
                          title: Text(title),
                          message: subtitle != null ? Text(subtitle) : null,
                          actions: [
                            for (final entry in options.entries)
                              CupertinoActionSheetAction(
                                onPressed: () {
                                  Navigator.pop(context);
                                  onChanged(entry.key);
                                },
                                child: Text(
                                  entry.value,
                                  style: TextStyle(
                                    color: value == entry.key
                                        ? (popupBrightness == Brightness.dark
                                            ? CupertinoColors
                                                .activeBlue.darkColor
                                            : CupertinoColors.activeBlue.color)
                                        : (popupBrightness == Brightness.dark
                                            ? CupertinoColors.label.darkColor
                                            : CupertinoColors.label.color),
                                  ),
                                ),
                              ),
                          ],
                          cancelButton: CupertinoActionSheetAction(
                            onPressed: () {
                              Navigator.pop(context);
                            },
                            child: Text(
                              AppLocalizations.of(context)!.cancel,
                              style: TextStyle(
                                color: popupBrightness == Brightness.dark
                                    ? CupertinoColors.systemRed.darkColor
                                    : CupertinoColors.systemRed.color,
                              ),
                            ),
                          ),
                        );
                      },
                    );
                  }
                : null,
            child: Container(
              width: double.infinity,
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
              decoration: BoxDecoration(
                color: isEnabled
                    ? (CupertinoTheme.of(context).brightness == Brightness.dark
                        ? CupertinoColors.systemGrey6.darkColor
                        : CupertinoColors.systemGrey6.color)
                    : (CupertinoTheme.of(context).brightness == Brightness.dark
                        ? CupertinoColors.tertiarySystemFill.darkColor
                        : CupertinoColors.tertiarySystemFill.color),
                borderRadius: BorderRadius.circular(8),
              ),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    currentLabel,
                    style: TextStyle(
                      fontSize: 16,
                      color: isEnabled
                          ? (brightness == Brightness.dark
                              ? CupertinoColors.label.darkColor
                              : CupertinoColors.label.color)
                          : (brightness == Brightness.dark
                              ? CupertinoColors.tertiaryLabel.darkColor
                              : CupertinoColors.tertiaryLabel.color),
                    ),
                  ),
                  Icon(
                    CupertinoIcons.chevron_down,
                    size: 18,
                    color: isEnabled
                        ? (brightness == Brightness.dark
                            ? CupertinoColors.systemGrey.darkColor
                            : CupertinoColors.systemGrey)
                        : (brightness == Brightness.dark
                            ? CupertinoColors.tertiaryLabel.darkColor
                            : CupertinoColors.tertiaryLabel.color),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}
