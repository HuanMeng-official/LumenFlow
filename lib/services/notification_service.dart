import 'dart:io';
import 'package:flutter/foundation.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';

/// 通知服务类
///
/// 负责处理应用的所有本地通知功能
/// 支持 Android、Windows、Linux 平台
class NotificationService {
  static final NotificationService _instance = NotificationService._internal();
  factory NotificationService() => _instance;
  NotificationService._internal();

  final FlutterLocalNotificationsPlugin _notificationsPlugin =
      FlutterLocalNotificationsPlugin();

  bool _isInitialized = false;

  /// 应用是否在前台
  bool _isAppInForeground = true;

  /// 设置应用前台状态
  ///
  /// [isInForeground] - 应用是否在前台
  void setAppForegroundState(bool isInForeground) {
    _isAppInForeground = isInForeground;
  }

  /// 初始化通知服务
  ///
  /// 配置通知插件并请求必要权限
  Future<void> initialize() async {
    if (_isInitialized) return;

    const initializationSettingsAndroid =
        AndroidInitializationSettings('@mipmap/ic_launcher');

    final initializationSettingsWindows = WindowsInitializationSettings(
      appName: 'LumenFlow',
      appUserModelId: 'com.lumenflow.app',
      guid: '550E8400-E29B-41D4-A716-446655440000',
    );

    final initializationSettingsLinux = LinuxInitializationSettings(
      defaultActionName: 'Open',
    );

    final initializationSettings = InitializationSettings(
      android: initializationSettingsAndroid,
      windows: initializationSettingsWindows,
      linux: initializationSettingsLinux,
    );

    await _notificationsPlugin.initialize(initializationSettings);

    // Android 上请求通知权限
    if (Platform.isAndroid) {
      final AndroidFlutterLocalNotificationsPlugin? androidImplementation =
          _notificationsPlugin
              .resolvePlatformSpecificImplementation<AndroidFlutterLocalNotificationsPlugin>();

      if (androidImplementation != null) {
        final bool? granted =
            await androidImplementation.requestNotificationsPermission();
        debugPrint('通知权限请求结果: $granted');
      }
    }

    _isInitialized = true;
    debugPrint('通知服务初始化成功');
  }

  /// 显示 AI 响应完成的通知
  ///
  /// [content] - AI 生成的消息内容预览
  /// [conversationTitle] - 对话标题（可选），用于显示为通知标题
  /// Shows a notification when AI response is completed
  Future<void> showAIResponseCompleted(
    String content, {
    String? conversationTitle,
  }) async {
    if (!_isInitialized) {
      debugPrint('通知服务未初始化');
      return;
    }

    // 如果应用在前台，则不显示通知
    if (_isAppInForeground) {
      debugPrint('应用在前台，跳过通知');
      return;
    }

    // 获取内容预览（最多 100 个字符）
    String preview = content.trim();
    if (preview.isEmpty) {
      preview = 'AI 回复已完成';
    } else if (preview.length > 100) {
      preview = '${preview.substring(0, 97)}...';
    }

    // 使用对话标题作为通知标题，如果未提供则使用默认标题
    final title = conversationTitle?.isNotEmpty == true
        ? conversationTitle!
        : 'LumenFlow';

    final androidDetails = AndroidNotificationDetails(
      'ai_response_channel',
      'AI Response',
      channelDescription: 'AI response completion notifications',
      importance: Importance.high,
      priority: Priority.high,
      showWhen: true,
      enableVibration: true,
      playSound: true,
      styleInformation: BigTextStyleInformation(
        preview,
        htmlFormatBigText: false,
        htmlFormatContent: false,
      ),
    );

    final windowsDetails = WindowsNotificationDetails();

    final linuxDetails = LinuxNotificationDetails();

    final notificationDetails = NotificationDetails(
      android: androidDetails,
      windows: windowsDetails,
      linux: linuxDetails,
    );

    await _notificationsPlugin.show(
      1, // 通知ID
      title, // 标题 - 使用对话标题
      preview, // 内容 - 使用预览内容
      notificationDetails,
      payload: content, // 点击时传递完整内容
    );

    debugPrint('已发送 AI 响应完成通知: $preview (标题: $title)');
  }

  /// 清除所有通知
  Future<void> cancelAll() async {
    await _notificationsPlugin.cancelAll();
    debugPrint('已清除所有通知');
  }

  /// 清除指定通知
  Future<void> cancel(int id) async {
    await _notificationsPlugin.cancel(id);
  }
}
