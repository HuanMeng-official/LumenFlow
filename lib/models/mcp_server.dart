/// MCP Server配置模型
///
/// 支持多个MCP Server（模型上下文协议服务器）的配置管理
/// 每个MCP Server包含连接类型、地址、名称等信息
class McpServer {
  /// 服务器唯一标识
  final String id;

  /// 服务器名称
  final String name;

  /// 连接类型：http, stdio, websocket
  final String type;

  /// 服务器地址
  /// - HTTP/WebSocket: URL地址
  /// - stdio: 命令行命令
  final String address;

  /// 是否启用
  final bool enabled;

  /// 创建时间
  final DateTime createdAt;

  /// 最后更新时间
  final DateTime updatedAt;

  McpServer({
    required this.id,
    required this.name,
    required this.type,
    required this.address,
    this.enabled = true,
    DateTime? createdAt,
    DateTime? updatedAt,
  })  : createdAt = createdAt ?? DateTime.now(),
        updatedAt = updatedAt ?? DateTime.now();

  /// 从JSON创建McpServer实例
  factory McpServer.fromJson(Map<String, dynamic> json) {
    return McpServer(
      id: json['id'] as String,
      name: json['name'] as String,
      type: json['type'] as String,
      address: json['address'] as String,
      enabled: json['enabled'] as bool? ?? true,
      createdAt: json['createdAt'] != null
          ? DateTime.parse(json['createdAt'] as String)
          : null,
      updatedAt: json['updatedAt'] != null
          ? DateTime.parse(json['updatedAt'] as String)
          : null,
    );
  }

  /// 转换为JSON
  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'name': name,
      'type': type,
      'address': address,
      'enabled': enabled,
      'createdAt': createdAt.toIso8601String(),
      'updatedAt': updatedAt.toIso8601String(),
    };
  }

  /// 创建拷贝
  McpServer copyWith({
    String? id,
    String? name,
    String? type,
    String? address,
    bool? enabled,
    DateTime? createdAt,
    DateTime? updatedAt,
  }) {
    return McpServer(
      id: id ?? this.id,
      name: name ?? this.name,
      type: type ?? this.type,
      address: address ?? this.address,
      enabled: enabled ?? this.enabled,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? DateTime.now(),
    );
  }

  /// 创建新MCP Server实例
  static McpServer create({
    required String name,
    required String type,
    required String address,
    bool enabled = true,
  }) {
    final id = 'mcp_${DateTime.now().millisecondsSinceEpoch}';
    return McpServer(
      id: id,
      name: name,
      type: type,
      address: address,
      enabled: enabled,
    );
  }

  /// 检查配置是否有效
  bool get isValid {
    if (name.isEmpty) return false;
    if (address.isEmpty) return false;

    // 根据类型验证地址格式
    switch (type) {
      case 'http':
      case 'websocket':
        // 简单验证URL格式
        return address.startsWith('http://') ||
               address.startsWith('https://') ||
               address.startsWith('ws://') ||
               address.startsWith('wss://');
      case 'stdio':
        // stdio只需要非空命令
        return address.isNotEmpty;
      default:
        return false;
    }
  }

  /// 获取显示名称
  String get displayName => name;

  /// 获取连接类型显示名称
  String get typeDisplayName {
    switch (type) {
      case 'http':
        return 'HTTP';
      case 'stdio':
        return 'STDIO';
      case 'websocket':
        return 'WebSocket';
      default:
        return type;
    }
  }

  /// 获取地址占位符文本
  String get addressPlaceholder {
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

  /// 获取地址描述
  String get addressDescription {
    switch (type) {
      case 'http':
        return 'HTTP/HTTPS URL地址';
      case 'websocket':
        return 'WebSocket URL地址';
      case 'stdio':
        return '本地命令行命令';
      default:
        return '服务器地址';
    }
  }
}