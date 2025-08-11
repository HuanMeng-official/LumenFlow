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
  static const String defaultCustomSystemPrompt = '';

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
    return prefs.getInt(_historyContextLengthKey) ?? defaultHistoryContextLength;
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
}