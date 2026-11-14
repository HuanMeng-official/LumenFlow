import 'dart:async';
import 'dart:convert';

import 'package:crypto/crypto.dart';
import 'package:flutter/foundation.dart';

import 'memory_policy.dart';
import 'memory_service.dart';
import 'settings_service.dart';
import 'system_prompt_builder.dart';
import 'tool_chat_service.dart';
import '../ai/contracts/ai_error.dart';
import '../ai/contracts/ai_tool_executor.dart';
import '../ai/mcp/mcp_client.dart';
import '../ai/mcp/mcp_models.dart';
import '../ai/mcp/mcp_tool_manager.dart';
import '../ai/providers/chat_completions_profile.dart';
import '../ai/providers/responses_tool_provider.dart';
import '../ai/tools/attachment_tool_context.dart';
import '../ai/tools/builtin_calculator_tool.dart';
import '../ai/tools/builtin_date_math_tool.dart';
import '../ai/tools/builtin_memory_note_tool.dart';
import '../ai/tools/builtin_memory_recall_tool.dart';
import '../ai/tools/builtin_lunar_calendar_tool.dart';
import '../ai/tools/builtin_read_attachment_tool.dart';
import '../ai/tools/builtin_text_tools.dart';
import '../ai/tools/builtin_time_tool.dart';
import '../ai/tools/builtin_user_profile_tool.dart';
import '../ai/tools/builtin_unit_convert_tool.dart';
import '../ai/tools/composite_tool_executor.dart';
import '../models/message.dart';
import '../models/attachment.dart';
import '../providers/ai_provider.dart';
import '../providers/openai_provider.dart';
import '../providers/gemini_provider.dart';
import '../providers/deepseek_provider.dart';
import '../providers/claude_provider.dart';
import '../providers/siliconflow_provider.dart';
import '../providers/minimax_provider.dart';
import '../providers/zhipu_provider.dart';
import '../providers/kimi_provider.dart';
import '../providers/lmstudio_provider.dart';
import '../providers/other_provider.dart';
import '../providers/grok_provider.dart';
import '../providers/openrouter_provider.dart';
import '../providers/xiaomimimo_provider.dart';
import '../l10n/app_localizations.dart';
import '../utils/ai_tools/time_utils.dart';

/// AI服务类，负责处理与AI模型的通信
/// 支持文本对话、文件附件处理、流式输出等功能
/// 提供统一的接口供聊天界面调用，隐藏不同API的差异
///
/// 重构说明：
/// - 使用 Provider 模式将不同 API 的实现分离
/// - 通过工厂模式根据 API 类型选择对应的 Provider
/// - 简化了主服务类的职责，主要负责配置管理和 Provider 选择
class AIService {
  AIService({
    SettingsService? settingsService,
    this._toolManagerFactory,
    this._toolChatServiceFactory,
    this.toolRefreshInterval = const Duration(seconds: 30),
  }) : _settingsService = settingsService ?? SettingsService();

  final SettingsService _settingsService;
  final McpToolManager Function(List<McpServerConfig> servers)?
  _toolManagerFactory;
  final ToolChatService Function(AIToolExecutor executor)?
  _toolChatServiceFactory;
  final Duration toolRefreshInterval;

  /// Provider 缓存
  AIProvider? _cachedProvider;

  /// 静态常量（为了向后兼容，从 AIProvider 重新导出）
  static const int maxFileSizeForBase64 = AIProvider.maxFileSizeForBase64;
  static const int maxFileSizeForTextExtraction =
      AIProvider.maxFileSizeForTextExtraction;
  static const int maxTotalAttachmentsSize = AIProvider.maxTotalAttachmentsSize;

  /// 获取 AI Provider 实例（工厂方法）
  ///
  /// 根据 API 类型返回对应的 Provider 实例，使用缓存避免重复创建
  /// 当 API 配置变更时，需要重新创建 Provider 实例
  Future<AIProvider> _getProvider() async {
    final apiType = await _settingsService.getApiType();

    // 如果缓存的 provider 类型匹配且配置未变化，直接返回
    if (_cachedProvider != null) {
      bool typeMatches =
          (apiType == 'gemini' && _cachedProvider is GeminiProvider) ||
          (apiType == 'deepseek' && _cachedProvider is DeepSeekProvider) ||
          (apiType == 'claude' && _cachedProvider is ClaudeProvider) ||
          (apiType == 'siliconflow' &&
              _cachedProvider is SiliconFlowProvider) ||
          (apiType == 'minimax' && _cachedProvider is MiniMaxProvider) ||
          (apiType == 'zhipu' && _cachedProvider is ZhiPuProvider) ||
          (apiType == 'kimi' && _cachedProvider is KimiProvider) ||
          (apiType == 'lmstudio' && _cachedProvider is LMStudioProvider) ||
          (apiType == 'other' && _cachedProvider is OtherProvider) ||
          (apiType == 'openai' && _cachedProvider is OpenAIProvider) ||
          (apiType == 'grok' && _cachedProvider is GrokProvider) ||
          (apiType == 'xiaomimimo' && _cachedProvider is XiaoMiMiMoProvider) ||
          (apiType == 'openrouter' && _cachedProvider is OpenRouterProvider);

      // 如果类型匹配，且配置未变更，使用缓存
      // 注意：这里需要比较配置，但由于 Provider 内部每次都会重新读取设置，
      // 我们可以简化逻辑，只在类型变化时重建
      if (typeMatches && _cachedApiType == apiType) {
        return _cachedProvider!;
      }
    }

    // 创建新的 provider 实例
    if (apiType == 'gemini') {
      _cachedProvider = GeminiProvider();
    } else if (apiType == 'deepseek') {
      _cachedProvider = DeepSeekProvider();
    } else if (apiType == 'claude') {
      _cachedProvider = ClaudeProvider();
    } else if (apiType == 'siliconflow') {
      _cachedProvider = SiliconFlowProvider();
    } else if (apiType == 'minimax') {
      _cachedProvider = MiniMaxProvider();
    } else if (apiType == 'zhipu') {
      _cachedProvider = ZhiPuProvider();
    } else if (apiType == 'kimi') {
      _cachedProvider = KimiProvider();
    } else if (apiType == 'lmstudio') {
      _cachedProvider = LMStudioProvider();
    } else if (apiType == 'other') {
      _cachedProvider = OtherProvider();
    } else if (apiType == 'grok') {
      _cachedProvider = GrokProvider();
    } else if (apiType == 'openrouter') {
      _cachedProvider = OpenRouterProvider();
    } else if (apiType == 'xiaomimimo') {
      _cachedProvider = XiaoMiMiMoProvider();
    } else {
      _cachedProvider = OpenAIProvider();
    }

    // 记录当前 API 类型，用于缓存比较
    _cachedApiType = apiType;
    return _cachedProvider!;
  }

  // 缓存的 API 类型，用于检测配置变化
  String? _cachedApiType;

  McpToolManager? _toolManager;
  String? _toolManagerSignature;
  Future<McpToolManager?>? _toolManagerLoad;
  DateTime? _lastToolRefresh;
  bool _disposed = false;

  @visibleForTesting
  Future<McpToolManager?> loadToolManagerForTest() => _loadToolManager();

  bool _supportsTools(String apiType) {
    return ChatCompletionsProfiles.forType(apiType) != null ||
        ResponsesToolProfiles.supports(apiType) ||
        apiType == 'claude' ||
        apiType == 'gemini';
  }

  /// 合并内置工具与 MCP 工具，供工具调用路径使用。
  AIToolExecutor buildToolExecutor({
    required bool timeEnabled,
    required bool calculatorEnabled,
    required bool textToolsEnabled,
    required bool dateMathEnabled,
    required bool unitConvertEnabled,
    required bool lunarCalendarEnabled,
    bool userProfileEnabled = true,
    AttachmentToolContext? attachmentContext,
    McpToolManager? manager,
    MemoryNoteSink? memoryNoteSink,
    MemoryRecallHandler? memoryRecallHandler,
  }) {
    return CompositeToolExecutor([
      if (timeEnabled) BuiltInTimeTool(),
      if (calculatorEnabled) BuiltInCalculatorTool(),
      if (textToolsEnabled) ...[
        BuiltInTextCompareTool(),
        BuiltInTextStatsTool(),
      ],
      if (dateMathEnabled) BuiltInDateMathTool(),
      if (unitConvertEnabled) BuiltInUnitConvertTool(),
      if (lunarCalendarEnabled) BuiltInLunarCalendarTool(),
      if (userProfileEnabled) BuiltInUserProfileTool(),
      if (attachmentContext != null)
        BuiltInReadAttachmentTool(context: attachmentContext),
      if (memoryNoteSink != null) MemoryNoteTool(sink: memoryNoteSink),
      if (memoryRecallHandler != null)
        MemoryRecallTool(handler: memoryRecallHandler),
      ?manager,
    ]);
  }

  Future<McpToolManager?> _loadToolManager() {
    if (_disposed) return Future.value(null);

    final existing = _toolManagerLoad;
    if (existing != null) return existing;

    final future = _loadToolManagerInternal();
    _toolManagerLoad = future;
    future.then<void>(
      (_) {
        if (identical(_toolManagerLoad, future)) {
          _toolManagerLoad = null;
        }
      },
      onError: (Object error, StackTrace stackTrace) {
        if (identical(_toolManagerLoad, future)) {
          _toolManagerLoad = null;
        }
      },
    );
    return future;
  }

  Future<McpToolManager?> _loadToolManagerInternal() async {
    final servers = (await _settingsService.getMcpServers())
        .where((server) => server.enabled)
        .toList();

    if (servers.isEmpty) {
      await _toolManager?.dispose();
      _toolManager = null;
      _toolManagerSignature = null;
      _lastToolRefresh = null;
      return null;
    }

    final signature = jsonEncode(
      servers.map((server) => server.toJson()).toList(),
    );
    final now = DateTime.now();

    if (_toolManager != null && _toolManagerSignature == signature) {
      final manager = _toolManager!;
      final shouldRetry = manager.tools.isEmpty || manager.errors.isNotEmpty;
      final due =
          _lastToolRefresh == null ||
          now.difference(_lastToolRefresh!) >= toolRefreshInterval;

      if (!shouldRetry || !due) {
        return manager;
      }

      await manager.refresh();
      _lastToolRefresh = DateTime.now();
      if (_disposed) {
        await manager.dispose();
        _toolManager = null;
        _toolManagerSignature = null;
        return null;
      }
      return manager;
    }

    await _toolManager?.dispose();
    final manager =
        _toolManagerFactory?.call(servers) ??
        McpToolManager(
          servers: servers,
          connectionFactory: (config) => McpClient(config: config),
          timeout: const Duration(seconds: 8),
        );
    await manager.refresh();
    _lastToolRefresh = DateTime.now();

    if (_disposed) {
      await manager.dispose();
      return null;
    }

    _toolManager = manager;
    _toolManagerSignature = signature;
    return manager;
  }

  /// 释放 MCP 连接。
  Future<void> dispose() async {
    _disposed = true;
    _toolManagerLoad = null;
    await _toolManager?.dispose();
    _toolManager = null;
    _toolManagerSignature = null;
    _lastToolRefresh = null;
  }

  /// 构建完整的系统提示词
  ///
  /// 按“基础规则 → 自定义提示 → 角色预设”的顺序拼接。角色预设保留在最后，
  /// 因此它可以覆盖角色身份与文风，但不会丢掉用户的全局自定义要求。
  static const String _memoryNoteInstruction =
      'You can call the remember_note tool to save durable agreements, rules, '
      'critical facts, important emotional turning points, or rejected '
      'proposals as soon as they happen. Use it sparingly; never record small '
      'talk.';

  static const String _memoryRecallInstruction =
      'When the user asks about a specific earlier detail, exact wording, or a '
      'prior agreement that is not in your current context, call the recall '
      'tool before answering. If it returns no matches, say you cannot find '
      'it; do not invent.';

  Future<String> _buildSystemPrompt(
    String presetSystemPrompt,
    AppLocalizations l10n, {
    String worldInfoBlock = '',
    String memoryBlock = '',
    bool memoryNoteEnabled = false,
    bool memoryRecallEnabled = false,
  }) async {
    final customSystemPrompt = await _settingsService.getCustomSystemPrompt();

    // 使用本地化的基础系统提示词，并追加独立的回复语言规则。
    final languageRule = await _buildReplyLanguageRule(l10n);
    final baseSystemPrompt = '${l10n.baseSystemPrompt}\n$languageRule';

    final stablePrefix = composeSystemPrompt(
      basePrompt: baseSystemPrompt,
      customPrompt: customSystemPrompt,
      presetPrompt: presetSystemPrompt,
      noteInstruction: memoryNoteEnabled ? _memoryNoteInstruction : '',
      recallInstruction: memoryRecallEnabled ? _memoryRecallInstruction : '',
    );

    // 记忆放最后：更靠近对话、演变状态压过静态人设，并保留稳定前缀缓存。
    final fullSystemPrompt = composeSystemPrompt(
      basePrompt: stablePrefix,
      customPrompt: '',
      presetPrompt: '',
      worldInfoBlock: worldInfoBlock,
      memoryBlock: memoryBlock,
    );

    if (kDebugMode) {
      // 记忆会按轮变化；这里只对稳定前缀做哈希，用于观察缓存是否被污染。
      debugPrint(
        'System prompt prefix sha256: '
        '${sha256.convert(utf8.encode(stablePrefix))}',
      );
    }
    return fullSystemPrompt;
  }

  @visibleForTesting
  Future<String> buildSystemPromptForTest(
    String presetSystemPrompt,
    AppLocalizations l10n, {
    String worldInfoBlock = '',
    String memoryBlock = '',
    bool memoryNoteEnabled = false,
    bool memoryRecallEnabled = false,
  }) {
    return _buildSystemPrompt(
      presetSystemPrompt,
      l10n,
      worldInfoBlock: worldInfoBlock,
      memoryBlock: memoryBlock,
      memoryNoteEnabled: memoryNoteEnabled,
      memoryRecallEnabled: memoryRecallEnabled,
    );
  }

  Future<String> _buildReplyLanguageRule(AppLocalizations l10n) async {
    final setting = await _settingsService.getReplyLanguage();
    if (setting == 'follow_user') {
      return l10n.baseSystemPromptFollowUser;
    }

    final code = setting == SettingsService.defaultReplyLanguage
        ? l10n.localeName
        : setting;
    final languageName = switch (code) {
      'zh' => l10n.languageNameZh,
      'en' => l10n.languageNameEn,
      'ja' => l10n.languageNameJa,
      'ko' => l10n.languageNameKo,
      'es' => l10n.languageNameEs,
      'lzh' => l10n.languageNameLzh,
      _ => l10n.languageNameZh,
    };
    return l10n.baseSystemPromptLanguageRule(languageName);
  }

  /// 发送消息到AI模型（同步方式）
  ///
  /// 参数:
  ///   message - 用户输入的文本消息
  ///   chatHistory - 聊天历史记录（用于上下文）
  ///   attachments - 附件列表（可选，默认为空）
  ///   thinkingMode - 是否启用思考模式
  ///   presetSystemPrompt - 预设系统提示词
  ///   l10n - 国际化对象
  /// 返回值:
  ///   返回一个`Map<String, dynamic>`，包含AI模型的响应
  ///   - 'reasoningContent': 思考过程内容（如果有）
  ///   - 'content': 最终回答内容
  /// 异常:
  ///   抛出Exception当API密钥未配置或网络请求失败时
  Future<Map<String, dynamic>> sendMessage(
    String message,
    List<Message> chatHistory, {
    List<Attachment> attachments = const [],
    bool thinkingMode = false,
    String presetSystemPrompt = '',
    String memoryBlock = '',
    required AppLocalizations l10n,
  }) async {
    final apiKey = await _settingsService.getApiKey();
    if (apiKey.isEmpty) {
      throw Exception(l10n.configureApiKeyFirst);
    }

    final provider = await _getProvider();
    final temperature = await _settingsService.getTemperature();
    final maxTokens = await _settingsService.getMaxTokens();
    final systemPrompt = await _buildSystemPrompt(
      presetSystemPrompt,
      l10n,
      memoryBlock: memoryBlock,
    );
    final addTimeToPrompt = await _settingsService.getAddTimeToPrompt();

    // 根据设置决定是否添加当前时间信息到用户消息
    final messageToSend = addTimeToPrompt
        ? '$message\n\n${l10n.currentTime}${TimeUtils.now()}'
        : message;

    try {
      return await provider.sendMessage(
        message: messageToSend,
        chatHistory: chatHistory,
        attachments: attachments,
        systemPrompt: systemPrompt,
        temperature: temperature,
        maxTokens: maxTokens,
        thinkingMode: thinkingMode,
        l10n: l10n,
      );
    } catch (e) {
      throw _handleError(e, l10n);
    }
  }

  /// 生成一次记忆更新结果。
  ///
  /// 使用当前激活平台的非流式接口。待总结的消息块由调用方序列化进
  /// [userPrompt]，[chatHistory] 故意传空，避免被 provider 的
  /// `historyContextLength` 二次截断。
  Future<String> generateMemoryUpdate({
    required String systemPrompt,
    required String userPrompt,
    required AppLocalizations l10n,
  }) async {
    final apiKey = await _settingsService.getApiKey();
    if (apiKey.isEmpty) {
      throw Exception(l10n.configureApiKeyFirst);
    }

    final provider = await _getProvider();
    try {
      final response = await provider.sendMessage(
        message: userPrompt,
        chatHistory: const [],
        attachments: const [],
        systemPrompt: systemPrompt,
        temperature: MemoryPolicy.updateTemperature,
        maxTokens: MemoryPolicy.maxUpdateTokens,
        thinkingMode: false,
        l10n: l10n,
      );
      return (response['content'] as String? ?? '').trim();
    } catch (e) {
      throw _handleError(e, l10n);
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
  ///   l10n - 国际化对象
  /// 返回值:
  ///   返回一个`Stream<Map<String, dynamic>>`，实时输出AI模型的响应片段
  ///   Map包含 'type' 和 'content' 字段，type可以是 'reasoning' 或 'answer'
  /// 异常:
  ///   抛出Exception当API密钥未配置或网络请求失败时
  Stream<Map<String, dynamic>> sendMessageStreaming(
    String message,
    List<Message> chatHistory, {
    List<Attachment> attachments = const [],
    bool thinkingMode = false,
    String presetSystemPrompt = '',
    String worldInfoBlock = '',
    String memoryBlock = '',
    MemoryNoteSink? memoryNoteSink,
    MemoryRecallHandler? memoryRecallHandler,
    required AppLocalizations l10n,
  }) async* {
    final apiKey = await _settingsService.getApiKey();
    if (apiKey.isEmpty) {
      throw Exception(l10n.configureApiKeyFirst);
    }

    final temperature = await _settingsService.getTemperature();
    final maxTokens = await _settingsService.getMaxTokens();
    final systemPrompt = await _buildSystemPrompt(
      presetSystemPrompt,
      l10n,
      worldInfoBlock: worldInfoBlock,
      memoryBlock: memoryBlock,
      memoryNoteEnabled: memoryNoteSink != null,
      memoryRecallEnabled: memoryRecallHandler != null,
    );
    final addTimeToPrompt = await _settingsService.getAddTimeToPrompt();

    try {
      final config = await _settingsService.getActivePlatformConfig();
      final attachmentContext = AttachmentToolContext.fromTextAttachments(
        attachments,
      );
      if ((attachments.isEmpty || attachmentContext != null) &&
          _supportsTools(config.apiType)) {
        final servers = await _settingsService.getMcpServers();
        if (servers.any((server) => server.enabled)) {
          yield {'type': 'tool_status', 'message': '正在发现 MCP 工具...'};
        }

        final manager = await _loadToolManager();
        if (manager != null && manager.errors.isNotEmpty) {
          yield {
            'type': 'tool_status',
            'message': '部分 MCP 服务器连接失败: ${manager.errors.values.join('; ')}',
          };
        } else if (manager != null && manager.tools.isEmpty) {
          yield {'type': 'tool_status', 'message': 'MCP 服务器没有可用工具'};
        }

        final calculatorEnabled = await _settingsService
            .getBuiltinCalculatorEnabled();
        final textToolsEnabled = await _settingsService
            .getBuiltinTextToolsEnabled();
        final dateMathEnabled = await _settingsService
            .getBuiltinDateMathEnabled();
        final unitConvertEnabled = await _settingsService
            .getBuiltinUnitConvertEnabled();
        final lunarCalendarEnabled = await _settingsService
            .getBuiltinLunarCalendarEnabled();
        final userProfileEnabled = await _settingsService
            .getBuiltinUserProfileEnabled();
        final executor = buildToolExecutor(
          timeEnabled: addTimeToPrompt,
          calculatorEnabled: calculatorEnabled,
          textToolsEnabled: textToolsEnabled,
          dateMathEnabled: dateMathEnabled,
          unitConvertEnabled: unitConvertEnabled,
          lunarCalendarEnabled: lunarCalendarEnabled,
          userProfileEnabled: userProfileEnabled,
          attachmentContext: attachmentContext,
          manager: manager,
          memoryNoteSink: memoryNoteSink,
          memoryRecallHandler: memoryRecallHandler,
        );
        if (executor.tools.isNotEmpty) {
          final enableHistory = await _settingsService.getEnableHistory();
          final historyContextLength = await _settingsService
              .getHistoryContextLength();
          final toolService =
              _toolChatServiceFactory?.call(executor) ??
              ToolChatService(executor: executor);
          final toolMessage = attachmentContext == null
              ? message
              : message.trim().isEmpty
                  ? attachmentContext.manifest
                  : '$message\n\n${attachmentContext.manifest}';
          yield* toolService.run(
            config: config,
            // 时间由内置工具提供，工具路径不再把时间拼进用户消息。
            message: toolMessage,
            history: chatHistory,
            systemPrompt: systemPrompt,
            temperature: temperature,
            maxTokens: maxTokens,
            thinkingMode: thinkingMode,
            enableHistory: enableHistory,
            historyContextLength: historyContextLength,
          );
          return;
        }
      }

      // 工具调用不可用时（非文本附件或不支持工具的模型）保留提示词时间兜底。
      final messageToSend = addTimeToPrompt
          ? '$message\n\n${l10n.currentTime}${TimeUtils.now()}'
          : message;

      final provider = await _getProvider();
      yield* provider.sendMessageStreaming(
        message: messageToSend,
        chatHistory: chatHistory,
        attachments: attachments,
        systemPrompt: systemPrompt,
        temperature: temperature,
        maxTokens: maxTokens,
        thinkingMode: thinkingMode,
        l10n: l10n,
      );
    } catch (e) {
      throw _handleError(e, l10n);
    }
  }

  /// 生成对话标题
  ///
  /// 参数:
  ///   messages - 对话消息列表
  ///   l10n - 国际化对象
  /// 返回值:
  ///   生成的对话标题（简短摘要）
  /// 异常:
  ///   抛出Exception当API密钥未配置或网络请求失败时
  Future<String> generateConversationTitle(
    List<Message> messages, {
    required AppLocalizations l10n,
  }) async {
    final apiKey = await _settingsService.getApiKey();
    if (apiKey.isEmpty) {
      throw Exception(l10n.configureApiKeyFirst);
    }

    final provider = await _getProvider();

    try {
      return await provider.generateConversationTitle(messages, l10n: l10n);
    } catch (e) {
      throw _handleError(e, l10n);
    }
  }

  /// 统一错误处理
  ///
  /// 将各种错误转换为用户友好的异常消息
  Exception _handleError(dynamic e, AppLocalizations l10n) {
    if (e is AIError) {
      switch (e.type) {
        case AIErrorType.authentication:
          return Exception(l10n.configureApiKeyFirst);
        case AIErrorType.timeout:
          return Exception(l10n.requestTimeout(e.message));
        case AIErrorType.network:
          return Exception(l10n.networkConnectionFailed(e.message));
        case AIErrorType.rateLimit:
        case AIErrorType.server:
          return Exception(
            l10n.providerApiError(
              e.message,
              e.statusCode ?? (e.type == AIErrorType.rateLimit ? 429 : 500),
            ),
          );
        case AIErrorType.invalidResponse:
          return Exception(l10n.providerInvalidResponseFormat);
        case AIErrorType.unsupported:
        case AIErrorType.cancelled:
          return Exception(e.message);
      }
    }

    // 如果已经是 API 错误，直接重新抛出
    if (e.toString().contains('API错误: ') ||
        e.toString().contains('API Error: ') ||
        e.toString().contains('Gemini API错误: ') ||
        e.toString().contains('Gemini API Error: ')) {
      return e as Exception;
    }

    // 根据错误类型提供更详细的错误信息
    final errorMsg = e.toString();
    if (errorMsg.contains('timeout') || errorMsg.contains('Timeout')) {
      return Exception(l10n.requestTimeout(e.toString()));
    } else if (errorMsg.contains('socket') || errorMsg.contains('Socket')) {
      return Exception(l10n.networkConnectionFailed(e.toString()));
    } else if (errorMsg.contains('handshake') ||
        errorMsg.contains('TLS') ||
        errorMsg.contains('SSL')) {
      return Exception(l10n.securityConnectionFailed(e.toString()));
    } else if (errorMsg.contains('Connection') ||
        errorMsg.contains('connection')) {
      return Exception(l10n.connectionError(e.toString()));
    } else if (errorMsg.contains('Http') || errorMsg.contains('http')) {
      return Exception(l10n.httpProtocolError(e.toString()));
    } else if (e is Exception) {
      return e;
    } else {
      return Exception(l10n.networkCommunicationFailed(e.toString()));
    }
  }
}

/// 把 [AIService] 适配成 [MemoryService] 需要的最小客户端。
class AIServiceMemoryUpdateClient implements MemoryUpdateClient {
  AIServiceMemoryUpdateClient(this._aiService, this._l10n);

  final AIService _aiService;
  final AppLocalizations _l10n;

  @override
  Future<String> generateMemoryUpdate({
    required String systemPrompt,
    required String userPrompt,
  }) {
    return _aiService.generateMemoryUpdate(
      systemPrompt: systemPrompt,
      userPrompt: userPrompt,
      l10n: _l10n,
    );
  }
}
