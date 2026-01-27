import 'package:flutter/cupertino.dart';
import '../l10n/app_localizations.dart';
import '../models/mcp_server.dart';
import '../services/settings_service.dart';

/// MCP Server配置界面
///
/// 用户提供统一的界面来管理多个MCP Server的配置：
/// - 添加、编辑、删除MCP Server配置
/// - 配置连接类型、地址、名称
/// - 启用/禁用MCP Server
class ToolsSettingsScreen extends StatefulWidget {
  const ToolsSettingsScreen({super.key});

  @override
  State<ToolsSettingsScreen> createState() => _ToolsSettingsScreenState();
}

class _ToolsSettingsScreenState extends State<ToolsSettingsScreen> {
  final SettingsService _settingsService = SettingsService();
  List<McpServer> _servers = [];
  bool _isLoading = true;

  /// 可用的连接类型列表
  static const List<String> _availableConnectionTypes = [
    'http',
    'stdio',
    'websocket',
  ];

  @override
  void initState() {
    super.initState();
    _loadData();
  }

  /// 加载MCP Server配置数据
  Future<void> _loadData() async {
    setState(() {
      _isLoading = true;
    });

    final servers = await _settingsService.getMcpServers();

    debugPrint('加载MCP Server数据完成: ${servers.length}个服务器');

    setState(() {
      _servers = servers;
      _isLoading = false;
    });
  }

  /// 显示添加/编辑MCP Server对话框
  Future<void> _showServerDialog([McpServer? server]) async {
    final l10n = AppLocalizations.of(context)!;
    final isEdit = server != null;

    final nameController = TextEditingController(text: server?.name ?? '');
    final addressController = TextEditingController(text: server?.address ?? '');
    String selectedType = server?.type ?? 'http';
    bool enabled = server?.enabled ?? true;

    final result = await showCupertinoDialog<bool>(
      context: context,
      builder: (context) => StatefulBuilder(
        builder: (context, setDialogState) => CupertinoAlertDialog(
          title: Text(isEdit ? l10n.edit : l10n.add),
          content: SizedBox(
            width: double.maxFinite,
            child: SingleChildScrollView(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // 连接类型选择
                  Text(l10n.mcpServerType),
                  const SizedBox(height: 8),
                  SizedBox(
                    height: 70,
                    child: GridView.builder(
                      gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                        crossAxisCount: 3,
                        mainAxisSpacing: 8,
                        crossAxisSpacing: 8,
                        childAspectRatio: 2,
                      ),
                      itemCount: _availableConnectionTypes.length,
                      itemBuilder: (context, index) {
                        final type = _availableConnectionTypes[index];
                        return _buildConnectionTypeButton(
                          type,
                          selectedType,
                          (value) {
                            setDialogState(() {
                              selectedType = value;
                              // 根据类型更新地址占位符提示
                              // 可以在这里添加类型切换时的地址清理逻辑
                            });
                          },
                        );
                      },
                    ),
                  ),
                  const SizedBox(height: 12),

                  // 服务器名称
                  CupertinoTextField(
                    controller: nameController,
                    placeholder: l10n.mcpServerNamePlaceholder,
                    prefix: Padding(
                      padding: const EdgeInsets.only(left: 8),
                      child: Icon(CupertinoIcons.tag, size: 20),
                    ),
                    padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                    decoration: BoxDecoration(
                      color: CupertinoColors.systemGrey6,
                      borderRadius: BorderRadius.circular(8),
                    ),
                  ),
                  const SizedBox(height: 12),

                  // 服务器地址
                  CupertinoTextField(
                    controller: addressController,
                    placeholder: _getAddressPlaceholder(selectedType),
                    prefix: const Padding(
                      padding: EdgeInsets.only(left: 8),
                      child: Icon(CupertinoIcons.link, size: 20),
                    ),
                    padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                    decoration: BoxDecoration(
                      color: CupertinoColors.systemGrey6,
                      borderRadius: BorderRadius.circular(8),
                    ),
                  ),
                  const SizedBox(height: 12),

                  // 启用/禁用开关
                  Row(
                    children: [
                      const Icon(CupertinoIcons.power, size: 20),
                      const SizedBox(width: 8),
                      Text(l10n.mcpServerEnable),
                      const Spacer(),
                      CupertinoSwitch(
                        value: enabled,
                        onChanged: (value) {
                          setDialogState(() {
                            enabled = value;
                          });
                        },
                      ),
                    ],
                  ),

                  // 地址描述
                  Padding(
                    padding: const EdgeInsets.only(top: 8),
                    child: Text(
                      _getAddressDescription(selectedType),
                      style: TextStyle(
                        fontSize: 12,
                        color: CupertinoColors.systemGrey,
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
          actions: [
            CupertinoDialogAction(
              child: Text(l10n.cancel),
              onPressed: () => Navigator.pop(context, false),
            ),
            CupertinoDialogAction(
              isDefaultAction: true,
              child: Text(isEdit ? l10n.save : l10n.add),
              onPressed: () {
                if (nameController.text.trim().isEmpty) {
                  _showError(l10n.mcpServerErrorNameRequired);
                  return;
                }
                if (addressController.text.trim().isEmpty) {
                  _showError(l10n.mcpServerErrorAddressRequired);
                  return;
                }
                Navigator.pop(context, true);
              },
            ),
          ],
        ),
      ),
    );

    if (result == true && mounted) {
      final newServer = McpServer(
        id: server?.id ?? 'mcp_${DateTime.now().millisecondsSinceEpoch}',
        name: nameController.text.trim(),
        type: selectedType,
        address: addressController.text.trim(),
        enabled: enabled,
      );

      await _settingsService.saveMcpServer(newServer);
      await _loadData();
    }
  }

  /// 构建连接类型选择按钮
  Widget _buildConnectionTypeButton(
    String type,
    String currentType,
    Function(String) onTap,
  ) {
    final isSelected = type == currentType;
    final brightness = CupertinoTheme.of(context).brightness;

    String displayText;
    switch (type) {
      case 'http':
        displayText = 'HTTP';
        break;
      case 'stdio':
        displayText = 'STDIO';
        break;
      case 'websocket':
        displayText = 'WebSocket';
        break;
      default:
        displayText = type;
    }

    return GestureDetector(
      onTap: () => onTap(type),
      child: Container(
        padding: const EdgeInsets.all(10),
        decoration: BoxDecoration(
          color: isSelected
              ? (brightness == Brightness.dark
                  ? CupertinoColors.activeBlue.darkColor
                  : CupertinoColors.activeBlue.color)
              : (brightness == Brightness.dark
                  ? CupertinoColors.systemGrey6.darkColor
                  : CupertinoColors.systemGrey6.color),
          borderRadius: BorderRadius.circular(10),
          border: Border.all(
            color: isSelected
                ? CupertinoColors.transparent
                : (brightness == Brightness.dark
                    ? CupertinoColors.systemGrey5.darkColor
                    : CupertinoColors.systemGrey5.color),
            width: 1,
          ),
        ),
        child: Center(
          child: Text(
            displayText,
            style: TextStyle(
              fontWeight: isSelected ? FontWeight.w600 : FontWeight.normal,
              color: isSelected
                  ? CupertinoColors.white
                  : (brightness == Brightness.dark
                      ? CupertinoColors.label.darkColor
                      : CupertinoColors.label.color),
            ),
          ),
        ),
      ),
    );
  }

  /// 获取地址占位符文本
  String _getAddressPlaceholder(String type) {
    switch (type) {
      case 'http':
        return 'https://example.com/mcp';
      case 'websocket':
        return 'ws://example.com/mcp';
      case 'stdio':
        return 'node server.js';
      default:
        return 'Enter server address';
    }
  }

  /// 获取地址描述文本
  String _getAddressDescription(String type) {
    final l10n = AppLocalizations.of(context)!;
    switch (type) {
      case 'http':
        return l10n.mcpServerAddressHttpDesc;
      case 'websocket':
        return l10n.mcpServerAddressWebsocketDesc;
      case 'stdio':
        return l10n.mcpServerAddressStdioDesc;
      default:
        return l10n.mcpServerAddressGenericDesc;
    }
  }

  /// 删除MCP Server
  Future<void> _deleteServer(McpServer server) async {
    final l10n = AppLocalizations.of(context)!;
    final result = await showCupertinoDialog<bool>(
      context: context,
      builder: (context) => CupertinoAlertDialog(
        title: Text(l10n.delete),
        content: Text(l10n.mcpServerDeleteConfirm(server.name)),
        actions: [
          CupertinoDialogAction(
            child: Text(l10n.cancel),
            onPressed: () => Navigator.pop(context, false),
          ),
          CupertinoDialogAction(
            isDestructiveAction: true,
            child: Text(l10n.delete),
            onPressed: () => Navigator.pop(context, true),
          ),
        ],
      ),
    );

    if (result == true && mounted) {
      await _settingsService.deleteMcpServer(server.id);
      await _loadData();
    }
  }

  /// 切换启用/禁用状态
  Future<void> _toggleServerEnabled(McpServer server) async {
    final updatedServer = server.copyWith(enabled: !server.enabled);
    await _settingsService.saveMcpServer(updatedServer);
    await _loadData();
  }

  void _showError(String message) {
    showCupertinoDialog(
      context: context,
      builder: (context) => CupertinoAlertDialog(
        title: Text(AppLocalizations.of(context)!.error),
        content: Text(message),
        actions: [
          CupertinoDialogAction(
            child: Text(AppLocalizations.of(context)!.ok),
            onPressed: () => Navigator.pop(context),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;

    return CupertinoPageScaffold(
      navigationBar: CupertinoNavigationBar(
        middle: Text(l10n.toolsSettings),
        trailing: CupertinoButton(
          padding: EdgeInsets.zero,
          onPressed: _showServerDialog,
          child: const Icon(CupertinoIcons.add),
        ),
      ),
      child: SafeArea(
        child: _isLoading
            ? const Center(child: CupertinoActivityIndicator())
            : _servers.isEmpty
                ? _buildEmptyState()
                : ListView.builder(
                    padding: const EdgeInsets.all(16),
                    itemCount: _servers.length,
                    itemBuilder: (context, index) {
                      final server = _servers[index];
                      return _buildServerCard(server);
                    },
                  ),
      ),
    );
  }

  Widget _buildServerCard(McpServer server) {
    final brightness = CupertinoTheme.of(context).brightness;

    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: brightness == Brightness.dark
            ? CupertinoColors.systemBackground.darkColor
            : CupertinoColors.systemBackground.color,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: server.enabled
              ? CupertinoColors.activeBlue
              : CupertinoColors.systemGrey4,
          width: server.enabled ? 2 : 1,
        ),
      ),
      child: Row(
        children: [
          _buildServerIcon(server.type),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  server.name,
                  style: TextStyle(
                    fontSize: 17,
                    fontWeight: FontWeight.w600,
                  ),
                ),
                const SizedBox(height: 4),
                Row(
                  children: [
                    Icon(
                      CupertinoIcons.globe,
                      size: 14,
                      color: CupertinoColors.systemBlue,
                    ),
                    const SizedBox(width: 4),
                    Expanded(
                      child: Text(
                        '${server.typeDisplayName}: ${server.address}',
                        style: TextStyle(
                          fontSize: 13,
                          color: brightness == Brightness.dark
                              ? CupertinoColors.systemGrey.darkColor
                              : CupertinoColors.systemGrey,
                        ),
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
          const SizedBox(width: 8),
          CupertinoSwitch(
            value: server.enabled,
            onChanged: (value) => _toggleServerEnabled(server),
          ),
          const SizedBox(width: 8),
          CupertinoButton(
            padding: EdgeInsets.zero,
            minimumSize: const Size(32, 32),
            onPressed: () => _showServerOptions(server),
            child: const Icon(
              CupertinoIcons.ellipsis,
              color: CupertinoColors.systemGrey,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildEmptyState() {
    final l10n = AppLocalizations.of(context)!;
    final brightness = CupertinoTheme.of(context).brightness;

    return SizedBox.expand(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
        const SizedBox(height: 60),
        Icon(
          CupertinoIcons.cube_box,
          size: 80,
          color: brightness == Brightness.dark
              ? CupertinoColors.systemGrey.darkColor
              : CupertinoColors.systemGrey3,
        ),
        const SizedBox(height: 24),
        Text(
          l10n.mcpServerNoConfig,
          style: TextStyle(
            fontSize: 22,
            fontWeight: FontWeight.w600,
            color: brightness == Brightness.dark
                ? CupertinoColors.label.darkColor
                : CupertinoColors.label.color,
          ),
        ),
        const SizedBox(height: 8),
        Text(
          l10n.mcpServerAddHint,
          style: TextStyle(
            fontSize: 15,
            color: brightness == Brightness.dark
                ? CupertinoColors.secondaryLabel.darkColor
                : CupertinoColors.secondaryLabel.color,
          ),
          textAlign: TextAlign.center,
        ),
        const SizedBox(height: 32),
        CupertinoButton.filled(
          onPressed: _showServerDialog,
          borderRadius: BorderRadius.circular(12),
          padding: const EdgeInsets.symmetric(horizontal: 32, vertical: 12),
          child: Text(l10n.add),
        ),
        const SizedBox(height: 20),
        ],
      ),
    );
  }

  void _showServerOptions(McpServer server) {
    final l10n = AppLocalizations.of(context)!;
    showCupertinoModalPopup(
      context: context,
      builder: (context) => CupertinoActionSheet(
        actions: [
          CupertinoActionSheetAction(
            child: Text(l10n.edit),
            onPressed: () {
              Navigator.pop(context);
              _showServerDialog(server);
            },
          ),
          CupertinoActionSheetAction(
            isDestructiveAction: true,
            child: Text(l10n.delete),
            onPressed: () {
              Navigator.pop(context);
              _deleteServer(server);
            },
          ),
        ],
        cancelButton: CupertinoActionSheetAction(
          child: Text(l10n.cancel),
          onPressed: () => Navigator.pop(context),
        ),
      ),
    );
  }

  /// 构建服务器图标
  Widget _buildServerIcon(String type) {
    IconData icon;
    Color color;

    switch (type) {
      case 'http':
        icon = CupertinoIcons.globe;
        color = CupertinoColors.systemBlue;
        break;
      case 'stdio':
        icon = CupertinoIcons.text_cursor;
        color = CupertinoColors.systemGreen;
        break;
      case 'websocket':
        icon = CupertinoIcons.bolt;
        color = CupertinoColors.systemOrange;
        break;
      default:
        icon = CupertinoIcons.cube_box;
        color = CupertinoColors.systemGrey;
    }

    return Container(
      width: 32,
      height: 32,
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.15),
        borderRadius: BorderRadius.circular(8),
      ),
      child: Icon(
        icon,
        color: color,
        size: 20,
      ),
    );
  }
}