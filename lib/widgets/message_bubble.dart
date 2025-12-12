import 'package:flutter/cupertino.dart';
import 'package:intl/intl.dart';
import 'package:flutter_markdown/flutter_markdown.dart';
import '../models/message.dart';
import '../models/user_profile.dart';
import '../services/user_service.dart';
import 'avatar_widget.dart';

class MessageBubble extends StatefulWidget {
  final Message message;

  const MessageBubble({Key? key, required this.message}) : super(key: key);

  @override
  State<MessageBubble> createState() => _MessageBubbleState();
}

class _MessageBubbleState extends State<MessageBubble> {
  final UserService _userService = UserService();
  UserProfile? _userProfile;

  @override
  void initState() {
    super.initState();
    if (widget.message.isUser) {
      _loadUserProfile();
    }
  }

  Future<void> _loadUserProfile() async {
    final profile = await _userService.getUserProfile();
    if (mounted) {
      setState(() {
        _userProfile = profile;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        mainAxisAlignment:
        widget.message.isUser ? MainAxisAlignment.end : MainAxisAlignment.start,
        crossAxisAlignment: CrossAxisAlignment.end,
        children: [
          if (!widget.message.isUser) ...[
            Container(
              width: 32,
              height: 32,
              decoration: BoxDecoration(
                color: widget.message.status == MessageStatus.error
                    ? CupertinoColors.systemRed
                    : CupertinoColors.systemBlue,
                borderRadius: BorderRadius.circular(16),
              ),
              child: Icon(
                widget.message.status == MessageStatus.error
                    ? CupertinoIcons.exclamationmark
                    : CupertinoIcons.sparkles,
                color: CupertinoColors.white,
                size: 16,
              ),
            ),
            const SizedBox(width: 8),
          ],
          Flexible(
            child: Container(
              constraints: BoxConstraints(
                maxWidth: MediaQuery.of(context).size.width * 0.75,
              ),
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
              decoration: BoxDecoration(
                color: widget.message.isUser
                    ? CupertinoColors.systemBlue
                    : (widget.message.status == MessageStatus.error
                    ? CupertinoColors.systemRed.withOpacity(0.1)
                    : CupertinoColors.systemGrey6),
                borderRadius: BorderRadius.circular(20),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  SelectableRegion(
                    selectionControls: cupertinoTextSelectionControls,
                    child: MarkdownBody(
                      data: widget.message.content,
                    styleSheet: MarkdownStyleSheet(
                      p: TextStyle(
                        color: widget.message.isUser
                            ? CupertinoColors.white
                            : (widget.message.status == MessageStatus.error
                            ? CupertinoColors.systemRed
                            : CupertinoColors.black),
                        fontSize: 16,
                        height: 1.5,
                      ),
                      code: TextStyle(
                        color: widget.message.isUser
                            ? CupertinoColors.white
                            : (widget.message.status == MessageStatus.error
                            ? CupertinoColors.systemRed
                            : CupertinoColors.black),
                        fontSize: 16,
                        fontFamily: 'Courier',
                        backgroundColor: widget.message.isUser
                            ? CupertinoColors.systemGrey6
                            : CupertinoColors.systemGrey5,
                      ),
                      codeblockPadding: const EdgeInsets.all(12),
                      codeblockDecoration: BoxDecoration(
                        color: widget.message.isUser
                            ? CupertinoColors.systemGrey6
                            : CupertinoColors.systemGrey5,
                        borderRadius: BorderRadius.circular(8),
                      ),
                      h1: TextStyle(
                        color: widget.message.isUser
                            ? CupertinoColors.white
                            : (widget.message.status == MessageStatus.error
                            ? CupertinoColors.systemRed
                            : CupertinoColors.black),
                        fontSize: 24,
                        fontWeight: FontWeight.bold,
                        height: 1.5,
                      ),
                      h2: TextStyle(
                        color: widget.message.isUser
                            ? CupertinoColors.white
                            : (widget.message.status == MessageStatus.error
                            ? CupertinoColors.systemRed
                            : CupertinoColors.black),
                        fontSize: 22,
                        fontWeight: FontWeight.bold,
                        height: 1.5,
                      ),
                      h3: TextStyle(
                        color: widget.message.isUser
                            ? CupertinoColors.white
                            : (widget.message.status == MessageStatus.error
                            ? CupertinoColors.systemRed
                            : CupertinoColors.black),
                        fontSize: 20,
                        fontWeight: FontWeight.bold,
                        height: 1.5,
                      ),
                      h4: TextStyle(
                        color: widget.message.isUser
                            ? CupertinoColors.white
                            : (widget.message.status == MessageStatus.error
                            ? CupertinoColors.systemRed
                            : CupertinoColors.black),
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                        height: 1.5,
                      ),
                      h5: TextStyle(
                        color: widget.message.isUser
                            ? CupertinoColors.white
                            : (widget.message.status == MessageStatus.error
                            ? CupertinoColors.systemRed
                            : CupertinoColors.black),
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                        height: 1.5,
                      ),
                      h6: TextStyle(
                        color: widget.message.isUser
                            ? CupertinoColors.white
                            : (widget.message.status == MessageStatus.error
                            ? CupertinoColors.systemRed
                            : CupertinoColors.black),
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                        height: 1.5,
                      ),
                      a: TextStyle(
                        color: widget.message.isUser
                            ? CupertinoColors.white
                            : CupertinoColors.systemBlue,
                        fontSize: 16,
                        decoration: TextDecoration.underline,
                        height: 1.5,
                      ),
                      blockquote: TextStyle(
                        color: widget.message.isUser
                            ? CupertinoColors.white
                            : (widget.message.status == MessageStatus.error
                            ? CupertinoColors.systemRed
                            : CupertinoColors.systemGrey),
                        fontSize: 16,
                        fontStyle: FontStyle.italic,
                        height: 1.5,
                      ),
                      blockquoteDecoration: BoxDecoration(
                        color: widget.message.isUser
                            ? CupertinoColors.systemGrey6
                            : CupertinoColors.systemGrey5,
                        borderRadius: BorderRadius.circular(4),
                        border: Border(
                          left: BorderSide(
                            color: widget.message.isUser
                                ? CupertinoColors.systemBlue
                                : CupertinoColors.systemGrey,
                            width: 4,
                          ),
                        ),
                      ),
                      blockquotePadding: const EdgeInsets.only(left: 16, top: 8, bottom: 8, right: 8),
                      listBullet: TextStyle(
                        color: widget.message.isUser
                            ? CupertinoColors.white
                            : (widget.message.status == MessageStatus.error
                            ? CupertinoColors.systemRed
                            : CupertinoColors.black),
                        fontSize: 16,
                        height: 1.5,
                      ),
                    ),
                  ),
                ),
                  const SizedBox(height: 4),
                  Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Text(
                        DateFormat('HH:mm').format(widget.message.timestamp),
                        style: TextStyle(
                          color: widget.message.isUser
                              ? CupertinoColors.systemGrey4
                              : CupertinoColors.systemGrey,
                          fontSize: 12,
                        ),
                      ),
                      if (widget.message.status == MessageStatus.sending) ...[
                        const SizedBox(width: 4),
                        const SizedBox(
                          width: 12,
                          height: 12,
                          child: CupertinoActivityIndicator(),
                        ),
                      ],
                      if (widget.message.status == MessageStatus.error) ...[
                        const SizedBox(width: 4),
                        const Icon(
                          CupertinoIcons.exclamationmark_circle_fill,
                          size: 12,
                          color: CupertinoColors.systemRed,
                        ),
                      ],
                    ],
                  ),
                ],
              ),
            ),
          ),
          if (widget.message.isUser) ...[
            const SizedBox(width: 8),
            _userProfile != null
                ? AvatarWidget(
              userProfile: _userProfile!,
              size: 32,
            )
                : Container(
              width: 32,
              height: 32,
              decoration: BoxDecoration(
                color: CupertinoColors.systemGrey4,
                borderRadius: BorderRadius.circular(16),
              ),
              child: const Icon(
                CupertinoIcons.person_fill,
                color: CupertinoColors.white,
                size: 16,
              ),
            ),
          ],
        ],
      ),
    );
  }
}