import 'package:flutter/cupertino.dart';
import 'services/settings_service.dart';
import 'screens/chat_screen.dart';
import 'utils/app_theme.dart';

void main() async {
  // 初始化主题
  final settingsService = SettingsService();
  try {
    final bool darkMode = await settingsService.getDarkMode();
    appBrightness.value = darkMode ? Brightness.dark : Brightness.light;
  } catch (e) {
    // 使用默认亮色模式
  }

  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return ValueListenableBuilder<Brightness>(
      valueListenable: appBrightness,
      builder: (context, brightness, child) {
        return CupertinoApp(
          title: '流光',
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
