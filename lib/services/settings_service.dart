import 'dart:convert';
import 'package:cupertino_ui/cupertino_ui.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../ai/mcp/mcp_models.dart';
import '../models/active_platform_config.dart';
import '../models/ai_platform.dart';
import 'version_service.dart';

class SettingsService {
  static const String _apiEndpointKey = 'api_endpoint';
  static const String _apiKeyKey = 'api_key';
  static const String _modelKey = 'model';
  static const String _temperatureKey = 'temperature';
  static const String _maxTokensKey = 'max_tokens';
  static const String _enableHistoryKey = 'enable_history';
  static const String _historyContextLengthKey = 'history_context_length';
  static const String _customSystemPromptKey = 'custom_system_prompt';
  static const String _apiTypeKey = 'api_type';
  static const String _darkModeKey = 'dark_mode';
  static const String _followSystemThemeKey = 'follow_system_theme';
  static const String _appThemeKey = 'app_theme';
  static const String _thinkingModeKey = 'thinking_mode';
  static const String _promptPresetEnabledKey = 'prompt_preset_enabled';
  static const String _promptPresetIdKey = 'prompt_preset_id';
  static const String _autoTitleEnabledKey = 'auto_title_enabled';
  static const String _autoTitleRoundsKey = 'auto_title_rounds';
  static const String _localeKey = 'locale';
  static const String _notificationEnabledKey = 'notification_enabled';
  static const String _liveUpdateEnabledKey = 'live_update_enabled';
  // 聊天背景设置相关的key
  static const String _backgroundImagePathKey = 'background_image_path';
  static const String _backgroundImageOpacityKey = 'background_image_opacity';
  static const String _backgroundImageEnabledKey = 'background_image_enabled';
  // 工具管理相关的key
  static const String _addTimeToPromptKey = 'add_time_to_prompt';
  static const String _builtinCalculatorKey = 'builtin_calculator_enabled';
  static const String _builtinTextToolsKey = 'builtin_text_tools_enabled';
  // 多平台配置相关的key
  static const String _platformsKey = 'ai_platforms';
  static const String _currentPlatformIdKey = 'current_platform_id';
  static const String _mcpServersKey = 'mcp_servers';
  static const String defaultCustomSystemPrompt = '';
  static const String defaultApiType = 'openai';
  static const bool defaultDarkMode = false;
  static const bool defaultFollowSystemTheme = true;
  static const String defaultAppTheme = 'light';
  static const bool defaultThinkingMode = false;
  static const bool defaultPromptPresetEnabled = false;
  static const String defaultPromptPresetId = '';
  static const bool defaultAutoTitleEnabled = true;
  static const int defaultAutoTitleRounds = 3;
  static const String defaultLocale = 'zh';
  static const bool defaultNotificationEnabled = true;
  static const bool defaultLiveUpdateEnabled = true;
  // 聊天背景设置默认值
  static const String defaultBackgroundImagePath = '';
  static const double defaultBackgroundImageOpacity = 0.15;
  static const bool defaultBackgroundImageEnabled = false;
  // 工具管理默认值
  static const bool defaultAddTimeToPrompt = true;
  static const bool defaultBuiltinCalculatorEnabled = true;
  static const bool defaultBuiltinTextToolsEnabled = true;

  static const String defaultEndpoint = 'https://api.openai.com/v1';
  static const String defaultModel = 'gpt-6.1-sol';
  static const double defaultTemperature = 0.7;
  static const int defaultMaxTokens = 8192;
  static const bool defaultEnableHistory = true;
  static const int defaultHistoryContextLength = 30;

  static const String _lumenflowFormat = 'lumenflow';
  static const String _lumenflowVersion = '1.0';

  static ActivePlatformConfig? _cachedActiveConfig;
  static Future<ActivePlatformConfig>? _activeConfigFuture;

  static void _invalidateActiveConfig() {
    _cachedActiveConfig = null;
    _activeConfigFuture = null;
  }

  /// Clears the resolved active-platform snapshot (tests and write paths).
  @visibleForTesting
  static void clearActiveConfigCache() => _invalidateActiveConfig();

  Future<String> getApiEndpoint() async =>
      (await getActivePlatformConfig()).endpoint;

  Future<void> setApiEndpoint(String endpoint) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_apiEndpointKey, endpoint);
    _invalidateActiveConfig();
  }

  Future<String> getApiKey() async =>
      (await getActivePlatformConfig()).apiKey;

  Future<void> setApiKey(String apiKey) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_apiKeyKey, apiKey);
    _invalidateActiveConfig();
  }

  Future<String> getModel() async =>
      (await getActivePlatformConfig()).model;

  Future<void> setModel(String model) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_modelKey, model);
    _invalidateActiveConfig();
  }

  Future<double> getTemperature() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getDouble(_temperatureKey) ?? defaultTemperature;
  }

  Future<void> setTemperature(double temperature) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setDouble(_temperatureKey, temperature);
  }

  Future<int> getMaxTokens() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getInt(_maxTokensKey) ?? defaultMaxTokens;
  }

  Future<void> setMaxTokens(int maxTokens) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setInt(_maxTokensKey, maxTokens);
  }

  Future<bool> getEnableHistory() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getBool(_enableHistoryKey) ?? defaultEnableHistory;
  }

  Future<void> setEnableHistory(bool enableHistory) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool(_enableHistoryKey, enableHistory);
  }

  Future<int> getHistoryContextLength() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getInt(_historyContextLengthKey) ??
        defaultHistoryContextLength;
  }

  Future<void> setHistoryContextLength(int length) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setInt(_historyContextLengthKey, length);
  }

  Future<String> getCustomSystemPrompt() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getString(_customSystemPromptKey) ?? defaultCustomSystemPrompt;
  }

  Future<void> setCustomSystemPrompt(String prompt) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_customSystemPromptKey, prompt);
  }

  Future<String> getApiType() async =>
      (await getActivePlatformConfig()).apiType;

  Future<void> setApiType(String apiType) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_apiTypeKey, apiType);
    _invalidateActiveConfig();
  }

  /// Resolves the current platform (or legacy fallback) into one snapshot.
  Future<ActivePlatformConfig> getActivePlatformConfig() {
    final cached = _cachedActiveConfig;
    if (cached != null) return Future.value(cached);

    return _activeConfigFuture ??= _resolveActivePlatformConfig().then(
      (config) {
        _cachedActiveConfig = config;
        _activeConfigFuture = null;
        return config;
      },
      onError: (Object error, StackTrace stackTrace) {
        _activeConfigFuture = null;
        Error.throwWithStackTrace(error, stackTrace);
      },
    );
  }

  Future<ActivePlatformConfig> _resolveActivePlatformConfig() async {
    final prefs = await SharedPreferences.getInstance();
    final platforms = _parsePlatforms(prefs.getString(_platformsKey));
    final currentId = prefs.getString(_currentPlatformIdKey) ?? 'openai';

    AIPlatform? selected;
    for (final platform in platforms) {
      if (platform.id == currentId) {
        selected = platform;
        break;
      }
    }
    if (selected == null) {
      final configured = platforms.where((platform) => platform.isConfigured);
      selected = configured.isNotEmpty
          ? configured.first
          : (platforms.isNotEmpty
              ? platforms.first
              : AIPlatform.createDefaultPlatform(defaultApiType));
    }
    final active = selected;

    // Legacy keys are a fallback only before a platform list is materialized.
    // Once it exists, the active platform is authoritative: clearing or
    // deleting a key must not resurrect an old legacy credential.
    if (!prefs.containsKey(_platformsKey)) {
      return ActivePlatformConfig(
        platform: active,
        endpoint: prefs.getString(_apiEndpointKey) ?? defaultEndpoint,
        apiKey: prefs.getString(_apiKeyKey) ?? '',
        model: prefs.getString(_modelKey) ?? defaultModel,
        apiType: prefs.getString(_apiTypeKey) ?? defaultApiType,
      );
    }

    return ActivePlatformConfig(
      platform: active,
      endpoint: active.endpoint.isNotEmpty ? active.endpoint : defaultEndpoint,
      apiKey: active.apiKey,
      model: active.defaultModel.isNotEmpty ? active.defaultModel : defaultModel,
      apiType: active.type.isNotEmpty ? active.type : defaultApiType,
    );
  }

  Future<bool> getDarkMode() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getBool(_darkModeKey) ?? defaultDarkMode;
  }

  Future<void> setDarkMode(bool darkMode) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool(_darkModeKey, darkMode);
  }

  Future<bool> getFollowSystemTheme() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getBool(_followSystemThemeKey) ?? defaultFollowSystemTheme;
  }

  Future<void> setFollowSystemTheme(bool followSystemTheme) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool(_followSystemThemeKey, followSystemTheme);
  }

  Future<String> getAppTheme() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getString(_appThemeKey) ?? defaultAppTheme;
  }

  Future<void> setAppTheme(String appTheme) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_appThemeKey, appTheme);
  }

  Future<bool> getThinkingMode() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getBool(_thinkingModeKey) ?? defaultThinkingMode;
  }

  Future<void> setThinkingMode(bool thinkingMode) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool(_thinkingModeKey, thinkingMode);
  }

  Future<bool> getPromptPresetEnabled() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getBool(_promptPresetEnabledKey) ?? defaultPromptPresetEnabled;
  }

  Future<void> setPromptPresetEnabled(bool enabled) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool(_promptPresetEnabledKey, enabled);
  }

  Future<String> getPromptPresetId() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getString(_promptPresetIdKey) ?? defaultPromptPresetId;
  }

  Future<void> setPromptPresetId(String presetId) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_promptPresetIdKey, presetId);
  }

  Future<bool> getAutoTitleEnabled() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getBool(_autoTitleEnabledKey) ?? defaultAutoTitleEnabled;
  }

  Future<void> setAutoTitleEnabled(bool enabled) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool(_autoTitleEnabledKey, enabled);
  }

  Future<int> getAutoTitleRounds() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getInt(_autoTitleRoundsKey) ?? defaultAutoTitleRounds;
  }

  Future<void> setAutoTitleRounds(int rounds) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setInt(_autoTitleRoundsKey, rounds);
  }

  Future<String> getLocale() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getString(_localeKey) ?? defaultLocale;
  }

  Future<void> setLocale(String locale) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_localeKey, locale);
  }

  Future<bool> getNotificationEnabled() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getBool(_notificationEnabledKey) ?? defaultNotificationEnabled;
  }

  Future<void> setNotificationEnabled(bool enabled) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool(_notificationEnabledKey, enabled);
  }

  Future<bool> getLiveUpdateEnabled() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getBool(_liveUpdateEnabledKey) ?? defaultLiveUpdateEnabled;
  }

  Future<void> setLiveUpdateEnabled(bool enabled) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool(_liveUpdateEnabledKey, enabled);
  }

  Future<String> getBackgroundImagePath() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getString(_backgroundImagePathKey) ?? defaultBackgroundImagePath;
  }

  Future<void> setBackgroundImagePath(String path) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_backgroundImagePathKey, path);
  }

  Future<double> getBackgroundImageOpacity() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getDouble(_backgroundImageOpacityKey) ?? defaultBackgroundImageOpacity;
  }

  Future<void> setBackgroundImageOpacity(double opacity) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setDouble(_backgroundImageOpacityKey, opacity);
  }

  Future<bool> getBackgroundImageEnabled() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getBool(_backgroundImageEnabledKey) ?? defaultBackgroundImageEnabled;
  }

  Future<void> setBackgroundImageEnabled(bool enabled) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool(_backgroundImageEnabledKey, enabled);
  }

  /// 是否启用内置时间工具（键名为兼容旧设置而保留）。
  Future<bool> getAddTimeToPrompt() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getBool(_addTimeToPromptKey) ?? defaultAddTimeToPrompt;
  }

  Future<void> setAddTimeToPrompt(bool enabled) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool(_addTimeToPromptKey, enabled);
  }

  /// 是否启用内置计算器工具。
  Future<bool> getBuiltinCalculatorEnabled() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getBool(_builtinCalculatorKey) ??
        defaultBuiltinCalculatorEnabled;
  }

  Future<void> setBuiltinCalculatorEnabled(bool enabled) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool(_builtinCalculatorKey, enabled);
  }

  /// 是否启用内置文本对比与统计工具。
  Future<bool> getBuiltinTextToolsEnabled() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getBool(_builtinTextToolsKey) ??
        defaultBuiltinTextToolsEnabled;
  }

  Future<void> setBuiltinTextToolsEnabled(bool enabled) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool(_builtinTextToolsKey, enabled);
  }

  /// 导出所有设置为JSON格式的Map
  /// 返回包含所有设置键值对的Map
  Future<Map<String, dynamic>> exportSettingsToJson() async {
    final prefs = await SharedPreferences.getInstance();
    final Map<String, dynamic> settings = {};

    // 收集所有设置键值对
    settings[_apiEndpointKey] =
        prefs.getString(_apiEndpointKey) ?? defaultEndpoint;
    settings[_apiKeyKey] = prefs.getString(_apiKeyKey) ?? '';
    settings[_modelKey] = prefs.getString(_modelKey) ?? defaultModel;
    settings[_temperatureKey] =
        prefs.getDouble(_temperatureKey) ?? defaultTemperature;
    settings[_maxTokensKey] = prefs.getInt(_maxTokensKey) ?? defaultMaxTokens;
    settings[_enableHistoryKey] =
        prefs.getBool(_enableHistoryKey) ?? defaultEnableHistory;
    settings[_historyContextLengthKey] =
        prefs.getInt(_historyContextLengthKey) ?? defaultHistoryContextLength;
    settings[_customSystemPromptKey] =
        prefs.getString(_customSystemPromptKey) ?? defaultCustomSystemPrompt;
    settings[_apiTypeKey] = prefs.getString(_apiTypeKey) ?? defaultApiType;
    settings[_darkModeKey] = prefs.getBool(_darkModeKey) ?? defaultDarkMode;
    settings[_followSystemThemeKey] =
        prefs.getBool(_followSystemThemeKey) ?? defaultFollowSystemTheme;
    settings[_appThemeKey] = prefs.getString(_appThemeKey) ?? defaultAppTheme;
    settings[_thinkingModeKey] =
        prefs.getBool(_thinkingModeKey) ?? defaultThinkingMode;
    settings[_promptPresetEnabledKey] =
        prefs.getBool(_promptPresetEnabledKey) ?? defaultPromptPresetEnabled;
    settings[_promptPresetIdKey] =
        prefs.getString(_promptPresetIdKey) ?? defaultPromptPresetId;
    settings[_autoTitleEnabledKey] =
        prefs.getBool(_autoTitleEnabledKey) ?? defaultAutoTitleEnabled;
    settings[_autoTitleRoundsKey] =
        prefs.getInt(_autoTitleRoundsKey) ?? defaultAutoTitleRounds;
    settings[_localeKey] = prefs.getString(_localeKey) ?? defaultLocale;
    settings[_notificationEnabledKey] =
        prefs.getBool(_notificationEnabledKey) ?? defaultNotificationEnabled;
    settings[_liveUpdateEnabledKey] =
        prefs.getBool(_liveUpdateEnabledKey) ?? defaultLiveUpdateEnabled;
    settings[_addTimeToPromptKey] =
        prefs.getBool(_addTimeToPromptKey) ?? defaultAddTimeToPrompt;
    settings[_builtinCalculatorKey] =
        prefs.getBool(_builtinCalculatorKey) ??
            defaultBuiltinCalculatorEnabled;
    settings[_builtinTextToolsKey] =
        prefs.getBool(_builtinTextToolsKey) ??
            defaultBuiltinTextToolsEnabled;
    settings[_backgroundImagePathKey] =
        prefs.getString(_backgroundImagePathKey) ?? defaultBackgroundImagePath;
    settings[_backgroundImageOpacityKey] =
        prefs.getDouble(_backgroundImageOpacityKey) ?? defaultBackgroundImageOpacity;
    settings[_backgroundImageEnabledKey] =
        prefs.getBool(_backgroundImageEnabledKey) ?? defaultBackgroundImageEnabled;

    // 导出平台设置
    settings[_platformsKey] = prefs.getString(_platformsKey);
    settings[_currentPlatformIdKey] =
        prefs.getString(_currentPlatformIdKey) ?? 'openai';

    return settings;
  }

  /// 导出所有设置为Lumenflow格式
  /// 返回Lumenflow格式的Map，包含元数据和设置数据
  Future<Map<String, dynamic>> exportSettingsToLumenflow() async {
    final settings = await exportSettingsToJson();
    final versionService = VersionService();
    final versionInfo = await versionService.getVersionInfo();

    final lumenflowData = {
      '_format': _lumenflowFormat,
      '_version': _lumenflowVersion,
      '_created': DateTime.now().toUtc().toIso8601String(),
      '_app_version': versionInfo['version'] ?? 'unknown',
      'settings': settings,
    };

    return lumenflowData;
  }

  /// 从JSON Map导入设置
  /// [settings] 包含设置键值对的Map
  /// [overwrite] 是否覆盖现有设置，默认为true
  Future<void> importSettingsFromJson(
    Map<String, dynamic> settings, {
    bool overwrite = true,
  }) async {
    final prefs = await SharedPreferences.getInstance();

    // 只导入存在的键值对
    if (settings.containsKey(_apiEndpointKey)) {
      await prefs.setString(
        _apiEndpointKey,
        settings[_apiEndpointKey] as String,
      );
    }
    if (settings.containsKey(_apiKeyKey)) {
      await prefs.setString(_apiKeyKey, settings[_apiKeyKey] as String);
    }
    if (settings.containsKey(_modelKey)) {
      await prefs.setString(_modelKey, settings[_modelKey] as String);
    }
    if (settings.containsKey(_temperatureKey)) {
      await prefs.setDouble(
        _temperatureKey,
        (settings[_temperatureKey] as num).toDouble(),
      );
    }
    if (settings.containsKey(_maxTokensKey)) {
      await prefs.setInt(_maxTokensKey, settings[_maxTokensKey] as int);
    }
    if (settings.containsKey(_enableHistoryKey)) {
      await prefs.setBool(
        _enableHistoryKey,
        settings[_enableHistoryKey] as bool,
      );
    }
    if (settings.containsKey(_historyContextLengthKey)) {
      await prefs.setInt(
        _historyContextLengthKey,
        settings[_historyContextLengthKey] as int,
      );
    }
    if (settings.containsKey(_customSystemPromptKey)) {
      await prefs.setString(
        _customSystemPromptKey,
        settings[_customSystemPromptKey] as String,
      );
    }
    if (settings.containsKey(_apiTypeKey)) {
      await prefs.setString(_apiTypeKey, settings[_apiTypeKey] as String);
    }
    if (settings.containsKey(_darkModeKey)) {
      await prefs.setBool(_darkModeKey, settings[_darkModeKey] as bool);
    }
    if (settings.containsKey(_followSystemThemeKey)) {
      await prefs.setBool(
        _followSystemThemeKey,
        settings[_followSystemThemeKey] as bool,
      );
    }
    if (settings.containsKey(_appThemeKey)) {
      await prefs.setString(_appThemeKey, settings[_appThemeKey] as String);
    }
    if (settings.containsKey(_thinkingModeKey)) {
      await prefs.setBool(_thinkingModeKey, settings[_thinkingModeKey] as bool);
    }
    if (settings.containsKey(_promptPresetEnabledKey)) {
      await prefs.setBool(
        _promptPresetEnabledKey,
        settings[_promptPresetEnabledKey] as bool,
      );
    }
    if (settings.containsKey(_promptPresetIdKey)) {
      await prefs.setString(
        _promptPresetIdKey,
        settings[_promptPresetIdKey] as String,
      );
    }
    if (settings.containsKey(_autoTitleEnabledKey)) {
      await prefs.setBool(
        _autoTitleEnabledKey,
        settings[_autoTitleEnabledKey] as bool,
      );
    }
    if (settings.containsKey(_autoTitleRoundsKey)) {
      await prefs.setInt(
        _autoTitleRoundsKey,
        settings[_autoTitleRoundsKey] as int,
      );
    }
    if (settings.containsKey(_localeKey)) {
      await prefs.setString(_localeKey, settings[_localeKey] as String);
    }
    if (settings.containsKey(_notificationEnabledKey)) {
      await prefs.setBool(
        _notificationEnabledKey,
        settings[_notificationEnabledKey] as bool,
      );
    }
    if (settings.containsKey(_liveUpdateEnabledKey)) {
      await prefs.setBool(
        _liveUpdateEnabledKey,
        settings[_liveUpdateEnabledKey] as bool,
      );
    }
    if (settings.containsKey(_addTimeToPromptKey)) {
      await prefs.setBool(
        _addTimeToPromptKey,
        settings[_addTimeToPromptKey] as bool,
      );
    }
    if (settings.containsKey(_builtinCalculatorKey)) {
      await prefs.setBool(
        _builtinCalculatorKey,
        settings[_builtinCalculatorKey] as bool,
      );
    }
    if (settings.containsKey(_builtinTextToolsKey)) {
      await prefs.setBool(
        _builtinTextToolsKey,
        settings[_builtinTextToolsKey] as bool,
      );
    }
    if (settings.containsKey(_backgroundImagePathKey)) {
      await prefs.setString(
        _backgroundImagePathKey,
        settings[_backgroundImagePathKey] as String,
      );
    }
    if (settings.containsKey(_backgroundImageOpacityKey)) {
      await prefs.setDouble(
        _backgroundImageOpacityKey,
        (settings[_backgroundImageOpacityKey] as num).toDouble(),
      );
    }
    if (settings.containsKey(_backgroundImageEnabledKey)) {
      await prefs.setBool(
        _backgroundImageEnabledKey,
        settings[_backgroundImageEnabledKey] as bool,
      );
    }

    // 导入平台设置
    if (settings.containsKey(_platformsKey) &&
        settings[_platformsKey] != null) {
      await prefs.setString(_platformsKey, settings[_platformsKey] as String);
    }
    if (settings.containsKey(_currentPlatformIdKey)) {
      await prefs.setString(
        _currentPlatformIdKey,
        settings[_currentPlatformIdKey] as String,
      );
    }

    _invalidateActiveConfig();
  }

  /// 从Lumenflow格式或旧JSON格式导入设置
  /// [data] 可以是Lumenflow格式（包含元数据）或旧JSON格式
  /// [overwrite] 是否覆盖现有设置，默认为true
  Future<void> importSettingsFromLumenflow(
    Map<String, dynamic> data, {
    bool overwrite = true,
  }) async {
    Map<String, dynamic> settings;

    if (data.containsKey('_format') && data['_format'] == _lumenflowFormat) {
      // 提取settings字段
      if (data.containsKey('settings') &&
          data['settings'] is Map<String, dynamic>) {
        settings = data['settings'] as Map<String, dynamic>;
      } else {
        throw FormatException('无效的Lumenflow格式：缺少settings字段');
      }
    } else {
      settings = data;
    }

    // 调用现有的导入函数
    await importSettingsFromJson(settings, overwrite: overwrite);
  }

  /// 获取所有AI平台配置
  Future<List<AIPlatform>> getPlatforms() async {
    final prefs = await SharedPreferences.getInstance();
    return _parsePlatforms(prefs.getString(_platformsKey));
  }

  List<AIPlatform> _parsePlatforms(String? platformsJson) {
    if (platformsJson == null || platformsJson.isEmpty) {
      // 如果没有保存的配置，返回默认平台列表
      return _getDefaultPlatforms();
    }

    try {
      final List<dynamic> decoded = jsonDecode(platformsJson);
      return decoded
          .map((e) => AIPlatform.fromJson(e as Map<String, dynamic>))
          .toList();
    } catch (e) {
      // 解析失败，返回默认列表
      return _getDefaultPlatforms();
    }
  }

  /// 保存所有AI平台配置
  Future<void> savePlatforms(List<AIPlatform> platforms) async {
    final prefs = await SharedPreferences.getInstance();
    final platformsJson = jsonEncode(platforms.map((p) => p.toJson()).toList());
    await prefs.setString(_platformsKey, platformsJson);
    _invalidateActiveConfig();
  }

  /// 添加或更新一个AI平台配置
  Future<void> savePlatform(AIPlatform platform) async {
    final platforms = await getPlatforms();
    final index = platforms.indexWhere((p) => p.id == platform.id);

    debugPrint(
      '保存平台: id=${platform.id}, name=${platform.name}, defaultModel=${platform.defaultModel}',
    );
    debugPrint('找到索引: $index, 总平台数: ${platforms.length}');

    if (index >= 0) {
      // 更新现有平台
      debugPrint('更新现有平台: ${platforms[index].name} -> ${platform.name}');
      debugPrint(
        '原默认模型: ${platforms[index].defaultModel}, 新默认模型: ${platform.defaultModel}',
      );
      platforms[index] = platform;
    } else {
      // 添加新平台
      debugPrint('添加新平台: ${platform.name}');
      platforms.add(platform);
    }

    await savePlatforms(platforms);
    debugPrint('保存完成');
  }

  /// 保存单平台配置：更新同类型平台或创建新平台，并设为当前平台。
  Future<AIPlatform> saveSinglePlatformConfig({
    required String type,
    required String endpoint,
    required String apiKey,
  }) async {
    final platforms = await getPlatforms();
    final active = await getCurrentPlatform();

    int index = -1;
    if (active != null && active.type == type) {
      index = platforms.indexWhere((platform) => platform.id == active.id);
    }

    if (index < 0) {
      final matches =
          platforms.where((platform) => platform.type == type).toList();
      if (matches.length == 1) {
        index =
            platforms.indexWhere((platform) => platform.id == matches.single.id);
      }
    }

    final base = index >= 0
        ? platforms[index]
        : AIPlatform.createDefaultPlatform(type).copyWith(
            id: '${type}_${DateTime.now().millisecondsSinceEpoch}',
          );
    final updated = base.copyWith(
      type: type,
      endpoint: endpoint,
      apiKey: apiKey,
    );

    if (index >= 0) {
      platforms[index] = updated;
    } else {
      platforms.add(updated);
    }

    await savePlatforms(platforms);
    await setCurrentPlatformId(updated.id);

    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_apiEndpointKey, endpoint);
    await prefs.setString(_apiKeyKey, apiKey);
    await prefs.setString(_apiTypeKey, type);
    _invalidateActiveConfig();

    return updated;
  }

  /// 删除一个AI平台配置
  Future<void> deletePlatform(String platformId) async {
    final platforms = await getPlatforms();
    platforms.removeWhere((p) => p.id == platformId);
    await savePlatforms(platforms);

    // 如果删除的是当前平台，优先切换到剩余平台中第一个已配置的平台
    final currentPlatformId = await getCurrentPlatformId();
    if (currentPlatformId == platformId) {
      final remainingPlatforms = await getPlatforms();
      if (remainingPlatforms.isNotEmpty) {
        final next = remainingPlatforms.firstWhere(
          (platform) => platform.isConfigured,
          orElse: () => remainingPlatforms.first,
        );
        await setCurrentPlatformId(next.id);
      }
    }
  }

  /// 获取当前选中的平台ID
  Future<String> getCurrentPlatformId() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getString(_currentPlatformIdKey) ?? 'openai';
  }

  /// 设置当前选中的平台ID
  Future<void> setCurrentPlatformId(String platformId) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_currentPlatformIdKey, platformId);
    _invalidateActiveConfig();
  }

  /// 获取当前选中的平台配置
  Future<AIPlatform?> getCurrentPlatform() async {
    final platforms = await getPlatforms();
    final currentId = await getCurrentPlatformId();
    try {
      return platforms.firstWhere((p) => p.id == currentId);
    } catch (e) {
      // 如果找不到当前平台，返回第一个配置的平台
      if (platforms.isNotEmpty) {
        return platforms.first;
      }
      return null;
    }
  }

  /// 根据ID获取平台配置
  Future<AIPlatform?> getPlatformById(String platformId) async {
    final platforms = await getPlatforms();
    try {
      return platforms.firstWhere((p) => p.id == platformId);
    } catch (e) {
      return null;
    }
  }

  /// 更新平台的模型列表
  Future<void> updatePlatformModels(
    String platformId,
    List<String> models, {
    String? newDefaultModel,
  }) async {
    final platforms = await getPlatforms();
    final index = platforms.indexWhere((p) => p.id == platformId);

    if (index >= 0) {
      final platform = platforms[index];
      final updatedPlatform = platform.copyWith(
        availableModels: models,
        defaultModel: newDefaultModel ?? platform.defaultModel,
        lastModelUpdate: DateTime.now(),
      );
      platforms[index] = updatedPlatform;
      await savePlatforms(platforms);
    }
  }

  /// 检查是否有任何平台已配置
  Future<bool> hasConfiguredPlatform() async {
    final platforms = await getPlatforms();
    return platforms.any((p) => p.isConfigured);
  }

  /// 检查应用是否已配置。
  /// 只检查当前解析出的平台配置，而不是任意平台。
  Future<bool> isConfigured() async {
    return (await getActivePlatformConfig()).isConfigured;
  }

  /// 迁移旧版本配置到新版本的多平台配置。
  ///
  /// 只在没有任何已配置平台时执行，且只读取原始旧键，避免把已解析的
  /// 平台配置再写回平台列表。已有配置的平台永远不会被覆盖。
  Future<void> migrateLegacySettings() async {
    final platforms = await getPlatforms();
    if (platforms.any((platform) => platform.isConfigured)) {
      return;
    }

    final prefs = await SharedPreferences.getInstance();
    final oldApiType = prefs.getString(_apiTypeKey) ?? defaultApiType;
    final oldEndpoint = prefs.getString(_apiEndpointKey) ?? defaultEndpoint;
    final oldApiKey = prefs.getString(_apiKeyKey) ?? '';
    final oldModel = prefs.getString(_modelKey) ?? defaultModel;

    if (oldApiKey.isEmpty) return;

    final index = platforms.indexWhere((p) => p.type == oldApiType);
    final base = index >= 0
        ? platforms[index]
        : AIPlatform.createDefaultPlatform(oldApiType);

    var updatedPlatform = base.copyWith(
      endpoint: oldEndpoint,
      apiKey: oldApiKey,
      defaultModel: oldModel,
    );

    if (!updatedPlatform.availableModels.contains(oldModel)) {
      updatedPlatform = updatedPlatform.copyWith(
        availableModels: [...updatedPlatform.availableModels, oldModel],
      );
    }

    if (index >= 0) {
      platforms[index] = updatedPlatform;
    } else {
      platforms.add(updatedPlatform);
    }

    await savePlatforms(platforms);
    await setCurrentPlatformId(updatedPlatform.id);
  }

  /// 获取已配置的 MCP 服务器。
  Future<List<McpServerConfig>> getMcpServers() async {
    final prefs = await SharedPreferences.getInstance();
    final raw = prefs.getString(_mcpServersKey);
    if (raw == null || raw.isEmpty) return const [];

    try {
      final decoded = jsonDecode(raw);
      if (decoded is! List) return const [];

      final servers = <McpServerConfig>[];
      for (final item in decoded) {
        if (item is! Map) continue;
        try {
          servers.add(
            McpServerConfig.fromJson(item.cast<String, dynamic>()),
          );
        } catch (_) {
          // Skip malformed entries.
        }
      }
      return servers;
    } catch (_) {
      return const [];
    }
  }

  /// 保存 MCP 服务器配置。
  Future<void> saveMcpServers(List<McpServerConfig> servers) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(
      _mcpServersKey,
      jsonEncode(servers.map((server) => server.toJson()).toList()),
    );
  }

  /// 获取默认平台列表
  List<AIPlatform> _getDefaultPlatforms() {
    return [
      AIPlatform.createDefaultPlatform('openai'),
      AIPlatform.createDefaultPlatform('gemini'),
      AIPlatform.createDefaultPlatform('claude'),
      AIPlatform.createDefaultPlatform('grok'),
      AIPlatform.createDefaultPlatform('deepseek'),
      AIPlatform.createDefaultPlatform('kimi'),
      AIPlatform.createDefaultPlatform('zhipu'),
      AIPlatform.createDefaultPlatform('minimax'),
      AIPlatform.createDefaultPlatform('xiaomimimo'),
      AIPlatform.createDefaultPlatform('siliconflow'),
      AIPlatform.createDefaultPlatform('openrouter'),
      AIPlatform.createDefaultPlatform('lmstudio'),
      AIPlatform.createDefaultPlatform('other'),
    ];
  }
}
