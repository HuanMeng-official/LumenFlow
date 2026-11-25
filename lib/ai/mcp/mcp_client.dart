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

/// Dual-era MCP client over Streamable HTTP JSON-RPC 2.0.
///
/// Prefers the stateless `2026-07-28` protocol (`server/discover`, per-request
/// `_meta`, `MCP-Protocol-Version` / `Mcp-Method` / `Mcp-Name` headers) and
/// falls back automatically to stateful `2025-11-25`..`2024-11-05` handshakes
/// (`initialize` + `notifications/initialized` + `Mcp-Session-Id`).
class McpClient implements McpConnection {
  McpClient({
    required this.config,
    http.Client? client,
    this.timeout = const Duration(seconds: 20),
    this.clientName = defaultClientName,
    this.clientVersion = defaultClientVersion,
  }) : _client = client ?? http.Client();

  final McpServerConfig config;
  final Duration timeout;
  final String clientName;
  final String clientVersion;
  final http.Client _client;

  static const String defaultClientName = 'LumenFlow';
  static const String defaultClientVersion = '3.2.0';

  static const String latestProtocolVersion = '2026-07-28';
  static const String latestStatefulProtocolVersion = '2025-11-25';

  static const List<String> supportedStatelessProtocolVersions = [
    '2026-07-28',
  ];
  static const List<String> supportedStatefulProtocolVersions = [
    '2025-11-25',
    '2025-06-18',
    '2025-03-26',
    '2024-11-05',
  ];
  static const List<String> supportedProtocolVersions = [
    ...supportedStatelessProtocolVersions,
    ...supportedStatefulProtocolVersions,
  ];

  static const int _unsupportedProtocolVersionCode = -32022;
  static const int _methodNotFoundCode = -32601;
  static const int _invalidRequestCode = -32600;
  static const int _invalidParamsCode = -32602;
  static const int _maxToolListPages = 50;
  static const Duration _closeRequestTimeout = Duration(seconds: 3);

  int _nextId = 1;
  String? _sessionId;
  String? _protocolVersion;
  McpProtocolEra? _protocolEra;
  McpServerInfo? _serverInfo;
  Map<String, dynamic>? _serverCapabilities;
  String? _serverInstructions;
  bool _initialized = false;
  Future<void>? _initializationFuture;

  String? get protocolVersion => _protocolVersion;
  McpProtocolEra? get protocolEra => _protocolEra;
  McpServerInfo? get serverInfo => _serverInfo;
  Map<String, dynamic>? get serverCapabilities => _serverCapabilities == null
      ? null
      : Map.unmodifiable(_serverCapabilities!);
  String? get serverInstructions => _serverInstructions;

  @override
  Future<List<McpTool>> initializeAndListTools() async {
    await _ensureInitialized();

    try {
      return await _withSessionRetry(_listAllTools);
    } on McpException catch (error) {
      if (error.code == _methodNotFoundCode &&
          _serverCapabilities != null &&
          !_serverCapabilities!.containsKey('tools')) {
        return const [];
      }
      rethrow;
    }
  }

  Future<List<McpTool>> _listAllTools() async {
    final tools = <McpTool>[];
    final seenCursors = <String>{};
    String? cursor;

    for (var page = 0; page < _maxToolListPages; page++) {
      final params = cursor == null
          ? const <String, dynamic>{}
          : <String, dynamic>{'cursor': cursor};
      final result = await _request('tools/list', params);
      final rawTools = result['tools'];
      if (rawTools is List) {
        for (final raw in rawTools) {
          if (raw is! Map) continue;
          final tool = _parseTool(raw.cast<String, dynamic>());
          if (tool != null) {
            tools.add(tool);
          }
        }
      }

      final nextCursor = result['nextCursor'];
      if (nextCursor is! String ||
          nextCursor.isEmpty ||
          !seenCursors.add(nextCursor)) {
        break;
      }
      cursor = nextCursor;
    }

    return tools;
  }

  McpTool? _parseTool(Map<String, dynamic> map) {
    final name = map['name']?.toString() ?? '';
    if (name.isEmpty) return null;

    final schema = map['inputSchema'] ?? map['input_schema'];
    final outputSchema = map['outputSchema'] ?? map['output_schema'];
    final annotations = map['annotations'];
    final title = map['title']?.toString();

    return McpTool(
      name: name,
      title: title != null && title.isNotEmpty ? title : null,
      description: map['description']?.toString() ?? '',
      inputSchema: schema is Map
          ? schema.cast<String, dynamic>()
          : const <String, dynamic>{},
      outputSchema: outputSchema is Map
          ? outputSchema.cast<String, dynamic>()
          : null,
      annotations: annotations is Map
          ? annotations.cast<String, dynamic>()
          : null,
    );
  }

  @override
  Future<AIToolResult> callTool(
    String name,
    Map<String, dynamic> arguments,
  ) async {
    await _ensureInitialized();

    final result = await _withSessionRetry(
      () => _request(
        'tools/call',
        {
          'name': name,
          'arguments': arguments,
        },
        targetName: name,
      ),
    );

    return AIToolResult(
      toolCallId: '',
      name: name,
      content: _formatToolCallResult(result),
      isError: result['isError'] == true,
    );
  }

  String _formatToolCallResult(Map<String, dynamic> result) {
    final parts = <String>[];
    final content = result['content'];
    if (content is List) {
      for (final item in content) {
        if (item is! Map) continue;
        final formatted = _formatContentBlock(item.cast<String, dynamic>());
        if (formatted != null && formatted.isNotEmpty) {
          parts.add(formatted);
        }
      }
    }

    final structured = result['structuredContent'];
    if (structured != null) {
      final structuredJson = jsonEncode(structured);
      if (parts.isEmpty) {
        return structuredJson;
      }
      final alreadyIncluded =
          parts.length == 1 && _isEquivalentJson(parts.first, structured);
      if (!alreadyIncluded) {
        parts.add('[structuredContent]\n$structuredJson');
      }
    }

    if (parts.isEmpty) {
      return jsonEncode(result);
    }
    return parts.join('\n');
  }

  String? _formatContentBlock(Map<String, dynamic> item) {
    final type = item['type']?.toString() ?? 'content';
    switch (type) {
      case 'text':
        final text = item['text'];
        return text is String ? text : null;

      case 'resource':
        final resource = item['resource'];
        if (resource is! Map) return '[resource]';
        final map = resource.cast<String, dynamic>();
        final uri = map['uri']?.toString() ?? '';
        final mimeType = map['mimeType']?.toString() ?? '';
        final header = _buildTaggedHeader('resource', uri, mimeType);
        final text = map['text'];
        if (text is String) {
          return text.isEmpty ? header : '$header\n$text';
        }
        final blob = map['blob'];
        if (blob is String) {
          return '$header (binary, ${blob.length} base64 chars)';
        }
        return header;

      case 'resource_link':
        final uri = item['uri']?.toString() ?? '';
        final title = item['title']?.toString();
        final name = item['name']?.toString();
        final label = (title != null && title.isNotEmpty)
            ? title
            : (name != null && name.isNotEmpty ? name : '');
        final mimeType = item['mimeType']?.toString() ?? '';
        final description = item['description']?.toString() ?? '';
        final buffer = StringBuffer('[resource_link]');
        if (label.isNotEmpty && uri.isNotEmpty) {
          buffer.write(' $label ($uri)');
        } else if (uri.isNotEmpty) {
          buffer.write(' $uri');
        } else if (label.isNotEmpty) {
          buffer.write(' $label');
        }
        if (mimeType.isNotEmpty) {
          buffer.write(' [$mimeType]');
        }
        if (description.isNotEmpty) {
          buffer.write(' - $description');
        }
        return buffer.toString();

      case 'image':
      case 'audio':
        final mimeType = item['mimeType']?.toString() ?? '';
        final data = item['data'];
        final details = <String>[
          if (mimeType.isNotEmpty) mimeType,
          if (data is String) '${data.length} base64 chars',
        ];
        return details.isEmpty ? '[$type]' : '[$type: ${details.join(', ')}]';

      default:
        return '[$type] ${jsonEncode(item)}';
    }
  }

  String _buildTaggedHeader(String tag, String uri, String mimeType) {
    if (uri.isEmpty && mimeType.isEmpty) return '[$tag]';
    if (uri.isNotEmpty && mimeType.isNotEmpty) {
      return '[$tag: $uri ($mimeType)]';
    }
    if (uri.isNotEmpty) return '[$tag: $uri]';
    return '[$tag ($mimeType)]';
  }

  bool _isEquivalentJson(String text, Object? structured) {
    final trimmed = text.trim();
    if (trimmed.isEmpty) return false;
    if (!trimmed.startsWith('{') && !trimmed.startsWith('[')) return false;
    try {
      final decoded = jsonDecode(trimmed);
      return jsonEncode(_canonicalizeJson(decoded)) ==
          jsonEncode(_canonicalizeJson(structured));
    } catch (_) {
      return false;
    }
  }

  Object? _canonicalizeJson(Object? value) {
    if (value is Map) {
      final keys = value.keys.map((k) => k.toString()).toList()..sort();
      return {
        for (final key in keys) key: _canonicalizeJson(value[key]),
      };
    }
    if (value is List) {
      return value.map(_canonicalizeJson).toList();
    }
    return value;
  }

  Future<void> _ensureInitialized() {
    if (_initialized) return Future.value();

    final pending = _initializationFuture;
    if (pending != null) return pending;

    final future = _initialize();
    _initializationFuture = future;
    return future.whenComplete(() {
      if (identical(_initializationFuture, future)) {
        _initializationFuture = null;
      }
    });
  }

  Future<void> _initialize() async {
    try {
      await _discoverStateless(latestProtocolVersion);
    } on McpException catch (error) {
      final fallbackVersion = _resolveFallbackVersion(error);
      if (fallbackVersion == null) rethrow;
      await _initializeStateful(requestedVersion: fallbackVersion);
    }
  }

  Future<void> _discoverStateless(String requestedVersion) async {
    final result = await _request(
      'server/discover',
      const {},
      statelessOverride: true,
      protocolVersionOverride: requestedVersion,
    );

    final serverVersions = _extractProtocolVersions(result);
    if (serverVersions.isNotEmpty &&
        !serverVersions.contains(requestedVersion)) {
      final statelessMatch = _pickBestVersion(
        serverVersions,
        supportedStatelessProtocolVersions,
      );
      if (statelessMatch != null) {
        _recordServerMetadata(result);
        _protocolEra = McpProtocolEra.stateless;
        _protocolVersion = statelessMatch;
        _initialized = true;
        return;
      }

      final statefulMatch = _pickBestVersion(
        serverVersions,
        supportedStatefulProtocolVersions,
      );
      if (statefulMatch != null) {
        await _initializeStateful(requestedVersion: statefulMatch);
        return;
      }

      throw McpException(
        'Unsupported MCP protocol version: ${serverVersions.join(', ')}',
      );
    }

    _recordServerMetadata(result);
    _protocolEra = McpProtocolEra.stateless;
    _protocolVersion = requestedVersion;
    _initialized = true;
  }

  Future<void> _initializeStateful({
    String requestedVersion = latestStatefulProtocolVersion,
  }) async {
    final result = await _request(
      'initialize',
      {
        'protocolVersion': requestedVersion,
        'capabilities': const <String, dynamic>{},
        'clientInfo': {
          'name': clientName,
          'version': clientVersion,
        },
      },
      captureSession: true,
      statelessOverride: false,
    );

    final negotiated = result['protocolVersion'];
    if (negotiated is String && negotiated.isNotEmpty) {
      if (!supportedProtocolVersions.contains(negotiated)) {
        throw McpException('Unsupported MCP protocol version: $negotiated');
      }
      _protocolVersion = negotiated;
    } else {
      _protocolVersion = requestedVersion;
    }

    _recordServerMetadata(result);
    _protocolEra = McpProtocolEra.stateful;

    await _notify('notifications/initialized');
    _initialized = true;
  }

  void _recordServerMetadata(Map<String, dynamic> result) {
    final rawInfo = result['serverInfo'];
    if (rawInfo is Map) {
      _serverInfo = McpServerInfo.fromJson(rawInfo.cast<String, dynamic>());
    }
    final rawCapabilities = result['capabilities'];
    if (rawCapabilities is Map) {
      _serverCapabilities = rawCapabilities.cast<String, dynamic>();
    }
    final instructions = result['instructions'];
    if (instructions is String && instructions.isNotEmpty) {
      _serverInstructions = instructions;
    }
  }

  List<String> _extractProtocolVersions(Map<String, dynamic> result) {
    final versions = <String>[];
    final list = result['protocolVersions'];
    if (list is List) {
      for (final item in list) {
        if (item is String && item.isNotEmpty) {
          versions.add(item);
        }
      }
    }
    if (versions.isEmpty) {
      final single = result['protocolVersion'];
      if (single is String && single.isNotEmpty) {
        versions.add(single);
      }
    }
    return versions;
  }

  String? _pickBestVersion(
    Iterable<String> offered,
    List<String> preferredOrder,
  ) {
    final offeredSet = offered.toSet();
    for (final version in preferredOrder) {
      if (offeredSet.contains(version)) {
        return version;
      }
    }
    return null;
  }

  /// Determines whether a failed `server/discover` probe should fall back to
  /// stateful `initialize`, and if so, which legacy version to request.
  String? _resolveFallbackVersion(McpException error) {
    if (error.code == _unsupportedProtocolVersionCode) {
      final data = error.data;
      if (data is Map && data['supported'] is List) {
        final supported = <String>[
          for (final item in data['supported'] as List)
            if (item is String && item.isNotEmpty) item,
        ];
        if (supported.isNotEmpty) {
          return _pickBestVersion(
            supported,
            supportedStatefulProtocolVersions,
          );
        }
      }
      return latestStatefulProtocolVersion;
    }

    final status = error.httpStatus;
    if (status == 401 || status == 403) return null;
    if (status != null && status >= 500) return null;

    final code = error.code;
    if (code == _methodNotFoundCode ||
        code == _invalidRequestCode ||
        code == _invalidParamsCode ||
        (code != null && code <= -32000 && code >= -32099)) {
      return latestStatefulProtocolVersion;
    }

    if (status == 400 ||
        status == 404 ||
        status == 405 ||
        status == 406 ||
        status == 422) {
      return latestStatefulProtocolVersion;
    }

    return null;
  }

  /// Retries once after a stateful server reports that the session has expired.
  Future<T> _withSessionRetry<T>(Future<T> Function() action) async {
    try {
      return await action();
    } on McpException catch (error) {
      final status = error.httpStatus ?? error.code;
      if (_protocolEra != McpProtocolEra.stateful || status != 404) {
        rethrow;
      }
      // 另一个并发请求可能已经在重建会话；此时不要再次清空它。
      if (_initializationFuture == null) {
        _resetState();
      }
      await _ensureInitialized();
      return action();
    }
  }

  void _resetState() {
    _initialized = false;
    _sessionId = null;
    _protocolVersion = null;
    _protocolEra = null;
    _serverInfo = null;
    _serverCapabilities = null;
    _serverInstructions = null;
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
      method: method,
      acceptEmpty: true,
    );
  }

  Future<Map<String, dynamic>> _request(
    String method,
    Map<String, dynamic> params, {
    String? targetName,
    bool captureSession = false,
    bool? statelessOverride,
    String? protocolVersionOverride,
  }) async {
    final isStateless =
        statelessOverride ?? (_protocolEra == McpProtocolEra.stateless);
    final effectiveVersion = protocolVersionOverride ?? _protocolVersion;
    final effectiveParams = isStateless
        ? _withStatelessMeta(
            params,
            effectiveVersion ?? latestProtocolVersion,
          )
        : params;

    final id = _nextId++;
    final response = await _post(
      {
        'jsonrpc': '2.0',
        'id': id,
        'method': method,
        'params': effectiveParams,
      },
      method: method,
      targetName: targetName,
      captureSession: captureSession,
      stateless: isStateless,
      protocolVersionOverride: protocolVersionOverride,
    );

    if (response is! Map) {
      throw const McpException('Invalid JSON-RPC response');
    }

    final map = response.cast<String, dynamic>();
    final error = map['error'];
    if (error != null) {
      throw _parseJsonRpcError(error);
    }

    final result = map['result'];
    return result is Map
        ? result.cast<String, dynamic>()
        : <String, dynamic>{};
  }

  Map<String, dynamic> _withStatelessMeta(
    Map<String, dynamic> params,
    String protocolVersion,
  ) {
    final existingMeta = params['_meta'];
    final meta = <String, dynamic>{
      if (existingMeta is Map) ...existingMeta.cast<String, dynamic>(),
      'io.modelcontextprotocol/protocolVersion': protocolVersion,
      'io.modelcontextprotocol/clientCapabilities': const <String, dynamic>{},
      'io.modelcontextprotocol/clientInfo': {
        'name': clientName,
        'version': clientVersion,
      },
    };
    return {
      ...params,
      '_meta': meta,
    };
  }

  McpException _parseJsonRpcError(Object error, {int? httpStatus}) {
    if (error is Map) {
      return McpException(
        error['message']?.toString() ?? 'JSON-RPC error',
        code: (error['code'] as num?)?.toInt() ?? httpStatus,
        httpStatus: httpStatus,
        data: error['data'],
      );
    }
    return McpException(
      error.toString(),
      code: httpStatus,
      httpStatus: httpStatus,
    );
  }

  Future<dynamic> _post(
    Map<String, dynamic> payload, {
    required String method,
    String? targetName,
    bool captureSession = false,
    bool acceptEmpty = false,
    bool stateless = false,
    String? protocolVersionOverride,
  }) async {
    final request = http.Request('POST', Uri.parse(config.url));
    request.headers.addAll(
      _buildHeaders(
        method: method,
        targetName: targetName,
        stateless: stateless,
        protocolVersionOverride: protocolVersionOverride,
      ),
    );
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
      throw _buildHttpError(response.statusCode, body);
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

  McpException _buildHttpError(int statusCode, String body) {
    final trimmed = body.trim();
    if (trimmed.startsWith('{')) {
      try {
        final decoded = jsonDecode(trimmed);
        if (decoded is Map && decoded['error'] != null) {
          return _parseJsonRpcError(
            decoded['error'] as Object,
            httpStatus: statusCode,
          );
        }
      } catch (_) {
        // Fall through to plain HTTP error formatting.
      }
    }
    return McpException(
      'HTTP $statusCode: $body',
      code: statusCode,
      httpStatus: statusCode,
    );
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

  Map<String, String> _buildHeaders({
    required String method,
    String? targetName,
    required bool stateless,
    String? protocolVersionOverride,
  }) {
    final headers = <String, String>{
      'Content-Type': 'application/json',
      'Accept': 'application/json, text/event-stream',
      ...config.headers,
    };
    final protocolVersion = protocolVersionOverride ?? _protocolVersion;
    if (protocolVersion != null && protocolVersion.isNotEmpty) {
      headers['MCP-Protocol-Version'] = protocolVersion;
    }
    if (stateless) {
      headers['Mcp-Method'] = method;
      if (targetName != null && targetName.isNotEmpty) {
        headers['Mcp-Name'] = targetName;
      }
    } else {
      final sessionId = _sessionId;
      if (sessionId != null && sessionId.isNotEmpty) {
        headers['mcp-session-id'] = sessionId;
      }
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

  Future<void> _terminateStatefulSession(
    String sessionId,
    String? protocolVersion,
  ) async {
    try {
      final request = http.Request('DELETE', Uri.parse(config.url));
      request.headers.addAll({
        ...config.headers,
        'mcp-session-id': sessionId,
        if (protocolVersion != null && protocolVersion.isNotEmpty)
          'MCP-Protocol-Version': protocolVersion,
      });
      final closeTimeout =
          timeout < _closeRequestTimeout ? timeout : _closeRequestTimeout;
      final response = await _client.send(request).timeout(closeTimeout);
      final subscription = response.stream.listen(null);
      await subscription.cancel();
    } catch (_) {
      // Session cleanup is best-effort and must never fail client close.
    }
  }

  @override
  Future<void> close() async {
    final shouldTerminate =
        _protocolEra == McpProtocolEra.stateful &&
        _sessionId != null &&
        _sessionId!.isNotEmpty;
    final sessionId = _sessionId;
    final protocolVersion = _protocolVersion;

    _resetState();
    _initializationFuture = null;

    if (shouldTerminate && sessionId != null) {
      await _terminateStatefulSession(sessionId, protocolVersion);
    }

    _client.close();
  }
}
