import 'package:shared_preferences/shared_preferences.dart';

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

  static const String defaultEndpoint = 'https://api.openai.com/v1';
  static const String defaultModel = 'gpt-5';
  static const double defaultTemperature = 0.7;
  static const int defaultMaxTokens = 1000;
  static const bool defaultEnableHistory = true;
  static const int defaultHistoryContextLength = 100;

  Future<String> getApiEndpoint() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getString(_apiEndpointKey) ?? defaultEndpoint;
  }

  Future<void> setApiEndpoint(String endpoint) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_apiEndpointKey, endpoint);
  }

  Future<String> getApiKey() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getString(_apiKeyKey) ?? '';
  }

  Future<void> setApiKey(String apiKey) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_apiKeyKey, apiKey);
  }

  Future<String> getModel() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getString(_modelKey) ?? defaultModel;
  }

  Future<void> setModel(String model) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_modelKey, model);
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

  Future<bool> isConfigured() async {
    final apiKey = await getApiKey();
    return apiKey.isNotEmpty;
  }

  Future<String> getCustomSystemPrompt() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getString(_customSystemPromptKey) ?? defaultCustomSystemPrompt;
  }

  Future<void> setCustomSystemPrompt(String prompt) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_customSystemPromptKey, prompt);
  }

  Future<String> getApiType() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getString(_apiTypeKey) ?? defaultApiType;
  }

  Future<void> setApiType(String apiType) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_apiTypeKey, apiType);
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

  /// 导出所有设置为JSON格式的Map
  /// 返回包含所有设置键值对的Map
  Future<Map<String, dynamic>> exportSettingsToJson() async {
    final prefs = await SharedPreferences.getInstance();
    final Map<String, dynamic> settings = {};

    // 收集所有设置键值对
    settings[_apiEndpointKey] = prefs.getString(_apiEndpointKey) ?? defaultEndpoint;
    settings[_apiKeyKey] = prefs.getString(_apiKeyKey) ?? '';
    settings[_modelKey] = prefs.getString(_modelKey) ?? defaultModel;
    settings[_temperatureKey] = prefs.getDouble(_temperatureKey) ?? defaultTemperature;
    settings[_maxTokensKey] = prefs.getInt(_maxTokensKey) ?? defaultMaxTokens;
    settings[_enableHistoryKey] = prefs.getBool(_enableHistoryKey) ?? defaultEnableHistory;
    settings[_historyContextLengthKey] = prefs.getInt(_historyContextLengthKey) ?? defaultHistoryContextLength;
    settings[_customSystemPromptKey] = prefs.getString(_customSystemPromptKey) ?? defaultCustomSystemPrompt;
    settings[_apiTypeKey] = prefs.getString(_apiTypeKey) ?? defaultApiType;
    settings[_darkModeKey] = prefs.getBool(_darkModeKey) ?? defaultDarkMode;
    settings[_followSystemThemeKey] = prefs.getBool(_followSystemThemeKey) ?? defaultFollowSystemTheme;
    settings[_appThemeKey] = prefs.getString(_appThemeKey) ?? defaultAppTheme;
    settings[_thinkingModeKey] = prefs.getBool(_thinkingModeKey) ?? defaultThinkingMode;
    settings[_promptPresetEnabledKey] = prefs.getBool(_promptPresetEnabledKey) ?? defaultPromptPresetEnabled;
    settings[_promptPresetIdKey] = prefs.getString(_promptPresetIdKey) ?? defaultPromptPresetId;
    settings[_autoTitleEnabledKey] = prefs.getBool(_autoTitleEnabledKey) ?? defaultAutoTitleEnabled;
    settings[_autoTitleRoundsKey] = prefs.getInt(_autoTitleRoundsKey) ?? defaultAutoTitleRounds;
    settings[_localeKey] = prefs.getString(_localeKey) ?? defaultLocale;

    return settings;
  }

  /// 从JSON Map导入设置
  /// [settings] 包含设置键值对的Map
  /// [overwrite] 是否覆盖现有设置，默认为true
  Future<void> importSettingsFromJson(Map<String, dynamic> settings, {bool overwrite = true}) async {
    final prefs = await SharedPreferences.getInstance();

    // 只导入存在的键值对
    if (settings.containsKey(_apiEndpointKey)) {
      await prefs.setString(_apiEndpointKey, settings[_apiEndpointKey] as String);
    }
    if (settings.containsKey(_apiKeyKey)) {
      await prefs.setString(_apiKeyKey, settings[_apiKeyKey] as String);
    }
    if (settings.containsKey(_modelKey)) {
      await prefs.setString(_modelKey, settings[_modelKey] as String);
    }
    if (settings.containsKey(_temperatureKey)) {
      await prefs.setDouble(_temperatureKey, (settings[_temperatureKey] as num).toDouble());
    }
    if (settings.containsKey(_maxTokensKey)) {
      await prefs.setInt(_maxTokensKey, settings[_maxTokensKey] as int);
    }
    if (settings.containsKey(_enableHistoryKey)) {
      await prefs.setBool(_enableHistoryKey, settings[_enableHistoryKey] as bool);
    }
    if (settings.containsKey(_historyContextLengthKey)) {
      await prefs.setInt(_historyContextLengthKey, settings[_historyContextLengthKey] as int);
    }
    if (settings.containsKey(_customSystemPromptKey)) {
      await prefs.setString(_customSystemPromptKey, settings[_customSystemPromptKey] as String);
    }
    if (settings.containsKey(_apiTypeKey)) {
      await prefs.setString(_apiTypeKey, settings[_apiTypeKey] as String);
    }
    if (settings.containsKey(_darkModeKey)) {
      await prefs.setBool(_darkModeKey, settings[_darkModeKey] as bool);
    }
    if (settings.containsKey(_followSystemThemeKey)) {
      await prefs.setBool(_followSystemThemeKey, settings[_followSystemThemeKey] as bool);
    }
    if (settings.containsKey(_appThemeKey)) {
      await prefs.setString(_appThemeKey, settings[_appThemeKey] as String);
    }
    if (settings.containsKey(_thinkingModeKey)) {
      await prefs.setBool(_thinkingModeKey, settings[_thinkingModeKey] as bool);
    }
    if (settings.containsKey(_promptPresetEnabledKey)) {
      await prefs.setBool(_promptPresetEnabledKey, settings[_promptPresetEnabledKey] as bool);
    }
    if (settings.containsKey(_promptPresetIdKey)) {
      await prefs.setString(_promptPresetIdKey, settings[_promptPresetIdKey] as String);
    }
    if (settings.containsKey(_autoTitleEnabledKey)) {
      await prefs.setBool(_autoTitleEnabledKey, settings[_autoTitleEnabledKey] as bool);
    }
    if (settings.containsKey(_autoTitleRoundsKey)) {
      await prefs.setInt(_autoTitleRoundsKey, settings[_autoTitleRoundsKey] as int);
    }
    if (settings.containsKey(_localeKey)) {
      await prefs.setString(_localeKey, settings[_localeKey] as String);
    }
  }
}
