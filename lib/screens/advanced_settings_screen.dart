import 'dart:convert';
import 'dart:io';
import 'package:flutter/cupertino.dart';
import '../l10n/app_localizations.dart';
import 'package:file_picker/file_picker.dart';
import 'package:path_provider/path_provider.dart';
import '../services/settings_service.dart';
import 'about_screen.dart';
import 'credits_screen.dart';
import '../widgets/settings/settings_section.dart';
import '../widgets/settings/settings_action_tile.dart';
import '../widgets/settings/settings_switch_tile.dart';

class AdvancedSettingsScreen extends StatefulWidget {
  const AdvancedSettingsScreen({super.key});

  @override
  State<AdvancedSettingsScreen> createState() => _AdvancedSettingsScreenState();
}

class _AdvancedSettingsScreenState extends State<AdvancedSettingsScreen> {
  final SettingsService _settingsService = SettingsService();
  bool _notificationEnabled = true;

  @override
  void initState() {
    super.initState();
    _loadNotificationSetting();
  }

  Future<void> _loadNotificationSetting() async {
    final enabled = await _settingsService.getNotificationEnabled();
    if (mounted) {
      setState(() {
        _notificationEnabled = enabled;
      });
    }
  }

  void _handleNotificationChanged(bool value) async {
    await _settingsService.setNotificationEnabled(value);
    setState(() {
      _notificationEnabled = value;
    });
  }

  void _openAbout() {
    Navigator.push(
      context,
      CupertinoPageRoute(
        builder: (context) => const AboutScreen(),
      ),
    );
  }

  void _openCredits() {
    Navigator.push(
      context,
      CupertinoPageRoute(
        builder: (context) => const CreditsScreen(),
      ),
    );
  }

  Future<void> _exportSettings() async {
    final l10n = AppLocalizations.of(context)!;
    try {
      final lumenflowData = await _settingsService.exportSettingsToLumenflow();
      if (lumenflowData.isEmpty) {
        throw Exception('设置数据为空，无法导出');
      }

      final jsonString = jsonEncode(lumenflowData);
      if (jsonString.isEmpty) {
        throw Exception('编码结果为空');
      }

      final bytes = utf8.encode(jsonString);
      if (bytes.isEmpty) {
        throw Exception('字节数据为空，无法保存文件');
      }

      Directory? targetDir = await getDownloadsDirectory();
      String locationName = l10n.downloadDirectory;

      if (targetDir == null) {
        targetDir = await getExternalStorageDirectory();
        locationName = l10n.externalStorageDirectory;
      }

      if (targetDir == null) {
        targetDir = await getApplicationDocumentsDirectory();
        locationName = l10n.appDocumentsDirectory;
      }

      if (!await targetDir.exists()) {
        await targetDir.create(recursive: true);
      }

      final fileName =
          'lumenflow_settings_${DateTime.now().toIso8601String().substring(0, 10)}.lumenflow';
      final targetFile = File('${targetDir.path}/$fileName');

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
        allowedExtensions: ['lumenflow', 'json'],
        dialogTitle: AppLocalizations.of(context)!.importSettings,
        allowMultiple: false,
      );

      if (result != null && result.files.isNotEmpty) {
        final file = File(result.files.single.path!);
        final jsonString = await file.readAsString();
        final data = jsonDecode(jsonString) as Map<String, dynamic>;

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
          await _settingsService.importSettingsFromLumenflow(data);

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

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;

    return CupertinoPageScaffold(
      navigationBar: CupertinoNavigationBar(
        middle: Text(l10n.advancedSettings),
      ),
      child: SafeArea(
        child: ListView(
          children: [
            SettingsSection(
              title: l10n.notificationSettings,
              children: [
                SettingsSwitchTile(
                  title: l10n.enableNotification,
                  subtitle: l10n.enableNotificationDesc,
                  value: _notificationEnabled,
                  onChanged: _handleNotificationChanged,
                ),
              ],
            ),
            SettingsSection(
              title: l10n.dataManagement,
              children: [
                SettingsActionTile(
                  icon: CupertinoIcons.arrow_down_doc,
                  title: l10n.exportSettings,
                  onTap: _exportSettings,
                ),
                SettingsActionTile(
                  icon: CupertinoIcons.arrow_up_doc,
                  title: l10n.importSettings,
                  onTap: _importSettings,
                ),
              ],
            ),
            SettingsSection(
              title: l10n.credits,
              children: [
                SettingsActionTile(
                  title: l10n.credits,
                  icon: CupertinoIcons.heart,
                  onTap: _openCredits,
                )
              ]
            ),
            SettingsSection(
              title: l10n.about,
              children: [
                SettingsActionTile(
                  icon: CupertinoIcons.info_circle,
                  title: l10n.about,
                  onTap: _openAbout,
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}
