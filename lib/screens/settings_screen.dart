import 'package:flutter/cupertino.dart';
import '../l10n/app_localizations.dart';
import 'user_profile_screen.dart';
import 'advanced_settings_screen.dart';
import 'platform_settings_screen.dart';
import 'api_settings_screen.dart';
import 'model_settings_screen.dart';
import 'conversation_settings_screen.dart';
import 'appearance_settings_screen.dart';
import 'tools_settings_screen.dart';
import '../widgets/settings/settings_section.dart';
import '../widgets/settings/settings_navigation_tile.dart';

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
  void _openUserProfile() {
    Navigator.push(
      context,
      CupertinoPageRoute(
        builder: (context) => const UserProfileScreen(),
      ),
    );
  }

  void _openAdvancedSettings() {
    Navigator.push(
      context,
      CupertinoPageRoute(
        builder: (context) => const AdvancedSettingsScreen(),
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

  void _openToolsSettings() {
    Navigator.push(
      context,
      CupertinoPageRoute(
        builder: (context) => const ToolsSettingsScreen(),
      ),
    );
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
                  title: l10n.toolsSettings,
                  subtitle: l10n.mcpServerUrlDesc,
                  icon: CupertinoIcons.wrench,
                  onTap: _openToolsSettings,
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
              title: l10n.others,
              children: [
                SettingsNavigationTile(
                  title: l10n.advancedSettings,
                  subtitle: l10n.advancedSettingsSubtitle,
                  icon: CupertinoIcons.settings,
                  onTap: _openAdvancedSettings,
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
