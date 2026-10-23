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

/// 构建全局 Cupertino 主题，为所有文本样式加上按语言选择的 CJK 回退。
///
/// 只设置 `DefaultTextStyle` 不够：`CupertinoListTile`、`CupertinoTextField`
/// 等组件会直接用主题里的 `textTheme` 样式覆盖环境样式，因此这里把
/// `CupertinoTextThemeData` 的每个命名样式都补上回退。
CupertinoThemeData buildAppTheme(Brightness brightness, Locale locale) {
  final fontFallback = cjkFontFallbackForLocale(locale);
  final baseTextTheme = CupertinoThemeData(brightness: brightness).textTheme;

  TextStyle withFallback(TextStyle style) {
    return style.copyWith(fontFamilyFallback: fontFallback);
  }

  return CupertinoThemeData(
    primaryColor: CupertinoColors.systemBlue,
    brightness: brightness,
    textTheme: CupertinoTextThemeData(
      primaryColor: CupertinoColors.systemBlue,
      textStyle: withFallback(baseTextTheme.textStyle),
      actionTextStyle: withFallback(baseTextTheme.actionTextStyle),
      actionSmallTextStyle: withFallback(baseTextTheme.actionSmallTextStyle),
      tabLabelTextStyle: withFallback(baseTextTheme.tabLabelTextStyle),
      navTitleTextStyle: withFallback(baseTextTheme.navTitleTextStyle),
      navLargeTitleTextStyle:
          withFallback(baseTextTheme.navLargeTitleTextStyle),
      navActionTextStyle: withFallback(baseTextTheme.navActionTextStyle),
      pickerTextStyle: withFallback(baseTextTheme.pickerTextStyle),
      dateTimePickerTextStyle:
          withFallback(baseTextTheme.dateTimePickerTextStyle),
    ),
  );
}
