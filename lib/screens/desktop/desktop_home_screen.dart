import 'package:cupertino_ui/cupertino_ui.dart';

import '../../controllers/chat_screen_controller.dart';
import '../../models/user_profile.dart';
import '../../services/conversation_service.dart';
import '../../services/user_service.dart';
import '../../utils/conversation_utils.dart';
import '../../widgets/desktop/sidebar_footer.dart';
import '../chat_screen.dart';
import '../conversation_list_screen.dart';
import 'desktop_settings_screen.dart';

class DesktopHomeScreen extends StatefulWidget {
  const DesktopHomeScreen({super.key});

  @override
  State<DesktopHomeScreen> createState() => _DesktopHomeScreenState();
}

class _DesktopHomeScreenState extends State<DesktopHomeScreen> {
  final ChatScreenController _chatController = ChatScreenController();
  final ConversationService _conversationService = ConversationService();
  final UserService _userService = UserService();

  String? _currentConversationId;
  int _sidebarRefreshToken = 0;
  UserProfile? _userProfile;

  @override
  void initState() {
    super.initState();
    _loadUserProfile();
  }

  Future<void> _loadUserProfile() async {
    final profile = await _userService.getUserProfile();
    if (!mounted) return;
    setState(() {
      _userProfile = profile;
    });
  }

  void _handleConversationChanged(String? conversationId) {
    if (!mounted) return;
    setState(() {
      _currentConversationId = conversationId;
      _sidebarRefreshToken++;
    });
  }

  void _refreshSidebar() {
    if (!mounted) return;
    setState(() => _sidebarRefreshToken++);
  }

  Future<void> _handleConversationSelected(String? conversationId) async {
    if (conversationId != null) {
      await _chatController.openConversation(conversationId);
      return;
    }

    final conversations = await _conversationService.loadConversations();
    final nextConversation = mostRecentlyUpdatedConversation(conversations);
    if (nextConversation == null) {
      await _chatController.createNewConversation();
    } else {
      await _chatController.openConversation(nextConversation.id);
    }
  }

  Future<void> _openSettings() async {
    await Navigator.push(
      context,
      CupertinoPageRoute(builder: (context) => const DesktopSettingsScreen()),
    );
    _chatController.refreshConfiguration();
    final profile = await _userService.getUserProfile();
    if (!mounted) return;
    setState(() {
      _userProfile = profile;
      _sidebarRefreshToken++;
    });
  }

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        SizedBox(
          width: 272,
          child: Column(
            children: [
              Expanded(
                child: ConversationListScreen(
                  embedded: true,
                  compact: true,
                  refreshToken: _sidebarRefreshToken,
                  selectedConversationId: _currentConversationId,
                  onConversationSelected: _handleConversationSelected,
                ),
              ),
              SidebarFooter(userProfile: _userProfile),
            ],
          ),
        ),
        Container(
          width: 0.5,
          color: CupertinoColors.systemGrey4.resolveFrom(context),
        ),
        Expanded(
          child: ChatScreen(
            embedded: true,
            controller: _chatController,
            onConversationChanged: _handleConversationChanged,
            onConversationListChanged: _refreshSidebar,
            onOpenSettings: _openSettings,
          ),
        ),
      ],
    );
  }
}
