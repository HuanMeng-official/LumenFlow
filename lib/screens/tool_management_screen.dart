import 'package:cupertino_ui/cupertino_ui.dart';

import '../ai/mcp/mcp_client.dart';
import '../ai/mcp/mcp_models.dart';
import '../ai/providers/chat_completions_profile.dart';
import '../ai/providers/responses_tool_provider.dart';
import '../l10n/app_localizations.dart';
import '../services/settings_service.dart';
import '../services/version_service.dart';
import '../utils/app_theme.dart';
import '../widgets/settings/settings_page_scaffold.dart';
import '../widgets/settings/settings_section.dart';
import '../widgets/settings/settings_switch_tile.dart';

/// 工具与 MCP 管理页面（含自动记忆工具、7 项内置工具与结构化 MCP 服务器表单）。
class ToolManagementScreen extends StatefulWidget {
  final bool embedded;
  final String? previousPageTitle;

  const ToolManagementScreen({
    super.key,
    this.embedded = false,
    this.previousPageTitle,
  });

  @override
  State<ToolManagementScreen> createState() => _ToolManagementScreenState();
}

class _ToolManagementScreenState extends State<ToolManagementScreen> {
  final SettingsService _settingsService = SettingsService();
  bool _isLoading = true;
  bool _addTimeToPrompt = SettingsService.defaultAddTimeToPrompt;
  bool _builtinCalculator = SettingsService.defaultBuiltinCalculatorEnabled;
  bool _builtinTextTools = SettingsService.defaultBuiltinTextToolsEnabled;
  bool _builtinDateMath = SettingsService.defaultBuiltinDateMathEnabled;
  bool _builtinUnitConvert = SettingsService.defaultBuiltinUnitConvertEnabled;
  bool _builtinLunarCalendar =
      SettingsService.defaultBuiltinLunarCalendarEnabled;
  bool _builtinUserProfile = SettingsService.defaultBuiltinUserProfileEnabled;

  List<McpServerConfig> _servers = const [];
  String _activePlatformType = '';
  String? _editingServerId;
  bool _isCreatingNew = false;

  final TextEditingController _mcpNameController = TextEditingController();
  final TextEditingController _mcpUrlController = TextEditingController();
  final List<_HeaderDraft> _headerDrafts = [];
  String? _mcpStatusMessage;

  @override
  void initState() {
    super.initState();
    _loadSettings();
  }

  @override
  void dispose() {
    _mcpNameController.dispose();
    _mcpUrlController.dispose();
    _disposeHeaderDrafts();
    super.dispose();
  }

  void _disposeHeaderDrafts() {
    for (final draft in _headerDrafts) {
      draft.dispose();
    }
    _headerDrafts.clear();
  }

  Future<void> _loadSettings() async {
    final addTimeToPrompt = await _settingsService.getAddTimeToPrompt();
    final builtinCalculator =
        await _settingsService.getBuiltinCalculatorEnabled();
    final builtinTextTools =
        await _settingsService.getBuiltinTextToolsEnabled();
    final builtinDateMath = await _settingsService.getBuiltinDateMathEnabled();
    final builtinUnitConvert =
        await _settingsService.getBuiltinUnitConvertEnabled();
    final builtinLunarCalendar =
        await _settingsService.getBuiltinLunarCalendarEnabled();
    final builtinUserProfile =
        await _settingsService.getBuiltinUserProfileEnabled();
    final servers = await _settingsService.getMcpServers();
    final config = await _settingsService.getActivePlatformConfig();

    if (!mounted) return;
    setState(() {
      _addTimeToPrompt = addTimeToPrompt;
      _builtinCalculator = builtinCalculator;
      _builtinTextTools = builtinTextTools;
      _builtinDateMath = builtinDateMath;
      _builtinUnitConvert = builtinUnitConvert;
      _builtinLunarCalendar = builtinLunarCalendar;
      _builtinUserProfile = builtinUserProfile;
      _servers = servers;
      _activePlatformType = config.apiType;
      _isLoading = false;
    });
  }

  void _beginEditServer(McpServerConfig? server) {
    _disposeHeaderDrafts();
    if (server == null) {
      _isCreatingNew = true;
      _editingServerId = null;
      _mcpNameController.clear();
      _mcpUrlController.clear();
    } else {
      _isCreatingNew = false;
      _editingServerId = server.id;
      _mcpNameController.text = server.name;
      _mcpUrlController.text = server.url;
      for (final entry in server.headers.entries) {
        _headerDrafts.add(_HeaderDraft(entry.key, entry.value));
      }
    }
    setState(() {});
  }

  void _cancelEditServer() {
    _disposeHeaderDrafts();
    setState(() {
      _isCreatingNew = false;
      _editingServerId = null;
    });
  }

  McpServerConfig? _buildConfigFromDraft({String? existingId, bool enabled = true}) {
    final name = _mcpNameController.text.trim();
    final url = _mcpUrlController.text.trim();
    if (name.isEmpty || url.isEmpty) return null;
    final uri = Uri.tryParse(url);
    if (uri == null || (uri.scheme != 'http' && uri.scheme != 'https')) {
      return null;
    }

    final headers = <String, String>{};
    for (final draft in _headerDrafts) {
      final k = draft.keyController.text.trim();
      final v = draft.valueController.text.trim();
      if (k.isNotEmpty) {
        headers[k] = v;
      }
    }

    return McpServerConfig(
      id: existingId ?? 'mcp_${DateTime.now().millisecondsSinceEpoch}',
      name: name,
      url: url,
      headers: headers,
      enabled: enabled,
    );
  }

  Future<void> _saveDraftServer({McpServerConfig? original}) async {
    final l10n = AppLocalizations.of(context)!;
    final built = _buildConfigFromDraft(
      existingId: original?.id,
      enabled: original?.enabled ?? true,
    );
    if (built == null) {
      _showNotice(l10n.error, l10n.mcpInvalidConfig);
      return;
    }

    final updated = List<McpServerConfig>.from(_servers);
    final idx = updated.indexWhere((s) => s.id == built.id);
    if (idx >= 0) {
      updated[idx] = built;
    } else {
      updated.add(built);
    }
    await _settingsService.saveMcpServers(updated);
    if (!mounted) return;
    _disposeHeaderDrafts();
    setState(() {
      _servers = updated;
      _isCreatingNew = false;
      _editingServerId = null;
    });
  }

  Future<void> _deleteServer(McpServerConfig server) async {
    final l10n = AppLocalizations.of(context)!;
    final confirmed = await showCupertinoDialog<bool>(
      context: context,
      builder: (dialogContext) => CupertinoAlertDialog(
        title: Text(l10n.deleteMcpServer),
        content: Text(server.name),
        actions: [
          CupertinoDialogAction(
            onPressed: () => Navigator.pop(dialogContext, false),
            child: Text(l10n.cancel),
          ),
          CupertinoDialogAction(
            isDestructiveAction: true,
            onPressed: () => Navigator.pop(dialogContext, true),
            child: Text(l10n.delete),
          ),
        ],
      ),
    );
    if (confirmed != true) return;
    final updated = _servers.where((item) => item.id != server.id).toList();
    await _settingsService.saveMcpServers(updated);
    if (!mounted) return;
    setState(() {
      _servers = updated;
      if (_editingServerId == server.id) _editingServerId = null;
    });
  }

  Future<void> _testConnection(McpServerConfig config) async {
    final l10n = AppLocalizations.of(context)!;
    final appVersion = await VersionService().getAppVersion();
    final client = McpClient(
      config: config,
      timeout: const Duration(seconds: 10),
      clientVersion: appVersion.isNotEmpty
          ? appVersion
          : McpClient.defaultClientVersion,
    );
    String message;
    try {
      final tools = await client.initializeAndListTools();
      if (tools.isEmpty) {
        message = l10n.mcpNoToolsReturned;
      } else {
        final names = tools.take(8).map((t) => t.name).join(', ');
        message = '${l10n.mcpConnectedToolsCount(tools.length)}: $names';
      }
    } catch (error) {
      message = error.toString();
    } finally {
      await client.close();
    }
    if (!mounted) return;
    setState(() => _mcpStatusMessage = '${config.name}: $message');
  }

  void _showNotice(String title, String message) {
    final l10n = AppLocalizations.of(context)!;
    showCupertinoDialog<void>(
      context: context,
      builder: (dialogContext) => CupertinoAlertDialog(
        title: Text(title),
        content: Text(message),
        actions: [
          CupertinoDialogAction(
            onPressed: () => Navigator.pop(dialogContext),
            child: Text(l10n.ok),
          ),
        ],
      ),
    );
  }

  bool get _platformSupportsTools =>
      ChatCompletionsProfiles.forType(_activePlatformType) != null ||
      ResponsesToolProfiles.supports(_activePlatformType) ||
      _activePlatformType == 'claude' ||
      _activePlatformType == 'gemini';

  Widget _memoryToolTile(
    BuildContext context, {
    required String title,
    required String subtitle,
  }) {
    final l10n = AppLocalizations.of(context)!;
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: TextStyle(
                    fontSize: 15.5,
                    fontWeight: FontWeight.w500,
                    color: AppTokens.label(context),
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  subtitle,
                  style: TextStyle(
                    fontSize: 12.5,
                    color: AppTokens.labelSecondary(context),
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(width: 12),
          Text(
            l10n.memoryToolsAuto,
            style: TextStyle(
              fontSize: 13,
              color: AppTokens.labelSecondary(context),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildMcpEditor(BuildContext context, {McpServerConfig? original}) {
    final l10n = AppLocalizations.of(context)!;
    return Container(
      margin: const EdgeInsets.fromLTRB(12, 6, 12, 12),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: AppTokens.fillSoft(context),
        borderRadius: BorderRadius.circular(10),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          CupertinoTextField(
            controller: _mcpNameController,
            placeholder: l10n.mcpServerName,
            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 9),
            decoration: BoxDecoration(
              color: AppTokens.elevatedSurface(context),
              borderRadius: BorderRadius.circular(8),
            ),
          ),
          const SizedBox(height: 8),
          CupertinoTextField(
            controller: _mcpUrlController,
            placeholder: l10n.mcpServerUrl,
            keyboardType: TextInputType.url,
            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 9),
            decoration: BoxDecoration(
              color: AppTokens.elevatedSurface(context),
              borderRadius: BorderRadius.circular(8),
            ),
          ),
          const SizedBox(height: 10),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                l10n.mcpHeadersTitle,
                style: TextStyle(
                  fontSize: 12.5,
                  fontWeight: FontWeight.w500,
                  color: AppTokens.labelSecondary(context),
                ),
              ),
              CupertinoButton(
                padding: EdgeInsets.zero,
                minimumSize: const Size(24, 24),
                onPressed: () {
                  setState(() => _headerDrafts.add(_HeaderDraft('', '')));
                },
                child: Text(
                  '+ ${l10n.addHeader}',
                  style: TextStyle(
                    fontSize: 12.5,
                    color: AppTokens.accent(context),
                  ),
                ),
              ),
            ],
          ),
          for (int i = 0; i < _headerDrafts.length; i++) ...[
            const SizedBox(height: 6),
            Row(
              children: [
                Expanded(
                  child: CupertinoTextField(
                    controller: _headerDrafts[i].keyController,
                    placeholder: l10n.headerKeyPlaceholder,
                    padding: const EdgeInsets.symmetric(
                      horizontal: 8,
                      vertical: 7,
                    ),
                    decoration: BoxDecoration(
                      color: AppTokens.elevatedSurface(context),
                      borderRadius: BorderRadius.circular(7),
                    ),
                  ),
                ),
                const SizedBox(width: 6),
                Expanded(
                  child: CupertinoTextField(
                    controller: _headerDrafts[i].valueController,
                    placeholder: l10n.headerValuePlaceholder,
                    padding: const EdgeInsets.symmetric(
                      horizontal: 8,
                      vertical: 7,
                    ),
                    decoration: BoxDecoration(
                      color: AppTokens.elevatedSurface(context),
                      borderRadius: BorderRadius.circular(7),
                    ),
                  ),
                ),
                CupertinoButton(
                  padding: const EdgeInsets.only(left: 4),
                  minimumSize: const Size(28, 28),
                  onPressed: () {
                    setState(() {
                      final removed = _headerDrafts.removeAt(i);
                      removed.dispose();
                    });
                  },
                  child: Icon(
                    CupertinoIcons.minus_circle,
                    size: 17,
                    color: AppTokens.red(context),
                  ),
                ),
              ],
            ),
          ],
          const SizedBox(height: 12),
          Row(
            children: [
              if (original != null)
                CupertinoButton(
                  padding: const EdgeInsets.symmetric(horizontal: 10),
                  onPressed: () => _deleteServer(original),
                  child: Text(
                    l10n.delete,
                    style: TextStyle(
                      fontSize: 13.5,
                      color: AppTokens.red(context),
                    ),
                  ),
                ),
              const Spacer(),
              CupertinoButton(
                padding: const EdgeInsets.symmetric(horizontal: 10),
                onPressed: _cancelEditServer,
                child: Text(
                  l10n.cancel,
                  style: TextStyle(
                    fontSize: 13.5,
                    color: AppTokens.labelSecondary(context),
                  ),
                ),
              ),
              const SizedBox(width: 6),
              CupertinoButton(
                padding: const EdgeInsets.symmetric(
                  horizontal: 14,
                  vertical: 7,
                ),
                color: AppTokens.accent(context),
                borderRadius: BorderRadius.circular(8),
                onPressed: () => _saveDraftServer(original: original),
                child: Text(
                  l10n.save,
                  style: const TextStyle(
                    fontSize: 13.5,
                    color: CupertinoColors.white,
                  ),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;

    if (_isLoading) {
      return SettingsPageScaffold(
        title: l10n.toolManagement,
        previousPageTitle: widget.previousPageTitle,
        embedded: widget.embedded,
        child: const Center(child: CupertinoActivityIndicator()),
      );
    }

    return SettingsPageScaffold(
      title: l10n.toolManagement,
      previousPageTitle: widget.previousPageTitle,
      embedded: widget.embedded,
      child: ListView(
        padding: const EdgeInsets.only(bottom: 32),
        children: [
          SettingsSection(
            title: l10n.memoryTools,
            children: [
              _memoryToolTile(
                context,
                title: l10n.memoryNoteToolName,
                subtitle: l10n.memoryNoteToolDesc,
              ),
              _memoryToolTile(
                context,
                title: l10n.memoryRecallToolName,
                subtitle: l10n.memoryRecallToolDesc,
              ),
            ],
          ),
          SettingsSection(
            title: l10n.promptTools,
            children: [
              SettingsSwitchTile(
                title: l10n.addTimeToPrompt,
                value: _addTimeToPrompt,
                subtitle: l10n.addTimeToPromptDesc,
                onChanged: (v) async {
                  setState(() => _addTimeToPrompt = v);
                  await _settingsService.setAddTimeToPrompt(v);
                },
              ),
              SettingsSwitchTile(
                title: l10n.builtinDateMath,
                value: _builtinDateMath,
                subtitle: l10n.builtinDateMathDesc,
                onChanged: (v) async {
                  setState(() => _builtinDateMath = v);
                  await _settingsService.setBuiltinDateMathEnabled(v);
                },
              ),
              SettingsSwitchTile(
                title: l10n.builtinLunarCalendar,
                value: _builtinLunarCalendar,
                subtitle: l10n.builtinLunarCalendarDesc,
                onChanged: (v) async {
                  setState(() => _builtinLunarCalendar = v);
                  await _settingsService.setBuiltinLunarCalendarEnabled(v);
                },
              ),
              SettingsSwitchTile(
                title: l10n.builtinCalculator,
                value: _builtinCalculator,
                subtitle: l10n.builtinCalculatorDesc,
                onChanged: (v) async {
                  setState(() => _builtinCalculator = v);
                  await _settingsService.setBuiltinCalculatorEnabled(v);
                },
              ),
              SettingsSwitchTile(
                title: l10n.builtinTextTools,
                value: _builtinTextTools,
                subtitle: l10n.builtinTextToolsDesc,
                onChanged: (v) async {
                  setState(() => _builtinTextTools = v);
                  await _settingsService.setBuiltinTextToolsEnabled(v);
                },
              ),
              SettingsSwitchTile(
                title: l10n.builtinUnitConvert,
                value: _builtinUnitConvert,
                subtitle: l10n.builtinUnitConvertDesc,
                onChanged: (v) async {
                  setState(() => _builtinUnitConvert = v);
                  await _settingsService.setBuiltinUnitConvertEnabled(v);
                },
              ),
              SettingsSwitchTile(
                title: l10n.builtinUserProfile,
                value: _builtinUserProfile,
                subtitle: l10n.builtinUserProfileDesc,
                onChanged: (v) async {
                  setState(() => _builtinUserProfile = v);
                  await _settingsService.setBuiltinUserProfileEnabled(v);
                },
              ),
            ],
          ),
          SettingsSection(
            title: l10n.mcpServers,
            footer: _mcpStatusMessage ??
                (_platformSupportsTools
                    ? l10n.mcpPlatformSupported
                    : l10n.mcpPlatformUnsupported),
            children: [
              for (final server in _servers) ...[
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 16,
                    vertical: 11,
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      Row(
                        children: [
                          Expanded(
                            child: GestureDetector(
                              behavior: HitTestBehavior.opaque,
                              onTap: () => _editingServerId == server.id
                                  ? _cancelEditServer()
                                  : _beginEditServer(server),
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    server.name,
                                    style: TextStyle(
                                      fontSize: 15.5,
                                      fontWeight: FontWeight.w500,
                                      color: AppTokens.label(context),
                                    ),
                                  ),
                                  const SizedBox(height: 2),
                                  Text(
                                    server.url,
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
                          ),
                          CupertinoButton(
                            padding: const EdgeInsets.symmetric(horizontal: 8),
                            onPressed: () => _testConnection(server),
                            child: Text(
                              l10n.mcpTestConnection,
                              style: TextStyle(
                                fontSize: 13,
                                color: AppTokens.accent(context),
                              ),
                            ),
                          ),
                          CupertinoSwitch(
                            value: server.enabled,
                            onChanged: (value) async {
                              final updated = _servers
                                  .map(
                                    (item) => item.id == server.id
                                        ? McpServerConfig(
                                            id: item.id,
                                            name: item.name,
                                            url: item.url,
                                            headers: item.headers,
                                            enabled: value,
                                          )
                                        : item,
                                  )
                                  .toList();
                              await _settingsService.saveMcpServers(updated);
                              if (!mounted) return;
                              setState(() => _servers = updated);
                            },
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
                if (_editingServerId == server.id)
                  _buildMcpEditor(context, original: server),
              ],
              if (_isCreatingNew) _buildMcpEditor(context),
              CupertinoButton(
                padding: const EdgeInsets.symmetric(
                  horizontal: 16,
                  vertical: 13,
                ),
                onPressed: () => _beginEditServer(null),
                child: Align(
                  alignment: Alignment.centerLeft,
                  child: Text(
                    '+ ${l10n.addMcpServer}',
                    style: TextStyle(
                      fontSize: 15,
                      fontWeight: FontWeight.w500,
                      color: AppTokens.accent(context),
                    ),
                  ),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class _HeaderDraft {
  final TextEditingController keyController;
  final TextEditingController valueController;

  _HeaderDraft(String key, String value)
      : keyController = TextEditingController(text: key),
        valueController = TextEditingController(text: value);

  void dispose() {
    keyController.dispose();
    valueController.dispose();
  }
}
