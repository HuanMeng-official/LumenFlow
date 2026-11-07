import 'package:cupertino_ui/cupertino_ui.dart';

import '../../l10n/app_localizations.dart';
import '../advanced_settings_screen.dart';
import '../api_settings_screen.dart';
import '../appearance_settings_screen.dart';
import '../conversation_settings_screen.dart';
import '../model_settings_screen.dart';
import '../platform_settings_screen.dart';
import '../preset_management_screen.dart';
import '../tool_management_screen.dart';
import '../user_profile_screen.dart';

enum _SettingsCategory {
  profile,
  platform,
  api,
  model,
  conversation,
  appearance,
  preset,
  tool,
  advanced,
}

/// 桌面端两栏设置页
///
/// 左侧是分类导航，右侧通过嵌套 Navigator 复用现有设置子页。
/// 切换分类时右侧回到该分类的根页面，二级页面留在右栏内。
class DesktopSettingsScreen extends StatefulWidget {
  const DesktopSettingsScreen({super.key});

  @override
  State<DesktopSettingsScreen> createState() => _DesktopSettingsScreenState();
}

class _DesktopSettingsScreenState extends State<DesktopSettingsScreen> {
  _SettingsCategory _category = _SettingsCategory.profile;
  GlobalKey<NavigatorState> _categoryNavigatorKey = GlobalKey<NavigatorState>();

  void _selectCategory(_SettingsCategory category) {
    if (category == _category) return;
    setState(() {
      _category = category;
      _categoryNavigatorKey = GlobalKey<NavigatorState>();
    });
  }

  String _categoryTitle(_SettingsCategory category, AppLocalizations l10n) {
    return switch (category) {
      _SettingsCategory.profile => l10n.userProfile,
      _SettingsCategory.platform => l10n.platformAndModel,
      _SettingsCategory.api => l10n.apiType,
      _SettingsCategory.model => l10n.modelSettings,
      _SettingsCategory.conversation => l10n.historyConversation,
      _SettingsCategory.appearance => l10n.appearance,
      _SettingsCategory.preset => l10n.presetManagement,
      _SettingsCategory.tool => l10n.toolManagement,
      _SettingsCategory.advanced => l10n.advancedSettings,
    };
  }

  IconData _categoryIcon(_SettingsCategory category) {
    return switch (category) {
      _SettingsCategory.profile => CupertinoIcons.person_crop_circle,
      _SettingsCategory.platform => CupertinoIcons.cube_box,
      _SettingsCategory.api => CupertinoIcons.cloud,
      _SettingsCategory.model => CupertinoIcons.speedometer,
      _SettingsCategory.conversation => CupertinoIcons.chat_bubble_2,
      _SettingsCategory.appearance => CupertinoIcons.paintbrush,
      _SettingsCategory.preset => CupertinoIcons.doc_text,
      _SettingsCategory.tool => CupertinoIcons.wrench,
      _SettingsCategory.advanced => CupertinoIcons.settings,
    };
  }

  Widget _buildPage(_SettingsCategory category) {
    return switch (category) {
      _SettingsCategory.profile => const UserProfileScreen(embedded: true),
      _SettingsCategory.platform =>
        const PlatformSettingsScreen(embedded: true),
      _SettingsCategory.api => const ApiSettingsScreen(embedded: true),
      _SettingsCategory.model => const ModelSettingsScreen(embedded: true),
      _SettingsCategory.conversation =>
        const ConversationSettingsScreen(embedded: true),
      _SettingsCategory.appearance =>
        const AppearanceSettingsScreen(embedded: true),
      _SettingsCategory.preset =>
        const PresetManagementScreen(embedded: true),
      _SettingsCategory.tool => const ToolManagementScreen(embedded: true),
      _SettingsCategory.advanced =>
        const AdvancedSettingsScreen(embedded: true),
    };
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final brightness = CupertinoTheme.of(context).brightness;
    final sidebarColor = brightness == Brightness.dark
        ? CupertinoColors.systemGrey6.darkColor
        : CupertinoColors.systemGrey6.color;
    final dividerColor = CupertinoColors.systemGrey4.resolveFrom(context);
    final contentColor = brightness == Brightness.dark
        ? CupertinoColors.systemBackground.darkColor
        : CupertinoColors.systemBackground.color;
    final groupLabelColor = CupertinoColors.systemGrey.resolveFrom(context);

    return ColoredBox(
      color: sidebarColor,
      child: SafeArea(
        bottom: false,
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            SizedBox(
              width: 236,
              child: Column(
                children: [
                  _buildHeader(l10n, dividerColor),
                  Expanded(
                    child: SafeArea(
                      top: false,
                      child: ListView(
                        padding: const EdgeInsets.fromLTRB(10, 6, 10, 12),
                        children: [
                          _buildGroupLabel(l10n.userInfo, groupLabelColor),
                          _buildItem(_SettingsCategory.profile, l10n),
                          _buildItem(_SettingsCategory.platform, l10n),
                          _buildGroupLabel(l10n.basicSettings, groupLabelColor),
                          _buildItem(_SettingsCategory.api, l10n),
                          _buildItem(_SettingsCategory.model, l10n),
                          _buildItem(_SettingsCategory.conversation, l10n),
                          _buildItem(_SettingsCategory.appearance, l10n),
                          _buildItem(_SettingsCategory.preset, l10n),
                          _buildItem(_SettingsCategory.tool, l10n),
                          _buildGroupLabel(l10n.others, groupLabelColor),
                          _buildItem(_SettingsCategory.advanced, l10n),
                        ],
                      ),
                    ),
                  ),
                ],
              ),
            ),
            Container(width: 0.5, color: dividerColor),
            Expanded(
              child: ColoredBox(
                color: contentColor,
                child: NavigatorPopHandler<Object?>(
                  onPopWithResult: (result) {
                    _categoryNavigatorKey.currentState?.pop(result);
                  },
                  child: Navigator(
                    key: _categoryNavigatorKey,
                    onGenerateRoute: (settings) => CupertinoPageRoute<void>(
                      settings: settings,
                      builder: (context) => _buildPage(_category),
                    ),
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildHeader(AppLocalizations l10n, Color dividerColor) {
    return Container(
      height: 52,
      padding: const EdgeInsets.symmetric(horizontal: 10),
      decoration: BoxDecoration(
        border: Border(
          bottom: BorderSide(color: dividerColor, width: 0.5),
        ),
      ),
      child: Row(
        children: [
          CupertinoButton(
            padding: EdgeInsets.zero,
            minimumSize: const Size(28, 28),
            onPressed: () => Navigator.of(context).pop(),
            child: const Icon(CupertinoIcons.chevron_back, size: 18),
          ),
          const SizedBox(width: 4),
          Text(
            l10n.settings,
            style: const TextStyle(fontSize: 15, fontWeight: FontWeight.w700),
          ),
        ],
      ),
    );
  }

  Widget _buildGroupLabel(String title, Color color) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(8, 14, 8, 4),
      child: Text(
        title,
        style: TextStyle(
          fontSize: 11,
          fontWeight: FontWeight.w500,
          color: color,
        ),
      ),
    );
  }

  Widget _buildItem(_SettingsCategory category, AppLocalizations l10n) {
    final primary = CupertinoTheme.of(context).primaryColor;
    final selected = category == _category;
    final textColor = selected
        ? primary
        : CupertinoColors.label.resolveFrom(context);

    return GestureDetector(
      key: ValueKey('settings-category-${category.name}'),
      behavior: HitTestBehavior.opaque,
      onTap: () => _selectCategory(category),
      child: Container(
        height: 32,
        padding: const EdgeInsets.symmetric(horizontal: 8),
        decoration: BoxDecoration(
          color: selected ? primary.withValues(alpha: 0.14) : null,
          borderRadius: BorderRadius.circular(6),
        ),
        child: Row(
          children: [
            Icon(_categoryIcon(category), size: 16, color: primary),
            const SizedBox(width: 8),
            Expanded(
              child: Text(
                _categoryTitle(category, l10n),
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: TextStyle(
                  fontSize: 13,
                  fontWeight: selected ? FontWeight.w600 : FontWeight.w400,
                  color: textColor,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
