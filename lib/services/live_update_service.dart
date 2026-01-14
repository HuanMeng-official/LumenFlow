import 'dart:io';
import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';

/// Android 16 Live Update 服务
///
/// 用于展示实时进度更新的通知，支持：
/// - 实时显示 AI 输出内容
/// - 进度追踪和进度点
/// - 追踪图标
/// - 完成状态提示
class LiveUpdateService {
  static final LiveUpdateService _instance = LiveUpdateService._internal();
  factory LiveUpdateService() =>
      _instance;
  LiveUpdateService._internal();

  static const MethodChannel _channel = MethodChannel('me.huanmeng.lumenflow/live_update');

  bool _isInitialized = false;
  bool _isAvailable = false;

  /// 应用是否在前台
  bool _isAppInForeground = true;

  /// 设置应用前台状态
  ///
  /// [isInForeground] - 应用是否在前台
  void setAppForegroundState(bool isInForeground) {
    _isAppInForeground = isInForeground;
  }

  /// 初始化服务
  Future<void> initialize() async {
    if (_isInitialized) return;

    // 仅在Android平台检查Live Update可用性
    if (Platform.isAndroid) {
      try {
        _isAvailable = await _channel.invokeMethod<bool>('isLiveUpdateAvailable') ?? false;
        debugPrint('Android 16 Live Update 可用: $_isAvailable');
      } catch (e) {
        debugPrint('检查Live Update可用性失败: $e');
        _isAvailable = false;
      }
    } else {
      debugPrint('Live Update 仅支持 Android 16+');
      _isAvailable = false;
    }

    _isInitialized = true;
  }

  /// 检查Live Update是否可用
  bool get isAvailable =>
      _isAvailable;

  /// 启动 Live Update 通知
  ///
  /// [title] - 通知标题前缀，默认为 "LumenFlow"
  Future<bool> startLiveUpdate({String title = 'LumenFlow'}) async {
    if (!_isAvailable) {
      debugPrint('Live Update 不可用，当前平台或SDK版本不支持');
      return false;
    }

    // 如果应用在前台，则不显示 Live Update
    if (_isAppInForeground) {
      debugPrint('应用在前台，跳过 Live Update');
      return false;
    }

    try {
      await _channel.invokeMethod('startLiveUpdate', {'title': title});
      debugPrint('Live Update 通知已启动: $title');
      return true;
    } catch (e) {
      debugPrint('启动 Live Update 失败: $e');
      return false;
    }
  }

  /// 更新通知内容（实时显示 AI 输出）
  ///
  /// [content] - 要显示的输出内容
  Future<bool> updateContent(String content) async {
    if (!_isAvailable) {
      return false;
    }

    try {
      await _channel.invokeMethod('updateContent', {'content': content});
      return true;
    } catch (e) {
      debugPrint('更新 Live Update 内容失败: $e');
      return false;
    }
  }

  /// 标记 Live Update 为完成状态
  Future<bool> complete() async {
    if (!_isAvailable) {
      return false;
    }

    try {
      await _channel.invokeMethod('completeLiveUpdate');
      debugPrint('Live Update 已标记为完成');
      return true;
    } catch (e) {
      debugPrint('完成 Live Update 失败: $e');
      return false;
    }
  }

  /// 停止 Live Update 通知
  Future<bool> stopLiveUpdate() async {
    if (!_isAvailable) {
      return false;
    }

    try {
      await _channel.invokeMethod('stopLiveUpdate');
      debugPrint('Live Update 通知已停止');
      return true;
    } catch (e) {
      debugPrint('停止 Live Update 失败: $e');
      return false;
    }
  }
}
