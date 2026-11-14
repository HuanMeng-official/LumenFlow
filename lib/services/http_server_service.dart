import 'dart:io';
import 'dart:async';

import 'package:flutter/services.dart';
import 'package:flutter/foundation.dart';
import 'package:path/path.dart' as path;

class HttpServerService {
  static const int _defaultPort = 5050;
  static const int _maxPort = 5059;
  static const String _indexPath = 'assets/gen/index.html';

  static const Set<String> _allowedExtensions = {
    '.html',
    '.css',
    '.js',
    '.png',
    '.svg',
    '.woff2',
    '.json',
  };

  @visibleForTesting
  static String? resolveGenAssetPath(String requestPath) {
    if (!requestPath.startsWith('/')) return null;
    if (requestPath.contains('\\') || requestPath.contains('%')) {
      return null;
    }
    if (requestPath == '/') return _indexPath;

    final relative = requestPath.substring(1);
    final segments = relative.split('/');
    for (final segment in segments) {
      if (segment.isEmpty ||
          segment == '.' ||
          segment == '..' ||
          segment.contains(':')) {
        return null;
      }
    }

    final extension = path.posix.extension(relative).toLowerCase();
    if (!_allowedExtensions.contains(extension)) {
      return null;
    }
    return 'assets/gen/$relative';
  }

  @visibleForTesting
  static ContentType contentTypeForGenAsset(String assetPath) {
    switch (path.posix.extension(assetPath).toLowerCase()) {
      case '.html':
        return ContentType.html;
      case '.css':
        return ContentType('text', 'css', charset: 'utf-8');
      case '.js':
        return ContentType('application', 'javascript', charset: 'utf-8');
      case '.png':
        return ContentType('image', 'png');
      case '.svg':
        return ContentType('image', 'svg+xml', charset: 'utf-8');
      case '.woff2':
        return ContentType('font', 'woff2');
      case '.json':
        return ContentType.json;
      default:
        return ContentType.binary;
    }
  }

  // 单例实例
  static HttpServerService? _instance;

  // 工厂构造函数返回单例
  factory HttpServerService() {
    _instance ??= HttpServerService._internal();
    return _instance!;
  }

  // 私有构造函数
  HttpServerService._internal();

  HttpServer? _server;
  bool _isRunning = false;
  String? _serverUrl;
  int? _activePort;

  // 状态通知器，用于UI更新
  final ValueNotifier<bool> isRunningNotifier = ValueNotifier<bool>(false);
  final ValueNotifier<String?> serverUrlNotifier = ValueNotifier<String?>(null);

  Future<void> start() async {
    if (_isRunning) {
      return;
    }

    Object? lastError;
    for (var candidate = _defaultPort; candidate <= _maxPort; candidate++) {
      try {
        final server = await HttpServer.bind(
          InternetAddress.loopbackIPv4,
          candidate,
        );
        _server = server;
        _activePort = candidate;
        _isRunning = true;
        _serverUrl = 'http://127.0.0.1:$candidate';

        // 更新通知器状态
        isRunningNotifier.value = true;
        serverUrlNotifier.value = _serverUrl;

        // 处理请求
        server.listen(_handleRequest);
        return;
      } catch (e) {
        lastError = e;
      }
    }

    throw StateError('无法在 $_defaultPort-$_maxPort 范围内启动生成器服务: $lastError');
  }

  Future<void> stop() async {
    if (_server != null) {
      await _server!.close();
      _server = null;
    }
    _isRunning = false;
    _serverUrl = null;
    _activePort = null;

    // 更新通知器状态
    isRunningNotifier.value = false;
    serverUrlNotifier.value = null;
  }

  Future<void> _handleRequest(HttpRequest request) async {
    try {
      final assetPath = resolveGenAssetPath(request.uri.path);
      if (assetPath == null) {
        await _sendNotFound(request);
        return;
      }
      await _serveGenAsset(request, assetPath);
    } catch (e) {
      await _sendError(request, e.toString());
    }
  }

  Future<void> _serveGenAsset(HttpRequest request, String assetPath) async {
    ByteData byteData;
    try {
      byteData = await rootBundle.load(assetPath);
    } catch (_) {
      await _sendNotFound(request);
      return;
    }

    final bytes = byteData.buffer.asUint8List(
      byteData.offsetInBytes,
      byteData.lengthInBytes,
    );
    request.response
      ..statusCode = HttpStatus.ok
      ..headers.contentType = contentTypeForGenAsset(assetPath)
      ..add(bytes);

    await request.response.close();
  }

  Future<void> _sendNotFound(HttpRequest request) async {
    request.response
      ..statusCode = HttpStatus.notFound
      ..headers.contentType = ContentType.html
      ..write('''
        <!DOCTYPE html>
        <html>
        <head><title>404 Not Found</title></head>
        <body>
          <h1>404 Not Found</h1>
        </body>
        </html>
      ''');
    await request.response.close();
  }

  Future<void> _sendError(HttpRequest request, String error) async {
    request.response
      ..statusCode = HttpStatus.internalServerError
      ..headers.contentType = ContentType.html
      ..write('''
        <!DOCTYPE html>
        <html>
        <head><title>500 Internal Server Error</title></head>
        <body>
          <h1>500 Internal Server Error</h1>
          <p>Error: $error</p>
        </body>
        </html>
      ''');
    await request.response.close();
  }

  bool get isRunning => _isRunning;
  String? get serverUrl => _serverUrl;
  int get port => _activePort ?? _defaultPort;

  /// 切换服务器状态
  Future<void> toggle() async {
    if (_isRunning) {
      await stop();
    } else {
      await start();
    }
  }

  void dispose() {
    stop();
    isRunningNotifier.dispose();
    serverUrlNotifier.dispose();
  }
}
