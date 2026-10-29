import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart' show rootBundle;
import '../models/conversation.dart';
import '../models/message.dart';
import '../l10n/app_localizations.dart';
import 'package:path_provider/path_provider.dart';
import 'dart:io';
import 'version_service.dart';
import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;
import 'package:archive/archive.dart';
import 'package:archive/archive_io.dart';
import 'package:path/path.dart' as path;
import '../models/attachment.dart';
import 'dart:async';
import 'dart:convert';
import 'conversation_database.dart';
import 'file_service.dart';

/// 对话服务，管理对话的持久化存储和CRUD操作
///
/// 使用SQLite作为本地存储，存储对话列表和当前对话ID
/// 提供对话的创建、读取、更新、删除等完整功能
///
/// 性能优化:
/// - 单例模式，确保缓存全局共享
/// - 内存缓存对话列表，减少磁盘IO
/// - 异步操作队列防止并发冲突
/// - 延迟加载消息，只在需要时加载
///
/// 设计特点:
/// - 自动按更新时间排序（最近更新的对话在前）
/// - 维护当前对话ID，支持快速切换
/// - 线程安全的异步操作
/// - 支持从 SharedPreferences 自动迁移数据
class ConversationService {
  // 单例实例
  static final ConversationService _instance = ConversationService._internal();
  factory ConversationService() => _instance;

  ConversationService._internal({ConversationDatabase? database})
      : _db = database ?? ConversationDatabase();

  /// 创建测试专用实例，使用独立数据库以避免共享单例缓存。
  @visibleForTesting
  factory ConversationService.forTesting(ConversationDatabase database) {
    return ConversationService._internal(database: database);
  }

  /// 数据库实例
  final ConversationDatabase _db;

  static pw.Font? _pdfRegularFont;
  static pw.Font? _pdfBoldFont;

  Future<(pw.Font, pw.Font)> _loadPdfFonts() async {
    final regular = _pdfRegularFont ??= pw.Font.ttf(
      await rootBundle.load('assets/fonts/NotoSansSC-Regular.ttf'),
    );
    final bold = _pdfBoldFont ??= pw.Font.ttf(
      await rootBundle.load('assets/fonts/NotoSansSC-Bold.ttf'),
    );
    return (regular, bold);
  }

  /// 内存缓存（由于是单例，实例变量也是全局共享的）
  List<Conversation>? _cachedConversations;
  bool _isCacheDirty = false;

  /// 内存缓存已加载消息的对话ID
  final Set<String> _loadedConversationIds = {};

  /// 置顶会话始终排在未置顶会话之前；同组内按更新时间倒序。
  void _sortConversations(List<Conversation> conversations) {
    conversations.sort((a, b) {
      if (a.isPinned != b.isPinned) return a.isPinned ? -1 : 1;
      return b.updatedAt.compareTo(a.updatedAt);
    });
  }

  /// 从本地存储加载所有对话（带缓存）
  /// 返回按更新时间倒序排序的对话列表（最近更新的在前）
  Future<List<Conversation>> loadConversations({bool forceReload = false}) async {
    // 如果缓存存在且未脏，直接返回缓存
    if (_cachedConversations != null && !_isCacheDirty && !forceReload) {
      return List.from(_cachedConversations!);
    }

    final conversations = await _db.getConversations();
    _sortConversations(conversations);

    _cachedConversations = conversations;
    // The list entries are metadata stubs, not fully loaded conversations.
    _loadedConversationIds.clear();
    _isCacheDirty = false;
    return conversations;
  }

  /// 搜索标题、消息正文或思考内容；空查询回退到完整列表。
  Future<List<Conversation>> searchConversations(String query) async {
    final trimmed = query.trim();
    if (trimmed.isEmpty) {
      return loadConversations(forceReload: true);
    }
    return _db.searchConversations(trimmed);
  }

  /// 清除缓存（用于测试或强制重新加载）
  void clearCache() {
    _cachedConversations = null;
    _isCacheDirty = true;
    _loadedConversationIds.clear();
  }

  Future<String?> getCurrentConversationId() async {
    final id = await _db.getCurrentConversationId();
    return (id == null || id.isEmpty) ? null : id;
  }

  Future<void> setCurrentConversationId(String conversationId) async {
    await _db.setCurrentConversationId(conversationId);
  }

  /// 创建新对话
  Future<Conversation> createNewConversation({String? title}) async {
    final conversation = Conversation(
      id: DateTime.now().millisecondsSinceEpoch.toString(),
      title: title ?? '新对话',
      createdAt: DateTime.now(),
      updatedAt: DateTime.now(),
      messages: [],
    );

    await _db.createConversation(
      id: conversation.id,
      title: conversation.title,
      createdAt: conversation.createdAt,
      updatedAt: conversation.updatedAt,
      thinkingMode: conversation.thinkingMode,
      promptPresetEnabled: conversation.promptPresetEnabled,
      promptPresetId: conversation.promptPresetId,
    );

    await setCurrentConversationId(conversation.id);

    // 更新缓存
    final cached = _cachedConversations;
    if (cached != null) {
      cached.insert(0, conversation);
      _sortConversations(cached);
    }
    _isCacheDirty = false;

    return conversation;
  }

  /// 更新对话
  Future<void> updateConversation(Conversation conversation) async {
    await _db.updateConversation(conversation);

    // 更新缓存
    if (_cachedConversations != null) {
      final index = _cachedConversations!.indexWhere((c) => c.id == conversation.id);
      if (index != -1) {
        _cachedConversations![index] = conversation.copyWith(
          updatedAt: conversation.updatedAt,
        );
        // 重新排序，确保置顶和最新对话在前面
        _sortConversations(_cachedConversations!);
      } else {
        // 如果对话不存在，添加它
        _cachedConversations!.insert(0, conversation.copyWith(
          updatedAt: conversation.updatedAt,
        ));
        _sortConversations(_cachedConversations!);
      }
      _isCacheDirty = false;
    }

    if (_cachedConversations != null) {
      _loadedConversationIds.add(conversation.id);
    }
  }

  /// 更新会话级思考模式与角色预设，不改变消息排序。
  Future<void> updateConversationPreferences(
    String conversationId, {
    required bool thinkingMode,
    required bool promptPresetEnabled,
    required String promptPresetId,
  }) async {
    await _db.updateConversationPreferences(
      conversationId,
      thinkingMode: thinkingMode,
      promptPresetEnabled: promptPresetEnabled,
      promptPresetId: promptPresetId,
    );

    final conversations = _cachedConversations;
    if (conversations == null) return;
    final index =
        conversations.indexWhere((conversation) => conversation.id == conversationId);
    if (index == -1) return;
    conversations[index] = conversations[index].copyWith(
      thinkingMode: thinkingMode,
      promptPresetEnabled: promptPresetEnabled,
      promptPresetId: promptPresetId,
    );
  }

  /// 更新会话置顶状态并重排缓存。
  Future<void> setConversationPinned(
    String conversationId,
    bool isPinned,
  ) async {
    await _db.updateConversationPinned(conversationId, isPinned);

    final conversations = _cachedConversations;
    if (conversations == null) return;
    final index =
        conversations.indexWhere((conversation) => conversation.id == conversationId);
    if (index == -1) return;
    conversations[index] = conversations[index].copyWith(isPinned: isPinned);
    _sortConversations(conversations);
  }

  /// 追加一条消息并同步已加载的缓存。
  Future<void> appendMessage(String conversationId, Message message) async {
    await _db.appendMessage(conversationId, message);
    _applyMessageToCache(conversationId, message);
  }

  /// 更新一条消息并同步已加载的缓存。
  Future<void> updateMessage(String conversationId, Message message) async {
    await _db.updateMessage(message);
    _applyMessageToCache(conversationId, message);
  }

  /// 只更新已经完全加载到内存的对话，避免把消息半成品写回列表缓存。
  void _applyMessageToCache(String conversationId, Message message) {
    final conversations = _cachedConversations;
    if (conversations == null) return;

    final conversationIndex =
        conversations.indexWhere((c) => c.id == conversationId);
    if (conversationIndex == -1) return;

    final conversation = conversations[conversationIndex];
    if (!_loadedConversationIds.contains(conversationId)) {
      conversations[conversationIndex] =
          conversation.copyWith(updatedAt: message.timestamp);
      _sortConversations(conversations);
      return;
    }

    final messages = List<Message>.from(conversation.messages);
    final messageIndex = messages.indexWhere((m) => m.id == message.id);
    if (messageIndex == -1) {
      messages.add(message);
    } else {
      messages[messageIndex] = message;
    }

    conversations[conversationIndex] = conversation.copyWith(
      messages: messages,
      updatedAt: message.timestamp,
    );
    _sortConversations(conversations);
  }

  /// 删除对话
  Future<void> deleteConversation(String conversationId) async {
    await _db.deleteConversation(conversationId);

    // 更新缓存
    _cachedConversations?.removeWhere((c) => c.id == conversationId);
    _loadedConversationIds.remove(conversationId);

    final currentId = await getCurrentConversationId();
    if (currentId == conversationId) {
      await _db.clearCurrentConversationId();
    }
  }

  /// 根据ID获取对话（带缓存优化）
  Future<Conversation?> getConversationById(String id) async {
    // 先检查缓存
    if (_loadedConversationIds.contains(id) && _cachedConversations != null) {
      try {
        final cachedConversation = _cachedConversations!.firstWhere((c) => c.id == id);
        // 如果缓存中的对话消息为空，可能是不完整的缓存，需要从数据库重新加载
        if (cachedConversation.messages.isEmpty) {
          // 从数据库加载完整对话
          final conversation = await _db.getConversationById(id);
          if (conversation != null) {
            // 更新缓存
            if (_cachedConversations != null) {
              final index = _cachedConversations!.indexWhere((c) => c.id == id);
              if (index != -1) {
                _cachedConversations![index] = conversation;
              } else {
                _cachedConversations!.add(conversation);
                _sortConversations(_cachedConversations!);
              }
            }
            _loadedConversationIds.add(id);
          }
          return conversation;
        }
        return cachedConversation;
      } catch (e) {
        // 缓存中找不到，继续从数据库加载
      }
    }

    // 从数据库加载完整对话
    final conversation = await _db.getConversationById(id);

    if (conversation != null) {
      // 更新缓存；只有真正存入了完整对话才标记为已加载
      if (_cachedConversations != null) {
        final index = _cachedConversations!.indexWhere((c) => c.id == id);
        if (index != -1) {
          _cachedConversations![index] = conversation;
        } else {
          _cachedConversations!.add(conversation);
          _sortConversations(_cachedConversations!);
        }
        _loadedConversationIds.add(id);
      }
    }

    return conversation;
  }

  /// 更新对话标题
  Future<void> updateConversationTitle(
      String conversationId, String title) async {
    await _db.updateConversationTitle(conversationId, title);

    // 更新缓存
    if (_cachedConversations != null) {
      final index = _cachedConversations!.indexWhere((c) => c.id == conversationId);
      if (index != -1) {
        _cachedConversations![index] = _cachedConversations![index].copyWith(
          title: title,
          updatedAt: DateTime.now(),
        );
      }
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

  /// 导入 LumenFlow 对话包。
  ///
  /// 支持会话列表导出的裸 `.lumenflow` 文件，也支持聊天页导出的 ZIP
  /// （内含 `conversation.lumenflow` 和 `attachments/`）。
  Future<Conversation> importConversationFromLumenflow({
    required List<int> bytes,
    required AppLocalizations l10n,
  }) async {
    final package = _decodeLumenflowPackage(bytes, l10n);
    final rawConversation = package.data['conversation'];
    Conversation imported;
    try {
      imported = Conversation.fromJson(
        (rawConversation as Map).cast<String, dynamic>(),
      );
    } catch (_) {
      throw FormatException(l10n.conversationImportInvalid);
    }

    final stamp = DateTime.now().microsecondsSinceEpoch;
    final conversationId = 'imported_$stamp';
    final attachmentEntries = <String, List<int>>{};
    if (package.archive != null) {
      for (final file in package.archive!.files) {
        if (!file.isFile) continue;
        final entryName = file.name.replaceAll('\\', '/');
        if (!entryName.startsWith('attachments/')) continue;
        attachmentEntries[entryName] =
            List<int>.from(file.content as List<int>);
      }
    }

    final fileService = FileService();
    final usedAttachmentEntries = <String>{};
    final messages = <Message>[];
    var messageIndex = 0;

    for (final message in imported.messages) {
      final messageId = '${conversationId}_m${messageIndex++}';
      final attachments = <Attachment>[];
      var attachmentIndex = 0;

      for (final attachment in message.attachments) {
        final entryName = _findAttachmentEntry(
          attachmentEntries,
          usedAttachmentEntries,
          attachment.fileName,
        );
        String? savedPath;
        int? importedSize;
        if (entryName != null) {
          usedAttachmentEntries.add(entryName);
          final data = attachmentEntries[entryName]!;
          savedPath = await fileService.saveAttachmentBytes(
            data,
            attachment.fileName,
          );
          importedSize = data.length;
        }

        attachments.add(
          Attachment(
            id: '${messageId}_a${attachmentIndex++}',
            fileName: attachment.fileName,
            filePath: savedPath,
            url: attachment.url,
            type: attachment.type,
            fileSize: importedSize ?? attachment.fileSize,
            mimeType: attachment.mimeType,
            createdAt: attachment.createdAt,
          ),
        );
      }

      messages.add(
        Message(
          id: messageId,
          content: message.content,
          reasoningContent: message.reasoningContent,
          isUser: message.isUser,
          timestamp: message.timestamp,
          status: message.status == MessageStatus.sending
              ? MessageStatus.sent
              : message.status,
          attachments: attachments,
        ),
      );
    }

    final conversation = Conversation(
      id: conversationId,
      title: imported.title.trim().isEmpty
          ? l10n.newConversation
          : imported.title,
      createdAt: imported.createdAt,
      updatedAt: DateTime.now(),
      messages: messages,
      thinkingMode: imported.thinkingMode,
      promptPresetEnabled: imported.promptPresetEnabled,
      promptPresetId: imported.promptPresetId,
      isPinned: imported.isPinned,
    );

    await _db.importConversation(conversation);

    final cached = _cachedConversations;
    if (cached != null) {
      cached.add(conversation);
      _loadedConversationIds.add(conversation.id);
      _sortConversations(cached);
      _isCacheDirty = false;
    } else {
      _isCacheDirty = true;
    }

    return conversation;
  }

  _LumenflowPackage _decodeLumenflowPackage(
    List<int> bytes,
    AppLocalizations l10n,
  ) {
    Archive? archive;
    dynamic decoded;

    try {
      if (bytes.length >= 2 && bytes[0] == 0x50 && bytes[1] == 0x4B) {
        archive = ZipDecoder().decodeBytes(bytes);
        ArchiveFile? conversationFile;
        for (final file in archive.files) {
          if (file.isFile &&
              file.name.toLowerCase().endsWith('.lumenflow')) {
            conversationFile = file;
            break;
          }
        }
        if (conversationFile == null) {
          throw FormatException(l10n.conversationImportInvalid);
        }
        decoded = jsonDecode(
          utf8.decode(List<int>.from(conversationFile.content as List<int>)),
        );
      } else {
        decoded = jsonDecode(utf8.decode(bytes));
      }
    } catch (_) {
      throw FormatException(l10n.conversationImportInvalid);
    }

    if (decoded is! Map) {
      throw FormatException(l10n.conversationImportInvalid);
    }
    final data = decoded.cast<String, dynamic>();
    if (data['_format'] != 'lumenflow' ||
        data['_type'] != 'conversation' ||
        data['conversation'] is! Map) {
      throw FormatException(l10n.conversationImportInvalid);
    }

    return _LumenflowPackage(data: data, archive: archive);
  }

  String? _findAttachmentEntry(
    Map<String, List<int>> entries,
    Set<String> used,
    String fileName,
  ) {
    final baseName = path.basename(fileName);
    final exact = 'attachments/$baseName';
    if (entries.containsKey(exact) && !used.contains(exact)) {
      return exact;
    }

    for (final name in entries.keys) {
      if (used.contains(name) || !name.startsWith('attachments/')) continue;
      final zipName = name.substring('attachments/'.length);
      if (zipName == baseName) return name;
      final normalized = zipName.replaceFirst(
        RegExp(r'_\(\d+\)(?=\.[^.]+$)'),
        '',
      );
      if (normalized == baseName) return name;
    }
    return null;
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

    final (regularFont, boldFont) = await _loadPdfFonts();
    final pdf = pw.Document(
      theme: pw.ThemeData.withFont(
        base: regularFont,
        bold: boldFont,
        italic: regularFont,
        boldItalic: boldFont,
      ),
    );

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

    // 添加消息页面（使用MultiPage自动分页）
    pdf.addPage(
      pw.MultiPage(
        pageFormat: PdfPageFormat.a4,
        margin: const pw.EdgeInsets.all(72.0), // 1 inch margin
        crossAxisAlignment: pw.CrossAxisAlignment.start,
        build: (pw.Context context) {
          final messageWidgets = <pw.Widget>[];

          for (final message in conversation.messages) {
            final sender = message.isUser ? l10n.user : l10n.aiAssistant;
            final time = message.timestamp.toLocal().toString();
            final borderColor = message.isUser ? PdfColors.blue : PdfColors.green;

            final messageWidget = pw.Container(
              margin: const pw.EdgeInsets.only(bottom: 25),
              padding: const pw.EdgeInsets.all(12),
              decoration: pw.BoxDecoration(
                border: pw.Border(
                  left: pw.BorderSide(
                    color: borderColor,
                    width: 4,
                  ),
                ),
              ),
              child: pw.Column(
                crossAxisAlignment: pw.CrossAxisAlignment.start,
                children: [
                  pw.Row(
                    crossAxisAlignment: pw.CrossAxisAlignment.start,
                    children: [
                      pw.Expanded(
                        child: pw.Text(sender,
                          style: pw.TextStyle(
                            fontSize: 14,
                            fontWeight: pw.FontWeight.bold,
                            color: borderColor,
                          ),
                        ),
                      ),
                      pw.Text(time,
                        style: pw.TextStyle(
                          fontSize: 10,
                          color: PdfColors.grey,
                        ),
                      ),
                    ],
                  ),
                  pw.SizedBox(height: 8),
                  pw.Text(message.content,
                      style: const pw.TextStyle(fontSize: 12)),
                  if (message.reasoningContent != null &&
                      message.reasoningContent!.isNotEmpty)
                    pw.Container(
                      margin: const pw.EdgeInsets.only(top: 12),
                      padding: const pw.EdgeInsets.all(8),
                      decoration: const pw.BoxDecoration(
                        borderRadius: pw.BorderRadius.all(pw.Radius.circular(4)),
                      ),
                      child: pw.Column(
                        crossAxisAlignment: pw.CrossAxisAlignment.start,
                        children: [
                          pw.Text(l10n.exportThinkingProcess,
                              style: pw.TextStyle(
                                fontSize: 12,
                                fontWeight: pw.FontWeight.bold,
                                color: PdfColors.grey,
                              )),
                          pw.SizedBox(height: 5),
                          pw.Text(message.reasoningContent!,
                              style: pw.TextStyle(
                                fontSize: 11,
                                color: PdfColors.grey,
                              )),
                        ],
                      ),
                    ),
                  if (message.attachments.isNotEmpty)
                    pw.Container(
                      margin: const pw.EdgeInsets.only(top: 12),
                      padding: const pw.EdgeInsets.all(8),
                      decoration: const pw.BoxDecoration(
                        borderRadius: pw.BorderRadius.all(pw.Radius.circular(4)),
                      ),
                      child: pw.Column(
                        crossAxisAlignment: pw.CrossAxisAlignment.start,
                        children: [
                          pw.Text(l10n.exportAttachmentsLabel,
                              style: pw.TextStyle(
                                fontSize: 12,
                                fontWeight: pw.FontWeight.bold,
                                color: PdfColors.grey,
                              )),
                          pw.SizedBox(height: 5),
                          for (final attachment in message.attachments)
                            pw.Text(
                                '  • ${attachment.fileName} (${attachment.fileSize}${l10n.exportBytes})',
                                style: pw.TextStyle(
                                  fontSize: 11,
                                  color: PdfColors.grey,
                                )),
                        ],
                      ),
                    ),
                ],
              ),
            );

            messageWidgets.add(messageWidget);
          }

          return messageWidgets;
        },
      ),
    );

    // 保存PDF
    return pdf.save();
  }

  /// 收集对话中的所有附件文件路径
  /// 返回Map<原始文件路径, 附件对象>
  Future<Map<String, Attachment>> _collectAttachmentFiles(Conversation conversation) async {
    final attachmentFiles = <String, Attachment>{};

    for (final message in conversation.messages) {
      for (final attachment in message.attachments) {
        if (attachment.filePath != null && attachment.filePath!.isNotEmpty) {
          final file = File(attachment.filePath!);
          if (await file.exists()) {
            attachmentFiles[attachment.filePath!] = attachment;
          }
        }
      }
    }

    return attachmentFiles;
  }

  /// 导出对话为指定格式（包含附件）
  /// 对于txt/json/lumenflow格式，返回包含对话文件和附件的ZIP文件字节
  /// 对于pdf格式，返回嵌入附件的PDF文件字节
  Future<List<int>> exportConversationWithAttachments(String conversationId, String format, AppLocalizations l10n) async {
    final conversation = await getConversationById(conversationId);
    if (conversation == null) {
      throw Exception(l10n.exportConversationNotFound);
    }

    // 收集所有附件文件
    final attachmentFiles = await _collectAttachmentFiles(conversation);

    if (format == 'pdf') {
      // PDF格式：嵌入附件到PDF中
      return await _exportConversationToPdfWithAttachments(conversation, attachmentFiles, l10n);
    } else {
      // txt/json/lumenflow格式：创建ZIP文件
      return await _exportConversationToZip(conversation, format, attachmentFiles, l10n);
    }
  }

  /// 导出对话为ZIP文件（包含对话文件和附件）
  Future<List<int>> _exportConversationToZip(Conversation conversation, String format, Map<String, Attachment> attachmentFiles, AppLocalizations l10n) async {
    final archive = Archive();

    // 1. 生成对话文件
    String conversationContent;
    String conversationFileName;

    switch (format) {
      case 'txt':
        final text = await exportConversationToText(conversation.id, l10n);
        conversationContent = text;
        conversationFileName = 'conversation.txt';
        break;
      case 'json':
        final jsonData = await exportConversationToJson(conversation.id, l10n);
        conversationContent = jsonEncode(jsonData);
        conversationFileName = 'conversation.json';
        break;
      case 'lumenflow':
        final lumenflowData = await exportConversationToLumenflow(conversation.id, l10n);
        conversationContent = jsonEncode(lumenflowData);
        conversationFileName = 'conversation.lumenflow';
        break;
      default:
        throw Exception('不支持的导出格式: $format');
    }

    // 添加对话文件到ZIP
    final conversationBytes = utf8.encode(conversationContent);
    archive.addFile(ArchiveFile(conversationFileName, conversationBytes.length, conversationBytes));

    // 2. 添加附件文件到ZIP（放在attachments子目录中）
    if (attachmentFiles.isNotEmpty) {
      final usedNames = <String>{}; // 跟踪已使用的文件名，避免冲突

      for (final entry in attachmentFiles.entries) {
        final filePath = entry.key;
        final attachment = entry.value;
        final file = File(filePath);

        if (await file.exists()) {
          final fileBytes = await file.readAsBytes();

          // 生成唯一的文件名
          String baseName = attachment.fileName;
          String zipPath = 'attachments/$baseName';
          int counter = 1;

          while (usedNames.contains(zipPath)) {
            final ext = baseName.contains('.') ? baseName.substring(baseName.lastIndexOf('.')) : '';
            final nameWithoutExt = ext.isNotEmpty ? baseName.substring(0, baseName.lastIndexOf('.')) : baseName;
            zipPath = 'attachments/${nameWithoutExt}_($counter)$ext';
            counter++;
          }

          usedNames.add(zipPath);
          archive.addFile(ArchiveFile(zipPath, fileBytes.length, fileBytes));
        }
      }
    }

    // 3. 创建ZIP文件
    final zipEncoder = ZipEncoder();
    final zipBytes = zipEncoder.encode(archive);

    return zipBytes;
  }

  /// 构建PDF中的附件部件
  pw.Widget _buildAttachmentsWidget(List<Attachment> attachments, Map<String, Attachment> attachmentFiles, AppLocalizations l10n) {
    final attachmentWidgets = <pw.Widget>[];

    for (final attachment in attachments) {
      // 尝试从attachmentFiles映射中获取文件路径，否则使用附件自带的路径
      String? filePath;
      if (attachment.filePath != null && attachment.filePath!.isNotEmpty) {
        filePath = attachment.filePath;
      } else {
        // 在映射中查找
        for (final entry in attachmentFiles.entries) {
          if (entry.value.id == attachment.id) {
            filePath = entry.key;
            break;
          }
        }
      }

      if (filePath == null) {
        // 文件不存在，只显示基本信息
        attachmentWidgets.add(
          pw.Container(
            margin: const pw.EdgeInsets.only(bottom: 8),
            child: pw.Column(
              crossAxisAlignment: pw.CrossAxisAlignment.start,
              children: [
                pw.Text('${attachment.fileName} (${attachment.fileSize}${l10n.exportBytes})',
                  style: pw.TextStyle(
                    fontSize: 11,
                    color: PdfColors.grey,
                  ),
                ),
                pw.Text('文件未找到', style: pw.TextStyle(fontSize: 10, color: PdfColors.red)),
              ],
            ),
          ),
        );
        continue;
      }

      final file = File(filePath);
      if (!file.existsSync()) {
        // 文件不存在
        attachmentWidgets.add(
          pw.Container(
            margin: const pw.EdgeInsets.only(bottom: 8),
            child: pw.Column(
              crossAxisAlignment: pw.CrossAxisAlignment.start,
              children: [
                pw.Text('${attachment.fileName} (${attachment.fileSize}${l10n.exportBytes})',
                  style: pw.TextStyle(
                    fontSize: 11,
                    color: PdfColors.grey,
                  ),
                ),
                pw.Text('文件不存在: $filePath', style: pw.TextStyle(fontSize: 10, color: PdfColors.red)),
              ],
            ),
          ),
        );
        continue;
      }

      try {
        final fileBytes = file.readAsBytesSync();

        if (attachment.type == AttachmentType.image) {
          // 图片附件：显示缩略图
          try {
            final image = pw.MemoryImage(fileBytes);
            attachmentWidgets.add(
              pw.Container(
                margin: const pw.EdgeInsets.only(bottom: 12),
                child: pw.Column(
                  crossAxisAlignment: pw.CrossAxisAlignment.start,
                  children: [
                    pw.Text('${attachment.fileName} (${attachment.fileSize}${l10n.exportBytes})',
                      style: pw.TextStyle(
                        fontSize: 11,
                        color: PdfColors.grey,
                      ),
                    ),
                    pw.SizedBox(height: 4),
                    pw.Container(
                      constraints: const pw.BoxConstraints(maxWidth: 300, maxHeight: 200),
                      child: pw.Image(image),
                    ),
                  ],
                ),
              ),
            );
          } catch (e) {
            // 图片加载失败，显示文件信息
            attachmentWidgets.add(_buildFileInfoWidget(attachment, l10n, '图片加载失败: $e'));
          }
        } else if (attachment.type == AttachmentType.document) {
          // 文档附件：显示文件信息和内容预览（如果是文本文件）
          if (attachment.mimeType?.startsWith('text/') == true ||
              attachment.fileName.toLowerCase().endsWith('.txt') ||
              attachment.fileName.toLowerCase().endsWith('.md')) {
            try {
              final content = utf8.decode(fileBytes.take(5000).toList()); // 限制预览长度
              attachmentWidgets.add(
                pw.Container(
                  margin: const pw.EdgeInsets.only(bottom: 12),
                  child: pw.Column(
                    crossAxisAlignment: pw.CrossAxisAlignment.start,
                    children: [
                      pw.Text('${attachment.fileName} (${attachment.fileSize}${l10n.exportBytes})',
                        style: pw.TextStyle(
                          fontSize: 11,
                          color: PdfColors.grey,
                        ),
                      ),
                      pw.SizedBox(height: 4),
                      pw.Container(
                        padding: const pw.EdgeInsets.all(8),
                        decoration: pw.BoxDecoration(
                          border: pw.Border.all(color: PdfColors.grey, width: 0.5),
                          borderRadius: const pw.BorderRadius.all(pw.Radius.circular(4)),
                        ),
                        child: pw.Text(
                          content,
                          style: const pw.TextStyle(fontSize: 10, color: PdfColors.grey),
                          maxLines: 20,
                          overflow: pw.TextOverflow.clip,
                        ),
                      ),
                    ],
                  ),
                ),
              );
            } catch (e) {
              attachmentWidgets.add(_buildFileInfoWidget(attachment, l10n, '内容预览失败'));
            }
          } else {
            // 非文本文档，只显示文件信息
            attachmentWidgets.add(_buildFileInfoWidget(attachment, l10n, '文档文件'));
          }
        } else {
          // 其他类型附件（音频、视频等）：显示文件信息
          attachmentWidgets.add(_buildFileInfoWidget(attachment, l10n, '${attachment.type.toString().split('.').last}文件'));
        }
      } catch (e) {
        // 文件读取失败
        attachmentWidgets.add(_buildFileInfoWidget(attachment, l10n, '文件读取失败: $e'));
      }
    }

    return pw.Container(
      margin: const pw.EdgeInsets.only(top: 12),
      padding: const pw.EdgeInsets.all(8),
      decoration: const pw.BoxDecoration(
        borderRadius: pw.BorderRadius.all(pw.Radius.circular(4)),
      ),
      child: pw.Column(
        crossAxisAlignment: pw.CrossAxisAlignment.start,
        children: [
          pw.Text(l10n.exportAttachmentsLabel,
              style: pw.TextStyle(
                fontSize: 12,
                fontWeight: pw.FontWeight.bold,
                color: PdfColors.grey,
              )),
          pw.SizedBox(height: 5),
          ...attachmentWidgets,
        ],
      ),
    );
  }

  /// 构建文件信息部件（通用）
  pw.Widget _buildFileInfoWidget(Attachment attachment, AppLocalizations l10n, String description) {
    return pw.Container(
      margin: const pw.EdgeInsets.only(bottom: 8),
      child: pw.Column(
        crossAxisAlignment: pw.CrossAxisAlignment.start,
        children: [
          pw.Text('${attachment.fileName} (${attachment.fileSize}${l10n.exportBytes})',
            style: pw.TextStyle(
              fontSize: 11,
              color: PdfColors.grey,
            ),
          ),
          if (description.isNotEmpty)
            pw.Text(description,
              style: pw.TextStyle(
                fontSize: 10,
                color: PdfColors.grey,
              ),
            ),
        ],
      ),
    );
  }

  /// 导出对话为PDF（嵌入附件）
  Future<List<int>> _exportConversationToPdfWithAttachments(Conversation conversation, Map<String, Attachment> attachmentFiles, AppLocalizations l10n) async {
    final (regularFont, boldFont) = await _loadPdfFonts();
    final pdf = pw.Document(
      theme: pw.ThemeData.withFont(
        base: regularFont,
        bold: boldFont,
        italic: regularFont,
        boldItalic: boldFont,
      ),
    );

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

    // 添加消息页面（使用MultiPage自动分页）
    pdf.addPage(
      pw.MultiPage(
        pageFormat: PdfPageFormat.a4,
        margin: const pw.EdgeInsets.all(72.0), // 1 inch margin
        crossAxisAlignment: pw.CrossAxisAlignment.start,
        build: (pw.Context context) {
          final messageWidgets = <pw.Widget>[];

          for (final message in conversation.messages) {
            final sender = message.isUser ? l10n.user : l10n.aiAssistant;
            final time = message.timestamp.toLocal().toString();
            final borderColor = message.isUser ? PdfColors.blue : PdfColors.green;

            final messageWidget = pw.Container(
              margin: const pw.EdgeInsets.only(bottom: 25),
              padding: const pw.EdgeInsets.all(12),
              decoration: pw.BoxDecoration(
                border: pw.Border(
                  left: pw.BorderSide(
                    color: borderColor,
                    width: 4,
                  ),
                ),
              ),
              child: pw.Column(
                crossAxisAlignment: pw.CrossAxisAlignment.start,
                children: [
                  pw.Row(
                    crossAxisAlignment: pw.CrossAxisAlignment.start,
                    children: [
                      pw.Expanded(
                        child: pw.Text(sender,
                          style: pw.TextStyle(
                            fontSize: 14,
                            fontWeight: pw.FontWeight.bold,
                            color: borderColor,
                          ),
                        ),
                      ),
                      pw.Text(time,
                        style: pw.TextStyle(
                          fontSize: 10,
                          color: PdfColors.grey,
                        ),
                      ),
                    ],
                  ),
                  pw.SizedBox(height: 8),
                  pw.Text(message.content,
                      style: const pw.TextStyle(fontSize: 12)),
                  if (message.reasoningContent != null &&
                      message.reasoningContent!.isNotEmpty)
                    pw.Container(
                      margin: const pw.EdgeInsets.only(top: 12),
                      padding: const pw.EdgeInsets.all(8),
                      decoration: const pw.BoxDecoration(
                        borderRadius: pw.BorderRadius.all(pw.Radius.circular(4)),
                      ),
                      child: pw.Column(
                        crossAxisAlignment: pw.CrossAxisAlignment.start,
                        children: [
                          pw.Text(l10n.exportThinkingProcess,
                              style: pw.TextStyle(
                                fontSize: 12,
                                fontWeight: pw.FontWeight.bold,
                                color: PdfColors.grey,
                              )),
                          pw.SizedBox(height: 5),
                          pw.Text(message.reasoningContent!,
                              style: pw.TextStyle(
                                fontSize: 11,
                                color: PdfColors.grey,
                              )),
                        ],
                      ),
                    ),
                  if (message.attachments.isNotEmpty)
                    _buildAttachmentsWidget(message.attachments, attachmentFiles, l10n),
                ],
              ),
            );

            messageWidgets.add(messageWidget);
          }

          return messageWidgets;
        },
      ),
    );

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

class _LumenflowPackage {
  final Map<String, dynamic> data;
  final Archive? archive;

  const _LumenflowPackage({required this.data, this.archive});
}
