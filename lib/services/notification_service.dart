import 'dart:io';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';

/// 通知服务类
///
/// 负责处理应用的所有本地通知功能
/// 支持 Android、iOS、macOS、Windows、Linux 平台
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

    // iOS / macOS 共用的 Darwin 配置。
    // 初始化时会向用户请求通知权限（首次启动会弹出系统授权框）。
    const initializationSettingsDarwin = DarwinInitializationSettings();

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
      iOS: initializationSettingsDarwin,
      macOS: initializationSettingsDarwin,
      windows: initializationSettingsWindows,
      linux: initializationSettingsLinux,
    );

    await _notificationsPlugin.initialize(settings: initializationSettings);

    // Android 上请求通知权限
    if (Platform.isAndroid) {
      final AndroidFlutterLocalNotificationsPlugin? androidImplementation =
          _notificationsPlugin
              .resolvePlatformSpecificImplementation<AndroidFlutterLocalNotificationsPlugin>();

      if (androidImplementation != null) {
        await androidImplementation.requestNotificationsPermission();
      }
    }

    _isInitialized = true;
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
      return;
    }

    // 如果应用在前台，则不显示通知
    if (_isAppInForeground) {
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

    final darwinDetails = DarwinNotificationDetails(
      presentAlert: true,
      presentSound: true,
      presentBanner: true,
    );

    final windowsDetails = WindowsNotificationDetails();

    final linuxDetails = LinuxNotificationDetails();

    final notificationDetails = NotificationDetails(
      android: androidDetails,
      iOS: darwinDetails,
      macOS: darwinDetails,
      windows: windowsDetails,
      linux: linuxDetails,
    );

    await _notificationsPlugin.show(
      id: 1, // 通知ID
      title: title, // 标题 - 使用对话标题
      body: preview, // 内容 - 使用预览内容
      notificationDetails: notificationDetails,
      payload: content, // 点击时传递完整内容
    );

  }

  /// 清除所有通知
  Future<void> cancelAll() async {
    await _notificationsPlugin.cancelAll();
  }

  /// 清除指定通知
  Future<void> cancel(int id) async {
    await _notificationsPlugin.cancel(id: id);
  }
}
