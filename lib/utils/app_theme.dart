import 'package:flutter/cupertino.dart';

/// 全局主题亮度通知器
final ValueNotifier<Brightness> appBrightness = ValueNotifier(Brightness.light);

/// 按当前语言选择 CJK 字体回退。
///
/// Windows 的默认字体不包含中文时，系统可能按字形选择日文字体，
/// 导致部分中文标题看起来更粗或字形不同。显式指定语言对应的字体，
/// 可以让同一组文本使用一致的字体。
List<String> cjkFontFallbackForLocale(Locale? locale) {
  switch (locale?.languageCode) {
    case 'ja':
      return const [
        'Yu Gothic UI',
        'Yu Gothic',
        'Hiragino Sans',
        'Noto Sans CJK JP',
        'Noto Sans JP',
      ];
    case 'ko':
      return const [
        'Malgun Gothic',
        'Apple SD Gothic Neo',
        'Noto Sans CJK KR',
        'Noto Sans KR',
      ];
    case 'zh':
    case 'lzh':
      return const [
        'Microsoft YaHei UI',
        'Microsoft YaHei',
        'PingFang SC',
        'Noto Sans CJK SC',
        'Noto Sans SC',
      ];
    default:
      return const [];
  }
}
