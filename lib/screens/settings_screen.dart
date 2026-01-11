import 'dart:convert';
import 'dart:io';
import 'package:flutter/cupertino.dart';
import '../l10n/app_localizations.dart';
import 'package:file_picker/file_picker.dart';
import 'package:path_provider/path_provider.dart';
import '../services/settings_service.dart';
import 'user_profile_screen.dart';
import 'about_screen.dart';
import 'platform_settings_screen.dart';
import 'api_settings_screen.dart';
import 'model_settings_screen.dart';
import 'conversation_settings_screen.dart';
import 'appearance_settings_screen.dart';
import '../widgets/settings/settings_section.dart';
import '../widgets/settings/settings_navigation_tile.dart';
import '../widgets/settings/settings_action_tile.dart';
import '../widgets/settings/settings_switch_tile.dart';

/// 应用主设置界面
///
/// 各类设置的汇总页面，提供导航到具体设置页面：
/// - 用户信息
/// - 平台和模型配置
/// - API设置
/// - 模型设置
/// - 对话设置
/// - 外观设置
/// - 数据导入导出
class SettingsScreen extends StatefulWidget {
  const SettingsScreen({super.key});

  @override
  State<SettingsScreen> createState() => _SettingsScreenState();
}

/// SettingsScreen的状态类，管理主设置页面的导航和操作
class _SettingsScreenState extends State<SettingsScreen> {
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

  void _openUserProfile() {
    Navigator.push(
      context,
      CupertinoPageRoute(
        builder: (context) => const UserProfileScreen(),
      ),
    );
  }

  void _openPlatformSettings() async {
    await Navigator.push(
      context,
      CupertinoPageRoute(
        builder: (context) => const PlatformSettingsScreen(),
      ),
    );
  }

  void _openApiSettings() {
    Navigator.push(
      context,
      CupertinoPageRoute(
        builder: (context) => const ApiSettingsScreen(),
      ),
    );
  }

  void _openModelSettings() {
    Navigator.push(
      context,
      CupertinoPageRoute(
        builder: (context) => const ModelSettingsScreen(),
      ),
    );
  }

  void _openConversationSettings() {
    Navigator.push(
      context,
      CupertinoPageRoute(
        builder: (context) => const ConversationSettingsScreen(),
      ),
    );
  }

  void _openAppearanceSettings() async {
    await Navigator.push(
      context,
      CupertinoPageRoute(
        builder: (context) => const AppearanceSettingsScreen(),
      ),
    );
  }

  void _openAbout() {
    Navigator.push(
      context,
      CupertinoPageRoute(
        builder: (context) => const AboutScreen(),
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
      final fileName =
          'lumenflow_settings_${DateTime.now().toIso8601String().substring(0, 10)}.lumenflow';
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
        allowedExtensions: ['lumenflow', 'json'],
        dialogTitle: AppLocalizations.of(context)!.importSettings,
        allowMultiple: false,
      );

      if (result != null && result.files.isNotEmpty) {
        final file = File(result.files.single.path!);
        final jsonString = await file.readAsString();
        final data = jsonDecode(jsonString) as Map<String, dynamic>;

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
        middle: Text(l10n.settings),
      ),
      child: SafeArea(
        child: ListView(
          children: [
            SettingsSection(
              title: l10n.userInfo,
              children: [
                SettingsNavigationTile(
                  title: l10n.userProfile,
                  subtitle: l10n.userProfileDesc,
                  icon: CupertinoIcons.person_crop_circle,
                  onTap: _openUserProfile,
                ),
                SettingsNavigationTile(
                  title: l10n.platformAndModel,
                  subtitle: l10n.platformAndModelDesc,
                  icon: CupertinoIcons.cube_box,
                  onTap: _openPlatformSettings,
                ),
              ],
            ),
            SettingsSection(
              title: l10n.basicSettings,
              children: [
                SettingsNavigationTile(
                  title: l10n.apiType,
                  subtitle: l10n.apiTypeDesc,
                  icon: CupertinoIcons.cloud,
                  onTap: _openApiSettings,
                ),
                SettingsNavigationTile(
                  title: l10n.modelSettings,
                  subtitle: l10n.modelDesc,
                  icon: CupertinoIcons.speedometer,
                  onTap: _openModelSettings,
                ),
                SettingsNavigationTile(
                  title: l10n.historyConversation,
                  subtitle: l10n.conversationTitle,
                  icon: CupertinoIcons.chat_bubble_2,
                  onTap: _openConversationSettings,
                ),
                SettingsNavigationTile(
                  title: l10n.appearance,
                  subtitle: l10n.followSystemDesc,
                  icon: CupertinoIcons.paintbrush,
                  onTap: _openAppearanceSettings,
                ),
              ],
            ),
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
                  isDestructive: false,
                ),
                SettingsActionTile(
                  icon: CupertinoIcons.arrow_up_doc,
                  title: l10n.importSettings,
                  onTap: _importSettings,
                  isDestructive: false,
                ),
              ],
            ),
            SettingsSection(
              title: l10n.others,
              children: [
                SettingsActionTile(
                  icon: CupertinoIcons.info_circle,
                  title: l10n.about,
                  onTap: _openAbout,
                  isDestructive: false,
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
}
