import 'package:flutter/cupertino.dart';
import 'package:intl/intl.dart';
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
                  Text(
                    widget.message.content,
                    style: TextStyle(
                      color: widget.message.isUser
                          ? CupertinoColors.white
                          : (widget.message.status == MessageStatus.error
                          ? CupertinoColors.systemRed
                          : CupertinoColors.black),
                      fontSize: 16,
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
                              ? CupertinoColors.white.withOpacity(0.7)
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