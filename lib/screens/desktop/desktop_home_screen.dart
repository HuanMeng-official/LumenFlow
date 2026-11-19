import 'package:cupertino_ui/cupertino_ui.dart';

import '../../controllers/chat_screen_controller.dart';
import '../../l10n/app_localizations.dart';
import '../../models/prompt_preset.dart';
import '../../models/user_profile.dart';
import '../../services/conversation_service.dart';
import '../../services/preset_repository.dart';
import '../../services/preset_ui_actions.dart';
import '../../services/user_service.dart';
import '../../utils/app_theme.dart';
import '../../utils/conversation_utils.dart';
import '../../widgets/desktop/sidebar_footer.dart';
import '../../widgets/preset_detail_view.dart';
import '../chat_screen.dart';
import '../conversation_list_screen.dart';
import '../preset_management_screen.dart';
import 'desktop_settings_screen.dart';

/// 桌面端两栏工作区（260px 侧栏 `对话 | 角色预设` + 统一主舞台）。
class DesktopHomeScreen extends StatefulWidget {
  const DesktopHomeScreen({super.key});

  @override
  State<DesktopHomeScreen> createState() => _DesktopHomeScreenState();
}

class _DesktopHomeScreenState extends State<DesktopHomeScreen> {
  final ChatScreenController _chatController = ChatScreenController();
  final ConversationListController _conversationListController =
      ConversationListController();
  final ConversationService _conversationService = ConversationService();
  final PresetRepository _presetRepository = PresetRepository.instance;
  final UserService _userService = UserService();

  int _sidebarTab = 0; // 0: 对话, 1: 角色预设
  String? _currentConversationId;
  String? _selectedPresetId;
  int _sidebarRefreshToken = 0;
  UserProfile? _userProfile;

  @override
  void initState() {
    super.initState();
    _presetRepository.addListener(_onPresetsChanged);
    _presetRepository.ensureLoaded();
    _loadUserProfile();
  }

  @override
  void dispose() {
    _presetRepository.removeListener(_onPresetsChanged);
    super.dispose();
  }

  void _onPresetsChanged() {
    if (!mounted) return;
    setState(() {
      _ensureSelectedPreset();
    });
  }

  PromptPreset? _resolveSelectedPreset() {
    final presets = _presetRepository.presets;
    if (presets.isEmpty) return null;
    if (_selectedPresetId != null) {
      for (final preset in presets) {
        if (preset.id == _selectedPresetId) return preset;
      }
    }
    return presets.first;
  }

  void _ensureSelectedPreset() {
    final resolved = _resolveSelectedPreset();
    _selectedPresetId = resolved?.id;
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

  Future<void> _startChatWithPreset(PromptPreset preset) async {
    final l10n = AppLocalizations.of(context)!;
    final conversation = await _conversationService.createNewConversation(
      title: preset.name.trim().isNotEmpty ? preset.name : l10n.newConversation,
      promptPresetEnabled: true,
      promptPresetId: preset.id,
    );
    if (!mounted) return;
    setState(() {
      _sidebarTab = 0;
      _currentConversationId = conversation.id;
      _sidebarRefreshToken++;
    });
    await _chatController.openConversation(conversation.id);
  }

  Future<void> _importPreset() async {
    final imported = await PresetUiActions.pickAndImportPreset(context);
    if (imported != null && mounted) {
      setState(() => _selectedPresetId = imported.id);
    }
  }

  Future<void> _openSettings({
    DesktopSettingsCategory initialCategory =
        DesktopSettingsCategory.providers,
  }) async {
    await Navigator.push(
      context,
      CupertinoPageRoute(
        builder: (context) =>
            DesktopSettingsScreen(initialCategory: initialCategory),
      ),
    );
    _chatController.refreshConfiguration();
    final profile = await _userService.getUserProfile();
    if (!mounted) return;
    setState(() {
      _userProfile = profile;
      _sidebarRefreshToken++;
    });
  }

  Widget _buildSidebarHeader(BuildContext context, AppLocalizations l10n) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Container(
          height: 52,
          padding: const EdgeInsets.symmetric(horizontal: 14),
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
              Expanded(
                child: Text(
                  'LumenFlow',
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: TextStyle(
                    fontSize: 15,
                    fontWeight: FontWeight.w700,
                    color: AppTokens.label(context),
                  ),
                ),
              ),
              if (_sidebarTab == 0) ...[
                CupertinoButton(
                  padding: const EdgeInsets.all(5),
                  minimumSize: const Size(28, 28),
                  onPressed: () =>
                      _conversationListController.importConversation(),
                  child: Icon(
                    CupertinoIcons.folder_open,
                    size: 16.5,
                    color: AppTokens.labelSecondary(context),
                  ),
                ),
                const SizedBox(width: 2),
                CupertinoButton(
                  padding: const EdgeInsets.all(5),
                  minimumSize: const Size(28, 28),
                  onPressed: () =>
                      _conversationListController.createNewConversation(),
                  child: Icon(
                    CupertinoIcons.square_pencil,
                    size: 17.5,
                    color: AppTokens.accent(context),
                  ),
                ),
              ] else
                CupertinoButton(
                  padding: const EdgeInsets.all(5),
                  minimumSize: const Size(28, 28),
                  onPressed: _importPreset,
                  child: Icon(
                    CupertinoIcons.plus,
                    size: 18,
                    color: AppTokens.accent(context),
                  ),
                ),
            ],
          ),
        ),
        Padding(
          padding: const EdgeInsets.fromLTRB(10, 10, 10, 2),
          child: CupertinoSlidingSegmentedControl<int>(
            groupValue: _sidebarTab,
            children: {
              0: Padding(
                padding: const EdgeInsets.symmetric(horizontal: 6),
                child: Text(
                  l10n.conversations,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(fontSize: 12.5),
                ),
              ),
              1: Padding(
                padding: const EdgeInsets.symmetric(horizontal: 6),
                child: Text(
                  l10n.characters,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(fontSize: 12.5),
                ),
              ),
            },
            onValueChanged: (value) {
              if (value == null) return;
              setState(() {
                _sidebarTab = value;
                if (value == 1) _ensureSelectedPreset();
              });
            },
          ),
        ),
      ],
    );
  }

  Widget _buildPresetMainStage(BuildContext context, AppLocalizations l10n) {
    final preset = _resolveSelectedPreset();
    if (preset == null) {
      return ColoredBox(
        color: AppTokens.bg(context),
        child: Center(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(
                CupertinoIcons.person_2,
                size: 48,
                color: AppTokens.labelTertiary(context),
              ),
              const SizedBox(height: 12),
              Text(
                l10n.noPresetsAvailable,
                style: TextStyle(color: AppTokens.labelSecondary(context)),
              ),
              const SizedBox(height: 16),
              CupertinoButton.filled(
                onPressed: _importPreset,
                child: Text(l10n.importButton),
              ),
            ],
          ),
        ),
      );
    }

    return ColoredBox(
      color: AppTokens.bg(context),
      child: PresetDetailView(
        key: ValueKey(preset.id),
        preset: preset,
        wide: true,
        onStartChat: () => _startChatWithPreset(preset),
        onEdit: preset.isUserPreset
            ? () => PresetUiActions.editPreset(context, preset)
            : null,
        onDuplicate: () async {
          final duplicated = await PresetUiActions.duplicatePreset(
            context,
            preset,
          );
          if (duplicated != null && mounted) {
            setState(() => _selectedPresetId = duplicated.id);
          }
        },
        onExport: () => PresetUiActions.exportPreset(context, preset),
        onDelete: preset.isUserPreset
            ? () async {
                final deleted = await PresetUiActions.confirmAndDeletePreset(
                  context,
                  preset,
                );
                if (deleted && mounted) {
                  setState(() => _ensureSelectedPreset());
                }
              }
            : null,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final selectedPreset = _resolveSelectedPreset();

    return ColoredBox(
      color: AppTokens.bg(context),
      child: Row(
        children: [
          SizedBox(
            width: 260,
            child: ColoredBox(
              color: AppTokens.sidebarBg(context),
              child: SafeArea(
                bottom: false,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    _buildSidebarHeader(context, l10n),
                    Expanded(
                      child: IndexedStack(
                        index: _sidebarTab,
                        children: [
                          ConversationListScreen(
                            embedded: true,
                            compact: true,
                            showEmbeddedHeader: false,
                            controller: _conversationListController,
                            refreshToken: _sidebarRefreshToken,
                            selectedConversationId: _currentConversationId,
                            onConversationSelected: _handleConversationSelected,
                          ),
                          PresetManagementScreen(
                            embedded: true,
                            sidebarOnly: true,
                            selectedPresetId: selectedPreset?.id,
                            onPresetSelected: (preset) {
                              setState(() => _selectedPresetId = preset.id);
                            },
                            onStartChatWithPreset: _startChatWithPreset,
                          ),
                        ],
                      ),
                    ),
                    SidebarFooter(
                      userProfile: _userProfile,
                      onOpenProfile: () => _openSettings(
                        initialCategory: DesktopSettingsCategory.profile,
                      ),
                      onOpenSettings: () => _openSettings(
                        initialCategory: DesktopSettingsCategory.providers,
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
          Container(
            width: 0.5,
            color: Color.alphaBlend(
              AppTokens.separator(context),
              AppTokens.bg(context),
            ),
          ),
          Expanded(
            child: IndexedStack(
              index: _sidebarTab,
              children: [
                ChatScreen(
                  embedded: true,
                  controller: _chatController,
                  onConversationChanged: _handleConversationChanged,
                  onConversationListChanged: _refreshSidebar,
                  onOpenSettings: () => _openSettings(
                    initialCategory: DesktopSettingsCategory.providers,
                  ),
                  onOpenBackgroundAppearance: () => _openSettings(
                    initialCategory: DesktopSettingsCategory.appearance,
                  ),
                ),
                _buildPresetMainStage(context, l10n),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
