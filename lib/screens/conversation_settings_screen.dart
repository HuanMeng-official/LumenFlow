import 'package:cupertino_ui/cupertino_ui.dart';

import '../l10n/app_localizations.dart';
import '../services/settings_service.dart';
import '../widgets/settings/settings_input_tile.dart';
import '../widgets/settings/settings_navigation_tile.dart';
import '../widgets/settings/settings_page_scaffold.dart';
import '../widgets/settings/settings_section.dart';
import '../widgets/settings/settings_slider_tile.dart';
import '../widgets/settings/settings_switch_tile.dart';

/// 对话设置页面
///
/// 管理对话相关配置：
/// - 对话历史记录
/// - 对话标题自动生成
///
/// 设置更改实时保存，无需手动点击保存按钮
class ConversationSettingsScreen extends StatefulWidget {
  final bool embedded;

  const ConversationSettingsScreen({super.key, this.embedded = false});

  @override
  State<ConversationSettingsScreen> createState() =>
      _ConversationSettingsScreenState();
}

class _ConversationSettingsScreenState
    extends State<ConversationSettingsScreen> {
  final SettingsService _settingsService = SettingsService();
  final TextEditingController _historyContextLengthController =
      TextEditingController();
  bool _isLoading = true;
  bool _enableHistory = SettingsService.defaultEnableHistory;
  bool _memoryCompressionEnabled =
      SettingsService.defaultMemoryCompressionEnabled;
  bool _autoTitleEnabled = SettingsService.defaultAutoTitleEnabled;
  int _autoTitleRounds = SettingsService.defaultAutoTitleRounds;
  String _replyLanguage = SettingsService.defaultReplyLanguage;

  @override
  void initState() {
    super.initState();
    _loadSettings();
  }

  @override
  void dispose() {
    _historyContextLengthController.dispose();
    super.dispose();
  }

  Future<void> _loadSettings() async {
    final enableHistory = await _settingsService.getEnableHistory();
    final historyContextLength = await _settingsService
        .getHistoryContextLength();
    final autoTitleEnabled = await _settingsService.getAutoTitleEnabled();
    final autoTitleRounds = await _settingsService.getAutoTitleRounds();
    final replyLanguage = await _settingsService.getReplyLanguage();
    final memoryCompressionEnabled =
        await _settingsService.getMemoryCompressionEnabled();

    if (!mounted) return;
    setState(() {
      _enableHistory = enableHistory;
      _memoryCompressionEnabled = memoryCompressionEnabled;
      _historyContextLengthController.text = historyContextLength.toString();
      _autoTitleEnabled = autoTitleEnabled;
      _autoTitleRounds = autoTitleRounds;
      _replyLanguage = replyLanguage;
      _isLoading = false;
    });
  }

  String _replyLanguageLabel(AppLocalizations l10n) {
    return switch (_replyLanguage) {
      'follow_user' => l10n.replyLanguageOptionFollowUser,
      'zh' => l10n.languageNameZh,
      'en' => l10n.languageNameEn,
      'ja' => l10n.languageNameJa,
      'ko' => l10n.languageNameKo,
      'es' => l10n.languageNameEs,
      'lzh' => l10n.languageNameLzh,
      _ => l10n.replyLanguageFollowUi,
    };
  }

  Future<void> _showReplyLanguagePicker() async {
    final l10n = AppLocalizations.of(context)!;
    final selected = await showCupertinoModalPopup<String>(
      context: context,
      builder: (context) => CupertinoActionSheet(
        title: Text(l10n.replyLanguageTitle),
        message: Text(l10n.replyLanguageSubtitle),
        actions: [
          for (final option in <String>[
            SettingsService.defaultReplyLanguage,
            'follow_user',
            'zh',
            'en',
            'ja',
            'ko',
            'es',
            'lzh',
          ])
            CupertinoActionSheetAction(
              onPressed: () => Navigator.pop(context, option),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Text(switch (option) {
                    'follow_user' => l10n.replyLanguageOptionFollowUser,
                    'zh' => l10n.languageNameZh,
                    'en' => l10n.languageNameEn,
                    'ja' => l10n.languageNameJa,
                    'ko' => l10n.languageNameKo,
                    'es' => l10n.languageNameEs,
                    'lzh' => l10n.languageNameLzh,
                    _ => l10n.replyLanguageFollowUi,
                  }),
                  if (_replyLanguage == option) ...[
                    const SizedBox(width: 8),
                    const Icon(
                      CupertinoIcons.checkmark_alt,
                      size: 18,
                      color: CupertinoColors.activeBlue,
                    ),
                  ],
                ],
              ),
            ),
        ],
        cancelButton: CupertinoActionSheetAction(
          child: Text(l10n.cancel),
          onPressed: () => Navigator.pop(context),
        ),
      ),
    );

    if (selected == null || !mounted) return;
    setState(() => _replyLanguage = selected);
    await _settingsService.setReplyLanguage(selected);
  }

  /// 实时保存历史记录开关状态
  Future<void> _onEnableHistoryChanged(bool value) async {
    setState(() {
      _enableHistory = value;
    });
    await _settingsService.setEnableHistory(value);
  }

  /// 实时保存历史记录轮数
  Future<void> _onHistoryContextLengthChanged(String value) async {
    final parsed = int.tryParse(value);
    if (parsed != null && parsed >= 1) {
      await _settingsService.setHistoryContextLength(parsed);
    }
  }

  /// 实时保存记忆压缩开关。
  Future<void> _onMemoryCompressionChanged(bool value) async {
    setState(() {
      _memoryCompressionEnabled = value;
    });
    await _settingsService.setMemoryCompressionEnabled(value);
  }

  /// 实时保存自动标题开关状态
  Future<void> _onAutoTitleEnabledChanged(bool value) async {
    setState(() {
      _autoTitleEnabled = value;
    });
    await _settingsService.setAutoTitleEnabled(value);
  }

  /// 实时保存自动标题生成轮数
  Future<void> _onAutoTitleRoundsChanged(double value) async {
    setState(() {
      _autoTitleRounds = value.toInt();
    });
    await _settingsService.setAutoTitleRounds(value.toInt());
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;

    if (_isLoading) {
      return SettingsPageScaffold(
        title: l10n.historyConversation,
        embeddedTitle: l10n.historyConversation,
        embedded: widget.embedded,
        child: const Center(child: CupertinoActivityIndicator()),
      );
    }

    return SettingsPageScaffold(
      title: l10n.historyConversation,
      embeddedTitle: l10n.historyConversation,
      embedded: widget.embedded,
      child: ListView(
        children: [
          SettingsSection(
            title: l10n.historyConversation,
            children: [
              SettingsSwitchTile(
                title: l10n.enableHistory,
                value: _enableHistory,
                subtitle: l10n.enableHistoryDesc,
                onChanged: _onEnableHistoryChanged,
              ),
              if (_enableHistory) ...[
                SettingsInputTile(
                  title: l10n.historyRounds,
                  controller: _historyContextLengthController,
                  placeholder: l10n.historyRoundsPlaceholder,
                  subtitle: l10n.historyRoundsDesc,
                  keyboardType: TextInputType.number,
                  onChanged: _onHistoryContextLengthChanged,
                ),
                SettingsSwitchTile(
                  title: l10n.memoryCompression,
                  value: _memoryCompressionEnabled,
                  subtitle: l10n.memoryCompressionDesc,
                  onChanged: _onMemoryCompressionChanged,
                ),
              ],
            ],
          ),
          SettingsSection(
            title: l10n.replyLanguageTitle,
            children: [
              SettingsNavigationTile(
                title: l10n.replyLanguageTitle,
                subtitle:
                    '${_replyLanguageLabel(l10n)}\n${l10n.replyLanguageSubtitle}',
                icon: CupertinoIcons.globe,
                onTap: _showReplyLanguagePicker,
              ),
            ],
          ),
          SettingsSection(
            title: l10n.conversationTitle,
            children: [
              SettingsSwitchTile(
                title: l10n.autoGenerateTitle,
                value: _autoTitleEnabled,
                subtitle: l10n.autoGenerateTitleDesc,
                onChanged: _onAutoTitleEnabledChanged,
              ),
              if (_autoTitleEnabled)
                SettingsSliderTile(
                  title: l10n.generateTiming,
                  value: _autoTitleRounds.toDouble(),
                  subtitle: l10n.generateTimingDesc,
                  min: 1,
                  max: 10,
                  divisions: 9,
                  decimalPlaces: 0,
                  valueSuffix: ' ${l10n.rounds}',
                  showValueInRow: true,
                  onChanged: _onAutoTitleRoundsChanged,
                ),
            ],
          ),
        ],
      ),
    );
  }
}
