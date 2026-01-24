import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:sqlite3/sqlite3.dart';
import 'package:path_provider/path_provider.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../models/conversation.dart';
import '../models/message.dart';
import '../models/attachment.dart';
import 'dart:async';

/// 数据库版本（预留用于未来版本升级）
// const int _dbVersion = 1;

/// 数据库管理类，使用 sqlite3 实现对话数据的持久化存储
///
/// 数据库结构:
/// - conversations: 对话表
/// - messages: 消息表
/// - attachments: 附件表
/// - settings: 设置表 (存储当前对话ID等)
///
/// 特性:
/// - 单例模式，全局共享数据库连接
/// - 启用外键约束，确保数据完整性
/// - 主 isolate 使用锁防止并发冲突（注意：sqlite3 非 isolate-safe）
/// - 自动初始化数据库和表结构
/// - 支持从 SharedPreferences 迁移数据
///
/// 重要提示:
/// - 此类设计为仅在主 isolate 使用
/// - 未来如需跨 isolate 访问，需要使用专门的 DB isolate 模式
class ConversationDatabase {
  // 单例实例
  static final ConversationDatabase _instance = ConversationDatabase._internal();
  factory ConversationDatabase() => _instance;
  ConversationDatabase._internal();

  Database? _db;

  // 异步锁 - 防止同一 isolate 内的并发写操作
  Completer<void>? _writeLock;

  /// 获取数据库实例
  Future<Database> get db async {
    if (_db == null) {
      await _init();
    }
    return _db!;
  }

  /// 初始化数据库
  Future<void> _init() async {
    if (_db != null) return;

    final appDir = await getApplicationDocumentsDirectory();
    final dbPath = '${appDir.path}/conversations.db';

    _db = sqlite3.open(dbPath);

    // 启用外键约束，否则 ON DELETE CASCADE 不会生效
    _db!.execute('PRAGMA foreign_keys = ON');

    // 创建表
    _createTables(_db!);

    // 检查是否需要迁移
    await _checkAndMigrateIfNeeded();
  }

  /// 创建数据库表
  void _createTables(Database db) {
    // 创建对话表
    db.execute('''
      CREATE TABLE IF NOT EXISTS conversations (
        id TEXT PRIMARY KEY,
        title TEXT NOT NULL,
        created_at INTEGER NOT NULL,
        updated_at INTEGER NOT NULL
      )
    ''');

    // 创建消息表
    db.execute('''
      CREATE TABLE IF NOT EXISTS messages (
        id TEXT PRIMARY KEY,
        conversation_id TEXT NOT NULL,
        content TEXT NOT NULL,
        reasoning_content TEXT,
        is_user INTEGER NOT NULL,
        timestamp INTEGER NOT NULL,
        status INTEGER NOT NULL,
        FOREIGN KEY (conversation_id) REFERENCES conversations (id) ON DELETE CASCADE
      )
    ''');

    // 创建附件表
    db.execute('''
      CREATE TABLE IF NOT EXISTS attachments (
        id TEXT PRIMARY KEY,
        message_id TEXT NOT NULL,
        file_name TEXT NOT NULL,
        file_path TEXT,
        url TEXT,
        type INTEGER NOT NULL,
        file_size INTEGER,
        mime_type TEXT,
        created_at INTEGER NOT NULL,
        FOREIGN KEY (message_id) REFERENCES messages (id) ON DELETE CASCADE
      )
    ''');

    // 创建设置表
    db.execute('''
      CREATE TABLE IF NOT EXISTS settings (
        key TEXT PRIMARY KEY,
        value TEXT NOT NULL
      )
    ''');

    // 创建索引
    db.execute('CREATE INDEX IF NOT EXISTS idx_messages_conversation ON messages(conversation_id)');
    db.execute('CREATE INDEX IF NOT EXISTS idx_attachments_message ON attachments(message_id)');
    db.execute('CREATE INDEX IF NOT EXISTS idx_conversations_updated ON conversations(updated_at)');
  }

  /// 执行带锁的操作，防止并发写入
  Future<T> _synchronized<T>(Future<T> Function() operation) async {
    // 等待上一个操作完成
    while (_writeLock != null) {
      await _writeLock!.future;
    }

    // 获取锁
    _writeLock = Completer<void>();

    try {
      return await operation();
    } finally {
      // 无论成功或失败，都要释放锁
      final completer = _writeLock!;
      _writeLock = null;
      completer.complete();
    }
  }

  /// 检查并执行数据迁移
  Future<void> _checkAndMigrateIfNeeded() async {
    final db = await this.db;

    // 检查是否已经迁移过
    final result = db.select('SELECT value FROM settings WHERE key = ?', ['migrated']);
    final hasMigrated = result.isNotEmpty;

    if (!hasMigrated) {
      // 执行迁移
      await _migrateFromSharedPreferences();
      // 标记已迁移
      db.execute('INSERT OR REPLACE INTO settings (key, value) VALUES (?, ?)', ['migrated', 'true']);
    }
  }

  /// 从 SharedPreferences 迁移数据
  Future<void> _migrateFromSharedPreferences() async {
    final prefs = await SharedPreferences.getInstance();
    final conversationsString = prefs.getString('conversations');

    if (conversationsString == null) return;

    try {
      final conversationsJson = jsonDecode(conversationsString) as List;

      final db = await this.db;

      // 开始事务
      db.execute('BEGIN TRANSACTION');

      try {
        for (final json in conversationsJson) {
          final conversation = Conversation.fromJson(json as Map<String, dynamic>);

          // 插入对话
          db.execute('''
            INSERT OR REPLACE INTO conversations (id, title, created_at, updated_at)
            VALUES (?, ?, ?, ?)
          ''', [
            conversation.id,
            conversation.title,
            conversation.createdAt.millisecondsSinceEpoch,
            conversation.updatedAt.millisecondsSinceEpoch,
          ]);

          // 插入消息
          for (final message in conversation.messages) {
            db.execute('''
              INSERT OR REPLACE INTO messages (id, conversation_id, content, reasoning_content, is_user, timestamp, status)
              VALUES (?, ?, ?, ?, ?, ?, ?)
            ''', [
              message.id,
              conversation.id,
              message.content,
              message.reasoningContent,
              message.isUser ? 1 : 0,
              message.timestamp.millisecondsSinceEpoch,
              message.status.index,
            ]);

            // 插入附件
            for (final attachment in message.attachments) {
              db.execute('''
                INSERT OR REPLACE INTO attachments (id, message_id, file_name, file_path, url, type, file_size, mime_type, created_at)
                VALUES (?, ?, ?, ?, ?, ?, ?, ?, ?)
              ''', [
                attachment.id,
                message.id,
                attachment.fileName,
                attachment.filePath,
                attachment.url,
                attachment.type.index,
                attachment.fileSize,
                attachment.mimeType,
                attachment.createdAt.millisecondsSinceEpoch,
              ]);
            }
          }
        }

        // 迁移当前对话ID
        final currentConversationId = prefs.getString('current_conversation_id');
        if (currentConversationId != null) {
          db.execute('INSERT OR REPLACE INTO settings (key, value) VALUES (?, ?)', [
            'current_conversation_id',
            currentConversationId,
          ]);
        }

        db.execute('COMMIT');
      } catch (e) {
        db.execute('ROLLBACK');
        rethrow;
      }
    } catch (e) {
      debugPrint('Migration failed: $e');
    }
  }

  /// 获取所有对话（按更新时间倒序）
  Future<List<Conversation>> getConversations() async {
    final db = await this.db;

    final result = db.select('''
      SELECT id, title, created_at, updated_at
      FROM conversations
      ORDER BY updated_at DESC
    ''');

    return result.map((row) {
      return Conversation(
        id: row['id'] as String,
        title: row['title'] as String,
        createdAt: DateTime.fromMillisecondsSinceEpoch(row['created_at'] as int),
        updatedAt: DateTime.fromMillisecondsSinceEpoch(row['updated_at'] as int),
        messages: [], // 稍后加载
      );
    }).toList();
  }

  /// 获取指定对话的完整数据（包含消息）
  Future<Conversation?> getConversationById(String id) async {
    final db = await this.db;

    // 获取对话
    final conversationResult = db.select('''
      SELECT id, title, created_at, updated_at
      FROM conversations
      WHERE id = ?
    ''', [id]);

    if (conversationResult.isEmpty) return null;

    final row = conversationResult.first;

    // 获取消息
    final messagesResult = db.select('''
      SELECT id, content, reasoning_content, is_user, timestamp, status
      FROM messages
      WHERE conversation_id = ?
      ORDER BY timestamp ASC
    ''', [id]);

    final messages = <Message>[];

    for (final msgRow in messagesResult) {
      final messageId = msgRow['id'] as String;

      // 获取附件
      final attachmentsResult = db.select('''
        SELECT id, file_name, file_path, url, type, file_size, mime_type, created_at
        FROM attachments
        WHERE message_id = ?
      ''', [messageId]);

      final attachments = attachmentsResult.map((attRow) {
        return Attachment(
          id: attRow['id'] as String,
          fileName: attRow['file_name'] as String,
          filePath: attRow['file_path'] as String?,
          url: attRow['url'] as String?,
          type: AttachmentType.values[attRow['type'] as int],
          fileSize: attRow['file_size'] as int?,
          mimeType: attRow['mime_type'] as String?,
          createdAt: DateTime.fromMillisecondsSinceEpoch(attRow['created_at'] as int),
        );
      }).toList();

      messages.add(Message(
        id: messageId,
        content: msgRow['content'] as String,
        reasoningContent: msgRow['reasoning_content'] as String?,
        isUser: (msgRow['is_user'] as int) == 1,
        timestamp: DateTime.fromMillisecondsSinceEpoch(msgRow['timestamp'] as int),
        status: MessageStatus.values[msgRow['status'] as int],
        attachments: attachments,
      ));
    }

    return Conversation(
      id: row['id'] as String,
      title: row['title'] as String,
      createdAt: DateTime.fromMillisecondsSinceEpoch(row['created_at'] as int),
      updatedAt: DateTime.fromMillisecondsSinceEpoch(row['updated_at'] as int),
      messages: messages,
    );
  }

  /// 创建新对话
  Future<Conversation> createConversation({
    required String id,
    required String title,
    required DateTime createdAt,
    required DateTime updatedAt,
  }) async {
    return _synchronized(() async {
      final db = await this.db;

      db.execute('''
        INSERT INTO conversations (id, title, created_at, updated_at)
        VALUES (?, ?, ?, ?)
      ''', [id, title, createdAt.millisecondsSinceEpoch, updatedAt.millisecondsSinceEpoch]);

      return Conversation(
        id: id,
        title: title,
        createdAt: createdAt,
        updatedAt: updatedAt,
        messages: [],
      );
    });
  }

  /// 更新对话
  Future<void> updateConversation(Conversation conversation) async {
    await _synchronized(() async {
      final db = await this.db;

      db.execute('''
        INSERT OR REPLACE INTO conversations (id, title, created_at, updated_at)
        VALUES (?, ?, ?, ?)
      ''', [
        conversation.id,
        conversation.title,
        conversation.createdAt.millisecondsSinceEpoch,
        conversation.updatedAt.millisecondsSinceEpoch,
      ]);

      // 删除旧消息
      db.execute('DELETE FROM messages WHERE conversation_id = ?', [conversation.id]);

      // 插入新消息
      for (final message in conversation.messages) {
        db.execute('''
          INSERT OR REPLACE INTO messages (id, conversation_id, content, reasoning_content, is_user, timestamp, status)
          VALUES (?, ?, ?, ?, ?, ?, ?)
        ''', [
          message.id,
          conversation.id,
          message.content,
          message.reasoningContent,
          message.isUser ? 1 : 0,
          message.timestamp.millisecondsSinceEpoch,
          message.status.index,
        ]);

        // 删除旧附件
        db.execute('DELETE FROM attachments WHERE message_id = ?', [message.id]);

        // 插入新附件
        for (final attachment in message.attachments) {
          db.execute('''
            INSERT OR REPLACE INTO attachments (id, message_id, file_name, file_path, url, type, file_size, mime_type, created_at)
            VALUES (?, ?, ?, ?, ?, ?, ?, ?, ?)
          ''', [
            attachment.id,
            message.id,
            attachment.fileName,
            attachment.filePath,
            attachment.url,
            attachment.type.index,
            attachment.fileSize,
            attachment.mimeType,
            attachment.createdAt.millisecondsSinceEpoch,
          ]);
        }
      }
    });
  }

  /// 删除对话
  Future<void> deleteConversation(String conversationId) async {
    await _synchronized(() async {
      final db = await this.db;
      db.execute('DELETE FROM conversations WHERE id = ?', [conversationId]);
    });
  }

  /// 更新对话标题
  Future<void> updateConversationTitle(String conversationId, String title) async {
    await _synchronized(() async {
      final db = await this.db;
      final now = DateTime.now().millisecondsSinceEpoch;
      db.execute('''
        UPDATE conversations
        SET title = ?, updated_at = ?
        WHERE id = ?
      ''', [title, now, conversationId]);
    });
  }

  /// 获取当前对话ID
  Future<String?> getCurrentConversationId() async {
    final db = await this.db;
    final result = db.select('SELECT value FROM settings WHERE key = ?', ['current_conversation_id']);
    return result.isEmpty ? null : result.first['value'] as String?;
  }

  /// 设置当前对话ID
  Future<void> setCurrentConversationId(String conversationId) async {
    final db = await this.db;
    db.execute('INSERT OR REPLACE INTO settings (key, value) VALUES (?, ?)', [
      'current_conversation_id',
      conversationId,
    ]);
  }

  /// 获取对话数量
  Future<int> getConversationCount() async {
    final db = await this.db;
    final result = db.select('SELECT COUNT(*) as count FROM conversations');
    return result.first['count'] as int;
  }

  /// 关闭数据库连接
  Future<void> close() async {
    if (_db != null) {
      _db!.close();
      _db = null;
    }
  }
}
