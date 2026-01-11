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
  bool _isSaving = false;
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

  Future<void> _save() async {
    setState(() {
      _isSaving = true;
    });

    try {
      await _settingsService.setEnableHistory(_enableHistory);
      await _settingsService.setHistoryContextLength(
          int.tryParse(_historyContextLengthController.text) ??
              SettingsService.defaultHistoryContextLength);
      await _settingsService.setAutoTitleEnabled(_autoTitleEnabled);
      await _settingsService.setAutoTitleRounds(_autoTitleRounds);

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
              title: l10n.historyConversation,
              children: [
                SettingsSwitchTile(
                  title: l10n.enableHistory,
                  value: _enableHistory,
                  subtitle: l10n.enableHistoryDesc,
                  onChanged: (value) {
                    setState(() {
                      _enableHistory = value;
                    });
                  },
                ),
                if (_enableHistory)
                  SettingsInputTile(
                    title: l10n.historyRounds,
                    controller: _historyContextLengthController,
                    placeholder: l10n.historyRoundsPlaceholder,
                    subtitle: l10n.historyRoundsDesc,
                    keyboardType: TextInputType.number,
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
                  onChanged: (value) {
                    setState(() {
                      _autoTitleEnabled = value;
                    });
                  },
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
                    onChanged: (value) {
                      setState(() {
                        _autoTitleRounds = value.toInt();
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
