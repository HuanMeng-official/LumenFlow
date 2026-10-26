import '../contracts/ai_tool.dart';
import '../contracts/ai_tool_executor.dart';
import 'mcp_client.dart';
import 'mcp_models.dart';

class _ServerResult {
  final McpServerConfig server;
  final McpConnection? connection;
  final List<McpTool> tools;
  final Object? error;

  const _ServerResult({
    required this.server,
    this.connection,
    this.tools = const [],
    this.error,
  });
}

/// Merges tools from multiple MCP servers and routes executions by prefix.
class McpToolManager implements AIToolExecutor {
  McpToolManager({
    required this._servers,
    required this._connectionFactory,
    this.timeout = const Duration(seconds: 20),
  });

  final List<McpServerConfig> _servers;
  final McpConnection Function(McpServerConfig config) _connectionFactory;
  final Duration timeout;

  final Map<String, McpConnection> _connections = {};
  final Map<String, McpTool> _toolsByPrefixedName = {};
  final Map<String, String> _serverByPrefixedName = {};
  final Map<String, String> _errors = {};

  List<AIToolDefinition> _definitions = const [];

  Map<String, String> get errors => Map.unmodifiable(_errors);

  @override
  List<AIToolDefinition> get tools => _definitions;

  Future<void> refresh() async {
    await dispose();

    final enabled = _servers.where((server) => server.enabled).toList();
    final results = await Future.wait(enabled.map(_connect));

    for (final result in results) {
      if (result.error != null) {
        _errors[result.server.id] = result.error.toString();
        continue;
      }

      final connection = result.connection;
      if (connection == null) continue;
      _connections[result.server.id] = connection;

      for (final tool in result.tools) {
        var prefixed = _prefix(result.server.id, tool.name);
        var attempt = 0;
        while (_toolsByPrefixedName.containsKey(prefixed)) {
          prefixed = _appendHash(
            _prefix(result.server.id, tool.name),
            '${tool.name}#${attempt++}',
          );
        }
        _toolsByPrefixedName[prefixed] = tool;
        _serverByPrefixedName[prefixed] = result.server.id;
      }
    }

    _definitions = _toolsByPrefixedName.entries
        .map((entry) => entry.value.toDefinition(name: entry.key))
        .toList();
  }

  Future<_ServerResult> _connect(McpServerConfig server) async {
    McpConnection? connection;
    try {
      connection = _connectionFactory(server);
      final serverTools =
          await connection.initializeAndListTools().timeout(timeout);
      return _ServerResult(
        server: server,
        connection: connection,
        tools: serverTools,
      );
    } catch (error) {
      try {
        await connection?.close();
      } catch (_) {
        // A failing close must not hide the original error.
      }
      return _ServerResult(server: server, error: error);
    }
  }

  @override
  Future<AIToolResult> execute(AIToolCall call) async {
    final serverId = _serverByPrefixedName[call.name];
    if (serverId == null) {
      return AIToolResult(
        toolCallId: call.id,
        name: call.name,
        content: 'Unknown tool: ${call.name}',
        isError: true,
      );
    }

    final connection = _connections[serverId];
    if (connection == null) {
      return AIToolResult(
        toolCallId: call.id,
        name: call.name,
        content: 'MCP server not connected: $serverId',
        isError: true,
      );
    }

    final originalName = _toolsByPrefixedName[call.name]?.name ?? call.name;

    try {
      final result = await connection.callTool(originalName, call.arguments);
      return AIToolResult(
        toolCallId: call.id,
        name: call.name,
        content: result.content,
        isError: result.isError,
      );
    } catch (error) {
      return AIToolResult(
        toolCallId: call.id,
        name: call.name,
        content: error.toString(),
        isError: true,
      );
    }
  }

  Future<void> dispose() async {
    for (final connection in _connections.values) {
      try {
        await connection.close();
      } catch (_) {
        // Keep disposing the remaining connections.
      }
    }
    _connections.clear();
    _toolsByPrefixedName.clear();
    _serverByPrefixedName.clear();
    _definitions = const [];
    _errors.clear();
  }

  String _prefix(String serverId, String toolName) {
    final serverSegment = _serverSegment(serverId);
    final prefix = 'mcp__${serverSegment}__';
    final maxToolLength = 64 - prefix.length;

    var toolPart = _sanitize(toolName);
    if (toolPart.isEmpty) toolPart = 'tool';

    if (toolPart.length > maxToolLength) {
      final suffix = '_${_shortHash(toolName)}';
      final cut = maxToolLength - suffix.length;
      toolPart = cut > 0
          ? '${toolPart.substring(0, cut)}$suffix'
          : suffix;
    }

    return '$prefix$toolPart';
  }

  String _appendHash(String prefixed, String original) {
    final suffix = '_${_shortHash(original)}';
    final base = prefixed.length + suffix.length > 64
        ? prefixed.substring(0, 64 - suffix.length)
        : prefixed;
    return '$base$suffix';
  }

  String _serverSegment(String id) {
    var sanitized = _sanitize(id);
    if (sanitized.isEmpty) sanitized = 'server';
    if (sanitized.length > 20) {
      sanitized = '${sanitized.substring(0, 11)}_${_shortHash(id)}';
    }
    return sanitized;
  }

  String _sanitize(String value) {
    return value.replaceAll(RegExp(r'[^A-Za-z0-9_-]'), '_');
  }

  String _shortHash(String value) {
    var hash = 0x811c9dc5;
    for (final code in value.codeUnits) {
      hash ^= code;
      hash = (hash * 0x01000193) & 0xffffffff;
    }
    return hash.toRadixString(16).padLeft(8, '0');
  }
}
