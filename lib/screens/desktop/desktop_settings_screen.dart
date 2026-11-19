import 'package:cupertino_ui/cupertino_ui.dart';

import '../../l10n/app_localizations.dart';
import '../../utils/app_theme.dart';
import '../advanced_settings_screen.dart';
import '../appearance_settings_screen.dart';
import '../conversation_settings_screen.dart';
import '../providers_models_screen.dart';
import '../tool_management_screen.dart';
import '../user_profile_screen.dart';

/// 桌面端统一设置分组枚举
enum DesktopSettingsCategory {
  providers,
  conversation,
  appearance,
  profile,
  tools,
  advanced,
}

class _SettingsNavItem {
  final DesktopSettingsCategory category;
  final IconData icon;
  final Color badgeColor;
  final String label;

  const _SettingsNavItem({
    required this.category,
    required this.icon,
    required this.badgeColor,
    required this.label,
  });
}

/// 桌面端两栏系统设置（macOS 系统设置风格：224px 侧栏 + 6 个原生分组）。
class DesktopSettingsScreen extends StatefulWidget {
  final DesktopSettingsCategory initialCategory;

  const DesktopSettingsScreen({
    super.key,
    this.initialCategory = DesktopSettingsCategory.providers,
  });

  @override
  State<DesktopSettingsScreen> createState() => _DesktopSettingsScreenState();
}

class _DesktopSettingsScreenState extends State<DesktopSettingsScreen> {
  late DesktopSettingsCategory _selected;

  @override
  void initState() {
    super.initState();
    _selected = widget.initialCategory;
  }

  List<_SettingsNavItem> _buildNavItems(AppLocalizations l10n) => [
        _SettingsNavItem(
          category: DesktopSettingsCategory.providers,
          icon: CupertinoIcons.cube_box,
          badgeColor: const Color(0xFF007AFF),
          label: l10n.providersAndModels,
        ),
        _SettingsNavItem(
          category: DesktopSettingsCategory.conversation,
          icon: CupertinoIcons.chat_bubble_2,
          badgeColor: const Color(0xFF34C759),
          label: l10n.conversationAndMemory,
        ),
        _SettingsNavItem(
          category: DesktopSettingsCategory.appearance,
          icon: CupertinoIcons.paintbrush,
          badgeColor: const Color(0xFF5856D6),
          label: l10n.appearanceAndLanguage,
        ),
        _SettingsNavItem(
          category: DesktopSettingsCategory.profile,
          icon: CupertinoIcons.person_fill,
          badgeColor: const Color(0xFF5AC8FA),
          label: l10n.userProfile,
        ),
        _SettingsNavItem(
          category: DesktopSettingsCategory.tools,
          icon: CupertinoIcons.wrench,
          badgeColor: const Color(0xFFFF9500),
          label: l10n.toolManagement,
        ),
        _SettingsNavItem(
          category: DesktopSettingsCategory.advanced,
          icon: CupertinoIcons.info_circle,
          badgeColor: const Color(0xFF8E8E93),
          label: l10n.notificationsDataAbout,
        ),
      ];

  Widget _buildDetailScreen() {
    switch (_selected) {
      case DesktopSettingsCategory.providers:
        return const ProvidersModelsScreen(
          key: ValueKey('providers'),
          embedded: true,
        );
      case DesktopSettingsCategory.conversation:
        return const ConversationSettingsScreen(
          key: ValueKey('conversation'),
          embedded: true,
        );
      case DesktopSettingsCategory.appearance:
        return const AppearanceSettingsScreen(
          key: ValueKey('appearance'),
          embedded: true,
        );
      case DesktopSettingsCategory.profile:
        return const UserProfileScreen(
          key: ValueKey('profile'),
          embedded: true,
        );
      case DesktopSettingsCategory.tools:
        return const ToolManagementScreen(
          key: ValueKey('tools'),
          embedded: true,
        );
      case DesktopSettingsCategory.advanced:
        return const AdvancedSettingsScreen(
          key: ValueKey('advanced'),
          embedded: true,
        );
    }
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final items = _buildNavItems(l10n);

    return CupertinoPageScaffold(
      backgroundColor: AppTokens.groupedBg(context),
      child: Row(
        children: [
          Container(
            width: 224,
            color: AppTokens.sidebarBg(context),
            child: SafeArea(
              right: false,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  Container(
                    height: 52,
                    padding: const EdgeInsets.symmetric(horizontal: 10),
                    decoration: BoxDecoration(
                      border: Border(
                        bottom: BorderSide(
                          color: AppTokens.separator(context),
                          width: 0.5,
                        ),
                      ),
                    ),
                    child: Row(
                      children: [
                        CupertinoButton(
                          padding: const EdgeInsets.symmetric(horizontal: 6),
                          minimumSize: const Size(32, 32),
                          onPressed: () => Navigator.of(context).pop(),
                          child: Icon(
                            CupertinoIcons.back,
                            size: 20,
                            color: AppTokens.accent(context),
                          ),
                        ),
                        const SizedBox(width: 2),
                        Expanded(
                          child: Text(
                            l10n.settings,
                            style: TextStyle(
                              fontSize: 16,
                              fontWeight: FontWeight.w600,
                              color: AppTokens.label(context),
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                  Expanded(
                    child: ListView.builder(
                      padding: const EdgeInsets.fromLTRB(10, 10, 10, 16),
                      itemCount: items.length,
                      itemBuilder: (context, index) {
                        final item = items[index];
                        final selected = item.category == _selected;
                        return Padding(
                          padding: const EdgeInsets.only(bottom: 2),
                          child: GestureDetector(
                            behavior: HitTestBehavior.opaque,
                            onTap: () =>
                                setState(() => _selected = item.category),
                            child: Container(
                              padding: const EdgeInsets.symmetric(
                                horizontal: 10,
                                vertical: 8,
                              ),
                              decoration: BoxDecoration(
                                color: selected
                                    ? AppTokens.accent(context)
                                    : CupertinoColors.transparent,
                                borderRadius: BorderRadius.circular(8),
                              ),
                              child: Row(
                                children: [
                                  Container(
                                    width: 24,
                                    height: 24,
                                    decoration: BoxDecoration(
                                      color: selected
                                          ? CupertinoColors.white
                                              .withValues(alpha: 0.22)
                                          : item.badgeColor,
                                      borderRadius: BorderRadius.circular(6),
                                    ),
                                    child: Icon(
                                      item.icon,
                                      size: 14,
                                      color: CupertinoColors.white,
                                    ),
                                  ),
                                  const SizedBox(width: 10),
                                  Expanded(
                                    child: Text(
                                      item.label,
                                      maxLines: 1,
                                      overflow: TextOverflow.ellipsis,
                                      style: TextStyle(
                                        fontSize: 13.5,
                                        fontWeight: selected
                                            ? FontWeight.w600
                                            : FontWeight.w500,
                                        color: selected
                                            ? CupertinoColors.white
                                            : AppTokens.label(context),
                                      ),
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ),
                        );
                      },
                    ),
                  ),
                ],
              ),
            ),
          ),
          Container(
            width: 0.5,
            color: AppTokens.separator(context),
          ),
          Expanded(child: _buildDetailScreen()),
        ],
      ),
    );
  }
}
