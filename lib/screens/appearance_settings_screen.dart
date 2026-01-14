import 'package:flutter/cupertino.dart';
import '../l10n/app_localizations.dart';
import '../services/settings_service.dart';
import '../utils/app_theme.dart';
import '../widgets/settings/settings_section.dart';
import '../widgets/settings/settings_switch_tile.dart';

/// 外观设置页面
///
/// 管理外观相关配置：
/// - 跟随系统主题
/// - 应用主题颜色
/// - 界面语言
///
/// 设置更改实时保存，无需手动点击保存按钮
/// 注意：更改语言后需要重启应用才能生效
class AppearanceSettingsScreen extends StatefulWidget {
  const AppearanceSettingsScreen({super.key});

  @override
  State<AppearanceSettingsScreen> createState() =>
      _AppearanceSettingsScreenState();
}

class _AppearanceSettingsScreenState extends State<AppearanceSettingsScreen>
    with WidgetsBindingObserver {
  final SettingsService _settingsService = SettingsService();
  bool _isLoading = true;
  bool _followSystemTheme = SettingsService.defaultFollowSystemTheme;
  String _appTheme = SettingsService.defaultAppTheme;
  String _locale = SettingsService.defaultLocale;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    _loadSettings();
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    super.dispose();
  }

  @override
  void didChangePlatformBrightness() {
    if (_followSystemTheme) {
      setState(() {});
      _updateAppBrightness();
    }
    super.didChangePlatformBrightness();
  }

  Future<void> _loadSettings() async {
    final followSystemTheme = await _settingsService.getFollowSystemTheme();
    final appTheme = await _settingsService.getAppTheme();
    final locale = await _settingsService.getLocale();

    setState(() {
      _followSystemTheme = followSystemTheme;
      _appTheme = appTheme;
      _locale = locale;
      _isLoading = false;
    });
  }

  /// 实时保存跟随系统主题设置
  Future<void> _onFollowSystemThemeChanged(bool value) async {
    setState(() {
      _followSystemTheme = value;
    });
    await _settingsService.setFollowSystemTheme(value);
    _updateAppBrightness();
  }

  /// 实时保存应用主题设置
  Future<void> _onAppThemeChanged(String? newValue) async {
    if (newValue == null) return;

    setState(() {
      _appTheme = newValue;
    });
    await _settingsService.setAppTheme(newValue);
    _updateAppBrightness();
  }

  /// 实时保存语言设置
  Future<void> _onLocaleChanged(String? newValue) async {
    if (newValue == null || newValue == _locale) return;

    setState(() {
      _locale = newValue;
    });
    await _settingsService.setLocale(newValue);

    // 语言更改需要重启应用才能生效
    _showRestartDialog();
  }

  void _updateAppBrightness() {
    Brightness brightness;
    if (_followSystemTheme) {
      brightness = MediaQuery.of(context).platformBrightness;
    } else {
      brightness = _appTheme == 'dark' ? Brightness.dark : Brightness.light;
    }
    appBrightness.value = brightness;
  }

  void _showRestartDialog() {
    final l10n = AppLocalizations.of(context)!;
    showCupertinoDialog(
      context: context,
      builder: (context) => CupertinoAlertDialog(
        title: Text(l10n.languageChanged),
        content: Text(l10n.restartAppToApplyLanguage),
        actions: [
          CupertinoDialogAction(
            child: Text(l10n.ok),
            onPressed: () => Navigator.pop(context),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;

    if (_isLoading) {
      return CupertinoPageScaffold(
        navigationBar: CupertinoNavigationBar(
          middle: Text(l10n.appearance),
        ),
        child: const Center(child: CupertinoActivityIndicator()),
      );
    }

    return CupertinoPageScaffold(
      navigationBar: CupertinoNavigationBar(
        middle: Text(l10n.appearance),
      ),
      child: SafeArea(
        child: ListView(
          children: [
            SettingsSection(
              title: l10n.appearance,
              children: [
                SettingsSwitchTile(
                  title: l10n.followSystem,
                  value: _followSystemTheme,
                  subtitle: l10n.followSystemDesc,
                  onChanged: _onFollowSystemThemeChanged,
                ),
                _ThemeDropdownTile(
                  title: l10n.appColor,
                  value: _followSystemTheme
                      ? (MediaQuery.of(context).platformBrightness ==
                              Brightness.dark
                          ? 'dark'
                          : 'light')
                      : _appTheme,
                  followSystemTheme: _followSystemTheme,
                  systemBrightness: MediaQuery.of(context).platformBrightness,
                  subtitle: _followSystemTheme
                      ? l10n.followSystemSetting(
                          MediaQuery.of(context).platformBrightness ==
                                  Brightness.dark
                              ? l10n.darkMode
                              : l10n.lightMode)
                      : l10n.selectColorMode,
                  onChanged: _followSystemTheme
                      ? null
                      : _onAppThemeChanged,
                ),
              ],
            ),
            SettingsSection(
              title: l10n.language,
              children: [
                _LanguageDropdownTile(
                  title: l10n.interfaceLanguage,
                  value: _locale,
                  subtitle: l10n.selectInterfaceLanguage,
                  onChanged: _onLocaleChanged,
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

/// 主题下拉选择组件（内部）
class _ThemeDropdownTile extends StatelessWidget {
  final String title;
  final String value;
  final bool followSystemTheme;
  final Brightness systemBrightness;
  final String? subtitle;
  final ValueChanged<String?>? onChanged;

  const _ThemeDropdownTile({
    required this.title,
    required this.value,
    required this.followSystemTheme,
    required this.systemBrightness,
    this.subtitle,
    this.onChanged,
  });

  @override
  Widget build(BuildContext context) {
    final brightness = CupertinoTheme.of(context).brightness;
    final isEnabled = onChanged != null;
    final l10n = AppLocalizations.of(context)!;

    final options = {
      'light': l10n.lightMode,
      'dark': l10n.darkMode,
    };

    final currentLabel = options[value] ?? value;

    return Container(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            title,
            style: const TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.w500,
            ),
          ),
          if (subtitle != null) ...[
            const SizedBox(height: 4),
            Text(
              subtitle!,
              style: TextStyle(
                fontSize: 13,
                color: brightness == Brightness.dark
                    ? CupertinoColors.systemGrey.darkColor
                    : CupertinoColors.systemGrey,
              ),
            ),
          ],
          const SizedBox(height: 12),
          CupertinoButton(
            padding: EdgeInsets.zero,
            onPressed: onChanged != null
                ? () {
                    showCupertinoModalPopup<void>(
                      context: context,
                      builder: (BuildContext context) {
                        final popupBrightness =
                            CupertinoTheme.of(context).brightness;
                        return CupertinoActionSheet(
                          title: Text(title),
                          message: subtitle != null ? Text(subtitle!) : null,
                          actions: [
                            for (final entry in options.entries)
                              CupertinoActionSheetAction(
                                onPressed: () {
                                  Navigator.pop(context);
                                  if (onChanged != null) {
                                    onChanged!(entry.key);
                                  }
                                },
                                child: Text(
                                  entry.value,
                                  style: TextStyle(
                                    color: value == entry.key
                                        ? (popupBrightness == Brightness.dark
                                            ? CupertinoColors.activeBlue.darkColor
                                            : CupertinoColors.activeBlue.color)
                                        : (popupBrightness == Brightness.dark
                                            ? CupertinoColors.label.darkColor
                                            : CupertinoColors.label.color),
                                  ),
                                ),
                              ),
                          ],
                          cancelButton: CupertinoActionSheetAction(
                            onPressed: () {
                              Navigator.pop(context);
                            },
                            child: Text(
                              l10n.cancel,
                              style: TextStyle(
                                color: popupBrightness == Brightness.dark
                                    ? CupertinoColors.systemRed.darkColor
                                    : CupertinoColors.systemRed.color,
                              ),
                            ),
                          ),
                        );
                      },
                    );
                  }
                : null,
            child: Container(
              width: double.infinity,
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
              decoration: BoxDecoration(
                color: isEnabled
                    ? (CupertinoTheme.of(context).brightness == Brightness.dark
                        ? CupertinoColors.systemGrey6.darkColor
                        : CupertinoColors.systemGrey6.color)
                    : (CupertinoTheme.of(context).brightness == Brightness.dark
                        ? CupertinoColors.tertiarySystemFill.darkColor
                        : CupertinoColors.tertiarySystemFill.color),
                borderRadius: BorderRadius.circular(8),
              ),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    currentLabel,
                    style: TextStyle(
                      fontSize: 16,
                      color: isEnabled
                          ? (brightness == Brightness.dark
                              ? CupertinoColors.label.darkColor
                              : CupertinoColors.label.color)
                          : (brightness == Brightness.dark
                              ? CupertinoColors.tertiaryLabel.darkColor
                              : CupertinoColors.tertiaryLabel.color),
                    ),
                  ),
                  Icon(
                    CupertinoIcons.chevron_down,
                    size: 18,
                    color: isEnabled
                        ? (brightness == Brightness.dark
                            ? CupertinoColors.systemGrey.darkColor
                            : CupertinoColors.systemGrey)
                        : (brightness == Brightness.dark
                            ? CupertinoColors.tertiaryLabel.darkColor
                            : CupertinoColors.tertiaryLabel.color),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}

/// 语言下拉选择组件（内部）
class _LanguageDropdownTile extends StatelessWidget {
  final String title;
  final String value;
  final String? subtitle;
  final ValueChanged<String?>? onChanged;

  const _LanguageDropdownTile({
    required this.title,
    required this.value,
    this.subtitle,
    this.onChanged,
  });

  @override
  Widget build(BuildContext context) {
    final brightness = CupertinoTheme.of(context).brightness;
    final isEnabled = onChanged != null;
    final l10n = AppLocalizations.of(context)!;

    final options = {
      'zh': '简体中文',
      'en': 'English',
      'ja': '日本語',
      'ko': '한국어',
    };

    final currentLabel = options[value] ?? value;

    return Container(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            title,
            style: const TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.w500,
            ),
          ),
          if (subtitle != null) ...[
            const SizedBox(height: 4),
            Text(
              subtitle!,
              style: TextStyle(
                fontSize: 13,
                color: brightness == Brightness.dark
                    ? CupertinoColors.systemGrey.darkColor
                    : CupertinoColors.systemGrey,
              ),
            ),
          ],
          const SizedBox(height: 12),
          CupertinoButton(
            padding: EdgeInsets.zero,
            onPressed: onChanged != null
                ? () {
                    showCupertinoModalPopup<void>(
                      context: context,
                      builder: (BuildContext context) {
                        final popupBrightness =
                            CupertinoTheme.of(context).brightness;
                        return CupertinoActionSheet(
                          title: Text(title),
                          message: subtitle != null ? Text(subtitle!) : null,
                          actions: [
                            for (final entry in options.entries)
                              CupertinoActionSheetAction(
                                onPressed: () {
                                  Navigator.pop(context);
                                  if (onChanged != null) {
                                    onChanged!(entry.key);
                                  }
                                },
                                child: Text(
                                  entry.value,
                                  style: TextStyle(
                                    color: value == entry.key
                                        ? (popupBrightness == Brightness.dark
                                            ? CupertinoColors.activeBlue.darkColor
                                            : CupertinoColors.activeBlue.color)
                                        : (popupBrightness == Brightness.dark
                                            ? CupertinoColors.label.darkColor
                                            : CupertinoColors.label.color),
                                  ),
                                ),
                              ),
                          ],
                          cancelButton: CupertinoActionSheetAction(
                            onPressed: () {
                              Navigator.pop(context);
                            },
                            child: Text(
                              l10n.cancel,
                              style: TextStyle(
                                color: popupBrightness == Brightness.dark
                                    ? CupertinoColors.systemRed.darkColor
                                    : CupertinoColors.systemRed.color,
                              ),
                            ),
                          ),
                        );
                      },
                    );
                  }
                : null,
            child: Container(
              width: double.infinity,
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
              decoration: BoxDecoration(
                color: isEnabled
                    ? (CupertinoTheme.of(context).brightness == Brightness.dark
                        ? CupertinoColors.systemGrey6.darkColor
                        : CupertinoColors.systemGrey6.color)
                    : (CupertinoTheme.of(context).brightness == Brightness.dark
                        ? CupertinoColors.tertiarySystemFill.darkColor
                        : CupertinoColors.tertiarySystemFill.color),
                borderRadius: BorderRadius.circular(8),
              ),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    currentLabel,
                    style: TextStyle(
                      fontSize: 16,
                      color: isEnabled
                          ? (brightness == Brightness.dark
                              ? CupertinoColors.label.darkColor
                              : CupertinoColors.label.color)
                          : (brightness == Brightness.dark
                              ? CupertinoColors.tertiaryLabel.darkColor
                              : CupertinoColors.tertiaryLabel.color),
                    ),
                  ),
                  Icon(
                    CupertinoIcons.chevron_down,
                    size: 18,
                    color: isEnabled
                        ? (brightness == Brightness.dark
                            ? CupertinoColors.systemGrey.darkColor
                            : CupertinoColors.systemGrey)
                        : (brightness == Brightness.dark
                            ? CupertinoColors.tertiaryLabel.darkColor
                            : CupertinoColors.tertiaryLabel.color),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}
