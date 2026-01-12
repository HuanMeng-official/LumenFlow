import 'package:flutter/cupertino.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'l10n/app_localizations.dart';
import 'services/settings_service.dart';
import 'services/notification_service.dart';
import 'services/live_update_service.dart';
import 'screens/chat_screen.dart';
import 'utils/app_theme.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  // 初始化通知服务
  final notificationService = NotificationService();
  await notificationService.initialize();

  // 初始化Live Update服务
  final liveUpdateService = LiveUpdateService();
  await liveUpdateService.initialize();

  final settingsService = SettingsService();
  try {
    final bool followSystemTheme = await settingsService.getFollowSystemTheme();
    if (followSystemTheme) {
      final systemBrightness =
          WidgetsBinding.instance.platformDispatcher.platformBrightness;
      appBrightness.value = systemBrightness;
    } else {
      final String appTheme = await settingsService.getAppTheme();
      appBrightness.value =
          appTheme == 'dark' ? Brightness.dark : Brightness.light;
    }
  } catch (e) {
    // 使用默认亮色模式
  }

  runApp(const MyApp());
}

class MyApp extends StatefulWidget {
  const MyApp({super.key});

  @override
  State<MyApp> createState() => _MyAppState();
}

class _MyAppState extends State<MyApp> with WidgetsBindingObserver {
  final SettingsService _settingsService = SettingsService();
  Locale _locale = const Locale('zh');

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    _updateAppThemeFromSystem();
    _loadLocale();
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    super.dispose();
  }

  @override
  void didChangePlatformBrightness() {
    _updateAppThemeFromSystem();
    super.didChangePlatformBrightness();
  }

  Future<void> _updateAppThemeFromSystem() async {
    try {
      final bool followSystemTheme =
          await _settingsService.getFollowSystemTheme();
      if (followSystemTheme) {
        final systemBrightness =
            WidgetsBinding.instance.platformDispatcher.platformBrightness;
        appBrightness.value = systemBrightness;
      }
    } catch (e) {
      // 忽略错误
    }
  }

  Future<void> _loadLocale() async {
    final localeCode = await _settingsService.getLocale();
    setState(() {
      _locale = Locale(localeCode);
    });
  }

  @override
  Widget build(BuildContext context) {
    return ValueListenableBuilder<Brightness>(
      valueListenable: appBrightness,
      builder: (context, brightness, child) {
        return CupertinoApp(
          title: '流光',
          localizationsDelegates: const [
            AppLocalizations.delegate,
            GlobalMaterialLocalizations.delegate,
            GlobalWidgetsLocalizations.delegate,
            GlobalCupertinoLocalizations.delegate,
          ],
          supportedLocales: const [
            Locale('en'),
            Locale('ja'),
            Locale('ko'),
            Locale('zh'),
          ],
          locale: _locale,
          theme: CupertinoThemeData(
            primaryColor: CupertinoColors.systemBlue,
            brightness: brightness,
          ),
          home: child!,
          debugShowCheckedModeBanner: false,
        );
      },
      child: ChatScreen(),
    );
  }
}
