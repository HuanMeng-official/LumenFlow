import 'dart:async';
import 'settings_service.dart';
import 'user_service.dart';
import '../models/message.dart';
import '../models/attachment.dart';
import '../models/user_profile.dart';
import '../providers/ai_provider.dart';
import '../providers/openai_provider.dart';
import '../providers/gemini_provider.dart';
import '../providers/deepseek_provider.dart';

/// AI服务类，负责处理与AI模型（OpenAI、Google Gemini和DeepSeek）的通信
/// 支持文本对话、文件附件处理、流式输出等功能
/// 提供统一的接口供聊天界面调用，隐藏不同API的差异
///
/// 重构说明：
/// - 使用 Provider 模式将不同 API 的实现分离
/// - 通过工厂模式根据 API 类型选择对应的 Provider
/// - 简化了主服务类的职责，主要负责配置管理和 Provider 选择
class AIService {
  final SettingsService _settingsService = SettingsService();
  final UserService _userService = UserService();

  /// Provider 缓存
  AIProvider? _cachedProvider;

  /// 静态常量（为了向后兼容，从 AIProvider 重新导出）
  static const int maxFileSizeForBase64 = AIProvider.maxFileSizeForBase64;
  static const int maxFileSizeForTextExtraction = AIProvider.maxFileSizeForTextExtraction;
  static const int maxTotalAttachmentsSize = AIProvider.maxTotalAttachmentsSize;

  /// 获取 AI Provider 实例（工厂方法）
  ///
  /// 根据 API 类型返回对应的 Provider 实例，使用缓存避免重复创建
  Future<AIProvider> _getProvider() async {
    final apiType = await _settingsService.getApiType();

    // 如果缓存的 provider 类型匹配，直接返回
    if (_cachedProvider != null) {
      if ((apiType == 'gemini' && _cachedProvider is GeminiProvider) ||
          (apiType == 'deepseek' && _cachedProvider is DeepSeekProvider) ||
          (apiType != 'gemini' && apiType != 'deepseek' && _cachedProvider is OpenAIProvider)) {
        return _cachedProvider!;
      }
    }

    // 创建新的 provider 实例
    if (apiType == 'gemini') {
      _cachedProvider = GeminiProvider();
    } else if (apiType == 'deepseek') {
      _cachedProvider = DeepSeekProvider();
    } else {
      _cachedProvider = OpenAIProvider();
    }
    return _cachedProvider!;
  }

  /// 替换系统提示词中的变量占位符
  ///
  /// 参数:
  ///   systemPrompt - 原始系统提示词
  ///   userProfile - 用户配置对象
  /// 返回值:
  ///   替换变量后的系统提示词
  String _replaceSystemPromptVariables(String systemPrompt, UserProfile userProfile) {
    return systemPrompt.replaceAll('\${userProfile.username}', userProfile.username);
  }

  /// 构建完整的系统提示词
  ///
  /// 包含基础提示词和用户自定义提示词
  Future<String> _buildSystemPrompt(String presetSystemPrompt) async {
    final userProfile = await _userService.getUserProfile();
    final customSystemPrompt = await _settingsService.getCustomSystemPrompt();

    // 决定使用哪个系统提示词：优先使用预设提示词
    final systemPromptToUse = presetSystemPrompt.isNotEmpty
        ? presetSystemPrompt
        : customSystemPrompt;

    String baseSystemPrompt =
        '用户的名字是"${userProfile.username}",请在对话中适当地使用这个名字来称呼用户并使用和用户相同的语言（如果用户说中文你就用中文，用户说英文你就用英文）。';
    String fullSystemPrompt = baseSystemPrompt;
    if (systemPromptToUse.isNotEmpty) {
      fullSystemPrompt += systemPromptToUse;
    }

    // 替换系统提示词中的变量占位符
    return _replaceSystemPromptVariables(fullSystemPrompt, userProfile);
  }

  /// 发送消息到AI模型（同步方式）
  ///
  /// 参数:
  ///   message - 用户输入的文本消息
  ///   chatHistory - 聊天历史记录（用于上下文）
  ///   attachments - 附件列表（可选，默认为空）
  ///   thinkingMode - 是否启用思考模式
  ///   presetSystemPrompt - 预设系统提示词
  /// 返回值:
  ///   返回一个`Map<String, dynamic>`，包含AI模型的响应
  ///   - 'reasoningContent': 思考过程内容（如果有）
  ///   - 'content': 最终回答内容
  /// 异常:
  ///   抛出Exception当API密钥未配置或网络请求失败时
  Future<Map<String, dynamic>> sendMessage(
      String message, List<Message> chatHistory,
      {List<Attachment> attachments = const [],
      bool thinkingMode = false,
      String presetSystemPrompt = ''}) async {
    final apiKey = await _settingsService.getApiKey();
    if (apiKey.isEmpty) {
      throw Exception('请先在设置中配置API密钥');
    }

    final provider = await _getProvider();
    final temperature = await _settingsService.getTemperature();
    final maxTokens = await _settingsService.getMaxTokens();
    final systemPrompt = await _buildSystemPrompt(presetSystemPrompt);

    try {
      return await provider.sendMessage(
        message: message,
        chatHistory: chatHistory,
        attachments: attachments,
        systemPrompt: systemPrompt,
        temperature: temperature,
        maxTokens: maxTokens,
        thinkingMode: thinkingMode,
      );
    } catch (e) {
      throw _handleError(e);
    }
  }

  /// 发送消息到AI模型（流式方式）
  ///
  /// 参数:
  ///   message - 用户输入的文本消息
  ///   chatHistory - 聊天历史记录（用于上下文）
  ///   attachments - 附件列表（可选，默认为空）
  ///   thinkingMode - 是否启用思考模式
  ///   presetSystemPrompt - 预设系统提示词
  /// 返回值:
  ///   返回一个`Stream<Map<String, dynamic>>`，实时输出AI模型的响应片段
  ///   Map包含 'type' 和 'content' 字段，type可以是 'reasoning' 或 'answer'
  /// 异常:
  ///   抛出Exception当API密钥未配置或网络请求失败时
  Stream<Map<String, dynamic>> sendMessageStreaming(
      String message, List<Message> chatHistory,
      {List<Attachment> attachments = const [],
      bool thinkingMode = false,
      String presetSystemPrompt = ''}) async* {
    final apiKey = await _settingsService.getApiKey();
    if (apiKey.isEmpty) {
      throw Exception('请先在设置中配置API密钥');
    }

    final provider = await _getProvider();
    final temperature = await _settingsService.getTemperature();
    final maxTokens = await _settingsService.getMaxTokens();
    final systemPrompt = await _buildSystemPrompt(presetSystemPrompt);

    try {
      yield* provider.sendMessageStreaming(
        message: message,
        chatHistory: chatHistory,
        attachments: attachments,
        systemPrompt: systemPrompt,
        temperature: temperature,
        maxTokens: maxTokens,
        thinkingMode: thinkingMode,
      );
    } catch (e) {
      throw _handleError(e);
    }
  }

  /// 生成对话标题
  ///
  /// 参数:
  ///   messages - 对话消息列表
  /// 返回值:
  ///   生成的对话标题（简短摘要）
  /// 异常:
  ///   抛出Exception当API密钥未配置或网络请求失败时
  Future<String> generateConversationTitle(List<Message> messages) async {
    final apiKey = await _settingsService.getApiKey();
    if (apiKey.isEmpty) {
      throw Exception('请先在设置中配置API密钥');
    }

    final provider = await _getProvider();

    try {
      return await provider.generateConversationTitle(messages);
    } catch (e) {
      throw _handleError(e);
    }
  }

  /// 统一错误处理
  ///
  /// 将各种错误转换为用户友好的异常消息
  Exception _handleError(dynamic e) {
    // 如果已经是 API 错误，直接重新抛出
    if (e.toString().contains('API错误')) {
      return e as Exception;
    }

    // 根据错误类型提供更详细的错误信息
    final errorMsg = e.toString();
    if (errorMsg.contains('timeout') || errorMsg.contains('Timeout')) {
      return Exception('请求超时：服务器响应时间过长，请检查网络连接或稍后重试。错误详情: $e');
    } else if (errorMsg.contains('socket') || errorMsg.contains('Socket')) {
      return Exception('网络连接失败：无法连接到服务器，请检查网络连接。错误详情: $e');
    } else if (errorMsg.contains('handshake') || errorMsg.contains('TLS') || errorMsg.contains('SSL')) {
      return Exception('安全连接失败：SSL/TLS握手失败，请检查系统时间或网络设置。错误详情: $e');
    } else if (errorMsg.contains('Connection') || errorMsg.contains('connection')) {
      return Exception('连接错误：网络连接出现问题，请检查网络设置。错误详情: $e');
    } else if (errorMsg.contains('Http') || errorMsg.contains('http')) {
      return Exception('HTTP协议错误：请求处理失败，请稍后重试。错误详情: $e');
    } else if (e is Exception) {
      return e;
    } else {
      return Exception('网络通信失败：$e');
    }
  }
}
