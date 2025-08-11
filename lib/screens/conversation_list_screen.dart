import 'package:flutter/cupertino.dart';
import 'package:intl/intl.dart';
import '../models/conversation.dart';
import '../services/conversation_service.dart';

class ConversationListScreen extends StatefulWidget {
  final Function(Conversation?) onConversationSelected;

  const ConversationListScreen({
    Key? key,
    required this.onConversationSelected,
  }) : super(key: key);

  @override
  State<ConversationListScreen> createState() => _ConversationListScreenState();
}

class _ConversationListScreenState extends State<ConversationListScreen> {
  final ConversationService _conversationService = ConversationService();
  List<Conversation> _conversations = [];
  String? _currentConversationId;
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadConversations();
  }

  Future<void> _loadConversations() async {
    final conversations = await _conversationService.loadConversations();
    final currentId = await _conversationService.getCurrentConversationId();

    setState(() {
      _conversations = conversations;
      _currentConversationId = currentId;
      _isLoading = false;
    });
  }

  Future<void> _createNewConversation() async {
    final conversation = await _conversationService.createNewConversation();
    setState(() {
      _conversations.insert(0, conversation);
      _currentConversationId = conversation.id;
    });
    widget.onConversationSelected(conversation);
    if (mounted) {
      Navigator.pop(context);
    }
  }

  Future<void> _selectConversation(Conversation conversation) async {
    await _conversationService.setCurrentConversationId(conversation.id);
    setState(() {
      _currentConversationId = conversation.id;
    });
    widget.onConversationSelected(conversation);
    if (mounted) {
      Navigator.pop(context);
    }
  }

  Future<void> _deleteConversation(Conversation conversation) async {
    showCupertinoDialog(
      context: context,
      builder: (context) => CupertinoAlertDialog(
        title: const Text('删除对话'),
        content: Text('确定要删除对话"${conversation.title}"吗？此操作无法撤销。'),
        actions: [
          CupertinoDialogAction(
            child: const Text('取消'),
            onPressed: () => Navigator.pop(context),
          ),
          CupertinoDialogAction(
            isDestructiveAction: true,
            child: const Text('删除'),
            onPressed: () async {
              Navigator.pop(context);
              await _conversationService.deleteConversation(conversation.id);
              await _loadConversations();

              if (conversation.id == _currentConversationId) {
                widget.onConversationSelected(null);
              }
            },
          ),
        ],
      ),
    );
  }

  Future<void> _editConversationTitle(Conversation conversation) async {
    final TextEditingController controller = TextEditingController(text: conversation.title);

    showCupertinoDialog(
      context: context,
      builder: (context) => CupertinoAlertDialog(
        title: const Text('编辑对话标题'),
        content: Padding(
          padding: const EdgeInsets.only(top: 16),
          child: CupertinoTextField(
            controller: controller,
            placeholder: '输入对话标题',
          ),
        ),
        actions: [
          CupertinoDialogAction(
            child: const Text('取消'),
            onPressed: () => Navigator.pop(context),
          ),
          CupertinoDialogAction(
            child: const Text('保存'),
            onPressed: () async {
              if (controller.text.trim().isNotEmpty) {
                await _conversationService.updateConversationTitle(
                  conversation.id,
                  controller.text.trim(),
                );
                await _loadConversations();
              }
              if (mounted) {
                Navigator.pop(context);
              }
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
        middle: const Text('对话记录'),
        trailing: CupertinoButton(
          padding: EdgeInsets.zero,
          child: const Icon(CupertinoIcons.add),
          onPressed: _createNewConversation,
        ),
      ),
      child: SafeArea(
        child: _isLoading
            ? const Center(child: CupertinoActivityIndicator())
            : _conversations.isEmpty
            ? _buildEmptyState()
            : ListView.builder(
          itemCount: _conversations.length,
          itemBuilder: (context, index) {
            final conversation = _conversations[index];
            final isCurrentConversation = conversation.id == _currentConversationId;

            return Container(
              color: isCurrentConversation
                  ? CupertinoColors.systemBlue.withOpacity(0.1)
                  : null,
              child: CupertinoListTile(
                title: Text(
                  conversation.title,
                  style: TextStyle(
                    fontWeight: isCurrentConversation
                        ? FontWeight.w600
                        : FontWeight.normal,
                  ),
                ),
                subtitle: Text(
                  _formatDate(conversation.updatedAt),
                  style: const TextStyle(
                    fontSize: 13,
                    color: CupertinoColors.systemGrey,
                  ),
                ),
                leading: Container(
                  width: 40,
                  height: 40,
                  decoration: BoxDecoration(
                    color: isCurrentConversation
                        ? CupertinoColors.systemBlue
                        : CupertinoColors.systemGrey5,
                    borderRadius: BorderRadius.circular(20),
                  ),
                  child: Icon(
                    CupertinoIcons.chat_bubble_2,
                    color: isCurrentConversation
                        ? CupertinoColors.white
                        : CupertinoColors.systemGrey,
                    size: 20,
                  ),
                ),
                trailing: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    if (conversation.messages.isNotEmpty)
                      Text(
                        '${conversation.messages.length}',
                        style: const TextStyle(
                          fontSize: 12,
                          color: CupertinoColors.systemGrey,
                        ),
                      ),
                    const SizedBox(width: 8),
                    CupertinoButton(
                      padding: EdgeInsets.zero,
                      child: const Icon(
                        CupertinoIcons.ellipsis,
                        size: 20,
                        color: CupertinoColors.systemGrey,
                      ),
                      onPressed: () => _showConversationOptions(conversation),
                    ),
                  ],
                ),
                onTap: () => _selectConversation(conversation),
              ),
            );
          },
        ),
      ),
    );
  }

  Widget _buildEmptyState() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          const Icon(
            CupertinoIcons.chat_bubble_2,
            size: 64,
            color: CupertinoColors.systemGrey3,
          ),
          const SizedBox(height: 16),
          const Text(
            '暂无对话记录',
            style: TextStyle(
              fontSize: 18,
              color: CupertinoColors.systemGrey,
            ),
          ),
          const SizedBox(height: 8),
          const Text(
            '点击右上角的 + 创建新对话',
            style: TextStyle(
              fontSize: 14,
              color: CupertinoColors.systemGrey2,
            ),
          ),
          const SizedBox(height: 24),
          CupertinoButton.filled(
            child: const Text('创建新对话'),
            onPressed: _createNewConversation,
          ),
        ],
      ),
    );
  }

  void _showConversationOptions(Conversation conversation) {
    showCupertinoModalPopup(
      context: context,
      builder: (context) => CupertinoActionSheet(
        title: Text(conversation.title),
        actions: [
          CupertinoActionSheetAction(
            child: const Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(CupertinoIcons.pencil, size: 20),
                SizedBox(width: 8),
                Text('编辑标题'),
              ],
            ),
            onPressed: () {
              Navigator.pop(context);
              _editConversationTitle(conversation);
            },
          ),
          CupertinoActionSheetAction(
            isDestructiveAction: true,
            child: const Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(CupertinoIcons.delete, size: 20),
                SizedBox(width: 8),
                Text('删除对话'),
              ],
            ),
            onPressed: () {
              Navigator.pop(context);
              _deleteConversation(conversation);
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

  String _formatDate(DateTime date) {
    final now = DateTime.now();
    final difference = now.difference(date);

    if (difference.inDays == 0) {
      return DateFormat('HH:mm').format(date);
    } else if (difference.inDays == 1) {
      return '昨天';
    } else if (difference.inDays < 7) {
      return '${difference.inDays}天前';
    } else {
      return DateFormat('MM/dd').format(date);
    }
  }
}