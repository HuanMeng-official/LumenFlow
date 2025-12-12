import 'dart:io';
import 'package:flutter/cupertino.dart';
import 'package:file_picker/file_picker.dart';
import '../services/file_service.dart';
import '../services/ai_service.dart';
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

  String _formatFileSize(int bytes) {
    if (bytes < 1024) {
      return '$bytes B';
    } else if (bytes < 1024 * 1024) {
      return '${(bytes / 1024).toStringAsFixed(1)} KB';
    } else if (bytes < 1024 * 1024 * 1024) {
      return '${(bytes / (1024 * 1024)).toStringAsFixed(1)} MB';
    } else {
      return '${(bytes / (1024 * 1024 * 1024)).toStringAsFixed(1)} GB';
    }
  }

  void _showErrorDialog(String title, String message) {
    showCupertinoDialog(
      context: context,
      builder: (context) => CupertinoAlertDialog(
        title: Text(title),
        content: Text(message),
        actions: [
          CupertinoDialogAction(
            child: const Text('确定'),
            onPressed: () => Navigator.pop(context),
          ),
        ],
      ),
    );
  }

  Future<bool> _showWarningDialog(String title, String message) async {
    final result = await showCupertinoDialog<bool>(
      context: context,
      builder: (context) => CupertinoAlertDialog(
        title: Text(title),
        content: Text(message),
        actions: [
          CupertinoDialogAction(
            child: const Text('取消'),
            onPressed: () => Navigator.pop(context, false),
          ),
          CupertinoDialogAction(
            child: const Text('继续'),
            onPressed: () => Navigator.pop(context, true),
          ),
        ],
      ),
    );
    return result ?? false;
  }

  Future<void> _pickFile() async {
    if (!widget.enabled) return;

    try {
      final FilePickerResult? result = await FilePicker.platform.pickFiles(
        allowMultiple: true,
        type: FileType.any,
      );

      if (result != null && result.files.isNotEmpty) {
        // 检查总文件大小
        int totalSize = 0;
        final oversizedFiles = <String>[];

        for (final platformFile in result.files) {
          if (platformFile.path != null) {
            final file = File(platformFile.path!);
            if (await file.exists()) {
              final stat = await file.stat();
              totalSize += stat.size;

              // 检查单个文件大小
              if (stat.size > AIService.maxFileSizeForBase64) {
                oversizedFiles.add('${platformFile.name} (${_formatFileSize(stat.size)})');
              }
            }
          }
        }

        // 检查总大小限制
        if (totalSize > AIService.maxTotalAttachmentsSize) {
          _showErrorDialog(
            '文件过大',
            '选择的文件总大小${_formatFileSize(totalSize)}超过${_formatFileSize(AIService.maxTotalAttachmentsSize)}限制。请选择较小的文件。'
          );
          return;
        }

        // 显示过大文件警告
        if (oversizedFiles.isNotEmpty) {
          final proceed = await _showWarningDialog(
            '文件过大警告',
            '以下文件超过${_formatFileSize(AIService.maxFileSizeForBase64)}限制，可能无法正确处理：\n\n${oversizedFiles.join('\n')}\n\n是否继续上传？'
          );
          if (!proceed) {
            return;
          }
        }

        final attachments = <Attachment>[];

        for (final platformFile in result.files) {
          if (platformFile.path != null) {
            final file = File(platformFile.path!);
            try {
              final attachment = await _fileService.saveFileAndCreateAttachment(file);
              if (attachment != null) {
                attachments.add(attachment);
              }
            } catch (e) {
              print('Error processing file ${platformFile.name}: $e');
              // 继续处理其他文件
            }
          }
        }

        if (attachments.isNotEmpty && widget.onAttachmentsSelected != null) {
          widget.onAttachmentsSelected!(attachments);
        } else if (attachments.isEmpty) {
          _showErrorDialog('无有效文件', '没有成功处理任何文件，请重试。');
        }
      }
    } catch (e) {
      print('Error picking file: $e');
      _showErrorDialog('选择文件失败', '错误：${e.toString().replaceAll('Exception: ', '')}');
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