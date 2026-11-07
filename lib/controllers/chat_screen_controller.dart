import 'package:flutter/foundation.dart';

/// 桌面壳控制嵌入聊天区的窄接口。
class ChatScreenController {
  Future<void> Function(String conversationId)? _openConversation;
  Future<void> Function()? _createNewConversation;
  VoidCallback? _refreshConfiguration;

  void attach({
    required Future<void> Function(String conversationId) openConversation,
    required Future<void> Function() createNewConversation,
    required VoidCallback refreshConfiguration,
  }) {
    _openConversation = openConversation;
    _createNewConversation = createNewConversation;
    _refreshConfiguration = refreshConfiguration;
  }

  void detach() {
    _openConversation = null;
    _createNewConversation = null;
    _refreshConfiguration = null;
  }

  Future<void> openConversation(String conversationId) async {
    await _openConversation?.call(conversationId);
  }

  Future<void> createNewConversation() async {
    await _createNewConversation?.call();
  }

  void refreshConfiguration() {
    _refreshConfiguration?.call();
  }
}
