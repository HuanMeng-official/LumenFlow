import 'package:cupertino_ui/cupertino_ui.dart';

import '../l10n/app_localizations.dart';
import '../models/prompt_preset.dart';
import '../services/conversation_service.dart';
import '../utils/app_theme.dart';
import 'chat_screen.dart';
import 'conversation_list_screen.dart';
import 'preset_management_screen.dart';
import 'settings_screen.dart';

/// 移动端三栏底部 Tab 根外壳（对话 · 角色 · 设置）。
///
/// 会话列表与角色详情采用原生 iOS Push 导航推入根导航栈，进入聊天线程后自动隐藏底部 Tab 栏。
class MobileHomeShell extends StatefulWidget {
  const MobileHomeShell({super.key, this.conversationService});

  final ConversationService? conversationService;

  @override
  State<MobileHomeShell> createState() => _MobileHomeShellState();
}

class _MobileHomeShellState extends State<MobileHomeShell> {
  final CupertinoTabController _tabController = CupertinoTabController();
  late final ConversationService _conversationService =
      widget.conversationService ?? ConversationService();
  int _conversationRefreshToken = 0;

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  void _refreshConversations() {
    if (!mounted) return;
    setState(() => _conversationRefreshToken++);
  }

  Future<void> _openConversation(String? conversationId) async {
    if (conversationId == null || !mounted) {
      _refreshConversations();
      return;
    }
    final l10n = AppLocalizations.of(context)!;
    await Navigator.of(context, rootNavigator: true).push(
      CupertinoPageRoute<void>(
        builder: (_) => ChatScreen(
          initialConversationId: conversationId,
          previousPageTitle: l10n.conversations,
          conversationService: _conversationService,
          onConversationListChanged: _refreshConversations,
        ),
      ),
    );
    _refreshConversations();
  }

  Future<void> _startChatWithPreset(PromptPreset preset) async {
    final l10n = AppLocalizations.of(context)!;
    final conversation = await _conversationService.createNewConversation(
      title: preset.name.trim().isNotEmpty ? preset.name : l10n.newConversation,
      promptPresetEnabled: true,
      promptPresetId: preset.id,
    );
    if (!mounted) return;
    _refreshConversations();
    _tabController.index = 0;
    await Navigator.of(context, rootNavigator: true).push(
      CupertinoPageRoute<void>(
        builder: (_) => ChatScreen(
          initialConversationId: conversation.id,
          previousPageTitle: l10n.conversations,
          conversationService: _conversationService,
          onConversationListChanged: _refreshConversations,
        ),
      ),
    );
    _refreshConversations();
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;

    return CupertinoTabScaffold(
      controller: _tabController,
      backgroundColor: AppTokens.bg(context),
      tabBar: CupertinoTabBar(
        backgroundColor: AppTokens.bg(context),
        activeColor: AppTokens.accent(context),
        inactiveColor: AppTokens.labelSecondary(context),
        border: Border(
          top: BorderSide(
            color: AppTokens.separator(context),
            width: 0.5,
          ),
        ),
        items: [
          BottomNavigationBarItem(
            icon: const Icon(CupertinoIcons.chat_bubble_2),
            activeIcon: const Icon(CupertinoIcons.chat_bubble_2_fill),
            label: l10n.conversations,
          ),
          BottomNavigationBarItem(
            icon: const Icon(CupertinoIcons.person_2),
            activeIcon: const Icon(CupertinoIcons.person_2_fill),
            label: l10n.characters,
          ),
          BottomNavigationBarItem(
            icon: const Icon(CupertinoIcons.gear_alt),
            activeIcon: const Icon(CupertinoIcons.gear_alt_fill),
            label: l10n.settings,
          ),
        ],
      ),
      tabBuilder: (context, index) {
        return CupertinoTabView(
          builder: (tabContext) => switch (index) {
            0 => ConversationListScreen(
              isRootTab: true,
              service: _conversationService,
              refreshToken: _conversationRefreshToken,
              onConversationSelected: _openConversation,
            ),
            1 => PresetManagementScreen(
              onStartChatWithPreset: _startChatWithPreset,
            ),
            _ => const SettingsScreen(),
          },
        );
      },
    );
  }
}
