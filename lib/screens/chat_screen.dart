import 'package:cupertino_ui/cupertino_ui.dart';
import 'package:flutter/rendering.dart' show ScrollCacheExtent;

import 'dart:io';
import 'dart:async';

import '../ai/tools/builtin_memory_recall_tool.dart';
import '../controllers/chat_send_controller.dart';
import '../controllers/chat_screen_controller.dart';
import '../l10n/app_localizations.dart';
import '../models/message.dart';
import '../models/attachment.dart';
import '../models/conversation.dart';
import '../models/memory_note.dart';
import '../models/prompt_preset.dart';
import '../models/user_profile.dart';
import '../services/ai_service.dart';
import '../services/conversation_memory_store.dart';
import '../services/conversation_service.dart';
import '../services/memory_recall.dart';
import '../services/memory_service.dart';
import '../services/settings_service.dart';
import '../services/notification_service.dart';
import '../services/live_update_service.dart';
import '../services/preset_repository.dart';
import '../services/user_service.dart';
import '../utils/app_theme.dart';
import '../widgets/message_bubble.dart';
import '../widgets/chat_input.dart';
import '../widgets/preset_unavailable_dialog.dart';
import 'settings_screen.dart';
import 'conversation_list_screen.dart';
import 'memory_viewer_screen.dart';
import 'message_search_screen.dart';

/// 主聊天界面，用户与AI进行交互的核心屏幕
///
/// 功能特性:
/// - 显示对话消息列表
/// - 处理用户输入和文件附件
/// - 调用AI服务获取响应
/// - 管理对话历史记录
/// - 支持流式输出显示
/// - 提供设置和对话管理功能
///
/// 设计模式:
/// 使用StatefulWidget管理本地状态，包括消息列表、加载状态、当前对话等
class ChatScreen extends StatefulWidget {
  const ChatScreen({
    super.key,
    this.embedded = false,
    this.controller,
    this.onConversationChanged,
    this.onConversationListChanged,
    this.onOpenSettings,
    this.conversationService,
  });

  /// 桌面嵌入模式：不渲染移动端导航栏。
  final bool embedded;
  final ChatScreenController? controller;
  final ValueChanged<String?>? onConversationChanged;
  final VoidCallback? onConversationListChanged;
  final VoidCallback? onOpenSettings;

  /// 测试注入；生产环境使用默认单例。
  final ConversationService? conversationService;

  @override
  State<ChatScreen> createState() => _ChatScreenState();
}

/// ChatScreen的状态类，管理界面的所有状态和业务逻辑
///
/// 状态变量:
/// - _messages: 当前对话的消息列表
/// - _isLoading: 是否正在加载AI响应
/// - _isConfigured: 应用是否已完成配置（API密钥等）
/// - _currentConversation: 当前对话对象
/// - _currentTitle: 当前对话标题
///
/// 服务实例:
/// - _aiService: AI服务，处理与AI模型的通信
/// - _conversationService: 对话服务，管理对话的CRUD操作
/// - _settingsService: 设置服务，读取应用配置
class _ChatScreenState extends State<ChatScreen> with WidgetsBindingObserver {
  final List<Message> _messages = [];
  final ScrollController _scrollController = ScrollController();
  final Map<String, GlobalKey> _messageKeys = {};
  final AIService _aiService = AIService();
  late final ConversationService _conversationService;
  final SettingsService _settingsService = SettingsService();
  final NotificationService _notificationService = NotificationService();
  final LiveUpdateService _liveUpdateService = LiveUpdateService();
  final PresetRepository _presetRepository = PresetRepository.instance;
  final UserService _userService = UserService();

  bool _isLoading = false;
  bool _isConfigured = false;
  bool _thinkingMode = false;
  bool _liveUpdateEnabled = true;
  bool _promptPresetEnabled = false;
  String _currentPresetId = '';
  Conversation? _currentConversation;
  String _currentTitle = '';
  bool _autoTitleGenerated = false; // 是否已经自动生成过标题
  String _currentModel = ''; // 当前选中的模型
  UserProfile? _userProfile; // 全局用户信息，预加载避免每个气泡重复加载

  // 聊天背景设置
  String _backgroundImagePath = SettingsService.defaultBackgroundImagePath;
  double _backgroundImageOpacity =
      SettingsService.defaultBackgroundImageOpacity;

  Timer? _setStateTimer; // 批量setState定时器
  bool _pendingStateUpdate = false; // 是否有待处理的state更新
  bool _isUserScrolling = false; // 用户是否正在手动滚动
  VoidCallback? _scrollListener; // 滚动监听器

  // AI生成控制相关变量
  ChatSendController? _sendController; // 当前流式发送的编排器
  String? _memoryStatus; // 当前记忆整理状态
  bool _isGenerating = false; // 是否正在生成AI回复
  bool _isPreparingSend = false; // 防止记忆整理期间重复发送
  int _memoryNoteCounter = 0; // 主动记忆便签的本地序号

  // 对话加载控制
  bool _isLoadingConversation = false; // 防止重复加载对话

  @override
  void initState() {
    super.initState();
    _conversationService = widget.conversationService ?? ConversationService();
    // 添加生命周期观察者
    WidgetsBinding.instance.addObserver(this);
    _presetRepository.addListener(_onPresetsChanged);

    widget.controller?.attach(
      openConversation: _setCurrentConversation,
      createNewConversation: _createNewConversation,
      refreshConfiguration: () => unawaited(_checkConfiguration()),
    );

    // 监听用户滚动状态
    _scrollListener = () {
      _isUserScrolling = _scrollController.position.isScrollingNotifier.value;
    };
    _scrollController.addListener(_scrollListener!);

    /// 初始化状态
    /// 1. 检查API配置是否完成
    /// 2. 加载最近使用的对话或创建新对话
    _initializeApp();
  }

  /// 初始化应用：检查配置并加载当前对话
  Future<void> _initializeApp() async {
    await _checkConfiguration();

    // 恢复上次会话；没有历史时才等用户发送第一条消息再创建，
    // 避免启动或打开列表时凭空多出一条「新对话」。
    final conversationId = await _conversationService
        .resolveConversationForStartup();
    if (conversationId != null) {
      await _setCurrentConversation(conversationId);
    }
  }

  /// 预设仓库（导入、删除、语言切换）更新后刷新角色胶囊和选择列表。
  void _onPresetsChanged() {
    if (mounted) {
      setState(() {});
    }
  }

  List<PromptPreset> get _presets => _presetRepository.presets;

  @override
  void dispose() {
    _presetRepository.removeListener(_onPresetsChanged);
    widget.controller?.detach();
    // 取消所有定时器
    _setStateTimer?.cancel();
    // 释放发送控制器
    final controller = _sendController;
    if (controller != null) {
      unawaited(controller.dispose());
    }
    _sendController = null;
    unawaited(_aiService.dispose());
    // 移除滚动监听器
    if (_scrollListener != null) {
      _scrollController.removeListener(_scrollListener!);
      _scrollListener = null;
    }
    // 移除生命周期观察者
    WidgetsBinding.instance.removeObserver(this);
    super.dispose();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    super.didChangeAppLifecycleState(state);
    // 监听应用前后台状态变化
    switch (state) {
      case AppLifecycleState.resumed:
        // 应用回到前台
        _notificationService.setAppForegroundState(true);
        break;
      case AppLifecycleState.paused:
      case AppLifecycleState.inactive:
      case AppLifecycleState.detached:
      case AppLifecycleState.hidden:
        // 应用进入后台或隐藏
        _notificationService.setAppForegroundState(false);
        break;
    }
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    // 只处理依赖变化（Theme / Provider / Locale），不重建业务数据
    _loadCurrentModel();
    _loadBackgroundSettings();
    // 语言变化时仓库会自动重新加载预设。
    unawaited(_presetRepository.ensureLoaded());
  }

  /// 检查应用配置状态
  ///
  /// 调用设置服务检查API密钥等必要配置是否已设置
  /// 更新_isConfigured状态变量，控制界面显示和交互
  /// 同时预加载用户头像，避免每个消息气泡重复加载
  Future<void> _checkConfiguration() async {
    final configured = await _settingsService.isConfigured();
    final liveUpdateEnabled = await _settingsService.getLiveUpdateEnabled();
    await _presetRepository.ensureLoaded();
    // 预加载用户头像，避免每个消息气泡重复加载
    final userProfile = await _userService.getUserProfile();
    // 加载聊天背景设置
    final backgroundImagePath = await _settingsService.getBackgroundImagePath();
    final backgroundImageOpacity = await _settingsService
        .getBackgroundImageOpacity();
    if (!mounted) return;
    setState(() {
      _isConfigured = configured;
      _liveUpdateEnabled = liveUpdateEnabled;
      _userProfile = userProfile;
      _backgroundImagePath = backgroundImagePath;
      _backgroundImageOpacity = backgroundImageOpacity;
    });

    // 加载当前模型
    await _loadCurrentModel();
  }

  /// 设置当前对话（统一的对话加载入口）
  ///
  /// 根据对话ID从数据库加载完整对话（包含消息），更新界面状态
  /// 这是所有对话切换操作的唯一入口点
  Future<void> _setCurrentConversation(String conversationId) async {
    // 防止重复加载对话
    if (_isLoadingConversation) {
      return;
    }

    // 如果已经是当前对话，且对话不为空，则跳过加载
    if (_currentConversation?.id == conversationId && _messages.isNotEmpty) {
      return;
    }

    // 切换对话前先停止并持久化当前生成，避免加载时丢弃半成品 AI 消息
    final activeController = _sendController;
    if (activeController != null &&
        activeController.isActive &&
        _currentConversation?.id != conversationId) {
      await activeController.stop();
    }

    if (!mounted) return;
    _isLoadingConversation = true;

    try {
      final l10n = AppLocalizations.of(context)!;
      final fullConversation = await _conversationService.getConversationById(
        conversationId,
      );

      if (!mounted || fullConversation == null) {
        return;
      }

      // 清理不完整的消息：将状态为sending的AI消息标记为error
      final processedMessages = <Message>[];
      for (final message in fullConversation.messages) {
        if (!message.isUser && message.status == MessageStatus.sending) {
          // 如果AI消息处于sending状态，说明上次会话可能异常中断
          // 如果消息内容为空，完全删除该消息；否则标记为error并保留已有内容
          if (message.content.isEmpty) {
            // 内容为空，完全删除
            continue;
          } else {
            // 有部分内容，标记为error并添加提示
            processedMessages.add(
              message.copyWith(
                status: MessageStatus.error,
                content: '${message.content}\n\n[${l10n.responseInterrupted}]',
              ),
            );
          }
        } else {
          processedMessages.add(message);
        }
      }

      setState(() {
        _currentConversation = fullConversation;
        _messages
          ..clear()
          ..addAll(processedMessages);
        _messageKeys.clear();
        _currentTitle = fullConversation.title;
        _thinkingMode = fullConversation.thinkingMode;
        _promptPresetEnabled = fullConversation.promptPresetEnabled;
        _currentPresetId = fullConversation.promptPresetId;
        _autoTitleGenerated = false; // 重置标题生成标志
      });

      // 保存处理后的对话，确保状态更新持久化
      if (processedMessages.length != fullConversation.messages.length) {
        await _conversationService.updateConversation(
          fullConversation.copyWith(messages: processedMessages),
        );
      }

      await _conversationService.setCurrentConversationId(fullConversation.id);
      widget.onConversationChanged?.call(fullConversation.id);
      _scrollToBottom();
    } finally {
      _isLoadingConversation = false;
    }
  }

  /// 创建新的对话
  ///
  /// 调用对话服务创建新的对话对象
  /// 重置消息列表和对话标题，更新状态
  Future<void> _createNewConversation() async {
    final l10n = AppLocalizations.of(context)!;
    final conversation = await _conversationService.createNewConversation(
      title: l10n.newConversation,
    );
    if (!mounted) return;
    setState(() {
      _currentConversation = conversation;
      _messages.clear();
      _messageKeys.clear();
      _currentTitle = conversation.title;
      _thinkingMode = conversation.thinkingMode;
      _promptPresetEnabled = conversation.promptPresetEnabled;
      _currentPresetId = conversation.promptPresetId;
      _autoTitleGenerated = false; // 重置标题生成标志
    });
    widget.onConversationChanged?.call(conversation.id);
  }

  /// 保存当前对话
  ///
  /// 将当前消息列表和更新时间保存到对话对象中
  /// 调用对话服务更新数据库中的对话记录
  Future<void> _saveCurrentConversation() async {
    if (_currentConversation != null) {
      final updatedConversation = _currentConversation!.copyWith(
        messages: List.from(_messages),
        updatedAt: DateTime.now(),
      );
      await _conversationService.updateConversation(updatedConversation);
      if (!mounted) return;
      setState(() {
        _currentConversation = updatedConversation;
      });
      widget.onConversationListChanged?.call();
    }
  }

  /// 批量setState（流式输出期间使用）
  ///
  /// 使用定时器合并多个setState调用，减少UI重绘次数
  /// 每100ms最多触发一次setState，提高流式输出时的流畅度
  void _batchedSetState(VoidCallback fn) {
    fn(); // 先执行函数更新数据
    if (!_pendingStateUpdate) {
      _pendingStateUpdate = true;
      _setStateTimer = Timer(const Duration(milliseconds: 100), () {
        if (mounted) {
          setState(() {}); // 触发一次UI更新
        }
        _pendingStateUpdate = false;
      });
    }
  }

  /// 滚动消息列表到底部
  ///
  /// 使用ScrollController滚动到最大滚动位置
  /// 添加平滑动画效果（300毫秒，easeOut曲线）
  /// 如果用户正在手动滚动，则跳过自动滚动
  void _scrollToBottom() {
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (_scrollController.hasClients && !_isUserScrolling) {
        _scrollController.animateTo(
          _scrollController.position.maxScrollExtent,
          duration: const Duration(milliseconds: 300),
          curve: Curves.easeOut,
        );
      }
    });
  }

  Future<void> _openMessageSearch() async {
    final messageId = await Navigator.push<String>(
      context,
      CupertinoPageRoute(
        builder: (context) =>
            MessageSearchScreen(messages: List<Message>.from(_messages)),
      ),
    );

    if (messageId != null && mounted) {
      await _scrollToMessage(messageId);
    }
  }

  /// 搜索页返回后定位到目标消息。ListView 是懒构建的，先按索引估算滚动，
  /// 等目标气泡进入构建范围后再用 ensureVisible 精确对齐。
  Future<void> _scrollToMessage(String messageId) async {
    final index = _messages.indexWhere((message) => message.id == messageId);
    if (index == -1) return;

    final key = _messageKeys.putIfAbsent(messageId, () => GlobalKey());
    for (var attempt = 0; attempt < 12; attempt++) {
      if (!mounted) return;

      final targetContext = key.currentContext;
      if (targetContext != null && targetContext.mounted) {
        await Scrollable.ensureVisible(
          targetContext,
          alignment: 0.3,
          duration: const Duration(milliseconds: 300),
          curve: Curves.easeOut,
        );
        return;
      }

      if (!_scrollController.hasClients) {
        await Future<void>.delayed(const Duration(milliseconds: 80));
        continue;
      }

      final position = _scrollController.position;
      if (position.maxScrollExtent <= 0) {
        await Future<void>.delayed(const Duration(milliseconds: 80));
        continue;
      }

      // Find the messages that ListView has actually built, then move toward
      // the target instead of repeatedly jumping to the same estimate.
      var firstBuilt = -1;
      var lastBuilt = -1;
      for (var i = 0; i < _messages.length; i++) {
        if (_messageKeys[_messages[i].id]?.currentContext != null) {
          if (firstBuilt == -1) firstBuilt = i;
          lastBuilt = i;
        }
      }

      double target;
      if (firstBuilt != -1 && index > lastBuilt) {
        target = position.pixels + position.viewportDimension * 0.8;
      } else if (firstBuilt != -1 && index < firstBuilt) {
        target = position.pixels - position.viewportDimension * 0.8;
      } else {
        final fraction = _messages.length <= 1
            ? 0.0
            : index / (_messages.length - 1);
        target = position.maxScrollExtent * fraction;
      }

      await _scrollController.animateTo(
        target.clamp(0.0, position.maxScrollExtent),
        duration: const Duration(milliseconds: 200),
        curve: Curves.easeOut,
      );
      await Future<void>.delayed(const Duration(milliseconds: 80));
    }
  }

  /// 处理用户选择的附件
  ///
  /// 参数:
  ///   attachments - 用户选择的附件列表
  /// 说明:
  ///   附件已由ChatInput组件管理，此处无需处理
  Future<void> _handleAttachmentsSelected(List<Attachment> attachments) async {
    // 附件已由ChatInput组件管理，此处无需处理
    // 保留此方法以保持回调兼容性
  }

  /// 处理思考模式开关变化
  ///
  /// 参数:
  ///   enabled - 思考模式是否启用
  /// 说明:
  ///   思考模式属于当前会话，切换会话时各自恢复。
  void _handleThinkingModeChanged(bool enabled) {
    setState(() {
      _thinkingMode = enabled;
    });
    _saveConversationPreferences();
  }

  /// 处理预设提示词模式开关变化
  void _handlePromptPresetEnabledChanged(bool enabled) {
    setState(() {
      _promptPresetEnabled = enabled;
      if (!enabled) {
        _currentPresetId = '';
      }
    });
    _saveConversationPreferences();
  }

  /// 处理预设选择变化
  void _handlePresetSelected(String presetId) {
    setState(() {
      _currentPresetId = presetId;
      _promptPresetEnabled = true;
    });
    _saveConversationPreferences();
  }

  PromptPreset? _findPresetById(String id) {
    for (final preset in _presets) {
      if (preset.id == id) return preset;
    }
    return null;
  }

  /// 当前会话已启用角色模式，但预设不存在或角色卡文件不可用。
  bool get _isCurrentPresetUnavailable {
    if (!_promptPresetEnabled || _currentPresetId.isEmpty) return false;
    final preset = _findPresetById(_currentPresetId);
    return preset == null || preset.isBroken;
  }

  /// 发送前确认：关闭不可用的角色模式继续发送，或取消。
  Future<bool> _confirmDisableUnavailablePreset() {
    final l10n = AppLocalizations.of(context)!;
    return showPresetUnavailableDialog(context, l10n);
  }

  /// 将思考模式与角色预设写回当前会话。
  void _saveConversationPreferences() {
    final conversation = _currentConversation;
    if (conversation == null) return;

    final updated = conversation.copyWith(
      thinkingMode: _thinkingMode,
      promptPresetEnabled: _promptPresetEnabled,
      promptPresetId: _currentPresetId,
    );
    _currentConversation = updated;
    unawaited(
      _conversationService.updateConversationPreferences(
        updated.id,
        thinkingMode: updated.thinkingMode,
        promptPresetEnabled: updated.promptPresetEnabled,
        promptPresetId: updated.promptPresetId,
      ),
    );
  }

  /// 自动生成对话标题
  ///
  /// 在对话达到指定轮次后，调用AI生成更准确的标题
  Future<void> _generateAutoTitle() async {
    // 检查是否启用自动标题生成
    final autoTitleEnabled = await _settingsService.getAutoTitleEnabled();
    if (!autoTitleEnabled) return;

    // 如果已经生成过标题，不再生成
    if (_autoTitleGenerated) return;

    // 获取配置的生成轮次
    final autoTitleRounds = await _settingsService.getAutoTitleRounds();

    // 计算实际对话轮次（用户消息数量）
    final userMessageCount = _messages.where((msg) => msg.isUser).length;

    // 检查是否达到生成轮次
    if (userMessageCount >= autoTitleRounds) {
      try {
        if (!mounted) return;
        final l10n = AppLocalizations.of(context)!;
        // 调用AI服务生成标题
        final newTitle = await _aiService.generateConversationTitle(
          _messages,
          l10n: l10n,
        );

        // 更新对话标题
        if (_currentConversation != null && newTitle.isNotEmpty) {
          await _conversationService.updateConversationTitle(
            _currentConversation!.id,
            newTitle,
          );
          setState(() {
            _currentTitle = newTitle;
            _currentConversation = _currentConversation!.copyWith(
              title: newTitle,
            );
            _autoTitleGenerated = true; // 标记已生成
          });
          widget.onConversationListChanged?.call();
        }
      } catch (e) {
        // 生成标题失败不影响对话继续
      }
    }
  }

  /// 发送前补齐记忆，返回注入 system prompt 的 `<memory>` 块。
  Future<String> _ensureMemoryBlock({
    required String conversationId,
    required List<Message> history,
    required int historyRounds,
    required AppLocalizations l10n,
    bool roleplayMode = false,
    String characterName = '',
    String characterDescription = '',
  }) async {
    final store = ConversationMemoryStore(_conversationService);
    final service = MemoryService(
      store: store,
      client: AIServiceMemoryUpdateClient(_aiService, l10n),
      noteStore: store,
    );
    try {
      return await service.ensureUpToDate(
        conversationId: conversationId,
        eligibleMessages: history,
        historyRounds: historyRounds,
        roleplayMode: roleplayMode,
        characterName: characterName,
        characterDescription: characterDescription,
        onStatus: (stage, {current, total}) {
          _setMemoryStatus(conversationId, l10n, stage, current, total);
        },
      );
    } catch (_) {
      return '';
    } finally {
      if (mounted && _currentConversation?.id == conversationId) {
        setState(() {
          _memoryStatus = null;
        });
      }
    }
  }

  /// 回复完成后在后台提前整理记忆，正常情况不会阻塞下一次发送。
  Future<void> _updateMemoryInBackground({
    required String conversationId,
    required List<Message> messages,
    required AppLocalizations l10n,
    bool roleplayMode = false,
    String characterName = '',
    String characterDescription = '',
  }) async {
    final memoryEnabled = await _settingsService.getMemoryCompressionEnabled();
    final historyEnabled = await _settingsService.getEnableHistory();
    if (!memoryEnabled || !historyEnabled) return;

    final historyRounds = await _settingsService.getHistoryContextLength();
    final store = ConversationMemoryStore(_conversationService);
    final service = MemoryService(
      store: store,
      client: AIServiceMemoryUpdateClient(_aiService, l10n),
      noteStore: store,
    );
    try {
      await service.updateInBackground(
        conversationId: conversationId,
        eligibleMessages: messages,
        historyRounds: historyRounds,
        roleplayMode: roleplayMode,
        characterName: characterName,
        characterDescription: characterDescription,
        onStatus: (stage, {current, total}) {
          _setMemoryStatus(conversationId, l10n, stage, current, total);
        },
      );
    } catch (_) {
      // 记忆整理失败不影响对话。
    } finally {
      if (mounted && _currentConversation?.id == conversationId) {
        setState(() {
          _memoryStatus = null;
        });
      }
    }
  }

  void _setMemoryStatus(
    String conversationId,
    AppLocalizations l10n,
    MemoryStatusStage stage,
    int? current,
    int? total,
  ) {
    if (!mounted || _currentConversation?.id != conversationId) return;
    setState(() {
      _memoryStatus = switch (stage) {
        MemoryStatusStage.failed => l10n.memoryCompressionFailed,
        _ when current != null && total != null && total > 1 =>
          l10n.memoryCompressingProgress(current, total),
        _ => l10n.memoryCompressing,
      };
    });
  }

  String? _lastUserMessageId() {
    for (var i = _messages.length - 1; i >= 0; i--) {
      if (_messages[i].isUser) return _messages[i].id;
    }
    return null;
  }

  /// 对话模型调用 remember_note 时，立即把便签追加到当前会话。
  Future<void> _recordMemoryNote({
    required String conversationId,
    required String? sourceMessageId,
    required MemoryNoteDraft draft,
  }) async {
    final note = MemoryNote(
      id: 'note_${DateTime.now().microsecondsSinceEpoch}_${_memoryNoteCounter++}',
      conversationId: conversationId,
      kind: draft.kind,
      text: draft.text,
      quote: draft.quote,
      reason: draft.reason,
      sourceMessageId: sourceMessageId,
      createdAt: DateTime.now(),
    );
    await _conversationService.appendMemoryNote(note);
  }

  /// 发送消息到AI模型并处理响应
  ///
  /// 参数:
  ///   content - 用户输入的文本内容
  ///   attachments - 附件列表（可选）
  /// 流程:
  ///   1. 验证输入（非空文本或附件）
  ///   2. 检查应用配置状态
  ///   3. 创建用户消息对象并添加到消息列表
  ///   4. 如果是第一条消息，生成对话标题
  ///   5. 调用AI服务的流式接口获取响应
  ///   6. 实时更新AI消息内容（流式输出）
  ///   7. 处理完成和错误状态
  ///   8. 保存对话到本地存储
  Future<void> _sendMessage(
    String content, {
    List<Attachment> attachments = const [],
    bool skipUserMessage = false,
    Message? targetAiMessage,
    List<Message>? historyOverride,
    String initialAnswer = '',
    String initialReasoning = '',
  }) async {
    if (_isPreparingSend) return;
    _isPreparingSend = true;
    try {
      await _sendMessageInternal(
        content,
        attachments: attachments,
        skipUserMessage: skipUserMessage,
        targetAiMessage: targetAiMessage,
        historyOverride: historyOverride,
        initialAnswer: initialAnswer,
        initialReasoning: initialReasoning,
      );
    } finally {
      _isPreparingSend = false;
    }
  }

  Future<void> _sendMessageInternal(
    String content, {
    List<Attachment> attachments = const [],
    bool skipUserMessage = false,
    Message? targetAiMessage,
    List<Message>? historyOverride,
    String initialAnswer = '',
    String initialReasoning = '',
  }) async {
    final l10n = AppLocalizations.of(context)!;
    if (content.trim().isEmpty && attachments.isEmpty) return;

    if (!_isConfigured) {
      _showConfigurationDialog();
      return;
    }

    // 角色预设已被删除或角色卡文件缺失时，禁止把空预设静默发送出去。
    if (_isCurrentPresetUnavailable) {
      final disableAndSend = await _confirmDisableUnavailablePreset();
      if (!disableAndSend || !mounted) return;
      setState(() {
        _promptPresetEnabled = false;
        _currentPresetId = '';
      });
      _saveConversationPreferences();
    }

    if (_currentConversation == null) {
      await _createNewConversation();
    }

    final previousController = _sendController;
    if (previousController != null && previousController.isActive) {
      await previousController.stop();
    }

    // 获取预设提示词内容（如果预设模式启用）
    String presetSystemPrompt = '';
    if (_promptPresetEnabled && _currentPresetId.isNotEmpty) {
      final preset = _presets.firstWhere(
        (preset) => preset.id == _currentPresetId,
        orElse: () => PromptPreset(
          id: '',
          name: '',
          description: '',
          author: '',
          version: '',
          systemPrompt: '',
        ),
      );
      if (preset.id.isNotEmpty) {
        presetSystemPrompt = preset.systemPrompt;
      }
    }

    Message? userMessage;
    if (!skipUserMessage) {
      userMessage = Message(
        id: DateTime.now().millisecondsSinceEpoch.toString(),
        content: content,
        isUser: true,
        timestamp: DateTime.now(),
        attachments: attachments,
      );

      setState(() {
        _messages.add(userMessage!);
        _isLoading = true;
      });

      if (_messages.length == 1 && _currentConversation != null) {
        final newTitle = Conversation.generateTitle(content);
        await _conversationService.updateConversationTitle(
          _currentConversation!.id,
          newTitle,
        );
        setState(() {
          _currentTitle = newTitle;
          _currentConversation = _currentConversation!.copyWith(
            title: newTitle,
          );
        });
        widget.onConversationListChanged?.call();
      }
    } else {
      setState(() {
        _isLoading = true;
      });
    }

    _scrollToBottom();
    await _saveCurrentConversation();

    // 启动Android 16 Live Update通知（如果可用）
    if (Platform.isAndroid &&
        _liveUpdateService.isAvailable &&
        _liveUpdateEnabled) {
      await _liveUpdateService.startLiveUpdate(
        title: l10n.liveUpdateAIResponse,
      );
    }

    final aiMessage =
        targetAiMessage ??
        Message(
          id: DateTime.now().millisecondsSinceEpoch.toString(),
          content: '',
          reasoningContent: null,
          isUser: false,
          timestamp: DateTime.now(),
          status: MessageStatus.sending,
        );

    setState(() {
      if (targetAiMessage == null) {
        _messages.add(aiMessage);
      } else {
        final index = _findMessageIndexById(aiMessage.id);
        if (index != -1) {
          _messages[index] = aiMessage;
        }
      }
      _isLoading = false;
    });
    _scrollToBottom();

    final conversationId = _currentConversation!.id;
    final titleAtSend = _currentTitle;
    final history =
        historyOverride ?? ChatSendController.buildHistory(_messages);

    // 发送前补齐记忆：旧消息即将滑出原文窗口时，宁可多等一会儿，也不能
    // 让模型在“没有前情”的状态下回答。
    var memoryBlock = '';
    final memoryEnabled = await _settingsService.getMemoryCompressionEnabled();
    final historyEnabled = await _settingsService.getEnableHistory();
    final roleplayMode = _promptPresetEnabled && _currentPresetId.isNotEmpty;
    final roleplayPreset = roleplayMode
        ? _findPresetById(_currentPresetId)
        : null;
    final characterName = roleplayPreset?.name ?? _currentTitle;
    final characterDescription = roleplayPreset?.description ?? '';
    var historyRounds = 0;
    if (memoryEnabled && historyEnabled) {
      historyRounds = await _settingsService.getHistoryContextLength();
      memoryBlock = await _ensureMemoryBlock(
        conversationId: conversationId,
        history: history,
        historyRounds: historyRounds,
        l10n: l10n,
        roleplayMode: roleplayMode,
        characterName: characterName,
        characterDescription: characterDescription,
      );
    }

    final noteSourceMessageId = _lastUserMessageId();
    final eligibleHistory = history
        .where(
          (message) =>
              message.status != MessageStatus.error &&
              message.content.trim().isNotEmpty,
        )
        .toList(growable: false);
    final rawWindowSize = historyRounds * 2;
    final recentMessageIds = <String>{
      ...(eligibleHistory.length > rawWindowSize
          ? eligibleHistory
                .skip(eligibleHistory.length - rawWindowSize)
                .map((message) => message.id)
          : const <String>[]),
      ?noteSourceMessageId,
    };
    final recallEnabled =
        memoryEnabled &&
        historyEnabled &&
        eligibleHistory.length > rawWindowSize;

    MemoryRecallHandler? recallHandler;
    if (recallEnabled) {
      final recallService = MemoryRecallService(_conversationService);
      recallHandler = (query) => recallService.search(
        conversationId: conversationId,
        query: query,
        excludeMessageIds: recentMessageIds,
      );
    }

    ChatSendController? controllerRef;
    final controller = ChatSendController(
      conversationService: _conversationService,
      conversationId: conversationId,
      initialMessage: aiMessage,
      history: history,
      initialAnswer: initialAnswer,
      initialReasoning: initialReasoning,
      appendInitialMessage: targetAiMessage == null,
      openStream: () => _aiService.sendMessageStreaming(
        content,
        history,
        attachments: attachments,
        thinkingMode: _thinkingMode,
        presetSystemPrompt: presetSystemPrompt,
        memoryBlock: memoryBlock,
        memoryNoteSink: (memoryEnabled && historyEnabled)
            ? (draft) => _recordMemoryNote(
                conversationId: conversationId,
                sourceMessageId: noteSourceMessageId,
                draft: draft,
              )
            : null,
        memoryRecallHandler: recallHandler,
        l10n: l10n,
      ),
      onUpdate: (message) {
        _batchedSetState(() {
          final index = _findMessageIndexById(message.id);
          if (index != -1) {
            _messages[index] = message;
          }
        });
        if (identical(_sendController, controllerRef) &&
            Platform.isAndroid &&
            _liveUpdateService.isAvailable &&
            _liveUpdateEnabled) {
          _liveUpdateService.updateContent(message.content);
        }
      },
      onComplete: (message) async {
        _batchedSetState(() {
          final index = _findMessageIndexById(message.id);
          if (index != -1) {
            _messages[index] = message;
          }
        });
        if (identical(_sendController, controllerRef) && mounted) {
          setState(() {
            _isGenerating = false;
          });
        }
        if (identical(_sendController, controllerRef) &&
            Platform.isAndroid &&
            _liveUpdateService.isAvailable &&
            _liveUpdateEnabled) {
          await _liveUpdateService.complete();
        }
        final notificationEnabled = await _settingsService
            .getNotificationEnabled();
        if (notificationEnabled) {
          await _notificationService.showAIResponseCompleted(
            message.content,
            conversationTitle: titleAtSend,
          );
        }
        if (_currentConversation?.id == conversationId) {
          await _generateAutoTitle();
          // 先同步快照消息；后续 await 期间用户可能切换会话。
          final memoryMessages = List<Message>.from(_messages);
          unawaited(
            _updateMemoryInBackground(
              conversationId: conversationId,
              messages: memoryMessages,
              l10n: l10n,
              roleplayMode: roleplayMode,
              characterName: characterName,
              characterDescription: characterDescription,
            ),
          );
        }
      },
      onError: (message) async {
        _batchedSetState(() {
          final index = _findMessageIndexById(message.id);
          if (index != -1) {
            _messages[index] = message;
          }
        });
        if (identical(_sendController, controllerRef) && mounted) {
          setState(() {
            _isGenerating = false;
          });
        }
        if (identical(_sendController, controllerRef) &&
            Platform.isAndroid &&
            _liveUpdateService.isAvailable &&
            _liveUpdateEnabled) {
          await _liveUpdateService.stopLiveUpdate();
        }
      },
      onStopped: (message) async {
        _batchedSetState(() {
          final index = _findMessageIndexById(message.id);
          if (index != -1) {
            _messages[index] = message;
          }
        });
        if (identical(_sendController, controllerRef) && mounted) {
          setState(() {
            _isGenerating = false;
          });
        }
        if (identical(_sendController, controllerRef) &&
            Platform.isAndroid &&
            _liveUpdateService.isAvailable &&
            _liveUpdateEnabled) {
          await _liveUpdateService.stopLiveUpdate();
        }
      },
      errorContentBuilder: (error) =>
          '${l10n.errorPrefix}: ${error.toString().replaceAll('Exception: ', '')}',
      emptyResponseContent: '${l10n.errorPrefix}: API未返回任何响应内容',
    );

    controllerRef = controller;
    _sendController = controller;
    setState(() {
      _isGenerating = true;
    });

    try {
      await controller.start();
    } catch (e) {
      await controller.dispose();
      if (Platform.isAndroid &&
          _liveUpdateService.isAvailable &&
          _liveUpdateEnabled) {
        await _liveUpdateService.stopLiveUpdate();
      }
      _batchedSetState(() {
        final index = _findMessageIndexById(aiMessage.id);
        if (index != -1) {
          _messages[index] = Message(
            id: aiMessage.id,
            content:
                '${l10n.errorPrefix}: ${e.toString().replaceAll('Exception: ', '')}',
            reasoningContent: null,
            isUser: false,
            timestamp: aiMessage.timestamp,
            status: MessageStatus.error,
          );
        }
      });
      if (mounted) {
        setState(() {
          _isGenerating = false;
        });
      }
      await _saveCurrentConversation();
    }
  }

  /// 停止AI生成
  void _stopGenerating() {
    final controller = _sendController;
    if (controller != null && controller.isActive) {
      unawaited(controller.stop());
    }
  }

  /// 通过消息ID查找消息索引
  int _findMessageIndexById(String messageId) {
    for (int i = 0; i < _messages.length; i++) {
      if (_messages[i].id == messageId) return i;
    }
    return -1;
  }

  /// 编辑用户消息
  Future<void> _editUserMessage(Message message) async {
    final l10n = AppLocalizations.of(context)!;
    final textController = TextEditingController(text: message.content);

    // 显示编辑对话框
    final editedContent = await showCupertinoDialog<String>(
      context: context,
      builder: (context) => CupertinoAlertDialog(
        title: Text(l10n.editMessageDialogTitle),
        content: CupertinoTextField(
          controller: textController,
          placeholder: l10n.editMessageHint,
          maxLines: 5,
          minLines: 1,
          autofocus: true,
        ),
        actions: [
          CupertinoDialogAction(
            child: Text(l10n.cancel),
            onPressed: () => Navigator.of(context).pop(),
          ),
          CupertinoDialogAction(
            child: Text(l10n.confirmEdit),
            onPressed: () {
              Navigator.of(context).pop(textController.text.trim());
            },
          ),
        ],
      ),
    );

    if (editedContent != null &&
        editedContent.trim().isNotEmpty &&
        editedContent != message.content) {
      await _resubmitMessage(message, editedContent);
    }
  }

  /// 重新提交消息（编辑后或原样重新提交）
  Future<void> _resubmitMessage(Message message, String newContent) async {
    // 停止当前正在进行的生成
    if (_isGenerating) {
      _stopGenerating();
    }

    final messageIndex = _findMessageIndexById(message.id);
    if (messageIndex == -1) {
      return;
    }

    // 更新用户消息内容（如果编辑过）
    if (newContent != message.content) {
      setState(() {
        _messages[messageIndex] = message.copyWith(content: newContent);
      });
    }

    // 删除该消息之后的所有消息（包括对应的AI响应）
    setState(() {
      _messages.removeRange(messageIndex + 1, _messages.length);
    });

    // 重新发送消息，保留原始附件，跳过用户消息添加
    await _sendMessage(
      newContent,
      attachments: message.attachments,
      skipUserMessage: true,
    );
  }

  /// 重新生成AI响应
  Future<void> _regenerateAiResponse(Message message) async {
    final l10n = AppLocalizations.of(context)!;

    // 确认对话框
    final confirmed = await showCupertinoDialog<bool>(
      context: context,
      builder: (context) => CupertinoAlertDialog(
        title: Text(l10n.regenerateResponse),
        content: Text(l10n.regenerateConfirm),
        actions: [
          CupertinoDialogAction(
            child: Text(l10n.cancel),
            onPressed: () => Navigator.of(context).pop(false),
          ),
          CupertinoDialogAction(
            child: Text(l10n.confirm),
            onPressed: () => Navigator.of(context).pop(true),
          ),
        ],
      ),
    );

    if (confirmed != true) {
      return;
    }

    // 停止当前正在进行的生成
    if (_isGenerating) {
      _stopGenerating();
    }

    final messageIndex = _findMessageIndexById(message.id);
    if (messageIndex <= 0 || !_messages[messageIndex - 1].isUser) {
      return;
    }

    final userMessage = _messages[messageIndex - 1];
    final target = _messages[messageIndex];
    final variants = target.variants.isNotEmpty
        ? List<MessageVariant>.from(target.variants)
        : [
            MessageVariant(
              content: target.content,
              reasoningContent: target.reasoningContent,
              timestamp: target.timestamp,
              status: target.status,
              toolCalls: target.toolCalls,
            ),
          ];
    final newVariant = MessageVariant(
      content: '',
      reasoningContent: null,
      timestamp: DateTime.now(),
      status: MessageStatus.sending,
    );
    final prepared = target.copyWith(
      content: '',
      reasoningContent: '',
      timestamp: newVariant.timestamp,
      status: MessageStatus.sending,
      variants: [...variants, newVariant],
      activeVariantIndex: variants.length,
      toolCalls: const [],
    );
    final history = messageIndex <= 1
        ? <Message>[]
        : List<Message>.from(_messages.sublist(0, messageIndex - 1));

    // 保留目标消息并追加新版本，删除它之后的消息。
    setState(() {
      _messages.removeRange(messageIndex + 1, _messages.length);
      _messages[messageIndex] = prepared;
    });
    await _saveCurrentConversation();

    await _sendMessage(
      userMessage.content,
      attachments: userMessage.attachments,
      skipUserMessage: true,
      targetAiMessage: prepared,
      historyOverride: history,
    );
  }

  /// 从当前回复末尾继续生成。
  Future<void> _continueGeneration(Message message) async {
    if (_isGenerating || message.isUser) return;

    final l10n = AppLocalizations.of(context)!;
    final messageIndex = _findMessageIndexById(message.id);
    if (messageIndex == -1 || messageIndex != _messages.length - 1) {
      return;
    }

    final variants = message.variants.isNotEmpty
        ? List<MessageVariant>.from(message.variants)
        : [
            MessageVariant(
              content: message.content,
              reasoningContent: message.reasoningContent,
              timestamp: message.timestamp,
              status: message.status,
              toolCalls: message.toolCalls,
            ),
          ];
    final activeIndex = message.variants.isEmpty
        ? 0
        : message.activeVariantIndex.clamp(0, variants.length - 1);
    final target = message.copyWith(
      variants: variants,
      activeVariantIndex: activeIndex,
    );

    setState(() {
      _messages[messageIndex] = target;
    });
    await _saveCurrentConversation();

    await _sendMessage(
      l10n.continueGenerationPrompt,
      skipUserMessage: true,
      targetAiMessage: target,
      historyOverride: List<Message>.from(
        _messages.sublist(0, messageIndex + 1),
      ),
      initialAnswer: target.content,
      initialReasoning: target.reasoningContent ?? '',
    );
  }

  /// 切换 AI 回复版本。
  Future<void> _switchMessageVariant(Message message, int index) async {
    if (index < 0 || index >= message.variants.length) return;
    final messageIndex = _findMessageIndexById(message.id);
    if (messageIndex == -1) return;

    final variant = message.variants[index];
    final updated = message.copyWith(
      content: variant.content,
      reasoningContent: variant.reasoningContent ?? '',
      timestamp: variant.timestamp,
      status: variant.status,
      activeVariantIndex: index,
      toolCalls: variant.toolCalls,
    );

    setState(() {
      _messages[messageIndex] = updated;
    });

    final conversation = _currentConversation;
    if (conversation != null) {
      await _conversationService.updateMessage(conversation.id, updated);
    }
  }

  /// 删除单条消息。
  Future<void> _deleteMessage(Message message) async {
    final l10n = AppLocalizations.of(context)!;
    final confirmed = await showCupertinoDialog<bool>(
      context: context,
      builder: (context) => CupertinoAlertDialog(
        title: Text(l10n.deleteMessage),
        content: Text(l10n.deleteMessageConfirm),
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
    if (confirmed != true) return;

    if (_isGenerating) {
      _stopGenerating();
    }
    setState(() {
      _messages.removeWhere((item) => item.id == message.id);
      _messageKeys.remove(message.id);
    });
    await _saveCurrentConversation();
  }

  /// 从指定消息处分叉出新会话。
  Future<void> _forkConversation(Message message) async {
    final conversation = _currentConversation;
    if (conversation == null || _isGenerating) return;
    final index = _findMessageIndexById(message.id);
    if (index == -1) return;

    final l10n = AppLocalizations.of(context)!;
    final fork = await _conversationService.forkConversation(
      sourceConversationId: conversation.id,
      messageIndex: index,
      title: '$_currentTitle · ${l10n.forkConversation}',
    );
    await _setCurrentConversation(fork.id);
  }

  /// 显示配置提示对话框
  ///
  /// 当用户尝试发送消息但应用未配置API密钥时显示
  /// 提供选项：取消或跳转到设置界面
  void _showConfigurationDialog() {
    final l10n = AppLocalizations.of(context)!;
    showCupertinoDialog(
      context: context,
      builder: (context) => CupertinoAlertDialog(
        title: Text(l10n.needConfiguration),
        content: Text(l10n.configureAPIPrompt),
        actions: [
          CupertinoDialogAction(
            child: Text(l10n.cancel),
            onPressed: () => Navigator.pop(context),
          ),
          CupertinoDialogAction(
            child: Text(l10n.goToSettings),
            onPressed: () {
              Navigator.pop(context);
              _openSettings();
            },
          ),
        ],
      ),
    );
  }

  /// 打开设置界面
  ///
  /// 使用CupertinoPageRoute导航到SettingsScreen
  /// 返回后重新检查配置状态
  Future<void> _openSettings() async {
    final openSettings = widget.onOpenSettings;
    if (openSettings != null) {
      openSettings();
      return;
    }
    await Navigator.push(
      context,
      CupertinoPageRoute(builder: (context) => const SettingsScreen()),
    );
    _checkConfiguration();
  }

  /// 打开对话列表界面
  ///
  /// 导航到ConversationListScreen并传递回调函数
  /// 当用户选择对话时，接收对话ID并加载对应的对话数据
  Future<void> _openConversationList() async {
    await Navigator.push(
      context,
      CupertinoPageRoute(
        builder: (context) => ConversationListScreen(
          service: _conversationService,
          onConversationSelected: (conversationId) {
            if (conversationId != null) {
              // 使用统一的入口加载对话
              _setCurrentConversation(conversationId);
            } else {
              _createNewConversation();
            }
          },
        ),
      ),
    );
  }

  /// 清除当前对话的所有消息
  ///
  /// 显示确认对话框，用户确认后清空消息列表并保存对话
  Future<void> _clearCurrentConversation() async {
    final l10n = AppLocalizations.of(context)!;
    showCupertinoDialog(
      context: context,
      builder: (context) => CupertinoAlertDialog(
        title: Text(l10n.clearConversation),
        content: Text(l10n.clearConversationConfirm),
        actions: [
          CupertinoDialogAction(
            child: Text(l10n.cancel),
            onPressed: () => Navigator.pop(context),
          ),
          CupertinoDialogAction(
            isDestructiveAction: true,
            child: Text(l10n.delete),
            onPressed: () async {
              Navigator.pop(context);
              setState(() {
                _messages.clear();
              });
              await _saveCurrentConversation();
            },
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final cjkFallback = cjkFontFallbackForLocale(
      Localizations.maybeLocaleOf(context),
    );

    /// 构建聊天界面布局
    /// 包含：导航栏、消息列表、输入框、配置提示等组件
    final chatBody = Stack(
      children: [
        // 背景层
        if (_backgroundImagePath.isNotEmpty)
          Positioned.fill(
            child: Opacity(
              opacity: _backgroundImageOpacity,
              child: Image.file(File(_backgroundImagePath), fit: BoxFit.cover),
            ),
          ),

        // 原有界面层
        SafeArea(
          child: Column(
            children: [
              if (!_isConfigured)
                Container(
                  width: double.infinity,
                  padding: const EdgeInsets.all(16),
                  color: CupertinoColors.systemYellow.withValues(alpha: 0.2),
                  child: Row(
                    children: [
                      const Icon(
                        CupertinoIcons.exclamationmark_triangle,
                        color: CupertinoColors.systemOrange,
                      ),
                      const SizedBox(width: 8),
                      Expanded(child: Text(l10n.pleaseConfigureAPI)),
                      CupertinoButton(
                        padding: EdgeInsets.zero,
                        onPressed: _openSettings,
                        child: Text(l10n.settingsButton),
                      ),
                    ],
                  ),
                ),
              Expanded(
                child: _messages.isEmpty
                    ? _buildEmptyState()
                    : ListView.builder(
                        controller: _scrollController,
                        padding: const EdgeInsets.all(16),
                        itemCount: _messages.length + (_isLoading ? 1 : 0),
                        physics: const AlwaysScrollableScrollPhysics(),
                        // 性能优化配置
                        addAutomaticKeepAlives: true, // 启用自动保持活动状态
                        addRepaintBoundaries: true, // 隔离重绘，避免整个列表重绘
                        scrollCacheExtent: ScrollCacheExtent.pixels(
                          500,
                        ), // 预渲染屏幕外 500 像素的消息
                        itemBuilder: (context, index) {
                          if (index == _messages.length && _isLoading) {
                            return const TypingIndicator();
                          }
                          final message = _messages[index];
                          return MessageBubble(
                            key: _messageKeys.putIfAbsent(
                              message.id,
                              () => GlobalKey(),
                            ),
                            message: message,
                            userProfile: _userProfile,
                            onEdit: _editUserMessage,
                            onRegenerate: _regenerateAiResponse,
                            onResubmit: (msg) =>
                                _resubmitMessage(msg, msg.content),
                            onVariantChanged: _switchMessageVariant,
                            onDelete: _deleteMessage,
                            onContinue:
                                index == _messages.length - 1 &&
                                    !message.isUser &&
                                    !_isGenerating
                                ? _continueGeneration
                                : null,
                            onFork: _forkConversation,
                          );
                        },
                      ),
              ),
              if (_memoryStatus != null)
                Container(
                  width: double.infinity,
                  padding: const EdgeInsets.symmetric(
                    horizontal: 16,
                    vertical: 8,
                  ),
                  color: CupertinoColors.systemGrey6.resolveFrom(context),
                  child: Row(
                    children: [
                      const CupertinoActivityIndicator(radius: 7),
                      const SizedBox(width: 8),
                      Expanded(
                        child: Text(
                          _memoryStatus!,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: TextStyle(
                            fontSize: 13,
                            fontFamilyFallback: cjkFallback,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ChatInput(
                onSendMessage: (content, attachments) =>
                    _sendMessage(content, attachments: attachments),
                onStopGenerating: _stopGenerating,
                onAttachmentsSelected: _handleAttachmentsSelected,
                enabled: _isConfigured,
                thinkingMode: _thinkingMode,
                onThinkingModeChanged: _handleThinkingModeChanged,
                promptPresetEnabled: _promptPresetEnabled,
                onPromptPresetEnabledChanged: _handlePromptPresetEnabledChanged,
                currentPresetId: _currentPresetId,
                onPresetSelected: _handlePresetSelected,
                presets: _presets,
                currentPresetUnavailable: _isCurrentPresetUnavailable,
                onShowModelSelector: _showModelSelector,
                currentModelName: _currentModel,
                isGenerating: _isGenerating,
              ),
            ],
          ),
        ),
      ],
    );

    if (widget.embedded) {
      return SafeArea(
        bottom: false,
        child: ColoredBox(
          color: CupertinoColors.systemBackground.resolveFrom(context),
          child: Column(
            children: [
              _buildDesktopTopBar(context),
              Expanded(
                child: MediaQuery.removePadding(
                  context: context,
                  removeTop: true,
                  child: chatBody,
                ),
              ),
            ],
          ),
        ),
      );
    }

    return CupertinoPageScaffold(
      navigationBar: _buildMobileNavigationBar(context),
      child: chatBody,
    );
  }

  CupertinoNavigationBar _buildMobileNavigationBar(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    return CupertinoNavigationBar(
      leading: CupertinoButton(
        padding: EdgeInsets.zero,
        onPressed: _openConversationList,
        child: const Icon(CupertinoIcons.chat_bubble_2),
      ),
      middle: Text(_currentTitle.isEmpty ? l10n.aiAssistant : _currentTitle),
      trailing: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          CupertinoButton(
            padding: EdgeInsets.zero,
            onPressed: _messages.isEmpty ? null : _openMessageSearch,
            child: const Icon(CupertinoIcons.search),
          ),
          CupertinoButton(
            padding: EdgeInsets.zero,
            onPressed: _createNewConversation,
            child: const Icon(CupertinoIcons.add),
          ),
          CupertinoButton(
            padding: EdgeInsets.zero,
            onPressed: _showMoreOptions,
            child: const Icon(CupertinoIcons.ellipsis),
          ),
        ],
      ),
    );
  }

  Widget _buildDesktopTopBar(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final iconColor = CupertinoTheme.of(context).primaryColor;
    final searchColor = _messages.isEmpty
        ? CupertinoColors.systemGrey.resolveFrom(context)
        : iconColor;
    return Container(
      height: 52,
      padding: const EdgeInsets.symmetric(horizontal: 16),
      decoration: BoxDecoration(
        border: Border(
          bottom: BorderSide(
            color: CupertinoColors.systemGrey4.resolveFrom(context),
            width: 0.5,
          ),
        ),
      ),
      child: Row(
        children: [
          Expanded(
            child: Text(
              _currentTitle.isEmpty ? l10n.aiAssistant : _currentTitle,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: const TextStyle(fontSize: 15, fontWeight: FontWeight.w600),
            ),
          ),
          CupertinoButton(
            padding: EdgeInsets.zero,
            onPressed: _messages.isEmpty ? null : _openMessageSearch,
            child: Icon(CupertinoIcons.search, color: searchColor),
          ),
          const SizedBox(width: 8),
          CupertinoButton(
            padding: EdgeInsets.zero,
            onPressed: _showMoreOptions,
            child: Icon(CupertinoIcons.ellipsis, color: iconColor),
          ),
        ],
      ),
    );
  }

  /// 构建空状态界面
  ///
  /// 当消息列表为空时显示，包含图标和提示文本
  Widget _buildEmptyState() {
    final l10n = AppLocalizations.of(context)!;
    final cjkFallback = cjkFontFallbackForLocale(
      Localizations.maybeLocaleOf(context),
    );
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          const Icon(
            CupertinoIcons.chat_bubble_2,
            size: 64,
            color: CupertinoColors.systemGrey,
          ),
          const SizedBox(height: 16),
          Text(
            l10n.startChatting,
            style: TextStyle(
              fontSize: 18,
              fontFamilyFallback: cjkFallback,
              color: CupertinoColors.systemGrey,
            ),
          ),
        ],
      ),
    );
  }

  /// 加载当前模型
  Future<void> _loadCurrentModel() async {
    final currentPlatform = await _settingsService.getCurrentPlatform();
    if (!mounted) return;
    if (currentPlatform != null && currentPlatform.defaultModel.isNotEmpty) {
      setState(() {
        _currentModel = currentPlatform.defaultModel;
      });
    } else {
      // 如果没有配置平台，使用旧版本的模型设置
      final oldModel = await _settingsService.getModel();
      if (!mounted) return;
      setState(() {
        _currentModel = oldModel;
      });
    }
  }

  /// 加载聊天背景设置
  Future<void> _loadBackgroundSettings() async {
    final backgroundImagePath = await _settingsService.getBackgroundImagePath();
    final backgroundImageOpacity = await _settingsService
        .getBackgroundImageOpacity();
    if (mounted) {
      setState(() {
        _backgroundImagePath = backgroundImagePath;
        _backgroundImageOpacity = backgroundImageOpacity;
      });
    }
  }

  /// 显示模型选择器
  ///
  /// 显示底部菜单让用户选择模型
  Future<void> _showModelSelector() async {
    final currentPlatform = await _settingsService.getCurrentPlatform();

    if (!mounted) return;

    final l10n = AppLocalizations.of(context)!;

    if (currentPlatform == null) {
      if (mounted) {
        showCupertinoDialog(
          context: context,
          builder: (context) => CupertinoAlertDialog(
            title: const Text('未配置平台'),
            content: const Text('请先在设置中配置AI平台'),
            actions: [
              CupertinoDialogAction(
                child: Text(l10n.ok),
                onPressed: () => Navigator.pop(context),
              ),
            ],
          ),
        );
      }
      return;
    }

    final availableModels = currentPlatform.availableModels;

    if (availableModels.isEmpty) {
      if (mounted) {
        showCupertinoDialog(
          context: context,
          builder: (context) => CupertinoAlertDialog(
            title: const Text('暂无可用模型'),
            content: const Text('当前平台没有可用的模型列表，请在设置中刷新模型列表'),
            actions: [
              CupertinoDialogAction(
                child: Text(l10n.ok),
                onPressed: () => Navigator.pop(context),
              ),
            ],
          ),
        );
      }
      return;
    }

    if (!mounted) return;

    showCupertinoModalPopup(
      context: context,
      builder: (context) => CupertinoActionSheet(
        title: Text(l10n.currentModel),
        message: Text(currentPlatform.name),
        actions: availableModels.map((model) {
          return CupertinoActionSheetAction(
            child: Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(_getModelIcon(currentPlatform.type), size: 20),
                const SizedBox(width: 8),
                Text(model),
                if (model == currentPlatform.defaultModel) ...[
                  const SizedBox(width: 8),
                  Icon(
                    CupertinoIcons.checkmark_alt,
                    color: CupertinoColors.systemBlue,
                    size: 20,
                  ),
                ],
              ],
            ),
            onPressed: () {
              Navigator.pop(context);
              _selectModel(model);
            },
          );
        }).toList(),
        cancelButton: CupertinoActionSheetAction(
          child: Text(l10n.cancel),
          onPressed: () => Navigator.pop(context),
        ),
      ),
    );
  }

  /// 根据平台类型获取图标
  IconData _getModelIcon(String platformType) {
    return CupertinoIcons.cube_box;
  }

  /// 选择模型
  Future<void> _selectModel(String model) async {
    final currentPlatform = await _settingsService.getCurrentPlatform();
    if (currentPlatform == null) return;

    // 获取最新的平台数据，确保可用模型列表是最新的
    final latestPlatform = await _settingsService.getPlatformById(
      currentPlatform.id,
    );
    if (latestPlatform == null) return;

    // 更新当前平台的默认模型，保持现有的可用模型列表
    await _settingsService.updatePlatformModels(
      currentPlatform.id,
      latestPlatform.availableModels, // 使用最新的可用模型列表
      newDefaultModel: model,
    );

    // 同步更新全局模型设置，确保AIService使用正确的模型
    await _settingsService.setModel(model);

    // 重新加载当前模型
    await _loadCurrentModel();
  }

  /// 显示更多选项菜单
  ///
  /// 显示底部操作菜单，包含设置和清除对话等选项
  void _showMoreOptions() {
    final l10n = AppLocalizations.of(context)!;
    showCupertinoModalPopup(
      context: context,
      builder: (context) {
        final primaryColor = CupertinoTheme.of(context).primaryColor;
        final destructiveColor = CupertinoColors.systemRed.resolveFrom(context);
        return CupertinoActionSheet(
          actions: [
            CupertinoActionSheetAction(
              child: Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(CupertinoIcons.settings, size: 20, color: primaryColor),
                  const SizedBox(width: 8),
                  Text(l10n.settings),
                ],
              ),
              onPressed: () {
                Navigator.pop(context);
                _openSettings();
              },
            ),
            if (_currentConversation != null)
              CupertinoActionSheetAction(
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(
                      CupertinoIcons.square_list,
                      size: 20,
                      color: primaryColor,
                    ),
                    const SizedBox(width: 8),
                    Text(l10n.viewMemory),
                  ],
                ),
                onPressed: () {
                  Navigator.pop(context);
                  _openMemoryViewer();
                },
              ),
            CupertinoActionSheetAction(
              child: Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(
                    CupertinoIcons.arrow_down_doc,
                    size: 20,
                    color: primaryColor,
                  ),
                  const SizedBox(width: 8),
                  Text(l10n.exportConversation),
                ],
              ),
              onPressed: () {
                Navigator.pop(context);
                _showExportFormatDialog();
              },
            ),
            CupertinoActionSheetAction(
              isDestructiveAction: true,
              child: Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(CupertinoIcons.clear, size: 20, color: destructiveColor),
                  const SizedBox(width: 8),
                  Text(l10n.clearConversation),
                ],
              ),
              onPressed: () {
                Navigator.pop(context);
                _clearCurrentConversation();
              },
            ),
          ],
          cancelButton: CupertinoActionSheetAction(
            child: Text(l10n.cancel),
            onPressed: () => Navigator.pop(context),
          ),
        );
      },
    );
  }

  void _openMemoryViewer() {
    final conversation = _currentConversation;
    if (conversation == null) return;
    Navigator.of(context).push(
      CupertinoPageRoute(
        builder: (_) => MemoryViewerScreen(
          conversationId: conversation.id,
          conversationService: _conversationService,
          roleplayMode: _promptPresetEnabled && _currentPresetId.isNotEmpty,
          preset: _promptPresetEnabled
              ? _findPresetById(_currentPresetId)
              : null,
        ),
      ),
    );
  }

  void _showExportFormatDialog() {
    final l10n = AppLocalizations.of(context)!;
    var includePresetCard = false;
    showCupertinoModalPopup(
      context: context,
      builder: (context) => StatefulBuilder(
        builder: (context, setSheetState) {
          void export(String format) {
            Navigator.pop(context);
            _exportCurrentConversation(
              format,
              includePresetSnapshot:
                  includePresetCard &&
                  (format == 'json' || format == 'lumenflow'),
            );
          }

          return CupertinoActionSheet(
            title: Text(l10n.exportFormat),
            message: Text(l10n.includePresetCardHint),
            actions: [
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 16),
                child: Row(
                  children: [
                    Expanded(child: Text(l10n.includePresetCard)),
                    CupertinoSwitch(
                      value: includePresetCard,
                      onChanged: (value) =>
                          setSheetState(() => includePresetCard = value),
                    ),
                  ],
                ),
              ),
              CupertinoActionSheetAction(
                child: Text(l10n.exportFormatTxt),
                onPressed: () => export('txt'),
              ),
              CupertinoActionSheetAction(
                child: Text(l10n.exportFormatJson),
                onPressed: () => export('json'),
              ),
              CupertinoActionSheetAction(
                child: Text(l10n.exportFormatLumenflow),
                onPressed: () => export('lumenflow'),
              ),
              CupertinoActionSheetAction(
                child: Text(l10n.exportFormatPdf),
                onPressed: () => export('pdf'),
              ),
            ],
            cancelButton: CupertinoActionSheetAction(
              child: Text(l10n.cancel),
              onPressed: () => Navigator.pop(context),
            ),
          );
        },
      ),
    );
  }

  Future<void> _exportCurrentConversation(
    String format, {
    bool includePresetSnapshot = false,
  }) async {
    final l10n = AppLocalizations.of(context)!;
    if (_currentConversation == null) {
      showCupertinoDialog(
        context: context,
        builder: (context) => CupertinoAlertDialog(
          title: Text(l10n.exportConversationFailed),
          content: const Text('当前没有对话可以导出'),
          actions: [
            CupertinoDialogAction(
              child: Text(l10n.ok),
              onPressed: () => Navigator.pop(context),
            ),
          ],
        ),
      );
      return;
    }

    try {
      List<int> bytes;
      String fileName;

      // 使用新的导出方法（包含附件）
      bytes = await _conversationService.exportConversationWithAttachments(
        _currentConversation!.id,
        format,
        l10n,
        includePresetSnapshot: includePresetSnapshot,
      );

      // 生成文件名（包含时间戳确保唯一性）
      final safeTitle = _currentConversation!.title
          .replaceAll(RegExp(r'[^\w\s-]'), '')
          .replaceAll(' ', '_');
      final timestamp = DateTime.now().millisecondsSinceEpoch;
      if (format == 'pdf') {
        fileName = '${safeTitle}_$timestamp.pdf';
      } else {
        // 对于ZIP文件，在文件名中包含原始格式信息
        fileName = '${safeTitle}_$timestamp.$format.zip';
      }

      // 保存文件
      final result = await _conversationService.saveExportFile(fileName, bytes);
      final filePath = result['filePath']!;
      final locationType = result['locationType']!;

      // 用户取消了保存
      if (locationType == 'cancelled') {
        return;
      }

      // 显示成功消息
      if (mounted) {
        final String content;
        if (locationType == 'saved') {
          content = l10n.exportSaved;
        } else {
          // 根据位置类型获取本地化的目录名称
          String locationName;
          switch (locationType) {
            case 'external':
              locationName = l10n.externalStorageDirectory;
              break;
            case 'app':
              locationName = l10n.appDocumentsDirectory;
              break;
            default:
              locationName = l10n.downloadDirectory;
          }
          content = l10n.exportLocation(locationName, filePath);
        }

        showCupertinoDialog(
          context: context,
          builder: (context) => CupertinoAlertDialog(
            title: Text(l10n.exportConversationSuccess),
            content: Text(content),
            actions: [
              CupertinoDialogAction(
                child: Text(l10n.ok),
                onPressed: () => Navigator.pop(context),
              ),
            ],
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        showCupertinoDialog(
          context: context,
          builder: (context) => CupertinoAlertDialog(
            title: Text(l10n.exportConversationFailed),
            content: Text(l10n.exportConversationError(e.toString())),
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
}

/// 打字指示器组件，显示AI正在输入的状态
///
/// 显示一个包含活动指示器的灰色气泡，表示AI正在生成响应
class TypingIndicator extends StatelessWidget {
  const TypingIndicator({super.key});

  @override
  Widget build(BuildContext context) {
    /// 构建打字指示器UI
    /// 包含一个灰色圆角矩形背景和Cupertino活动指示器
    return Padding(
      padding: const EdgeInsets.all(16),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: CupertinoColors.systemGrey5,
              borderRadius: BorderRadius.circular(20),
            ),
            child: const CupertinoActivityIndicator(),
          ),
        ],
      ),
    );
  }
}
