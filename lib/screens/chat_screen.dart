import 'package:flutter/cupertino.dart';
import '../models/message.dart';
import '../models/attachment.dart';
import '../models/conversation.dart';
import '../services/ai_service.dart';
import '../services/conversation_service.dart';
import '../services/settings_service.dart';
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

  bool _isLoading = false;
  bool _isConfigured = false;
  Conversation? _currentConversation;
  String _currentTitle = 'AI 助手';

  @override
  void initState() {
    super.initState();

    /// 初始化状态时检查应用配置并加载当前对话
    /// 1. 检查API配置是否完成
    /// 2. 加载最近使用的对话或创建新对话
    _checkConfiguration();
    _loadCurrentConversation();
  }

  /// 检查应用配置状态
  ///
  /// 调用设置服务检查API密钥等必要配置是否已设置
  /// 更新_isConfigured状态变量，控制界面显示和交互
  Future<void> _checkConfiguration() async {
    final configured = await _settingsService.isConfigured();
    setState(() {
      _isConfigured = configured;
    });
  }

  /// 加载当前对话
  ///
  /// 从对话服务获取最近使用的对话ID，然后加载对应的对话数据
  /// 如果不存在最近对话，则创建新的对话
  /// 加载完成后，将对话消息添加到状态中并滚动到底部
  Future<void> _loadCurrentConversation() async {
    final currentConversationId =
        await _conversationService.getCurrentConversationId();

    if (currentConversationId != null) {
      final conversation =
          await _conversationService.getConversationById(currentConversationId);
      if (conversation != null) {
        setState(() {
          _currentConversation = conversation;
          _messages.clear();
          _messages.addAll(conversation.messages);
          _currentTitle = conversation.title;
        });
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
    final conversation = await _conversationService.createNewConversation();
    setState(() {
      _currentConversation = conversation;
      _messages.clear();
      _currentTitle = conversation.title;
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
  ///   当用户选择附件但没有输入文本时，发送一个空消息包含附件
  Future<void> _handleAttachmentsSelected(List<Attachment> attachments) async {
    if (attachments.isEmpty) return;

    await _sendMessage('', attachments: attachments);
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
    if (content.trim().isEmpty && attachments.isEmpty) return;

    if (!_isConfigured) {
      _showConfigurationDialog();
      return;
    }

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
      final stream = _aiService.sendMessageStreaming(content, _messages,
          attachments: attachments);
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
      print('AI消息发送错误: $e');
      print(e.toString());
      setState(() {
        _messages[aiMessageIndex] = Message(
          id: aiMessageId,
          content: '错误: ${e.toString().replaceAll('Exception: ', '')}',
          reasoningContent: null,
          isUser: false,
          timestamp: _messages[aiMessageIndex].timestamp,
          status: MessageStatus.error,
        );
      });
    }

    _scrollToBottom();
    await _saveCurrentConversation();
  }

  /// 显示配置提示对话框
  ///
  /// 当用户尝试发送消息但应用未配置API密钥时显示
  /// 提供选项：取消或跳转到设置界面
  void _showConfigurationDialog() {
    showCupertinoDialog(
      context: context,
      builder: (context) => CupertinoAlertDialog(
        title: const Text('需要配置'),
        content: const Text('请先在设置中配置API端点和密钥'),
        actions: [
          CupertinoDialogAction(
            child: const Text('取消'),
            onPressed: () => Navigator.pop(context),
          ),
          CupertinoDialogAction(
            child: const Text('去设置'),
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
    showCupertinoDialog(
      context: context,
      builder: (context) => CupertinoAlertDialog(
        title: const Text('清除当前对话'),
        content: const Text('确定要清除当前对话的所有消息吗？'),
        actions: [
          CupertinoDialogAction(
            child: const Text('取消'),
            onPressed: () => Navigator.pop(context),
          ),
          CupertinoDialogAction(
            isDestructiveAction: true,
            child: const Text('清除'),
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
    /// 构建聊天界面布局
    /// 包含：导航栏、消息列表、输入框、配置提示等组件
    return CupertinoPageScaffold(
      navigationBar: CupertinoNavigationBar(
        leading: CupertinoButton(
          padding: EdgeInsets.zero,
          onPressed: _openConversationList,
          child: const Icon(CupertinoIcons.chat_bubble_2),
        ),
        middle: Text(_currentTitle),
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
                    const Expanded(
                      child: Text('请先配置API设置才能开始对话'),
                    ),
                    CupertinoButton(
                      padding: EdgeInsets.zero,
                      onPressed: _openSettings,
                      child: const Text('设置'),
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
              onSendMessage: (content) => _sendMessage(content),
              onAttachmentsSelected: _handleAttachmentsSelected,
              enabled: _isConfigured,
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
    return const Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            CupertinoIcons.chat_bubble_2,
            size: 64,
            color: CupertinoColors.systemGrey,
          ),
          SizedBox(height: 16),
          Text(
            '开始与AI对话吧！',
            style: TextStyle(
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
    showCupertinoModalPopup(
      context: context,
      builder: (context) => CupertinoActionSheet(
        actions: [
          CupertinoActionSheetAction(
            child: const Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(CupertinoIcons.settings, size: 20),
                SizedBox(width: 8),
                Text('设置'),
              ],
            ),
            onPressed: () {
              Navigator.pop(context);
              _openSettings();
            },
          ),
          CupertinoActionSheetAction(
            isDestructiveAction: true,
            child: const Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(CupertinoIcons.clear, size: 20),
                SizedBox(width: 8),
                Text('清除当前对话'),
              ],
            ),
            onPressed: () {
              Navigator.pop(context);
              _clearCurrentConversation();
            },
          ),
        ],
        cancelButton: CupertinoActionSheetAction(
          child: const Text('取消'),
          onPressed: () => Navigator.pop(context),
        ),
      ),
    );
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
