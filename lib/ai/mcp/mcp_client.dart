import 'dart:async';
import 'dart:convert';

import 'package:http/http.dart' as http;

import '../contracts/ai_tool.dart';
import '../transport/sse_decoder.dart';
import 'mcp_models.dart';

abstract class McpConnection {
  Future<List<McpTool>> initializeAndListTools();

  Future<AIToolResult> callTool(
    String name,
    Map<String, dynamic> arguments,
  );

  Future<void> close();
}

/// Minimal MCP client over Streamable HTTP JSON-RPC 2.0.
class McpClient implements McpConnection {
  McpClient({
    required this.config,
    http.Client? client,
    this.timeout = const Duration(seconds: 20),
  }) : _client = client ?? http.Client();

  final McpServerConfig config;
  final Duration timeout;
  final http.Client _client;

  static const String _requestedProtocolVersion = '2025-03-26';
  static const Set<String> _supportedProtocolVersions = {
    '2024-11-05',
    '2025-03-26',
    '2025-06-18',
  };

  int _nextId = 1;
  String? _sessionId;
  String? _protocolVersion;
  bool _initialized = false;

  @override
  Future<List<McpTool>> initializeAndListTools() async {
    await _ensureInitialized();

    final result = await _request('tools/list', const {});
    final rawTools = result['tools'];
    if (rawTools is! List) return const [];

    final tools = <McpTool>[];
    for (final raw in rawTools) {
      if (raw is! Map) continue;
      final map = raw.cast<String, dynamic>();
      final name = map['name']?.toString() ?? '';
      if (name.isEmpty) continue;

      final schema = map['inputSchema'] ?? map['input_schema'];
      tools.add(
        McpTool(
          name: name,
          description: map['description']?.toString() ?? '',
          inputSchema: schema is Map
              ? schema.cast<String, dynamic>()
              : const <String, dynamic>{},
        ),
      );
    }

    return tools;
  }

  @override
  Future<AIToolResult> callTool(
    String name,
    Map<String, dynamic> arguments,
  ) async {
    await _ensureInitialized();

    final result = await _request('tools/call', {
      'name': name,
      'arguments': arguments,
    });

    final content = result['content'];
    final buffer = StringBuffer();
    if (content is List) {
      for (final item in content) {
        if (item is! Map) continue;
        if (item['type'] == 'text') {
          final text = item['text'];
          if (text is String) {
            if (buffer.isNotEmpty) buffer.write('\n');
            buffer.write(text);
          }
        } else {
          if (buffer.isNotEmpty) buffer.write('\n');
          buffer.write('[${item['type'] ?? 'content'}]');
        }
      }
    }
    if (buffer.isEmpty) {
      buffer.write(jsonEncode(result));
    }

    return AIToolResult(
      toolCallId: '',
      name: name,
      content: buffer.toString(),
      isError: result['isError'] == true,
    );
  }

  Future<void> _ensureInitialized() async {
    if (_initialized) return;

    final result = await _request(
      'initialize',
      {
        'protocolVersion': _requestedProtocolVersion,
        'capabilities': const <String, dynamic>{},
        'clientInfo': const {
          'name': 'LumenFlow',
          'version': '2.4.0',
        },
      },
      captureSession: true,
    );

    final negotiated = result['protocolVersion'];
    if (negotiated is String && negotiated.isNotEmpty) {
      if (!_supportedProtocolVersions.contains(negotiated)) {
        throw McpException('Unsupported MCP protocol version: $negotiated');
      }
      _protocolVersion = negotiated;
    } else {
      _protocolVersion = _requestedProtocolVersion;
    }

    await _notify('notifications/initialized');
    _initialized = true;
  }

  Future<void> _notify(
    String method, [
    Map<String, dynamic> params = const {},
  ]) async {
    await _post(
      {
        'jsonrpc': '2.0',
        'method': method,
        'params': params,
      },
      acceptEmpty: true,
    );
  }

  Future<Map<String, dynamic>> _request(
    String method,
    Map<String, dynamic> params, {
    bool captureSession = false,
  }) async {
    final id = _nextId++;
    final response = await _post(
      {
        'jsonrpc': '2.0',
        'id': id,
        'method': method,
        'params': params,
      },
      captureSession: captureSession,
    );

    if (response is! Map) {
      throw const McpException('Invalid JSON-RPC response');
    }

    final map = response.cast<String, dynamic>();
    final error = map['error'];
    if (error != null) {
      if (error is Map) {
        throw McpException(
          error['message']?.toString() ?? 'JSON-RPC error',
          code: (error['code'] as num?)?.toInt(),
          data: error['data'],
        );
      }
      throw McpException(error.toString());
    }

    final result = map['result'];
    return result is Map
        ? result.cast<String, dynamic>()
        : <String, dynamic>{};
  }

  Future<dynamic> _post(
    Map<String, dynamic> payload, {
    bool captureSession = false,
    bool acceptEmpty = false,
  }) async {
    final request = http.Request('POST', Uri.parse(config.url));
    request.headers.addAll(_headers);
    request.body = jsonEncode(payload);

    final response = await _withTimeout(_client.send(request));

    if (captureSession) {
      final session = response.headers['mcp-session-id'] ??
          response.headers['Mcp-Session-Id'];
      if (session != null && session.isNotEmpty) {
        _sessionId = session;
      }
    }

    if (response.statusCode < 200 || response.statusCode >= 300) {
      final body = await _withTimeout(response.stream.bytesToString());
      throw McpException(
        'HTTP ${response.statusCode}: $body',
        code: response.statusCode,
      );
    }

    final contentType = response.headers['content-type'] ?? '';

    if (acceptEmpty) {
      if (contentType.contains('text/event-stream')) {
        final subscription = response.stream.listen(null);
        await subscription.cancel();
      } else {
        await _withTimeout(response.stream.drain<void>());
      }
      return null;
    }

    if (contentType.contains('text/event-stream')) {
      return _readSseResponse(response.stream, id: payload['id']);
    }

    final body = await _withTimeout(response.stream.bytesToString());
    if (body.trim().isEmpty) {
      throw const McpException('Empty response');
    }

    try {
      return jsonDecode(body);
    } on FormatException catch (error) {
      throw McpException('Invalid JSON: ${error.message}');
    }
  }

  Future<Map<String, dynamic>> _readSseResponse(
    Stream<List<int>> stream, {
    required Object? id,
  }) async {
    final decoder = SseDecoder();

    dynamic parse(String data) {
      try {
        return jsonDecode(data);
      } catch (_) {
        return null;
      }
    }

    try {
      await for (final chunk
          in stream.timeout(timeout).transform(utf8.decoder)) {
        for (final event in decoder.add(chunk)) {
          final data = event.data.trim();
          if (data.isEmpty) continue;
          final decoded = parse(data);
          if (decoded is Map && decoded['id'] == id) {
            return decoded.cast<String, dynamic>();
          }
        }
      }
    } on TimeoutException {
      throw const McpException('MCP request timed out');
    }

    for (final event in decoder.flush()) {
      final data = event.data.trim();
      if (data.isEmpty) continue;
      final decoded = parse(data);
      if (decoded is Map && decoded['id'] == id) {
        return decoded.cast<String, dynamic>();
      }
    }

    throw const McpException('SSE stream ended without a matching response');
  }

  Map<String, String> get _headers {
    final headers = <String, String>{
      'Content-Type': 'application/json',
      'Accept': 'application/json, text/event-stream',
      ...config.headers,
    };
    final sessionId = _sessionId;
    if (sessionId != null) {
      headers['mcp-session-id'] = sessionId;
    }
    final protocolVersion = _protocolVersion;
    if (protocolVersion != null) {
      headers['MCP-Protocol-Version'] = protocolVersion;
    }
    return headers;
  }

  Future<T> _withTimeout<T>(Future<T> future) async {
    try {
      return await future.timeout(timeout);
    } on TimeoutException {
      throw const McpException('MCP request timed out');
    }
  }

  @override
  Future<void> close() async {
    _client.close();
    _initialized = false;
    _sessionId = null;
    _protocolVersion = null;
  }
}
