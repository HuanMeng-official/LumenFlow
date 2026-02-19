import 'package:flutter/cupertino.dart';
import '../l10n/app_localizations.dart';
import '../services/settings_service.dart';
import '../widgets/settings/settings_input_tile.dart';
import '../widgets/settings/settings_section.dart';

/// API设置页面
///
/// 管理API相关配置：
/// - API类型选择
/// - API端点配置
/// - API密钥管理
class ApiSettingsScreen extends StatefulWidget {
  const ApiSettingsScreen({super.key});

  @override
  State<ApiSettingsScreen> createState() => _ApiSettingsScreenState();
}

class _ApiSettingsScreenState extends State<ApiSettingsScreen> {
  final SettingsService _settingsService = SettingsService();
  final TextEditingController _endpointController = TextEditingController();
  final TextEditingController _apiKeyController = TextEditingController();
  bool _isLoading = true;
  bool _isSaving = false;
  bool _obscureApiKey = true;
  String _apiType = SettingsService.defaultApiType;

  @override
  void initState() {
    super.initState();
    _loadSettings();
  }

  @override
  void dispose() {
    _endpointController.dispose();
    _apiKeyController.dispose();
    super.dispose();
  }

  Future<void> _loadSettings() async {
    final endpoint = await _settingsService.getApiEndpoint();
    final apiKey = await _settingsService.getApiKey();
    final apiType = await _settingsService.getApiType();

    setState(() {
      _endpointController.text = endpoint;
      _apiKeyController.text = apiKey;
      _apiType = apiType;
      _isLoading = false;
    });
  }

  void _updateApiDefaults(String apiType) {
    setState(() {
      if (apiType == 'gemini') {
        _endpointController.text =
            'https://generativelanguage.googleapis.com/v1beta/models/gemini-2.5-flash:generateContent';
      } else if (apiType == 'deepseek') {
        _endpointController.text = 'https://api.deepseek.com';
      } else if (apiType == 'claude') {
        _endpointController.text = 'https://api.anthropic.com/v1';
      } else if (apiType == 'siliconflow') {
        _endpointController.text = 'https://api.siliconflow.cn/v1';
      } else if (apiType == 'zhipu') {
        _endpointController.text = 'https://open.bigmodel.cn/api/paas/v4';
      } else if (apiType == 'kimi') {
        _endpointController.text = 'https://api.moonshot.cn/v1';
      } else if (apiType == 'lmstudio') {
        _endpointController.text = 'http://YOUR_LM-STUDIO_ADDRESS:PORT/v1';
      } else if (apiType == 'grok') {
        _endpointController.text = 'https://api.x.ai/v1';
      } else if (apiType == 'other') {
        _endpointController.text = 'https://YOUR_LLM_ADDRESS/v1';
      } else {
        _endpointController.text = SettingsService.defaultEndpoint;
      }
    });
  }

  Future<void> _save() async {
    setState(() {
      _isSaving = true;
    });

    try {
      await _settingsService.setApiEndpoint(_endpointController.text.trim());
      await _settingsService.setApiKey(_apiKeyController.text.trim());
      await _settingsService.setApiType(_apiType);

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

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;

    if (_isLoading) {
      return CupertinoPageScaffold(
        navigationBar: CupertinoNavigationBar(
          middle: Text(l10n.apiType),
        ),
        child: const Center(child: CupertinoActivityIndicator()),
      );
    }

    return CupertinoPageScaffold(
      navigationBar: CupertinoNavigationBar(
        middle: Text(l10n.apiType),
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
              title: l10n.apiType,
              children: [
                CustomSelectWidget<String>(
                  title: l10n.apiType,
                  value: _apiType,
                  options: {
                    'openai': l10n.openaiApi,
                    'gemini': l10n.geminiApi,
                    'claude': l10n.claudeApi,
                    'deepseek': l10n.deepseekApi,
                    'siliconflow': l10n.siliconflowApi,
                    'minimax': l10n.minimaxApi,
                    'zhipu': l10n.zhipuApi,
                    'kimi': l10n.kimiApi,
                    'lmstudio': l10n.lmsApi,
                    'grok': l10n.grokApi,
                    'other': l10n.otherApi
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
              ],
            ),
            SettingsSection(
              title: l10n.apiEndpoint,
              children: [
                SettingsInputTile(
                  title: l10n.apiEndpoint,
                  controller: _endpointController,
                  placeholder: l10n.apiEndpointPlaceholder,
                  subtitle: l10n.apiEndpointDesc,
                  showHelpButton: true,
                  onHelpPressed: _showEndpointHelp,
                  keyboardType: TextInputType.url,
                ),
              ],
            ),
            SettingsSection(
              title: l10n.apiKey,
              children: [
                SettingsInputTile(
                  title: l10n.apiKey,
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
          ],
        ),
      ),
    );
  }
}

/// 临时的下拉选择组件，避免循环依赖
/// 后续会统一到settings_dropdown_tile.dart中
class CustomSelectWidget<T> extends StatelessWidget {
  final String title;
  final T value;
  final Map<T, String> options;
  final String? subtitle;
  final ValueChanged<T?>? onChanged;

  const CustomSelectWidget({
    super.key,
    required this.title,
    required this.value,
    required this.options,
    this.subtitle,
    this.onChanged,
  });

  @override
  Widget build(BuildContext context) {
    final currentLabel = options[value] ?? value.toString();
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
              subtitle!,
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
                          message: subtitle != null ? Text(subtitle!) : null,
                          actions: [
                            for (final entry in options.entries)
                              CupertinoActionSheetAction(
                                onPressed: () {
                                  Navigator.pop(context);
                                  if (onChanged != null) {
                                    onChanged!(entry.key);
                                  }
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
