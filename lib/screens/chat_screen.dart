import 'package:flutter/cupertino.dart';
import 'dart:convert';
import '../l10n/app_localizations.dart';
import '../models/message.dart';
import '../models/attachment.dart';
import '../models/conversation.dart';
import '../models/prompt_preset.dart';
import '../services/ai_service.dart';
import '../services/conversation_service.dart';
import '../services/settings_service.dart';
import '../services/prompt_service.dart';
import '../widgets/message_bubble.dart';
import '../widgets/chat_input.dart';
import 'settings_screen.dart';
import 'conversation_list_screen.dart';

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
  const ChatScreen({super.key});

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
class _ChatScreenState extends State<ChatScreen> {
  final List<Message> _messages = [];
  final ScrollController _scrollController = ScrollController();
  final AIService _aiService = AIService();
  final ConversationService _conversationService = ConversationService();
  final SettingsService _settingsService = SettingsService();
  final PromptService _promptService = PromptService();

  bool _isLoading = false;
  bool _isConfigured = false;
  bool _thinkingMode = false;
  bool _promptPresetEnabled = false;
  String _currentPresetId = '';
  List<PromptPreset> _presets = [];
  Conversation? _currentConversation;
  String _currentTitle = '';
  bool _autoTitleGenerated = false; // 是否已经自动生成过标题

  @override
  void initState() {
    super.initState();

    /// 初始化状态时检查应用配置并加载当前对话
    /// 1. 检查API配置是否完成
    /// 2. 加载最近使用的对话或创建新对话
    _checkConfiguration();
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    // 在这里加载当前对话,确保可以访问 AppLocalizations
    _loadCurrentConversation();
  }

  /// 检查应用配置状态
  ///
  /// 调用设置服务检查API密钥等必要配置是否已设置
  /// 更新_isConfigured状态变量，控制界面显示和交互
  Future<void> _checkConfiguration() async {
    final configured = await _settingsService.isConfigured();
    final thinkingMode = await _settingsService.getThinkingMode();
    final promptPresetEnabled = await _settingsService.getPromptPresetEnabled();
    final currentPresetId = await _settingsService.getPromptPresetId();
    final presets = await _promptService.loadPresets();
    // 调试日志：检查加载的预设
    debugPrint('Loaded ${presets.length} preset(s)');
    for (final preset in presets) {
      final length = preset.systemPrompt.length;
      final preview = length > 50 ? '${preset.systemPrompt.substring(0, 50)}...' : preset.systemPrompt;
      debugPrint('Preset: ${preset.name}, systemPrompt length: $length, starts with: "$preview"');
    }

    setState(() {
      _isConfigured = configured;
      _thinkingMode = thinkingMode;
      _promptPresetEnabled = promptPresetEnabled;
      _currentPresetId = currentPresetId;
      _presets = presets;
    });
  }

  /// 加载当前对话
  ///
  /// 从对话服务获取最近使用的对话ID，然后加载对应的对话数据
  /// 如果不存在最近对话，则创建新的对话
  /// 加载完成后，将对话消息添加到状态中并滚动到底部
  Future<void> _loadCurrentConversation() async {
    final l10n = AppLocalizations.of(context)!;
    final currentConversationId =
        await _conversationService.getCurrentConversationId();

    if (currentConversationId != null) {
      final conversation =
          await _conversationService.getConversationById(currentConversationId);
      if (conversation != null) {
        // 清理不完整的消息：将状态为sending的AI消息标记为error
        final processedMessages = <Message>[];
        for (final message in conversation.messages) {
          if (!message.isUser && message.status == MessageStatus.sending) {
            // 如果AI消息处于sending状态，说明上次会话可能异常中断
            // 如果消息内容为空，完全删除该消息；否则标记为error并保留已有内容
            if (message.content.isEmpty) {
              // 内容为空，完全删除
              continue;
            } else {
              // 有部分内容，标记为error并添加提示
              processedMessages.add(message.copyWith(
                status: MessageStatus.error,
                content: '${message.content}\n\n[${l10n.responseInterrupted}]',
              ));
            }
          } else {
            processedMessages.add(message);
          }
        }

        setState(() {
          _currentConversation = conversation;
          _messages.clear();
          _messages.addAll(processedMessages);
          _currentTitle = conversation.title;
          _autoTitleGenerated = false; // 重置标题生成标志
        });

        // 保存处理后的对话，确保状态更新持久化
        if (processedMessages.length != conversation.messages.length) {
          await _conversationService.updateConversation(
            conversation.copyWith(messages: processedMessages),
          );
        }

        _scrollToBottom();
        return;
      }
    }

    await _createNewConversation();
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
    setState(() {
      _currentConversation = conversation;
      _messages.clear();
      _currentTitle = conversation.title;
      _autoTitleGenerated = false; // 重置标题生成标志
    });
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
      setState(() {
        _currentConversation = updatedConversation;
      });
    }
  }

  /// 滚动消息列表到底部
  ///
  /// 使用ScrollController滚动到最大滚动位置
  /// 添加平滑动画效果（300毫秒，easeOut曲线）
  void _scrollToBottom() {
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (_scrollController.hasClients) {
        _scrollController.animateTo(
          _scrollController.position.maxScrollExtent,
          duration: const Duration(milliseconds: 300),
          curve: Curves.easeOut,
        );
      }
    });
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
  ///   更新思考模式状态变量，未来可以保存到设置中
  void _handleThinkingModeChanged(bool enabled) {
    setState(() {
      _thinkingMode = enabled;
    });
    // 保存到设置服务
    _settingsService.setThinkingMode(enabled);
  }

  /// 处理预设提示词模式开关变化
  void _handlePromptPresetEnabledChanged(bool enabled) {
    setState(() {
      _promptPresetEnabled = enabled;
    });
    // 保存到设置服务
    _settingsService.setPromptPresetEnabled(enabled);
  }

  /// 处理预设选择变化
  void _handlePresetSelected(String presetId) {
    setState(() {
      _currentPresetId = presetId;
    });
    // 保存到设置服务
    _settingsService.setPromptPresetId(presetId);
    // 如果预设模式未启用，自动启用
    if (!_promptPresetEnabled) {
      _handlePromptPresetEnabledChanged(true);
    }
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
        final newTitle = await _aiService.generateConversationTitle(_messages, l10n: l10n);

        // 更新对话标题
        if (_currentConversation != null && newTitle.isNotEmpty) {
          await _conversationService.updateConversationTitle(
              _currentConversation!.id, newTitle);
          setState(() {
            _currentTitle = newTitle;
            _currentConversation = _currentConversation!.copyWith(title: newTitle);
            _autoTitleGenerated = true; // 标记已生成
          });
        }
      } catch (e) {
        // 生成标题失败不影响对话继续
        debugPrint('自动生成标题失败: $e');
      }
    }
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
  Future<void> _sendMessage(String content,
      {List<Attachment> attachments = const []}) async {
    final l10n = AppLocalizations.of(context)!;
    if (content.trim().isEmpty && attachments.isEmpty) return;

    if (!_isConfigured) {
      _showConfigurationDialog();
      return;
    }

    // 获取预设提示词内容（如果预设模式启用）
    String presetSystemPrompt = '';
    if (_promptPresetEnabled && _currentPresetId.isNotEmpty) {
      debugPrint('Preset mode enabled, currentPresetId: $_currentPresetId');
      debugPrint('Available presets count: ${_presets.length}');
      for (final p in _presets) {
        debugPrint('  - ${p.id}: ${p.name}, systemPrompt length: ${p.systemPrompt.length}');
      }

      final preset = _presets.firstWhere(
        (preset) => preset.id == _currentPresetId,
        orElse: () => PromptPreset(id: '', name: '', description: '', systemPrompt: ''),
      );
      if (preset.id.isNotEmpty) {
        presetSystemPrompt = preset.systemPrompt;
        debugPrint('Found preset: ${preset.name}, systemPrompt: ${preset.systemPrompt.length > 50 ? '${preset.systemPrompt.substring(0, 50)}...' : preset.systemPrompt}');
      } else {
        debugPrint('Preset not found for id: $_currentPresetId');
      }
    } else {
      debugPrint('Preset mode disabled or no preset selected. enabled: $_promptPresetEnabled, presetId: $_currentPresetId');
    }
    debugPrint('Final presetSystemPrompt to use: ${presetSystemPrompt.isNotEmpty ? "length: ${presetSystemPrompt.length}" : "empty"}');

    final userMessage = Message(
      id: DateTime.now().millisecondsSinceEpoch.toString(),
      content: content,
      isUser: true,
      timestamp: DateTime.now(),
      attachments: attachments,
    );

    setState(() {
      _messages.add(userMessage);
      _isLoading = true;
    });

    if (_messages.length == 1 && _currentConversation != null) {
      final newTitle = Conversation.generateTitle(content);
      await _conversationService.updateConversationTitle(
          _currentConversation!.id, newTitle);
      setState(() {
        _currentTitle = newTitle;
        _currentConversation = _currentConversation!.copyWith(title: newTitle);
      });
    }

    _scrollToBottom();
    await _saveCurrentConversation();

    final aiMessageId = DateTime.now().millisecondsSinceEpoch.toString();
    var aiMessageIndex = _messages.length;

    setState(() {
      _messages.add(Message(
        id: aiMessageId,
        content: '',
        reasoningContent: null,
        isUser: false,
        timestamp: DateTime.now(),
        status: MessageStatus.sending,
      ));
      _isLoading = false;
      aiMessageIndex = _messages.length - 1;
    });
    _scrollToBottom();

    try {
      // 排除最后两条消息（当前用户消息和空的AI消息）作为历史消息
      final historyMessages = _messages.length >= 2
          ? _messages.sublist(0, _messages.length - 2)
          : <Message>[];
      final stream = _aiService.sendMessageStreaming(content, historyMessages,
          attachments: attachments, thinkingMode: _thinkingMode,
          presetSystemPrompt: presetSystemPrompt, l10n: l10n);
      final reasoningBuffer = StringBuffer();
      final answerBuffer = StringBuffer();
      int receivedChunks = 0;

      await for (final chunk in stream) {
        receivedChunks++;
        final type = chunk['type'] as String;
        final chunkContent = chunk['content'] as String? ?? '';

        if (type == 'reasoning') {
          reasoningBuffer.write(chunkContent);
        } else if (type == 'answer') {
          answerBuffer.write(chunkContent);
        } else {
          // 未知类型，作为答案处理
          answerBuffer.write(chunkContent);
        }

        setState(() {
          _messages[aiMessageIndex] = Message(
            id: aiMessageId,
            content: answerBuffer.toString(),
            reasoningContent: reasoningBuffer.toString(),
            isUser: false,
            timestamp: _messages[aiMessageIndex].timestamp,
            status: MessageStatus.sending,
          );
        });
        _scrollToBottom();
        // 流式输出过程中实时保存对话，防止应用崩溃时消息丢失
        WidgetsBinding.instance.addPostFrameCallback((_) {
          _saveCurrentConversation();
        });
      }

      // 如果没有收到任何chunk，显示错误
      if (receivedChunks == 0) {
        throw Exception('API未返回任何响应内容');
      }

      setState(() {
        _messages[aiMessageIndex] = Message(
          id: aiMessageId,
          content: answerBuffer.toString(),
          reasoningContent: reasoningBuffer.toString(),
          isUser: false,
          timestamp: _messages[aiMessageIndex].timestamp,
          status: MessageStatus.sent,
        );
      });
    } catch (e) {
      debugPrint('AI消息发送错误: $e');
      debugPrint(e.toString());
      setState(() {
        _messages[aiMessageIndex] = Message(
          id: aiMessageId,
          content: '${l10n.errorPrefix}: ${e.toString().replaceAll('Exception: ', '')}',
          reasoningContent: null,
          isUser: false,
          timestamp: _messages[aiMessageIndex].timestamp,
          status: MessageStatus.error,
        );
      });
    }

    _scrollToBottom();
    await _saveCurrentConversation();

    // 尝试自动生成标题
    await _generateAutoTitle();
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
    await Navigator.push(
      context,
      CupertinoPageRoute(
        builder: (context) => const SettingsScreen(),
      ),
    );
    _checkConfiguration();
  }

  /// 打开对话列表界面
  ///
  /// 导航到ConversationListScreen并传递回调函数
  /// 当用户选择对话时，加载对应的对话数据
  Future<void> _openConversationList() async {
    await Navigator.push(
      context,
      CupertinoPageRoute(
        builder: (context) => ConversationListScreen(
          onConversationSelected: (conversation) {
            if (conversation != null) {
              setState(() {
                _currentConversation = conversation;
                _messages.clear();
                _messages.addAll(conversation.messages);
                _currentTitle = conversation.title;
              });
              _scrollToBottom();
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
    /// 构建聊天界面布局
    /// 包含：导航栏、消息列表、输入框、配置提示等组件
    return CupertinoPageScaffold(
      navigationBar: CupertinoNavigationBar(
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
      ),
      child: SafeArea(
        child: Column(
          children: [
            if (!_isConfigured)
              Container(
                width: double.infinity,
                padding: const EdgeInsets.all(16),
                color: CupertinoColors.systemYellow.withOpacity(0.2),
                child: Row(
                  children: [
                    const Icon(
                      CupertinoIcons.exclamationmark_triangle,
                      color: CupertinoColors.systemOrange,
                    ),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Text(l10n.pleaseConfigureAPI),
                    ),
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
                      itemBuilder: (context, index) {
                        if (index == _messages.length && _isLoading) {
                          return const TypingIndicator();
                        }
                        return MessageBubble(message: _messages[index]);
                      },
                    ),
            ),
            ChatInput(
              onSendMessage: (content, attachments) => _sendMessage(content, attachments: attachments),
              onAttachmentsSelected: _handleAttachmentsSelected,
              enabled: _isConfigured,
              thinkingMode: _thinkingMode,
              onThinkingModeChanged: _handleThinkingModeChanged,
              promptPresetEnabled: _promptPresetEnabled,
              onPromptPresetEnabledChanged: _handlePromptPresetEnabledChanged,
              currentPresetId: _currentPresetId,
              onPresetSelected: _handlePresetSelected,
              presets: _presets,
            ),
          ],
        ),
      ),
    );
  }

  /// 构建空状态界面
  ///
  /// 当消息列表为空时显示，包含图标和提示文本
  Widget _buildEmptyState() {
    final l10n = AppLocalizations.of(context)!;
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
            style: const TextStyle(
              fontSize: 18,
              color: CupertinoColors.systemGrey,
            ),
          ),
        ],
      ),
    );
  }

  /// 显示更多选项菜单
  ///
  /// 显示底部操作菜单，包含设置和清除对话等选项
  void _showMoreOptions() {
    final l10n = AppLocalizations.of(context)!;
    showCupertinoModalPopup(
      context: context,
      builder: (context) => CupertinoActionSheet(
        actions: [
          CupertinoActionSheetAction(
            child: Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                const Icon(CupertinoIcons.settings, size: 20),
                const SizedBox(width: 8),
                Text(l10n.settings),
              ],
            ),
            onPressed: () {
              Navigator.pop(context);
              _openSettings();
            },
          ),
          CupertinoActionSheetAction(
            child: Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                const Icon(CupertinoIcons.arrow_down_doc, size: 20),
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
                const Icon(CupertinoIcons.clear, size: 20),
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
      ),
    );
  }

  void _showExportFormatDialog() {
    final l10n = AppLocalizations.of(context)!;
    showCupertinoModalPopup(
      context: context,
      builder: (context) => CupertinoActionSheet(
        title: Text(l10n.exportFormat),
        actions: [
          CupertinoActionSheetAction(
            child: Text(l10n.exportFormatTxt),
            onPressed: () {
              Navigator.pop(context);
              _exportCurrentConversation('txt');
            },
          ),
          CupertinoActionSheetAction(
            child: Text(l10n.exportFormatJson),
            onPressed: () {
              Navigator.pop(context);
              _exportCurrentConversation('json');
            },
          ),
          CupertinoActionSheetAction(
            child: Text(l10n.exportFormatLumenflow),
            onPressed: () {
              Navigator.pop(context);
              _exportCurrentConversation('lumenflow');
            },
          ),
          CupertinoActionSheetAction(
            child: Text(l10n.exportFormatPdf),
            onPressed: () {
              Navigator.pop(context);
              _exportCurrentConversation('pdf');
            },
          ),
        ],
        cancelButton: CupertinoActionSheetAction(
          child: Text(l10n.cancel),
          onPressed: () => Navigator.pop(context),
        ),
      ),
    );
  }

  Future<void> _exportCurrentConversation(String format) async {
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
      String extension;

      switch (format) {
        case 'txt':
          final text = await _conversationService.exportConversationToText(_currentConversation!.id, l10n);
          bytes = utf8.encode(text);
          extension = 'txt';
          break;
        case 'json':
          final jsonData = await _conversationService.exportConversationToJson(_currentConversation!.id, l10n);
          final jsonString = jsonEncode(jsonData);
          bytes = utf8.encode(jsonString);
          extension = 'json';
          break;
        case 'lumenflow':
          final lumenflowData = await _conversationService.exportConversationToLumenflow(_currentConversation!.id, l10n);
          final jsonString = jsonEncode(lumenflowData);
          bytes = utf8.encode(jsonString);
          extension = 'lumenflow';
          break;
        case 'pdf':
          bytes = await _conversationService.exportConversationToPdf(_currentConversation!.id, l10n);
          extension = 'pdf';
          break;
        default:
          throw Exception('不支持的导出格式: $format');
      }

      // 生成文件名
      final safeTitle = _currentConversation!.title.replaceAll(RegExp(r'[^\w\s-]'), '').replaceAll(' ', '_');
      fileName = '${safeTitle}_${DateTime.now().toIso8601String().substring(0, 10)}.$extension';

      // 保存文件
      final result = await _conversationService.saveExportFile(fileName, bytes);
      final filePath = result['filePath']!;
      final locationType = result['locationType']!;

      // 根据位置类型获取本地化的目录名称
      String locationName;
      switch (locationType) {
        case 'download':
          locationName = l10n.downloadDirectory;
          break;
        case 'external':
          locationName = l10n.externalStorageDirectory;
          break;
        case 'app':
          locationName = l10n.appDocumentsDirectory;
          break;
        default:
          locationName = l10n.downloadDirectory;
      }

      // 显示成功消息
      if (mounted) {
        showCupertinoDialog(
          context: context,
          builder: (context) => CupertinoAlertDialog(
            title: Text(l10n.exportConversationSuccess),
            content: Text(l10n.exportLocation(locationName, filePath)),
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
