import 'dart:async';
import '../models/message.dart';
import '../models/attachment.dart';
import '../l10n/app_localizations.dart';

/// AI Provider 抽象基类
/// 定义所有 AI 服务提供者必须实现的接口
abstract class AIProvider {
  /// 常量定义
  static const int maxFileSizeForBase64 = 25 * 1024 * 1024;
  static const int maxFileSizeForTextExtraction = 10 * 1024 * 1024;
  static const int maxTotalAttachmentsSize = 50 * 1024 * 1024;

  /// 发送消息（同步方式）
  ///
  /// 参数:
  ///   message - 用户输入的文本消息
  ///   chatHistory - 聊天历史记录
  ///   attachments - 附件列表
  ///   systemPrompt - 系统提示词
  ///   temperature - 温度参数
  ///   maxTokens - 最大 token 数
  ///   thinkingMode - 是否启用思考模式
  ///   l10n - 国际化对象
  ///
  /// 返回值:
  ///   Map包含 'reasoningContent' 和 'content' 字段
  Future<Map<String, dynamic>> sendMessage({
    required String message,
    required List<Message> chatHistory,
    required List<Attachment> attachments,
    required String systemPrompt,
    required double temperature,
    required int maxTokens,
    bool thinkingMode = false,
    required AppLocalizations l10n,
  });

  /// 发送消息（流式方式）
  ///
  /// 参数:
  ///   message - 用户输入的文本消息
  ///   chatHistory - 聊天历史记录
  ///   attachments - 附件列表
  ///   systemPrompt - 系统提示词
  ///   temperature - 温度参数
  ///   maxTokens - 最大 token 数
  ///   thinkingMode - 是否启用思考模式
  ///   l10n - 国际化对象
  ///
  /// 返回值:
  ///   `Stream<Map<String, dynamic>>`，包含 'type' 和 'content' 字段
  ///   type可以是 'reasoning' 或 'answer'
  Stream<Map<String, dynamic>> sendMessageStreaming({
    required String message,
    required List<Message> chatHistory,
    required List<Attachment> attachments,
    required String systemPrompt,
    required double temperature,
    required int maxTokens,
    bool thinkingMode = false,
    required AppLocalizations l10n,
  });

  /// 生成对话标题
  ///
  /// 参数:
  ///   messages - 对话消息列表
  ///   l10n - 国际化对象
  ///
  /// 返回值:
  ///   生成的对话标题（简短摘要）
  Future<String> generateConversationTitle(List<Message> messages, {required AppLocalizations l10n});

  /// 检查附件是否支持视觉API
  bool isVisionSupportedFile(Attachment attachment) {
    final mimeType = attachment.mimeType?.toLowerCase() ?? '';
    return mimeType.startsWith('image/') ||
        mimeType.startsWith('video/') ||
        mimeType.startsWith('audio/');
  }

  /// 格式化文件大小
  String formatFileSize(int bytes) {
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
}
