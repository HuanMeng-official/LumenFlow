import 'dart:io';
import 'package:cupertino_ui/cupertino_ui.dart';
import 'package:image_picker/image_picker.dart';
import '../l10n/app_localizations.dart';
import '../services/settings_service.dart';
import '../utils/app_theme.dart';
import '../utils/path_utils.dart';
import '../utils/platform_utils.dart';
import '../widgets/desktop/desktop_popover.dart';
import '../widgets/settings/settings_section.dart';
import '../widgets/settings/settings_page_scaffold.dart';
import '../widgets/settings/settings_switch_tile.dart';
import '../widgets/settings/settings_action_tile.dart';
import '../widgets/settings/settings_slider_tile.dart';

/// 外观设置页面
///
/// 管理外观相关配置：
/// - 跟随系统主题
/// - 应用主题颜色（浅色 / 深色分段控件）
/// - 界面语言
/// - 聊天背景图片与透明度
class AppearanceSettingsScreen extends StatefulWidget {
  final bool embedded;
  final String? previousPageTitle;

  const AppearanceSettingsScreen({
    super.key,
    this.embedded = false,
    this.previousPageTitle,
  });

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
  // 聊天背景设置
  String _backgroundImagePath = SettingsService.defaultBackgroundImagePath;
  double _backgroundImageOpacity = SettingsService.defaultBackgroundImageOpacity;

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
    final backgroundImagePath = await _settingsService.getBackgroundImagePath();
    final backgroundImageOpacity = await _settingsService.getBackgroundImageOpacity();

    if (!mounted) return;
    setState(() {
      _followSystemTheme = followSystemTheme;
      _appTheme = appTheme;
      _locale = locale;
      _backgroundImagePath = backgroundImagePath;
      _backgroundImageOpacity = backgroundImageOpacity;
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

  Future<void> _onBackgroundOpacityChanged(double value) async {
    setState(() {
      _backgroundImageOpacity = value;
    });
    await _settingsService.setBackgroundImageOpacity(value);
  }

  // 同步包装函数，用于Widget回调

  void _handleSelectBackgroundImage() {
    _selectBackgroundImage();
  }

  void _handleClearBackgroundImage() {
    _clearBackgroundImage();
  }

  void _handleBackgroundOpacityChanged(double value) {
    _onBackgroundOpacityChanged(value);
  }

  Future<void> _selectBackgroundImage() async {
    final l10n = AppLocalizations.of(context)!;
    final ImagePicker picker = ImagePicker();

    try {
      // 从图库选择图片
      final XFile? image = await picker.pickImage(
        source: ImageSource.gallery,
        maxWidth: 1920,
        maxHeight: 1080,
        imageQuality: 85,
      );

      if (image != null && mounted) {
        // 生成唯一文件名
        final timestamp = DateTime.now().millisecondsSinceEpoch;
        final random = DateTime.now().microsecondsSinceEpoch % 10000;
        final extension = image.path.split('.').last.toLowerCase();
        final filename = 'background_${timestamp}_$random.$extension';

        // 获取背景图片目录
        final backgroundsDirPath = await PathUtils.getBackgroundsDirPath();
        final newFilePath = '$backgroundsDirPath/$filename';

        // 复制文件到应用目录
        final sourceFile = File(image.path);
        final targetFile = File(newFilePath);
        await sourceFile.copy(targetFile.path);

        // 删除旧的背景图片（如果有）
        if (_backgroundImagePath.isNotEmpty && _backgroundImagePath != newFilePath) {
          final oldFile = File(_backgroundImagePath);
          if (await oldFile.exists()) {
            try {
              await oldFile.delete();
            } catch (e) {
              // 忽略删除错误
            }
          }
        }

        // 更新设置
        setState(() {
          _backgroundImagePath = newFilePath;
        });
        await _settingsService.setBackgroundImagePath(newFilePath);

      }
    } catch (e) {
      if (mounted) {
        showCupertinoDialog(
          context: context,
          builder: (context) => CupertinoAlertDialog(
            title: Text(l10n.error),
            content: Text(l10n.selectImageFailed),
            actions: [
              CupertinoDialogAction(
                child: Text(l10n.ok),
                onPressed: () => Navigator.pop(context),
              ),
            ],
          ),
        );
      }
    }
  }

  Future<void> _clearBackgroundImage() async {
    final l10n = AppLocalizations.of(context)!;

    // 显示确认对话框
    final confirmed = await showCupertinoDialog<bool>(
      context: context,
      builder: (context) => CupertinoAlertDialog(
        title: Text(l10n.clearBackgroundImage),
        content: Text(l10n.clearBackgroundImageConfirm),
        actions: [
          CupertinoDialogAction(
            child: Text(l10n.cancel),
            onPressed: () => Navigator.pop(context, false),
          ),
          CupertinoDialogAction(
            isDestructiveAction: true,
            child: Text(l10n.delete),
            onPressed: () => Navigator.pop(context, true),
          ),
        ],
      ),
    );

    if (confirmed == true) {
      // 删除文件
      if (_backgroundImagePath.isNotEmpty) {
        final file = File(_backgroundImagePath);
        if (await file.exists()) {
          try {
            await file.delete();
          } catch (e) {
            // 忽略删除错误
          }
        }
      }

      // 清除设置
      setState(() {
        _backgroundImagePath = SettingsService.defaultBackgroundImagePath;
      });
      await _settingsService.setBackgroundImagePath(SettingsService.defaultBackgroundImagePath);
    }
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;

    if (_isLoading) {
      return SettingsPageScaffold(
        title: l10n.appearanceAndLanguage,
        previousPageTitle: widget.previousPageTitle,
        embedded: widget.embedded,
        child: const Center(child: CupertinoActivityIndicator()),
      );
    }

    final currentMode = _followSystemTheme
        ? (MediaQuery.of(context).platformBrightness == Brightness.dark
            ? 'dark'
            : 'light')
        : _appTheme;

    return SettingsPageScaffold(
      title: l10n.appearanceAndLanguage,
      previousPageTitle: widget.previousPageTitle,
      embedded: widget.embedded,
      child: ListView(
        padding: const EdgeInsets.only(bottom: 32),
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
              Opacity(
                opacity: _followSystemTheme ? 0.48 : 1.0,
                child: AbsorbPointer(
                  absorbing: _followSystemTheme,
                  child: Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 16,
                      vertical: 14,
                    ),
                    child: Row(
                      children: [
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                l10n.appColor,
                                style: TextStyle(
                                  fontSize: 16,
                                  fontWeight: FontWeight.w500,
                                  color: AppTokens.label(context),
                                ),
                              ),
                              const SizedBox(height: 2),
                              Text(
                                _followSystemTheme
                                    ? l10n.followSystemSetting(
                                        currentMode == 'dark'
                                            ? l10n.darkMode
                                            : l10n.lightMode,
                                      )
                                    : l10n.selectColorMode,
                                style: TextStyle(
                                  fontSize: 13,
                                  color: AppTokens.labelSecondary(context),
                                ),
                              ),
                            ],
                          ),
                        ),
                        const SizedBox(width: 12),
                        CupertinoSlidingSegmentedControl<String>(
                          groupValue: currentMode,
                          children: {
                            'light': Padding(
                              padding: const EdgeInsets.symmetric(horizontal: 8),
                              child: Text(
                                l10n.lightMode,
                                style: const TextStyle(fontSize: 13),
                              ),
                            ),
                            'dark': Padding(
                              padding: const EdgeInsets.symmetric(horizontal: 8),
                              child: Text(
                                l10n.darkMode,
                                style: const TextStyle(fontSize: 13),
                              ),
                            ),
                          },
                          onValueChanged: (value) {
                            if (value != null && !_followSystemTheme) {
                              _onAppThemeChanged(value);
                            }
                          },
                        ),
                      ],
                    ),
                  ),
                ),
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
          SettingsSection(
            title: l10n.chatBackground,
            children: [
              SettingsActionTile(
                title: _backgroundImagePath.isEmpty
                    ? l10n.selectBackgroundImage
                    : l10n.changeBackgroundImage,
                subtitle: _backgroundImagePath.isEmpty
                    ? l10n.selectBackgroundImageDesc
                    : l10n.currentBackgroundImage,
                icon: CupertinoIcons.photo,
                onTap: _handleSelectBackgroundImage,
                trailing: _backgroundImagePath.isNotEmpty
                    ? CupertinoButton(
                        padding: EdgeInsets.zero,
                        onPressed: _handleClearBackgroundImage,
                        child: Text(
                          l10n.clear,
                          style: TextStyle(color: AppTokens.red(context)),
                        ),
                      )
                    : null,
              ),
              SettingsSliderTile(
                title: l10n.backgroundOpacity,
                value: _backgroundImageOpacity,
                min: 0.0,
                max: 1.0,
                divisions: 20,
                decimalPlaces: 2,
                subtitle: l10n.backgroundOpacityDesc,
                showValueInRow: true,
                onChanged: _handleBackgroundOpacityChanged,
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class _LanguageDropdownTile extends StatefulWidget {
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
  State<_LanguageDropdownTile> createState() => _LanguageDropdownTileState();
}

class _LanguageDropdownTileState extends State<_LanguageDropdownTile> {
  final GlobalKey _anchorKey = GlobalKey();

  static const Map<String, String> _options = {
    'zh': '简体中文',
    'lzh': '文言',
    'en': 'English',
    'es': 'Español',
    'ja': '日本語',
    'ko': '한국어',
  };

  Future<void> _pickLanguage() async {
    final l10n = AppLocalizations.of(context)!;
    final useWide = useWideLayout(MediaQuery.sizeOf(context));

    if (useWide && _anchorKey.currentContext != null) {
      await showDesktopPopoverMenu(
        anchorContext: _anchorKey.currentContext!,
        width: 210,
        alignRight: true,
        items: [
          for (final entry in _options.entries)
            DesktopPopoverItem(
              label: entry.value,
              selected: widget.value == entry.key,
              onTap: () => widget.onChanged?.call(entry.key),
            ),
        ],
      );
      return;
    }

    await showCupertinoModalPopup<void>(
      context: context,
      builder: (sheetContext) => CupertinoActionSheet(
        title: Text(widget.title),
        message: widget.subtitle != null ? Text(widget.subtitle!) : null,
        actions: [
          for (final entry in _options.entries)
            CupertinoActionSheetAction(
              onPressed: () {
                Navigator.pop(sheetContext);
                widget.onChanged?.call(entry.key);
              },
              child: Text(
                entry.value,
                style: TextStyle(
                  color: widget.value == entry.key
                      ? AppTokens.accent(sheetContext)
                      : AppTokens.label(sheetContext),
                ),
              ),
            ),
        ],
        cancelButton: CupertinoActionSheetAction(
          onPressed: () => Navigator.pop(sheetContext),
          child: Text(
            l10n.cancel,
            style: TextStyle(color: AppTokens.red(sheetContext)),
          ),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final currentLabel = _options[widget.value] ?? widget.value;

    return GestureDetector(
      key: _anchorKey,
      behavior: HitTestBehavior.opaque,
      onTap: widget.onChanged != null ? _pickLanguage : null,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
        child: Row(
          children: [
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    widget.title,
                    style: TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.w500,
                      color: AppTokens.label(context),
                    ),
                  ),
                  if (widget.subtitle != null) ...[
                    const SizedBox(height: 2),
                    Text(
                      widget.subtitle!,
                      style: TextStyle(
                        fontSize: 13,
                        color: AppTokens.labelSecondary(context),
                      ),
                    ),
                  ],
                ],
              ),
            ),
            const SizedBox(width: 12),
            Text(
              currentLabel,
              style: TextStyle(
                fontSize: 14.5,
                color: AppTokens.accent(context),
              ),
            ),
            const SizedBox(width: 4),
            Icon(
              CupertinoIcons.chevron_up_chevron_down,
              size: 14,
              color: AppTokens.labelSecondary(context),
            ),
          ],
        ),
      ),
    );
  }
}
