import 'package:cupertino_ui/cupertino_ui.dart';
import 'package:intl/intl.dart';

import '../l10n/app_localizations.dart';
import '../models/message.dart';
import '../utils/app_theme.dart';

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
    final fontFallback =
        cjkFontFallbackForLocale(Localizations.maybeLocaleOf(context));

    return CupertinoPageScaffold(
      backgroundColor: AppTokens.bg(context),
      navigationBar: CupertinoNavigationBar(
        backgroundColor: AppTokens.bg(context),
        middle: Text(l10n.searchMessages),
        border: Border(
          bottom: BorderSide(
            color: AppTokens.separator(context),
            width: 0.5,
          ),
        ),
      ),
      child: SafeArea(
        child: Center(
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: AppTokens.chatMaxWidth),
            child: Column(
              children: [
                Padding(
                  padding: const EdgeInsets.fromLTRB(16, 12, 16, 6),
                  child: CupertinoSearchTextField(
                    controller: _controller,
                    autofocus: true,
                    placeholder: l10n.searchMessages,
                    backgroundColor: AppTokens.fill(context),
                    borderRadius: BorderRadius.circular(10),
                    style: TextStyle(
                      fontSize: 15,
                      fontFamilyFallback: fontFallback,
                      color: AppTokens.label(context),
                    ),
                    placeholderStyle: TextStyle(
                      fontSize: 15,
                      fontFamilyFallback: fontFallback,
                      color: AppTokens.labelTertiary(context),
                    ),
                    onChanged: (value) => setState(() => _query = value),
                  ),
                ),
                Expanded(child: _buildResults(context, l10n, fontFallback)),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildResults(
    BuildContext context,
    AppLocalizations l10n,
    List<String> fontFallback,
  ) {
    if (_query.trim().isEmpty) {
      return Center(
        child: Text(
          l10n.messageSearchHint,
          style: TextStyle(
            fontSize: 14.5,
            fontFamilyFallback: fontFallback,
            color: AppTokens.labelSecondary(context),
          ),
        ),
      );
    }

    final results = _results;
    if (results.isEmpty) {
      return Center(
        child: Text(
          l10n.messageSearchNoResults,
          style: TextStyle(
            fontSize: 14.5,
            fontFamilyFallback: fontFallback,
            color: AppTokens.labelSecondary(context),
          ),
        ),
      );
    }

    return ListView.separated(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      itemCount: results.length,
      separatorBuilder: (_, _) => Container(
        height: 0.5,
        margin: const EdgeInsets.only(left: 44),
        color: AppTokens.separator(context),
      ),
      itemBuilder: (context, index) {
        final message = results[index];
        final snippet = message.content.trim().isNotEmpty
            ? message.content.trim()
            : (message.reasoningContent ?? '').trim();

        return GestureDetector(
          behavior: HitTestBehavior.opaque,
          onTap: () => Navigator.pop(context, message.id),
          child: Padding(
            padding: const EdgeInsets.symmetric(vertical: 12),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Container(
                  width: 32,
                  height: 32,
                  decoration: BoxDecoration(
                    color: message.isUser
                        ? AppTokens.accentSoft(context)
                        : AppTokens.fill(context),
                    shape: BoxShape.circle,
                  ),
                  child: Icon(
                    message.isUser
                        ? CupertinoIcons.person_fill
                        : CupertinoIcons.chat_bubble_text,
                    size: 15,
                    color: message.isUser
                        ? AppTokens.accent(context)
                        : AppTokens.labelSecondary(context),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        snippet,
                        maxLines: 3,
                        overflow: TextOverflow.ellipsis,
                        style: TextStyle(
                          fontSize: 14.5,
                          height: 1.4,
                          fontFamilyFallback: fontFallback,
                          color: AppTokens.label(context),
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        '${message.isUser ? l10n.user : l10n.aiAssistant} · '
                        '${DateFormat('MM-dd HH:mm').format(message.timestamp)}',
                        style: TextStyle(
                          fontSize: 12,
                          color: AppTokens.labelTertiary(context),
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        );
      },
    );
  }
}
