import '../contracts/ai_tool.dart';

/// Protocol era negotiated with an MCP server.
enum McpProtocolEra {
  /// MCP 2026-07-28+: stateless requests with `server/discover`, per-request
  /// `_meta`, and `MCP-Protocol-Version` / `Mcp-Method` / `Mcp-Name` headers.
  stateless,

  /// MCP 2024-11-05 .. 2025-11-25: stateful `initialize` / `initialized`
  /// handshake with optional `Mcp-Session-Id` session tracking.
  stateful,
}

class McpServerInfo {
  final String name;
  final String version;
  final String? title;

  const McpServerInfo({
    required this.name,
    this.version = '',
    this.title,
  });

  factory McpServerInfo.fromJson(Map<String, dynamic> json) {
    return McpServerInfo(
      name: json['name']?.toString() ?? '',
      version: json['version']?.toString() ?? '',
      title: json['title']?.toString(),
    );
  }
}

class McpServerConfig {
  final String id;
  final String name;
  final String url;
  final Map<String, String> headers;
  final bool enabled;

  const McpServerConfig({
    required this.id,
    required this.name,
    required this.url,
    this.headers = const {},
    this.enabled = true,
  });

  factory McpServerConfig.fromJson(Map<String, dynamic> json) {
    final rawHeaders = json['headers'];
    final headers = <String, String>{};
    if (rawHeaders is Map) {
      for (final entry in rawHeaders.entries) {
        headers[entry.key.toString()] = entry.value.toString();
      }
    }

    return McpServerConfig(
      id: json['id'] as String,
      name: json['name'] as String? ?? json['id'] as String,
      url: json['url'] as String,
      headers: headers,
      enabled: json['enabled'] as bool? ?? true,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'name': name,
      'url': url,
      'headers': headers,
      'enabled': enabled,
    };
  }
}

class McpTool {
  final String name;
  final String? title;
  final String description;
  final Map<String, dynamic> inputSchema;
  final Map<String, dynamic>? outputSchema;
  final Map<String, dynamic>? annotations;

  const McpTool({
    required this.name,
    this.title,
    this.description = '',
    this.inputSchema = const {},
    this.outputSchema,
    this.annotations,
  });

  AIToolDefinition toDefinition({required String name}) {
    return AIToolDefinition(
      name: name,
      description: description.isNotEmpty ? description : (title ?? ''),
      inputSchema: inputSchema,
    );
  }
}

class McpException implements Exception {
  final String message;
  final int? code;
  final int? httpStatus;
  final Object? data;

  const McpException(
    this.message, {
    this.code,
    this.httpStatus,
    this.data,
  });

  @override
  String toString() {
    final codeText = code == null ? '' : ' code=$code';
    return 'McpException($codeText): $message';
  }
}
