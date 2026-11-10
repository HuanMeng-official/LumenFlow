import 'dart:io';
import 'dart:async';
import 'dart:convert';

import 'package:flutter/services.dart';
import 'package:flutter/foundation.dart';

class HttpServerService {
  static const int _defaultPort = 5050;
  static const int _maxPort = 5059;
  static const String _htmlFilePath = 'assets/gen/generator.html';

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
      // 只处理根路径请求
      if (request.uri.path == '/' || request.uri.path == '/generator.html') {
        await _serveHtmlFile(request);
      } else {
        await _sendNotFound(request);
      }
    } catch (e) {
      await _sendError(request, e.toString());
    }
  }

  Future<void> _serveHtmlFile(HttpRequest request) async {
    try {
      // 从assets加载HTML文件
      final byteData = await rootBundle.load(_htmlFilePath);
      final htmlContent = utf8.decode(byteData.buffer.asUint8List());

      request.response
        ..statusCode = HttpStatus.ok
        ..headers.contentType = ContentType.html
        ..write(htmlContent);

      await request.response.close();
    } catch (e) {
      await _sendNotFound(request);
    }
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
