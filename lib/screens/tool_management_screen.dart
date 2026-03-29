import 'package:flutter/cupertino.dart';
import '../l10n/app_localizations.dart';
import '../services/settings_service.dart';
import '../widgets/settings/settings_section.dart';
import '../widgets/settings/settings_switch_tile.dart';

/// 工具管理页面
///
/// 管理应用程序的各种工具和功能开关：
/// - 时间附加到提示词
///
/// 设置更改实时保存，无需手动点击保存按钮
class ToolManagementScreen extends StatefulWidget {
  const ToolManagementScreen({super.key});

  @override
  State<ToolManagementScreen> createState() => _ToolManagementScreenState();
}

class _ToolManagementScreenState extends State<ToolManagementScreen> {
  final SettingsService _settingsService = SettingsService();
  bool _isLoading = true;
  bool _addTimeToPrompt = SettingsService.defaultAddTimeToPrompt;

  @override
  void initState() {
    super.initState();
    _loadSettings();
  }

  Future<void> _loadSettings() async {
    final addTimeToPrompt = await _settingsService.getAddTimeToPrompt();

    setState(() {
      _addTimeToPrompt = addTimeToPrompt;
      _isLoading = false;
    });
  }

  /// 实时保存时间附加开关状态
  Future<void> _onAddTimeToPromptChanged(bool value) async {
    setState(() {
      _addTimeToPrompt = value;
    });
    await _settingsService.setAddTimeToPrompt(value);
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;

    if (_isLoading) {
      return CupertinoPageScaffold(
        navigationBar: CupertinoNavigationBar(
          middle: Text(l10n.toolManagement),
        ),
        child: const Center(child: CupertinoActivityIndicator()),
      );
    }

    return CupertinoPageScaffold(
      navigationBar: CupertinoNavigationBar(
        middle: Text(l10n.toolManagement),
      ),
      child: SafeArea(
        child: ListView(
          children: [
            SettingsSection(
              title: l10n.promptTools,
              children: [
                SettingsSwitchTile(
                  title: l10n.addTimeToPrompt,
                  value: _addTimeToPrompt,
                  subtitle: l10n.addTimeToPromptDesc,
                  onChanged: _onAddTimeToPromptChanged,
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}