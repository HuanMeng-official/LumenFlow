import 'package:flutter/cupertino.dart';
import 'package:intl/intl.dart';
import 'dart:convert';
import '../l10n/app_localizations.dart';
import '../models/conversation.dart';
import '../services/conversation_service.dart';

class ConversationListScreen extends StatefulWidget {
  final Function(Conversation?) onConversationSelected;

  const ConversationListScreen({
    super.key,
    required this.onConversationSelected,
  });

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
    final l10n = AppLocalizations.of(context)!;
    final conversation = await _conversationService.createNewConversation(
      title: l10n.newConversation,
    );
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
    final l10n = AppLocalizations.of(context)!;
    showCupertinoDialog(
      context: context,
      builder: (context) => CupertinoAlertDialog(
        title: Text(l10n.deleteConversation),
        content: Text(l10n.deleteConversationConfirm(conversation.title)),
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
    final l10n = AppLocalizations.of(context)!;
    final TextEditingController controller =
        TextEditingController(text: conversation.title);

    showCupertinoDialog(
      context: context,
      builder: (context) => CupertinoAlertDialog(
        title: Text(l10n.editConversationTitle),
        content: Padding(
          padding: const EdgeInsets.only(top: 16),
          child: CupertinoTextField(
            controller: controller,
            placeholder: l10n.enterConversationTitle,
          ),
        ),
        actions: [
          CupertinoDialogAction(
            child: Text(l10n.cancel),
            onPressed: () => Navigator.pop(context),
          ),
          CupertinoDialogAction(
            child: Text(l10n.save),
            onPressed: () async {
              if (controller.text.trim().isNotEmpty) {
                await _conversationService.updateConversationTitle(
                  conversation.id,
                  controller.text.trim(),
                );
                await _loadConversations();
              }
              if (mounted) {
                Navigator.pop(
                    context); // ignore: use_build_context_synchronously
              }
            },
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    return CupertinoPageScaffold(
      navigationBar: CupertinoNavigationBar(
        middle: Text(l10n.conversations),
        trailing: CupertinoButton(
          padding: EdgeInsets.zero,
          onPressed: _createNewConversation,
          child: const Icon(CupertinoIcons.add),
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
                      final isCurrentConversation =
                          conversation.id == _currentConversationId;

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
                                onPressed: () =>
                                    _showConversationOptions(conversation),
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
    final l10n = AppLocalizations.of(context)!;
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
          Text(
            l10n.noConversations,
            style: const TextStyle(
              fontSize: 18,
              color: CupertinoColors.systemGrey,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            l10n.createNewConversation,
            style: const TextStyle(
              fontSize: 14,
              color: CupertinoColors.systemGrey2,
            ),
          ),
          const SizedBox(height: 24),
          CupertinoButton.filled(
            onPressed: _createNewConversation,
            child: Text(l10n.newConversation),
          ),
        ],
      ),
    );
  }

  void _showConversationOptions(Conversation conversation) {
    final l10n = AppLocalizations.of(context)!;
    showCupertinoModalPopup(
      context: context,
      builder: (context) => CupertinoActionSheet(
        title: Text(conversation.title),
        actions: [
          CupertinoActionSheetAction(
            child: Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                const Icon(CupertinoIcons.pencil, size: 20),
                const SizedBox(width: 8),
                Text(l10n.editTitle),
              ],
            ),
            onPressed: () {
              Navigator.pop(context);
              _editConversationTitle(conversation);
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
              _showExportFormatDialog(conversation);
            },
          ),
          CupertinoActionSheetAction(
            isDestructiveAction: true,
            child: Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                const Icon(CupertinoIcons.delete, size: 20),
                const SizedBox(width: 8),
                Text(l10n.deleteConversation2),
              ],
            ),
            onPressed: () {
              Navigator.pop(context);
              _deleteConversation(conversation);
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

  void _showExportFormatDialog(Conversation conversation) {
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
              _exportConversation(conversation, 'txt');
            },
          ),
          CupertinoActionSheetAction(
            child: Text(l10n.exportFormatJson),
            onPressed: () {
              Navigator.pop(context);
              _exportConversation(conversation, 'json');
            },
          ),
          CupertinoActionSheetAction(
            child: Text(l10n.exportFormatLumenflow),
            onPressed: () {
              Navigator.pop(context);
              _exportConversation(conversation, 'lumenflow');
            },
          ),
          CupertinoActionSheetAction(
            child: Text(l10n.exportFormatPdf),
            onPressed: () {
              Navigator.pop(context);
              _exportConversation(conversation, 'pdf');
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

  Future<void> _exportConversation(Conversation conversation, String format) async {
    final l10n = AppLocalizations.of(context)!;
    try {
      List<int> bytes;
      String fileName;
      String extension;

      switch (format) {
        case 'txt':
          final text = await _conversationService.exportConversationToText(conversation.id);
          bytes = utf8.encode(text);
          extension = 'txt';
          break;
        case 'json':
          final jsonData = await _conversationService.exportConversationToJson(conversation.id);
          final jsonString = jsonEncode(jsonData);
          bytes = utf8.encode(jsonString);
          extension = 'json';
          break;
        case 'lumenflow':
          final lumenflowData = await _conversationService.exportConversationToLumenflow(conversation.id);
          final jsonString = jsonEncode(lumenflowData);
          bytes = utf8.encode(jsonString);
          extension = 'lumenflow';
          break;
        case 'pdf':
          bytes = await _conversationService.exportConversationToPdf(conversation.id);
          extension = 'pdf';
          break;
        default:
          throw Exception('不支持的导出格式: $format');
      }

      // 生成文件名
      final safeTitle = conversation.title.replaceAll(RegExp(r'[^\w\s-]'), '').replaceAll(' ', '_');
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

  String _formatDate(DateTime date) {
    final l10n = AppLocalizations.of(context)!;
    final now = DateTime.now();
    final difference = now.difference(date);

    if (difference.inDays == 0) {
      return DateFormat('HH:mm').format(date);
    } else if (difference.inDays == 1) {
      return l10n.yesterday;
    } else if (difference.inDays < 7) {
      return l10n.daysAgo(difference.inDays);
    } else {
      return DateFormat('MM/dd').format(date);
    }
  }
}
