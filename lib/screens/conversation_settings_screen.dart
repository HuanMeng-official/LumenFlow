import 'package:flutter/cupertino.dart';
import '../l10n/app_localizations.dart';
import '../services/settings_service.dart';
import '../widgets/settings/settings_input_tile.dart';
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
  const ConversationSettingsScreen({super.key});

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
  bool _autoTitleEnabled = SettingsService.defaultAutoTitleEnabled;
  int _autoTitleRounds = SettingsService.defaultAutoTitleRounds;

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
    final historyContextLength =
        await _settingsService.getHistoryContextLength();
    final autoTitleEnabled = await _settingsService.getAutoTitleEnabled();
    final autoTitleRounds = await _settingsService.getAutoTitleRounds();

    setState(() {
      _enableHistory = enableHistory;
      _historyContextLengthController.text = historyContextLength.toString();
      _autoTitleEnabled = autoTitleEnabled;
      _autoTitleRounds = autoTitleRounds;
      _isLoading = false;
    });
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
      return CupertinoPageScaffold(
        navigationBar: CupertinoNavigationBar(
          middle: Text(l10n.basicSettings),
        ),
        child: const Center(child: CupertinoActivityIndicator()),
      );
    }

    return CupertinoPageScaffold(
      navigationBar: CupertinoNavigationBar(
        middle: Text(l10n.basicSettings),
      ),
      child: SafeArea(
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
                if (_enableHistory)
                  SettingsInputTile(
                    title: l10n.historyRounds,
                    controller: _historyContextLengthController,
                    placeholder: l10n.historyRoundsPlaceholder,
                    subtitle: l10n.historyRoundsDesc,
                    keyboardType: TextInputType.number,
                    onChanged: _onHistoryContextLengthChanged,
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
      ),
    );
  }
}
