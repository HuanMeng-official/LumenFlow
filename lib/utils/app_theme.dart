import 'package:cupertino_ui/cupertino_ui.dart';
import 'package:material_ui/material_ui.dart' as material;

/// 全局主题亮度通知器
final ValueNotifier<Brightness> appBrightness = ValueNotifier(Brightness.light);

/// 随包携带的默认字体，保证各平台中文都使用一致的字形。
const String appFontFamily = 'NotoSansSC';

/// 日文/韩文仍优先使用系统本地字体，避免用中文汉字字形渲染日文汉字。
String? appFontFamilyForLocale(Locale? locale) {
  switch (locale?.languageCode) {
    case 'ja':
    case 'ko':
      return null;
    default:
      return appFontFamily;
  }
}

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
/// 全局 Design Tokens（对齐原生 Apple Cupertino HIG 规范）
abstract final class AppTokens {
  static bool isDark(BuildContext context) =>
      CupertinoTheme.of(context).brightness == Brightness.dark;

  /// 主阅读/对话画布背景
  static Color bg(BuildContext context) =>
      isDark(context) ? const Color(0xFF141416) : const Color(0xFFFFFFFF);

  /// 设置与检视分组底层背景（iOS/macOS systemGroupedBackground）
  static Color groupedBg(BuildContext context) =>
      isDark(context) ? const Color(0xFF0A0A0C) : const Color(0xFFF2F2F7);

  /// 桌面端侧栏与输入框底色
  static Color sidebarBg(BuildContext context) =>
      isDark(context) ? const Color(0xFF1C1C1E) : const Color(0xFFF5F5F7);

  /// 分组卡片 / 弹出浮层表面
  static Color elevatedSurface(BuildContext context) =>
      isDark(context) ? const Color(0xFF1C1C1E) : const Color(0xFFFFFFFF);

  /// 次级填充（搜索框、分段底层）
  static Color fill(BuildContext context) => isDark(context)
      ? const Color(0x38787880)
      : const Color(0x1C767680);

  /// 极轻悬浮 / 内嵌输入框底色
  static Color fillSoft(BuildContext context) => isDark(context)
      ? const Color(0x24787880)
      : const Color(0x0F767680);

  /// 侧栏列表选中态高亮
  static Color rowActive(BuildContext context) =>
      accent(context).withValues(alpha: isDark(context) ? 0.20 : 0.12);

  /// 0.5px 细分隔线
  static Color separator(BuildContext context) => isDark(context)
      ? const Color(0x6B545458)
      : const Color(0x263C3C43);

  /// 主文本 / 次文本 / 弱文本
  static Color label(BuildContext context) =>
      isDark(context) ? const Color(0xFFFFFFFF) : const Color(0xFF000000);

  static Color labelSecondary(BuildContext context) => isDark(context)
      ? const Color(0xA6EBEBF5)
      : const Color(0xA63C3C43);

  static Color labelTertiary(BuildContext context) => isDark(context)
      ? const Color(0x61EBEBF5)
      : const Color(0x663C3C43);

  /// 主强调色与功能色
  static Color accent(BuildContext context) =>
      isDark(context) ? const Color(0xFF0A84FF) : const Color(0xFF007AFF);

  static Color accentSoft(BuildContext context) =>
      accent(context).withValues(alpha: isDark(context) ? 0.18 : 0.11);

  static Color green(BuildContext context) =>
      isDark(context) ? const Color(0xFF30D158) : const Color(0xFF34C759);

  static Color red(BuildContext context) =>
      isDark(context) ? const Color(0xFFFF453A) : const Color(0xFFFF3B30);

  // 4px 间距比例尺
  static const double space4 = 4;
  static const double space8 = 8;
  static const double space12 = 12;
  static const double space16 = 16;
  static const double space20 = 20;
  static const double space24 = 24;

  // 圆角体系
  static const double radiusSm = 8;
  static const double radiusMd = 12;
  static const double radiusLg = 16;
  static const double radiusBubble = 20;
  static const double radiusComposer = 22;

  // 对话阅读最大行宽
  static const double chatMaxWidth = 760;
}

CupertinoThemeData buildAppTheme(Brightness brightness, Locale locale) {
  final fontFamily = appFontFamilyForLocale(locale);
  final fontFallback = cjkFontFallbackForLocale(locale);
  final baseTextTheme = CupertinoThemeData(brightness: brightness).textTheme;
  final isDark = brightness == Brightness.dark;
  final primary = isDark ? const Color(0xFF0A84FF) : const Color(0xFF007AFF);

  TextStyle withFallback(TextStyle style) {
    return style.copyWith(
      fontFamily: fontFamily ?? style.fontFamily,
      fontFamilyFallback: fontFallback,
    );
  }

  return CupertinoThemeData(
    primaryColor: primary,
    brightness: brightness,
    scaffoldBackgroundColor:
        isDark ? const Color(0xFF141416) : CupertinoColors.white,
    barBackgroundColor:
        isDark ? const Color(0xFF1C1C1E) : const Color(0xFFF5F5F7),
    textTheme: CupertinoTextThemeData(
      primaryColor: primary,
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

/// Material 组件（如 TextField、Tooltip）默认不读 Cupertino 主题，
/// 这里给它们注入同一套字体，避免混用系统默认字体。
material.ThemeData buildMaterialAppTheme(
  Brightness brightness,
  Locale locale,
) {
  return material.ThemeData(
    brightness: brightness,
    fontFamily: appFontFamilyForLocale(locale),
    fontFamilyFallback: cjkFontFallbackForLocale(locale),
  );
}
