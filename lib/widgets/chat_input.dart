import 'dart:io';
import 'package:flutter/cupertino.dart';
import 'package:image_picker/image_picker.dart';
import '../services/file_service.dart';
import '../models/attachment.dart';

class ChatInput extends StatefulWidget {
  final Function(String) onSendMessage;
  final Function(List<Attachment>)? onAttachmentsSelected;
  final bool enabled;

  const ChatInput({
    Key? key,
    required this.onSendMessage,
    this.onAttachmentsSelected,
    this.enabled = true,
  }) : super(key: key);

  @override
  State<ChatInput> createState() => _ChatInputState();
}

class _ChatInputState extends State<ChatInput> {
  final TextEditingController _controller = TextEditingController();
  final ImagePicker _imagePicker = ImagePicker();
  final FileService _fileService = FileService();
  bool _canSend = false;

  @override
  void initState() {
    super.initState();
    _controller.addListener(_onTextChanged);
  }

  void _onTextChanged() {
    setState(() {
      _canSend = _controller.text.trim().isNotEmpty && widget.enabled;
    });
  }

  @override
  void didUpdateWidget(ChatInput oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.enabled != widget.enabled) {
      _onTextChanged(); // 重新计算发送按钮状态
    }
  }

  Future<void> _pickFile() async {
    if (!widget.enabled) return;

    try {
      final XFile? pickedFile = await _imagePicker.pickImage(
        source: ImageSource.gallery,
        maxWidth: 1920,
        maxHeight: 1080,
        imageQuality: 85,
      );

      if (pickedFile != null) {
        final file = File(pickedFile.path);
        final attachment = await _fileService.saveFileAndCreateAttachment(file);

        if (attachment != null && widget.onAttachmentsSelected != null) {
          widget.onAttachmentsSelected!([attachment]);
        }
      }
    } catch (e) {
      print('Error picking file: $e');
      // 可以在这里显示错误提示
    }
  }

  void _sendMessage() {
    if (_canSend) {
      widget.onSendMessage(_controller.text);
      _controller.clear();
    }
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: const BoxDecoration(
        color: CupertinoColors.systemBackground,
        border: Border(
          top: BorderSide(
            color: CupertinoColors.systemGrey4,
            width: 0.5,
          ),
        ),
      ),
      child: Row(
        children: [
          CupertinoButton(
            padding: EdgeInsets.zero,
            onPressed: widget.enabled ? _pickFile : null,
            child: Container(
              width: 36,
              height: 36,
              decoration: BoxDecoration(
                color: widget.enabled
                    ? CupertinoColors.systemGrey6
                    : CupertinoColors.systemGrey5,
                borderRadius: BorderRadius.circular(18),
              ),
              child: Icon(
                CupertinoIcons.paperclip,
                color: widget.enabled
                    ? CupertinoColors.systemGrey
                    : CupertinoColors.systemGrey4,
                size: 20,
              ),
            ),
          ),
          const SizedBox(width: 8),
          Expanded(
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
              decoration: BoxDecoration(
                color: widget.enabled
                    ? CupertinoColors.systemGrey6
                    : CupertinoColors.systemGrey5,
                borderRadius: BorderRadius.circular(20),
              ),
              child: CupertinoTextField(
                controller: _controller,
                placeholder: widget.enabled ? '输入消息...' : '请先配置API设置',
                enabled: widget.enabled,
                decoration: null, // 使用null而不是InputBorder.none
                maxLines: null,
                textInputAction: TextInputAction.send,
                onSubmitted: widget.enabled ? (_) => _sendMessage() : null,
              ),
            ),
          ),
          const SizedBox(width: 8),
          CupertinoButton(
            padding: EdgeInsets.zero,
            onPressed: _canSend ? _sendMessage : null,
            child: Container(
              width: 36,
              height: 36,
              decoration: BoxDecoration(
                color: _canSend
                    ? CupertinoColors.systemBlue
                    : CupertinoColors.systemGrey4,
                borderRadius: BorderRadius.circular(18),
              ),
              child: const Icon(
                CupertinoIcons.arrow_up,
                color: CupertinoColors.white,
                size: 20,
              ),
            ),
          ),
        ],
      ),
    );
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }
}