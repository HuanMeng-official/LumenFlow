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

class ChatScreen extends StatefulWidget {
  const ChatScreen({Key? key}) : super(key: key);

  @override
  State<ChatScreen> createState() => _ChatScreenState();
}

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
    _checkConfiguration();
    _loadCurrentConversation();
  }

  Future<void> _checkConfiguration() async {
    final configured = await _settingsService.isConfigured();
    setState(() {
      _isConfigured = configured;
    });
  }

  Future<void> _loadCurrentConversation() async {
    final currentConversationId = await _conversationService.getCurrentConversationId();

    if (currentConversationId != null) {
      final conversation = await _conversationService.getConversationById(currentConversationId);
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

  Future<void> _createNewConversation() async {
    final conversation = await _conversationService.createNewConversation();
    setState(() {
      _currentConversation = conversation;
      _messages.clear();
      _currentTitle = conversation.title;
    });
  }

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

  Future<void> _handleAttachmentsSelected(List<Attachment> attachments) async {
    if (attachments.isEmpty) return;

    // 创建一个只有附件的消息（没有文本内容）
    await _sendMessage('', attachments: attachments);
  }

  Future<void> _sendMessage(String content, {List<Attachment> attachments = const []}) async {
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
      await _conversationService.updateConversationTitle(_currentConversation!.id, newTitle);
      setState(() {
        _currentTitle = newTitle;
        _currentConversation = _currentConversation!.copyWith(title: newTitle);
      });
    }

    _scrollToBottom();
    await _saveCurrentConversation();

    // Create a placeholder AI message for streaming
    final aiMessageId = DateTime.now().millisecondsSinceEpoch.toString();
    var aiMessageIndex = _messages.length; // Index where AI message will be added

    setState(() {
      _messages.add(Message(
        id: aiMessageId,
        content: '',
        isUser: false,
        timestamp: DateTime.now(),
        status: MessageStatus.sending,
      ));
      _isLoading = false; // We'll handle loading state differently for streaming
      aiMessageIndex = _messages.length - 1; // Update index after adding
    });
    _scrollToBottom();

    try {
      final stream = _aiService.sendMessageStreaming(content, _messages, attachments: attachments);
      final buffer = StringBuffer();

      await for (final chunk in stream) {
        buffer.write(chunk);
        // Update the AI message with new content
        setState(() {
          _messages[aiMessageIndex] = Message(
            id: aiMessageId,
            content: buffer.toString(),
            isUser: false,
            timestamp: _messages[aiMessageIndex].timestamp,
            status: MessageStatus.sending,
          );
        });
        _scrollToBottom();
      }

      // Streaming completed successfully - update status to sent
      setState(() {
        _messages[aiMessageIndex] = Message(
          id: aiMessageId,
          content: buffer.toString(),
          isUser: false,
          timestamp: _messages[aiMessageIndex].timestamp,
          status: MessageStatus.sent,
        );
      });
    } catch (e) {
      // Error during streaming
      setState(() {
        _messages[aiMessageIndex] = Message(
          id: aiMessageId,
          content: '错误: ${e.toString().replaceAll('Exception: ', '')}',
          isUser: false,
          timestamp: _messages[aiMessageIndex].timestamp,
          status: MessageStatus.error,
        );
      });
    }

    _scrollToBottom();
    await _saveCurrentConversation();
  }

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

  Future<void> _openSettings() async {
    await Navigator.push(
      context,
      CupertinoPageRoute(
        builder: (context) => const SettingsScreen(),
      ),
    );
    _checkConfiguration();
  }

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
    return CupertinoPageScaffold(
      navigationBar: CupertinoNavigationBar(
        leading: CupertinoButton(
          padding: EdgeInsets.zero,
          child: const Icon(CupertinoIcons.chat_bubble_2),
          onPressed: _openConversationList,
        ),
        middle: Text(_currentTitle),
        trailing: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            CupertinoButton(
              padding: EdgeInsets.zero,
              child: const Icon(CupertinoIcons.add),
              onPressed: _createNewConversation,
            ),
            CupertinoButton(
              padding: EdgeInsets.zero,
              child: const Icon(CupertinoIcons.ellipsis),
              onPressed: _showMoreOptions,
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
                      child: const Text('设置'),
                      onPressed: _openSettings,
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

class TypingIndicator extends StatelessWidget {
  const TypingIndicator({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
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