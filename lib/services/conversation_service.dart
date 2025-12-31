import 'dart:convert';
import 'package:shared_preferences/shared_preferences.dart';
import '../models/conversation.dart';
import '../l10n/app_localizations.dart';
import 'package:path_provider/path_provider.dart';
import 'dart:io';
import 'version_service.dart';
import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;

/// 对话服务，管理对话的持久化存储和CRUD操作
///
/// 使用SharedPreferences作为本地存储，存储对话列表和当前对话ID
/// 提供对话的创建、读取、更新、删除等完整功能
///
/// 设计特点:
/// - 自动按更新时间排序（最近更新的对话在前）
/// - 维护当前对话ID，支持快速切换
/// - 线程安全的异步操作
class ConversationService {
  static const String _conversationsKey = 'conversations';
  static const String _currentConversationIdKey = 'current_conversation_id';

  /// 从本地存储加载所有对话
  /// 返回按更新时间倒序排序的对话列表（最近更新的在前）
  Future<List<Conversation>> loadConversations() async {
    final prefs = await SharedPreferences.getInstance();
    final conversationsString = prefs.getString(_conversationsKey);

    if (conversationsString == null) return [];

    final conversationsJson = jsonDecode(conversationsString) as List;
    return conversationsJson
        .map((json) => Conversation.fromJson(json as Map<String, dynamic>))
        .toList()
      ..sort((a, b) => b.updatedAt.compareTo(a.updatedAt));
  }

  Future<void> saveConversations(List<Conversation> conversations) async {
    final prefs = await SharedPreferences.getInstance();
    final conversationsJson = conversations.map((c) => c.toJson()).toList();
    await prefs.setString(_conversationsKey, jsonEncode(conversationsJson));
  }

  Future<String?> getCurrentConversationId() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getString(_currentConversationIdKey);
  }

  Future<void> setCurrentConversationId(String conversationId) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_currentConversationIdKey, conversationId);
  }

  Future<Conversation> createNewConversation({String? title}) async {
    final conversation = Conversation(
      id: DateTime.now().millisecondsSinceEpoch.toString(),
      title: title ?? '新对话',
      createdAt: DateTime.now(),
      updatedAt: DateTime.now(),
      messages: [],
    );

    final conversations = await loadConversations();
    conversations.insert(0, conversation);
    await saveConversations(conversations);
    await setCurrentConversationId(conversation.id);

    return conversation;
  }

  Future<void> updateConversation(Conversation conversation) async {
    final conversations = await loadConversations();
    final index = conversations.indexWhere((c) => c.id == conversation.id);

    if (index != -1) {
      conversations[index] = conversation.copyWith(updatedAt: DateTime.now());
      await saveConversations(conversations);
    }
  }

  Future<void> deleteConversation(String conversationId) async {
    final conversations = await loadConversations();
    conversations.removeWhere((c) => c.id == conversationId);
    await saveConversations(conversations);

    final currentId = await getCurrentConversationId();
    if (currentId == conversationId) {
      final prefs = await SharedPreferences.getInstance();
      await prefs.remove(_currentConversationIdKey);
    }
  }

  Future<Conversation?> getConversationById(String id) async {
    final conversations = await loadConversations();
    try {
      return conversations.firstWhere((c) => c.id == id);
    } catch (e) {
      return null;
    }
  }

  Future<void> updateConversationTitle(
      String conversationId, String title) async {
    final conversations = await loadConversations();
    final index = conversations.indexWhere((c) => c.id == conversationId);

    if (index != -1) {
      conversations[index] = conversations[index].copyWith(
        title: title,
        updatedAt: DateTime.now(),
      );
      await saveConversations(conversations);
    }
  }

  /// 导出对话为JSON格式
  /// 返回原始对话的JSON表示
  Future<Map<String, dynamic>> exportConversationToJson(String conversationId, AppLocalizations l10n) async {
    final conversation = await getConversationById(conversationId);
    if (conversation == null) {
      throw Exception(l10n.exportConversationNotFound);
    }
    return conversation.toJson();
  }

  /// 导出对话为Lumenflow格式
  /// 包含元数据和对话内容
  Future<Map<String, dynamic>> exportConversationToLumenflow(String conversationId, AppLocalizations l10n) async {
    final conversation = await getConversationById(conversationId);
    if (conversation == null) {
      throw Exception(l10n.exportConversationNotFound);
    }

    final versionService = VersionService();
    final versionInfo = await versionService.getVersionInfo();

    final conversationJson = conversation.toJson();
    final lumenflowData = {
      '_format': 'lumenflow',
      '_version': '1.0',
      '_type': 'conversation',
      '_created': DateTime.now().toUtc().toIso8601String(),
      '_app_version': versionInfo['version'] ?? 'unknown',
      'conversation': conversationJson,
    };

    return lumenflowData;
  }

  /// 导出对话为纯文本格式
  /// 返回人类可读的文本表示
  Future<String> exportConversationToText(String conversationId, AppLocalizations l10n) async {
    final conversation = await getConversationById(conversationId);
    if (conversation == null) {
      throw Exception(l10n.exportConversationNotFound);
    }

    final buffer = StringBuffer();
    buffer.writeln('${l10n.exportConversationTitle}${conversation.title}');
    buffer.writeln('${l10n.exportCreatedTime}${conversation.createdAt.toLocal()}');
    buffer.writeln('${l10n.exportUpdatedTime}${conversation.updatedAt.toLocal()}');
    buffer.writeln('${l10n.exportMessageCount}${conversation.messages.length}');
    buffer.writeln('=' * 40);

    for (final message in conversation.messages) {
      final sender = message.isUser ? l10n.user : l10n.aiAssistant;
      final time = message.timestamp.toLocal().toString();
      buffer.writeln('\n[$sender - $time]');
      buffer.writeln(message.content);
      if (message.reasoningContent != null && message.reasoningContent!.isNotEmpty) {
        buffer.writeln('\n${l10n.exportReasoningProcess}');
        buffer.writeln(message.reasoningContent!);
      }
      if (message.attachments.isNotEmpty) {
        buffer.writeln('\n${l10n.exportAttachments(message.attachments.length)}');
        for (final attachment in message.attachments) {
          buffer.writeln('  - ${attachment.fileName} (${attachment.fileSize}${l10n.exportBytes})');
        }
      }
    }

    return buffer.toString();
  }

  /// 导出对话为PDF格式
  /// 返回PDF文件的字节列表
  Future<List<int>> exportConversationToPdf(String conversationId, AppLocalizations l10n) async {
    final conversation = await getConversationById(conversationId);
    if (conversation == null) {
      throw Exception(l10n.exportConversationNotFound);
    }

    final pdf = pw.Document();

    // 添加元数据
    pdf.addPage(
      pw.Page(
        build: (pw.Context context) {
          return pw.Column(
            crossAxisAlignment: pw.CrossAxisAlignment.start,
            children: [
              pw.Header(
                level: 0,
                child: pw.Text(conversation.title,
                    style: pw.TextStyle(
                      fontSize: 24,
                      fontWeight: pw.FontWeight.bold,
                    )),
              ),
              pw.SizedBox(height: 10),
              pw.Text('${l10n.exportCreatedTime}${conversation.createdAt.toLocal()}'),
              pw.Text('${l10n.exportUpdatedTime}${conversation.updatedAt.toLocal()}'),
              pw.Text('${l10n.exportMessageCount}${conversation.messages.length}'),
              pw.Divider(),
              pw.SizedBox(height: 20),
            ],
          );
        },
      ),
    );

    // 添加消息页面
    for (final message in conversation.messages) {
      final sender = message.isUser ? l10n.user : l10n.aiAssistant;
      final time = message.timestamp.toLocal().toString();

      pdf.addPage(
        pw.Page(
          build: (pw.Context context) {
            return pw.Column(
              crossAxisAlignment: pw.CrossAxisAlignment.start,
              children: [
                pw.Header(
                  level: 1,
                  child: pw.Text('$sender - $time',
                      style: pw.TextStyle(
                        fontSize: 18,
                        fontWeight: pw.FontWeight.bold,
                        color: message.isUser ? PdfColors.blue : PdfColors.green,
                      )),
                ),
                pw.SizedBox(height: 10),
                pw.Text(message.content,
                    style: const pw.TextStyle(fontSize: 12)),
                if (message.reasoningContent != null &&
                    message.reasoningContent!.isNotEmpty)
                  pw.Column(
                    crossAxisAlignment: pw.CrossAxisAlignment.start,
                    children: [
                      pw.SizedBox(height: 10),
                      pw.Header(
                        level: 2,
                        child: pw.Text(l10n.exportThinkingProcess,
                            style: pw.TextStyle(
                              fontSize: 14,
                              fontWeight: pw.FontWeight.bold,
                              color: PdfColors.grey,
                            )),
                      ),
                      pw.Text(message.reasoningContent!,
                          style: pw.TextStyle(
                            fontSize: 11,
                            color: PdfColors.grey,
                          )),
                    ],
                  ),
                if (message.attachments.isNotEmpty)
                  pw.Column(
                    crossAxisAlignment: pw.CrossAxisAlignment.start,
                    children: [
                      pw.SizedBox(height: 10),
                      pw.Header(
                        level: 2,
                        child: pw.Text(l10n.exportAttachmentsLabel,
                            style: pw.TextStyle(
                              fontSize: 14,
                              fontWeight: pw.FontWeight.bold,
                              color: PdfColors.grey,
                            )),
                      ),
                      for (final attachment in message.attachments)
                        pw.Text(
                            '  • ${attachment.fileName} (${attachment.fileSize}${l10n.exportBytes})',
                            style: const pw.TextStyle(fontSize: 11)),
                    ],
                  ),
              ],
            );
          },
        ),
      );
    }

    // 保存PDF
    return pdf.save();
  }

  /// 保存文件到设备
  /// 返回包含文件路径和位置标识的Map
  /// locationType: 'download', 'external', 'app'
  Future<Map<String, String>> saveExportFile(String fileName, List<int> bytes) async {
    // 优先尝试保存到下载目录
    Directory? targetDir = await getDownloadsDirectory();
    String locationType = 'download';

    // 如果下载目录不可用，尝试外部存储目录
    if (targetDir == null) {
      targetDir = await getExternalStorageDirectory();
      locationType = 'external';
    }

    // 如果外部存储目录也不可用，使用应用文档目录
    if (targetDir == null) {
      targetDir = await getApplicationDocumentsDirectory();
      locationType = 'app';
    }

    // 确保目录存在
    if (!await targetDir.exists()) {
      await targetDir.create(recursive: true);
    }

    final targetFile = File('${targetDir.path}/$fileName');
    await targetFile.writeAsBytes(bytes);

    return {
      'filePath': targetFile.path,
      'locationType': locationType,
    };
  }
}
