import '../contracts/ai_tool.dart';

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
  final String description;
  final Map<String, dynamic> inputSchema;

  const McpTool({
    required this.name,
    this.description = '',
    this.inputSchema = const {},
  });

  AIToolDefinition toDefinition({required String name}) {
    return AIToolDefinition(
      name: name,
      description: description,
      inputSchema: inputSchema,
    );
  }
}

class McpException implements Exception {
  final String message;
  final int? code;
  final Object? data;

  const McpException(this.message, {this.code, this.data});

  @override
  String toString() {
    final codeText = code == null ? '' : ' code=$code';
    return 'McpException($codeText): $message';
  }
}
