import 'package:cupertino_ui/cupertino_ui.dart';
import 'package:intl/intl.dart';
import 'package:material_ui/material_ui.dart' as material;

import '../l10n/app_localizations.dart';
import '../models/message.dart';

/// 在当前会话内搜索消息正文和思考内容。
class MessageSearchScreen extends StatefulWidget {
  final List<Message> messages;

  const MessageSearchScreen({super.key, required this.messages});

  @override
  State<MessageSearchScreen> createState() => _MessageSearchScreenState();
}

class _MessageSearchScreenState extends State<MessageSearchScreen> {
  final TextEditingController _controller = TextEditingController();
  String _query = '';

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  List<Message> get _results {
    final query = _query.trim().toLowerCase();
    if (query.isEmpty) return const [];
    return widget.messages.where((message) {
      final content = message.content.toLowerCase();
      final reasoning = (message.reasoningContent ?? '').toLowerCase();
      return content.contains(query) || reasoning.contains(query);
    }).toList();
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final brightness = CupertinoTheme.of(context).brightness;
    final searchBackground = brightness == Brightness.dark
        ? CupertinoColors.systemGrey6.darkColor
        : CupertinoColors.systemGrey6.color;
    final searchIconColor = brightness == Brightness.dark
        ? CupertinoColors.systemGrey.darkColor
        : CupertinoColors.systemGrey;
    final primaryColor = CupertinoTheme.of(context).primaryColor;

    return CupertinoPageScaffold(
      navigationBar: CupertinoNavigationBar(
        middle: Text(l10n.searchMessages),
      ),
      child: SafeArea(
        child: Column(
          children: [
            Padding(
              padding: const EdgeInsets.fromLTRB(16, 8, 16, 4),
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 10),
                decoration: BoxDecoration(
                  color: searchBackground,
                  borderRadius: BorderRadius.circular(10),
                ),
                child: material.Material(
                  color: material.Colors.transparent,
                  child: Row(
                    children: [
                      Icon(
                        CupertinoIcons.search,
                        size: 18,
                        color: searchIconColor,
                      ),
                      const SizedBox(width: 8),
                      Expanded(
                        child: material.TextField(
                          controller: _controller,
                          autofocus: true,
                          onChanged: (value) {
                            setState(() {
                              _query = value;
                            });
                          },
                          style: const TextStyle(fontSize: 16),
                          cursorColor: primaryColor,
                          decoration: material.InputDecoration(
                            border: material.InputBorder.none,
                            focusedBorder: material.InputBorder.none,
                            enabledBorder: material.InputBorder.none,
                            hintText: l10n.searchMessages,
                            hintStyle: TextStyle(color: searchIconColor),
                            isDense: true,
                            contentPadding: const EdgeInsets.symmetric(
                              vertical: 10,
                            ),
                          ),
                        ),
                      ),
                      if (_query.isNotEmpty)
                        GestureDetector(
                          onTap: () {
                            _controller.clear();
                            setState(() {
                              _query = '';
                            });
                          },
                          child: Padding(
                            padding: const EdgeInsets.all(4),
                            child: Icon(
                              CupertinoIcons.xmark_circle_fill,
                              size: 16,
                              color: searchIconColor,
                            ),
                          ),
                        ),
                    ],
                  ),
                ),
              ),
            ),
            Expanded(child: _buildResults(l10n, primaryColor)),
          ],
        ),
      ),
    );
  }

  Widget _buildResults(AppLocalizations l10n, Color primaryColor) {
    if (_query.trim().isEmpty) {
      return Center(
        child: Text(
          l10n.messageSearchHint,
          style: const TextStyle(
            fontSize: 15,
            color: CupertinoColors.systemGrey,
          ),
        ),
      );
    }

    final results = _results;
    if (results.isEmpty) {
      return Center(
        child: Text(
          l10n.messageSearchNoResults,
          style: const TextStyle(
            fontSize: 15,
            color: CupertinoColors.systemGrey,
          ),
        ),
      );
    }

    return ListView.builder(
      itemCount: results.length,
      itemBuilder: (context, index) {
        final message = results[index];
        final snippet = message.content.trim().isNotEmpty
            ? message.content.trim()
            : (message.reasoningContent ?? '').trim();

        return CupertinoListTile(
          leading: Container(
            width: 32,
            height: 32,
            decoration: BoxDecoration(
              color: message.isUser
                  ? primaryColor.withValues(alpha: 0.15)
                  : CupertinoColors.systemGrey5.resolveFrom(context),
              borderRadius: BorderRadius.circular(16),
            ),
            child: Icon(
              message.isUser
                  ? CupertinoIcons.person_fill
                  : CupertinoIcons.sparkles,
              size: 16,
              color: message.isUser ? primaryColor : CupertinoColors.systemGrey,
            ),
          ),
          title: Text(
            snippet,
            maxLines: 3,
            overflow: TextOverflow.ellipsis,
          ),
          subtitle: Text(
            '${message.isUser ? l10n.user : l10n.aiAssistant} · '
            '${DateFormat('MM-dd HH:mm').format(message.timestamp)}',
            style: const TextStyle(
              fontSize: 12,
              color: CupertinoColors.systemGrey,
            ),
          ),
          onTap: () => Navigator.pop(context, message.id),
        );
      },
    );
  }
}
