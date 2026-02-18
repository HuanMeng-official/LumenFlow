import 'dart:io';
import 'dart:async';
import 'dart:convert';
import 'package:flutter/services.dart';
import 'package:flutter/foundation.dart';

class HttpServerService {
  static const int _port = 5050;
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

  // 状态通知器，用于UI更新
  final ValueNotifier<bool> isRunningNotifier = ValueNotifier<bool>(false);
  final ValueNotifier<String?> serverUrlNotifier = ValueNotifier<String?>(null);

  Future<void> start() async {
    if (_isRunning) {
      debugPrint('HTTP服务器已经在运行');
      return;
    }

    try {
      // 创建HTTP服务器
      _server = await HttpServer.bind(InternetAddress.anyIPv4, _port);
      _isRunning = true;
      _serverUrl = 'http://localhost:$_port';

      // 更新通知器状态
      isRunningNotifier.value = true;
      serverUrlNotifier.value = _serverUrl;

      debugPrint('HTTP服务器启动在 $_serverUrl');
      debugPrint('服务文件: $_htmlFilePath');

      // 处理请求
      _server!.listen(_handleRequest);
    } catch (e) {
      debugPrint('启动HTTP服务器失败: $e');
      rethrow;
    }
  }

  Future<void> stop() async {
    if (_server != null) {
      await _server!.close();
      _server = null;
    }
    _isRunning = false;
    _serverUrl = null;

    // 更新通知器状态
    isRunningNotifier.value = false;
    serverUrlNotifier.value = null;

    debugPrint('HTTP服务器已停止');
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
      debugPrint('处理请求时出错: $e');
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
      debugPrint('已提供文件: $_htmlFilePath');
    } catch (e) {
      debugPrint('加载HTML文件失败: $e');
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
  int get port => _port;

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
