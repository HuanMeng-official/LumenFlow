import 'dart:convert';

import 'package:flutter/cupertino.dart';

import '../ai/mcp/mcp_client.dart';
import '../ai/mcp/mcp_models.dart';
import '../ai/providers/chat_completions_profile.dart';
import '../ai/providers/responses_tool_provider.dart';
import '../l10n/app_localizations.dart';
import '../services/settings_service.dart';
import '../widgets/settings/settings_section.dart';
import '../widgets/settings/settings_switch_tile.dart';

/// 工具管理页面
///
/// 管理应用程序的各种工具和功能开关：
/// - 内置工具（时间、计算器、文本）
/// - MCP 服务器与工具
///
/// 设置更改实时保存，无需手动点击保存按钮
class ToolManagementScreen extends StatefulWidget {
  const ToolManagementScreen({super.key});

  @override
  State<ToolManagementScreen> createState() => _ToolManagementScreenState();
}

class _ToolManagementScreenState extends State<ToolManagementScreen> {
  final SettingsService _settingsService = SettingsService();
  bool _isLoading = true;
  bool _addTimeToPrompt = SettingsService.defaultAddTimeToPrompt;
  bool _builtinCalculator = SettingsService.defaultBuiltinCalculatorEnabled;
  bool _builtinTextTools = SettingsService.defaultBuiltinTextToolsEnabled;
  List<McpServerConfig> _servers = const [];
  String _activePlatformType = '';

  @override
  void initState() {
    super.initState();
    _loadSettings();
  }

  Future<void> _loadSettings() async {
    final addTimeToPrompt = await _settingsService.getAddTimeToPrompt();
    final builtinCalculator =
        await _settingsService.getBuiltinCalculatorEnabled();
    final builtinTextTools =
        await _settingsService.getBuiltinTextToolsEnabled();
    final servers = await _settingsService.getMcpServers();
    final config = await _settingsService.getActivePlatformConfig();

    if (!mounted) return;
    setState(() {
      _addTimeToPrompt = addTimeToPrompt;
      _builtinCalculator = builtinCalculator;
      _builtinTextTools = builtinTextTools;
      _servers = servers;
      _activePlatformType = config.apiType;
      _isLoading = false;
    });
  }

  /// 实时保存时间附加开关状态
  Future<void> _onAddTimeToPromptChanged(bool value) async {
    setState(() {
      _addTimeToPrompt = value;
    });
    await _settingsService.setAddTimeToPrompt(value);
  }

  Future<void> _onBuiltinCalculatorChanged(bool value) async {
    setState(() {
      _builtinCalculator = value;
    });
    await _settingsService.setBuiltinCalculatorEnabled(value);
  }

  Future<void> _onBuiltinTextToolsChanged(bool value) async {
    setState(() {
      _builtinTextTools = value;
    });
    await _settingsService.setBuiltinTextToolsEnabled(value);
  }

  Future<void> _saveServers(List<McpServerConfig> servers) async {
    await _settingsService.saveMcpServers(servers);
    if (!mounted) return;
    setState(() {
      _servers = servers;
    });
  }

  Future<void> _toggleServer(McpServerConfig server, bool enabled) async {
    final updated = _servers
        .map(
          (item) => item.id == server.id
              ? McpServerConfig(
                  id: item.id,
                  name: item.name,
                  url: item.url,
                  headers: item.headers,
                  enabled: enabled,
                )
              : item,
        )
        .toList();
    await _saveServers(updated);
  }

  Future<void> _showServerActions(McpServerConfig server) async {
    await showCupertinoModalPopup<void>(
      context: context,
      builder: (context) => CupertinoActionSheet(
        title: Text(server.name),
        message: Text(server.url),
        actions: [
          CupertinoActionSheetAction(
            onPressed: () {
              Navigator.pop(context);
              _showServerDialog(server: server);
            },
            child: const Text('编辑'),
          ),
          CupertinoActionSheetAction(
            onPressed: () {
              Navigator.pop(context);
              _testConnection(this.context, server);
            },
            child: const Text('测试连接'),
          ),
          CupertinoActionSheetAction(
            isDestructiveAction: true,
            onPressed: () {
              Navigator.pop(context);
              _confirmDelete(server);
            },
            child: const Text('删除'),
          ),
        ],
        cancelButton: CupertinoActionSheetAction(
          onPressed: () => Navigator.pop(context),
          child: const Text('取消'),
        ),
      ),
    );
  }

  Future<void> _confirmDelete(McpServerConfig server) async {
    final confirmed = await showCupertinoDialog<bool>(
      context: context,
      builder: (context) => CupertinoAlertDialog(
        title: const Text('删除 MCP 服务器'),
        content: Text('确定删除“${server.name}”吗？'),
        actions: [
          CupertinoDialogAction(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('取消'),
          ),
          CupertinoDialogAction(
            isDestructiveAction: true,
            onPressed: () => Navigator.pop(context, true),
            child: const Text('删除'),
          ),
        ],
      ),
    );

    if (confirmed != true) return;
    await _saveServers(
      _servers.where((item) => item.id != server.id).toList(),
    );
  }

  Future<void> _showServerDialog({McpServerConfig? server}) async {
    final nameController = TextEditingController(text: server?.name ?? '');
    final urlController = TextEditingController(text: server?.url ?? '');
    final headersController = TextEditingController(
      text: server == null || server.headers.isEmpty
          ? ''
          : jsonEncode(server.headers),
    );
    final enabled = server?.enabled ?? true;

    final result = await showCupertinoDialog<McpServerConfig>(
      context: context,
      builder: (dialogContext) {
        McpServerConfig? buildConfig() {
          return _buildConfig(
            id: server?.id,
            name: nameController.text,
            url: urlController.text,
            headersJson: headersController.text,
            enabled: enabled,
          );
        }

        return CupertinoAlertDialog(
          title: Text(server == null ? '添加 MCP 服务器' : '编辑 MCP 服务器'),
          content: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                CupertinoTextField(
                  controller: nameController,
                  placeholder: '名称',
                  padding: const EdgeInsets.all(10),
                ),
                const SizedBox(height: 8),
                CupertinoTextField(
                  controller: urlController,
                  placeholder: 'URL（http/https）',
                  keyboardType: TextInputType.url,
                  padding: const EdgeInsets.all(10),
                ),
                const SizedBox(height: 8),
                CupertinoTextField(
                  controller: headersController,
                  placeholder:
                      '可选：Headers JSON，例如 {"Authorization":"Bearer ..."}',
                  maxLines: 3,
                  minLines: 2,
                  padding: const EdgeInsets.all(10),
                ),
              ],
            ),
          ),
          actions: [
            CupertinoDialogAction(
              onPressed: () => Navigator.pop(dialogContext),
              child: const Text('取消'),
            ),
            CupertinoDialogAction(
              onPressed: () {
                final config = buildConfig();
                if (config == null) {
                  _showValidationError(dialogContext);
                  return;
                }
                _testConnection(dialogContext, config);
              },
              child: const Text('测试'),
            ),
            CupertinoDialogAction(
              onPressed: () {
                final config = buildConfig();
                if (config == null) {
                  _showValidationError(dialogContext);
                  return;
                }
                Navigator.pop(dialogContext, config);
              },
              child: const Text('保存'),
            ),
          ],
        );
      },
    );

    nameController.dispose();
    urlController.dispose();
    headersController.dispose();

    if (result == null) return;

    final index = _servers.indexWhere((item) => item.id == result.id);
    final updated = List<McpServerConfig>.from(_servers);
    if (index >= 0) {
      updated[index] = result;
    } else {
      updated.add(result);
    }
    await _saveServers(updated);
  }

  McpServerConfig? _buildConfig({
    required String? id,
    required String name,
    required String url,
    required String headersJson,
    required bool enabled,
  }) {
    final trimmedName = name.trim();
    final trimmedUrl = url.trim();
    if (trimmedName.isEmpty || trimmedUrl.isEmpty) return null;

    final uri = Uri.tryParse(trimmedUrl);
    if (uri == null || (uri.scheme != 'http' && uri.scheme != 'https')) {
      return null;
    }

    Map<String, String> headers;
    try {
      if (headersJson.trim().isEmpty) {
        headers = const {};
      } else {
        final decoded = jsonDecode(headersJson);
        if (decoded is! Map) return null;
        headers = decoded.map(
          (key, value) => MapEntry(key.toString(), value.toString()),
        );
      }
    } catch (_) {
      return null;
    }

    return McpServerConfig(
      id: id ?? 'mcp_${DateTime.now().millisecondsSinceEpoch}',
      name: trimmedName,
      url: trimmedUrl,
      headers: headers,
      enabled: enabled,
    );
  }

  Future<void> _testConnection(
    BuildContext context,
    McpServerConfig config,
  ) async {
    final client = McpClient(
      config: config,
      timeout: const Duration(seconds: 10),
    );

    String message;
    try {
      final tools = await client.initializeAndListTools();
      if (tools.isEmpty) {
        message = '连接成功，但没有发现工具。';
      } else {
        final names = tools.take(10).map((tool) => tool.name).join(', ');
        message = '连接成功，发现 ${tools.length} 个工具：\n$names';
      }
    } catch (error) {
      message = '连接失败：$error';
    } finally {
      await client.close();
    }

    if (!context.mounted) return;
    await showCupertinoDialog<void>(
      context: context,
      builder: (dialogContext) => CupertinoAlertDialog(
        title: const Text('测试连接'),
        content: Text(message),
        actions: [
          CupertinoDialogAction(
            onPressed: () => Navigator.pop(dialogContext),
            child: const Text('好'),
          ),
        ],
      ),
    );
  }

  void _showValidationError(BuildContext context) {
    showCupertinoDialog<void>(
      context: context,
      builder: (dialogContext) => CupertinoAlertDialog(
        title: const Text('配置无效'),
        content: const Text('请填写名称和有效的 http/https URL，并确保 Headers 是 JSON 对象。'),
        actions: [
          CupertinoDialogAction(
            onPressed: () => Navigator.pop(dialogContext),
            child: const Text('好'),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;

    if (_isLoading) {
      return CupertinoPageScaffold(
        navigationBar: CupertinoNavigationBar(
          middle: Text(l10n.toolManagement),
        ),
        child: const Center(child: CupertinoActivityIndicator()),
      );
    }

    return CupertinoPageScaffold(
      navigationBar: CupertinoNavigationBar(
        middle: Text(l10n.toolManagement),
      ),
      child: SafeArea(
        child: ListView(
          children: [
            SettingsSection(
              title: l10n.promptTools,
              children: [
                SettingsSwitchTile(
                  title: l10n.addTimeToPrompt,
                  value: _addTimeToPrompt,
                  subtitle: l10n.addTimeToPromptDesc,
                  onChanged: _onAddTimeToPromptChanged,
                ),
                SettingsSwitchTile(
                  title: l10n.builtinCalculator,
                  value: _builtinCalculator,
                  subtitle: l10n.builtinCalculatorDesc,
                  onChanged: _onBuiltinCalculatorChanged,
                ),
                SettingsSwitchTile(
                  title: l10n.builtinTextTools,
                  value: _builtinTextTools,
                  subtitle: l10n.builtinTextToolsDesc,
                  onChanged: _onBuiltinTextToolsChanged,
                ),
              ],
            ),
            SettingsSection(
              title: 'MCP 服务器',
              children: [
                Padding(
                  padding: const EdgeInsets.fromLTRB(16, 12, 16, 4),
                  child: Text(
                    ChatCompletionsProfiles.forType(_activePlatformType) !=
                                null ||
                            ResponsesToolProfiles.supports(_activePlatformType)
                        ? '当前平台（$_activePlatformType）支持工具调用。'
                        : '当前平台（$_activePlatformType）暂不支持工具调用。支持的平台：DeepSeek、Kimi、MiniMax、智谱、SiliconFlow、Other、Xiaomi MiMo、OpenAI、Grok、OpenRouter、LM Studio。',
                    style: const TextStyle(fontSize: 13),
                  ),
                ),
                if (_servers.isEmpty)
                  const Padding(
                    padding: EdgeInsets.fromLTRB(16, 12, 16, 12),
                    child: Text(
                      '尚未配置 MCP 服务器。添加后，支持的平台可以在对话中调用这些工具。',
                      style: TextStyle(fontSize: 13),
                    ),
                  ),
                for (final server in _servers)
                  CupertinoListTile(
                    title: Text(server.name),
                    subtitle: Text(
                      server.url,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                    trailing: CupertinoSwitch(
                      value: server.enabled,
                      onChanged: (value) => _toggleServer(server, value),
                    ),
                    onTap: () => _showServerActions(server),
                  ),
                CupertinoListTile(
                  leading: const Icon(CupertinoIcons.add),
                  title: const Text('添加 MCP 服务器'),
                  onTap: () => _showServerDialog(),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}
