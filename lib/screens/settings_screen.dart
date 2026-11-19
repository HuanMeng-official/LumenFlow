import 'package:cupertino_ui/cupertino_ui.dart';

import '../l10n/app_localizations.dart';
import '../models/user_profile.dart';
import '../services/user_service.dart';
import '../utils/app_theme.dart';
import '../widgets/avatar_widget.dart';
import '../widgets/settings/settings_navigation_tile.dart';
import '../widgets/settings/settings_section.dart';
import 'advanced_settings_screen.dart';
import 'appearance_settings_screen.dart';
import 'conversation_settings_screen.dart';
import 'providers_models_screen.dart';
import 'tool_management_screen.dart';
import 'user_profile_screen.dart';

/// 移动端设置主页（原生 Apple iOS 设置风格）
///
/// 顶部展示个人档案卡片，下方收拢为 5 组带彩色徽标的入口，不展示多余右侧摘要文字。
class SettingsScreen extends StatefulWidget {
  const SettingsScreen({super.key});

  @override
  State<SettingsScreen> createState() => _SettingsScreenState();
}

class _SettingsScreenState extends State<SettingsScreen> {
  final UserService _userService = UserService();
  UserProfile? _userProfile;

  @override
  void initState() {
    super.initState();
    _loadProfile();
  }

  Future<void> _loadProfile() async {
    final profile = await _userService.getUserProfile();
    if (!mounted) return;
    setState(() => _userProfile = profile);
  }

  Future<void> _pushScreen(Widget screen) async {
    await Navigator.of(context).push(
      CupertinoPageRoute(builder: (_) => screen),
    );
    _loadProfile();
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final profile = _userProfile;

    return CupertinoPageScaffold(
      backgroundColor: AppTokens.groupedBg(context),
      navigationBar: CupertinoNavigationBar(
        backgroundColor: AppTokens.bg(context),
        middle: Text(l10n.settings),
        border: Border(
          bottom: BorderSide(
            color: AppTokens.separator(context),
            width: 0.5,
          ),
        ),
      ),
      child: SafeArea(
        child: ListView(
          padding: const EdgeInsets.only(bottom: 32),
          children: [
            SettingsSection(
              title: '',
              children: [
                GestureDetector(
                  behavior: HitTestBehavior.opaque,
                  onTap: () => _pushScreen(
                    UserProfileScreen(previousPageTitle: l10n.settings),
                  ),
                  child: Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 16,
                      vertical: 12,
                    ),
                    child: Row(
                      children: [
                        if (profile != null)
                          AvatarWidget(userProfile: profile, size: 52)
                        else
                          Container(
                            width: 52,
                            height: 52,
                            decoration: BoxDecoration(
                              color: AppTokens.fill(context),
                              shape: BoxShape.circle,
                            ),
                            child: Icon(
                              CupertinoIcons.person_fill,
                              size: 26,
                              color: AppTokens.labelSecondary(context),
                            ),
                          ),
                        const SizedBox(width: 14),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                (profile?.username.isNotEmpty ?? false)
                                    ? profile!.username
                                    : l10n.userProfile,
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                                style: TextStyle(
                                  fontSize: 17,
                                  fontWeight: FontWeight.w600,
                                  color: AppTokens.label(context),
                                ),
                              ),
                              const SizedBox(height: 2),
                              Text(
                                l10n.userProfileSummarySubtitle,
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                                style: TextStyle(
                                  fontSize: 12.5,
                                  color: AppTokens.labelSecondary(context),
                                ),
                              ),
                            ],
                          ),
                        ),
                        Icon(
                          CupertinoIcons.chevron_right,
                          size: 16,
                          color: AppTokens.labelTertiary(context),
                        ),
                      ],
                    ),
                  ),
                ),
              ],
            ),
            SettingsSection(
              title: '',
              children: [
                SettingsNavigationTile(
                  title: l10n.providersAndModels,
                  icon: CupertinoIcons.cube_box,
                  badgeColor: const Color(0xFF007AFF),
                  onTap: () => _pushScreen(
                    ProvidersModelsScreen(previousPageTitle: l10n.settings),
                  ),
                ),
                SettingsNavigationTile(
                  title: l10n.conversationAndMemory,
                  icon: CupertinoIcons.chat_bubble_2,
                  badgeColor: const Color(0xFF34C759),
                  onTap: () => _pushScreen(
                    ConversationSettingsScreen(previousPageTitle: l10n.settings),
                  ),
                ),
                SettingsNavigationTile(
                  title: l10n.appearanceAndLanguage,
                  icon: CupertinoIcons.paintbrush,
                  badgeColor: const Color(0xFF5856D6),
                  onTap: () => _pushScreen(
                    AppearanceSettingsScreen(previousPageTitle: l10n.settings),
                  ),
                ),
                SettingsNavigationTile(
                  title: l10n.toolManagement,
                  icon: CupertinoIcons.wrench,
                  badgeColor: const Color(0xFFFF9500),
                  onTap: () => _pushScreen(
                    ToolManagementScreen(previousPageTitle: l10n.settings),
                  ),
                ),
                SettingsNavigationTile(
                  title: l10n.notificationsDataAbout,
                  icon: CupertinoIcons.info_circle,
                  badgeColor: const Color(0xFF8E8E93),
                  onTap: () => _pushScreen(
                    AdvancedSettingsScreen(previousPageTitle: l10n.settings),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}
