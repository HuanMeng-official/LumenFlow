import 'dart:io';
import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';

/// Android 16 Live Update 服务
///
/// 用于展示实时进度更新的通知，支持：
/// - 进度追踪和进度点
/// - 追踪图标
/// - 倒计时功能
/// - 提升为持续通知
class LiveUpdateService {
  static final LiveUpdateService _instance = LiveUpdateService._internal();
  factory LiveUpdateService() => _instance;
  LiveUpdateService._internal();

  static const MethodChannel _channel = MethodChannel('me.huanmeng.lumenflow/live_update');

  bool _isInitialized = false;
  bool _isAvailable = false;

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
  bool get isAvailable => _isAvailable;

  /// 启动 Live Update 通知
  ///
  /// [title] - 通知标题前缀，默认为 "LumenFlow"
  Future<bool> startLiveUpdate({String title = 'LumenFlow'}) async {
    if (!_isAvailable) {
      debugPrint('Live Update 不可用，当前平台或SDK版本不支持');
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
