import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:sqlite3/sqlite3.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../models/conversation.dart';
import '../models/message.dart';
import '../models/attachment.dart';
import 'dart:async';
import '../utils/path_utils.dart';

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

  ConversationDatabase._internal({
    this._databasePath,
    this._preferences,
    this._skipLegacyFileMigration = false,
    this._beforeMigration,
  });

  /// 创建测试专用实例，使用独立数据库路径和可注入的偏好设置。
  @visibleForTesting
  factory ConversationDatabase.forTesting({
    required String databasePath,
    SharedPreferences? preferences,
    bool skipLegacyFileMigration = true,
    Future<void> Function()? beforeMigration,
  }) {
    return ConversationDatabase._internal(
      databasePath: databasePath,
      preferences: preferences,
      skipLegacyFileMigration: skipLegacyFileMigration,
      beforeMigration: beforeMigration,
    );
  }

  final String? _databasePath;
  final SharedPreferences? _preferences;
  final bool _skipLegacyFileMigration;
  final Future<void> Function()? _beforeMigration;

  /// 当前数据库结构版本。
  static const int schemaVersion = 2;

  Database? _db;
  Future<void>? _initFuture;
  int _debugInitCount = 0;

  /// 成功初始化的次数，用于验证并发初始化只执行一次。
  @visibleForTesting
  int get debugInitCount => _debugInitCount;

  /// 读取数据库结构版本，用于测试迁移行为。
  @visibleForTesting
  Future<int> debugSchemaVersion() async {
    final db = await this.db;
    return db.select('PRAGMA user_version').first.values.first as int;
  }

  // 异步锁 - 防止同一 isolate 内的并发写操作
  Completer<void>? _writeLock;

  /// 获取数据库实例
  Future<Database> get db async {
    final pending = _initFuture;
    if (pending != null) {
      await pending;
    } else if (_db == null) {
      await _ensureInitialized();
    }
    return _db!;
  }

  /// 单飞初始化：并发调用共享同一个 Future，结束后清除以便失败重试。
  Future<void> _ensureInitialized() {
    final existing = _initFuture;
    if (existing != null) return existing;

    final future = _init();
    _initFuture = future;
    future.then<void>(
      (_) {
        if (identical(_initFuture, future)) {
          _initFuture = null;
        }
      },
      onError: (Object error, StackTrace stackTrace) {
        if (identical(_initFuture, future)) {
          _initFuture = null;
        }
      },
    );
    return future;
  }

  /// 初始化数据库
  Future<void> _init() async {
    if (_db != null) return;

    Database? opened;
    try {
      // 迁移旧数据到新位置（如果需要）
      if (!_skipLegacyFileMigration) {
        await PathUtils.migrateOldDataIfNeeded();
      }

      final dbPath = _databasePath ?? await PathUtils.getDatabasePath();
      final db = sqlite3.open(dbPath);
      opened = db;

      // 启用外键约束，否则 ON DELETE CASCADE 不会生效
      db.execute('PRAGMA foreign_keys = ON');

      // 创建表
      _createTables(db);
      await _migrateSchema(db);

      // Test-only gate: pauses before prefs migration.
      await _beforeMigration?.call();

      // 迁移使用本地句柄，避免初始化期间重入 db getter。
      await _checkAndMigrateIfNeeded(db);

      // 只有初始化（含迁移）成功后才发布连接。
      _db = db;
      _debugInitCount++;
    } catch (_) {
      opened?.close();
      _db = null;
      rethrow;
    }
  }

  /// 前向迁移数据库结构。只增加版本号，不删除或重写现有数据。
  ///
  /// v2 尚未随正式版本发布，因此置顶字段也归入 v2；同时对已经由
  /// 开发构建创建、但缺少 `is_pinned` 的 v2 数据库做一次补列。
  Future<void> _migrateSchema(Database db) async {
    final currentVersion =
        db.select('PRAGMA user_version').first.values.first as int;
    final columns = db
        .select('PRAGMA table_info(conversations)')
        .map((row) => row['name'] as String)
        .toSet();

    if (currentVersion < 2) {
      final addedColumns = <String>[];
      if (!columns.contains('thinking_mode')) {
        db.execute(
          'ALTER TABLE conversations ADD COLUMN thinking_mode INTEGER NOT NULL DEFAULT 0',
        );
        addedColumns.add('thinking_mode');
      }
      if (!columns.contains('prompt_preset_enabled')) {
        db.execute(
          'ALTER TABLE conversations ADD COLUMN prompt_preset_enabled INTEGER NOT NULL DEFAULT 0',
        );
        addedColumns.add('prompt_preset_enabled');
      }
      if (!columns.contains('prompt_preset_id')) {
        db.execute(
          "ALTER TABLE conversations ADD COLUMN prompt_preset_id TEXT NOT NULL DEFAULT ''",
        );
        addedColumns.add('prompt_preset_id');
      }
      if (!columns.contains('is_pinned')) {
        db.execute(
          'ALTER TABLE conversations ADD COLUMN is_pinned INTEGER NOT NULL DEFAULT 0',
        );
      }

      // Preserve the previous global selection for conversations that existed
      // before these settings became conversation-scoped.
      if (addedColumns.isNotEmpty) {
        final prefs =
            _preferences ?? await SharedPreferences.getInstance();
        db.execute(
          'UPDATE conversations SET thinking_mode = ?, prompt_preset_enabled = ?, prompt_preset_id = ?',
          [
            (prefs.getBool('thinking_mode') ?? false) ? 1 : 0,
            (prefs.getBool('prompt_preset_enabled') ?? false) ? 1 : 0,
            prefs.getString('prompt_preset_id') ?? '',
          ],
        );
      }
    } else if (!columns.contains('is_pinned')) {
      // Development-only databases created before pin support was added to v2.
      db.execute(
        'ALTER TABLE conversations ADD COLUMN is_pinned INTEGER NOT NULL DEFAULT 0',
      );
    }

    if (currentVersion < schemaVersion) {
      db.execute('PRAGMA user_version = $schemaVersion');
    } else if (currentVersion == 3 && schemaVersion == 2) {
      // v3 was used only by an unreleased development build. Fold it back
      // into v2 now that pinning is part of the v2 schema.
      db.execute('PRAGMA user_version = $schemaVersion');
    }
  }

  /// 创建数据库表
  void _createTables(Database db) {
    // 创建对话表
    db.execute('''
      CREATE TABLE IF NOT EXISTS conversations (
        id TEXT PRIMARY KEY,
        title TEXT NOT NULL,
        created_at INTEGER NOT NULL,
        updated_at INTEGER NOT NULL,
        thinking_mode INTEGER NOT NULL DEFAULT 0,
        prompt_preset_enabled INTEGER NOT NULL DEFAULT 0,
        prompt_preset_id TEXT NOT NULL DEFAULT '',
        is_pinned INTEGER NOT NULL DEFAULT 0
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
  Future<void> _checkAndMigrateIfNeeded(Database db) async {
    // 检查是否已经迁移过
    final result = db.select('SELECT value FROM settings WHERE key = ?', ['migrated']);
    final hasMigrated = result.isNotEmpty;

    if (!hasMigrated) {
      // 只有迁移成功后才标记，失败时下次启动会重试
      await _migrateFromSharedPreferences(db);
      db.execute('INSERT OR REPLACE INTO settings (key, value) VALUES (?, ?)', ['migrated', 'true']);
    }
  }

  /// 从 SharedPreferences 迁移数据
  ///
  /// 迁移失败时事务回滚并向上抛出，调用方不得写入 migrated 标记。
  Future<void> _migrateFromSharedPreferences(Database db) async {
    final prefs = _preferences ?? await SharedPreferences.getInstance();
    final conversationsString = prefs.getString('conversations');

    if (conversationsString == null) return;

    final conversationsJson = jsonDecode(conversationsString) as List;

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
  }

  /// 获取所有对话（按更新时间倒序）
  Future<List<Conversation>> getConversations() async {
    final db = await this.db;

    final result = db.select('''
      SELECT id, title, created_at, updated_at,
             thinking_mode, prompt_preset_enabled, prompt_preset_id, is_pinned
      FROM conversations
      ORDER BY is_pinned DESC, updated_at DESC
    ''');

    return result.map((row) {
      return Conversation(
        id: row['id'] as String,
        title: row['title'] as String,
        createdAt: DateTime.fromMillisecondsSinceEpoch(row['created_at'] as int),
        updatedAt: DateTime.fromMillisecondsSinceEpoch(row['updated_at'] as int),
        messages: [], // 稍后加载
        thinkingMode: (row['thinking_mode'] as int? ?? 0) == 1,
        promptPresetEnabled:
            (row['prompt_preset_enabled'] as int? ?? 0) == 1,
        promptPresetId: row['prompt_preset_id'] as String? ?? '',
        isPinned: (row['is_pinned'] as int? ?? 0) == 1,
      );
    }).toList();
  }

  /// 获取指定对话的完整数据（包含消息）
  Future<Conversation?> getConversationById(String id) async {
    final db = await this.db;

    // 获取对话
    final conversationResult = db.select('''
      SELECT id, title, created_at, updated_at,
             thinking_mode, prompt_preset_enabled, prompt_preset_id, is_pinned
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
      thinkingMode: (row['thinking_mode'] as int? ?? 0) == 1,
      promptPresetEnabled: (row['prompt_preset_enabled'] as int? ?? 0) == 1,
      promptPresetId: row['prompt_preset_id'] as String? ?? '',
      isPinned: (row['is_pinned'] as int? ?? 0) == 1,
    );
  }

  /// 创建新对话
  Future<Conversation> createConversation({
    required String id,
    required String title,
    required DateTime createdAt,
    required DateTime updatedAt,
    bool thinkingMode = false,
    bool promptPresetEnabled = false,
    String promptPresetId = '',
    bool isPinned = false,
  }) async {
    return _synchronized(() async {
      final db = await this.db;

      db.execute('''
        INSERT INTO conversations (
          id, title, created_at, updated_at,
          thinking_mode, prompt_preset_enabled, prompt_preset_id, is_pinned
        )
        VALUES (?, ?, ?, ?, ?, ?, ?, ?)
      ''', [
        id,
        title,
        createdAt.millisecondsSinceEpoch,
        updatedAt.millisecondsSinceEpoch,
        thinkingMode ? 1 : 0,
        promptPresetEnabled ? 1 : 0,
        promptPresetId,
        isPinned ? 1 : 0,
      ]);

      return Conversation(
        id: id,
        title: title,
        createdAt: createdAt,
        updatedAt: updatedAt,
        messages: [],
        thinkingMode: thinkingMode,
        promptPresetEnabled: promptPresetEnabled,
        promptPresetId: promptPresetId,
        isPinned: isPinned,
      );
    });
  }

  /// 插入一条消息记录。
  void _insertMessageRow(
    Database db,
    String conversationId,
    Message message, {
    bool replace = false,
  }) {
    final verb = replace ? 'INSERT OR REPLACE' : 'INSERT';
    db.execute('''
      $verb INTO messages (id, conversation_id, content, reasoning_content, is_user, timestamp, status)
      VALUES (?, ?, ?, ?, ?, ?, ?)
    ''', [
      message.id,
      conversationId,
      message.content,
      message.reasoningContent,
      message.isUser ? 1 : 0,
      message.timestamp.millisecondsSinceEpoch,
      message.status.index,
    ]);
  }

  /// 插入一条附件记录。
  void _insertAttachmentRow(
    Database db,
    String messageId,
    Attachment attachment, {
    bool replace = false,
  }) {
    final verb = replace ? 'INSERT OR REPLACE' : 'INSERT';
    db.execute('''
      $verb INTO attachments (id, message_id, file_name, file_path, url, type, file_size, mime_type, created_at)
      VALUES (?, ?, ?, ?, ?, ?, ?, ?, ?)
    ''', [
      attachment.id,
      messageId,
      attachment.fileName,
      attachment.filePath,
      attachment.url,
      attachment.type.index,
      attachment.fileSize,
      attachment.mimeType,
      attachment.createdAt.millisecondsSinceEpoch,
    ]);
  }

  /// 更新对话的最近更新时间。
  void _touchConversation(
    Database db,
    String conversationId,
    DateTime at,
  ) {
    db.execute('UPDATE conversations SET updated_at = ? WHERE id = ?', [
      at.millisecondsSinceEpoch,
      conversationId,
    ]);
  }

  /// 更新对话
  Future<void> updateConversation(Conversation conversation) async {
    await _synchronized(() async {
      final db = await this.db;

      db.execute('BEGIN IMMEDIATE TRANSACTION');
      try {
        db.execute('''
          INSERT OR REPLACE INTO conversations (
            id, title, created_at, updated_at,
            thinking_mode, prompt_preset_enabled, prompt_preset_id, is_pinned
          )
          VALUES (?, ?, ?, ?, ?, ?, ?, ?)
        ''', [
          conversation.id,
          conversation.title,
          conversation.createdAt.millisecondsSinceEpoch,
          conversation.updatedAt.millisecondsSinceEpoch,
          conversation.thinkingMode ? 1 : 0,
          conversation.promptPresetEnabled ? 1 : 0,
          conversation.promptPresetId,
          conversation.isPinned ? 1 : 0,
        ]);

        // 删除旧消息
        db.execute('DELETE FROM messages WHERE conversation_id = ?',
            [conversation.id]);

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
          db.execute('DELETE FROM attachments WHERE message_id = ?',
              [message.id]);

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

        db.execute('COMMIT');
      } catch (_) {
        db.execute('ROLLBACK');
        rethrow;
      }
    });
  }

  /// 更新会话置顶状态。
  Future<void> updateConversationPinned(
    String conversationId,
    bool isPinned,
  ) async {
    await _synchronized(() async {
      final db = await this.db;
      db.execute(
        'UPDATE conversations SET is_pinned = ? WHERE id = ?',
        [isPinned ? 1 : 0, conversationId],
      );
    });
  }

  /// 只更新会话级偏好，不修改更新时间或消息内容。
  Future<void> updateConversationPreferences(
    String conversationId, {
    required bool thinkingMode,
    required bool promptPresetEnabled,
    required String promptPresetId,
  }) async {
    await _synchronized(() async {
      final db = await this.db;
      db.execute('''
        UPDATE conversations
        SET thinking_mode = ?, prompt_preset_enabled = ?, prompt_preset_id = ?
        WHERE id = ?
      ''', [
        thinkingMode ? 1 : 0,
        promptPresetEnabled ? 1 : 0,
        promptPresetId,
        conversationId,
      ]);
    });
  }

  /// 追加一条消息及其附件，并更新对话的最近更新时间。
  Future<void> appendMessage(
    String conversationId,
    Message message,
  ) async {
    await _synchronized(() async {
      final db = await this.db;

      db.execute('BEGIN IMMEDIATE TRANSACTION');
      try {
        _insertMessageRow(db, conversationId, message);
        for (final attachment in message.attachments) {
          _insertAttachmentRow(db, message.id, attachment);
        }
        _touchConversation(db, conversationId, message.timestamp);
        db.execute('COMMIT');
      } catch (_) {
        db.execute('ROLLBACK');
        rethrow;
      }
    });
  }

  /// 更新一条消息及其附件；消息不存在时抛出 [StateError]。
  Future<void> updateMessage(Message message) async {
    await _synchronized(() async {
      final db = await this.db;

      db.execute('BEGIN IMMEDIATE TRANSACTION');
      try {
        final existing = db.select(
          'SELECT conversation_id FROM messages WHERE id = ?',
          [message.id],
        );
        if (existing.isEmpty) {
          throw StateError('Message not found: ${message.id}');
        }
        final conversationId = existing.first['conversation_id'] as String;

        db.execute('''
          UPDATE messages
          SET content = ?, reasoning_content = ?, is_user = ?, timestamp = ?, status = ?
          WHERE id = ?
        ''', [
          message.content,
          message.reasoningContent,
          message.isUser ? 1 : 0,
          message.timestamp.millisecondsSinceEpoch,
          message.status.index,
          message.id,
        ]);

        db.execute('DELETE FROM attachments WHERE message_id = ?', [message.id]);
        for (final attachment in message.attachments) {
          _insertAttachmentRow(db, message.id, attachment);
        }

        _touchConversation(db, conversationId, message.timestamp);
        db.execute('COMMIT');
      } catch (_) {
        db.execute('ROLLBACK');
        rethrow;
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

  /// 获取当前对话ID；空字符串视为没有当前对话。
  Future<String?> getCurrentConversationId() async {
    final db = await this.db;
    final result = db.select('SELECT value FROM settings WHERE key = ?', ['current_conversation_id']);
    if (result.isEmpty) return null;
    final value = result.first['value'] as String?;
    return (value == null || value.isEmpty) ? null : value;
  }

  /// 清除当前对话ID。
  Future<void> clearCurrentConversationId() async {
    await _synchronized(() async {
      final db = await this.db;
      db.execute(
        'DELETE FROM settings WHERE key = ?',
        ['current_conversation_id'],
      );
    });
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

  /// 关闭数据库连接，并把初始化状态重置为未初始化。
  Future<void> close() async {
    final db = _db;
    _db = null;
    _initFuture = null;
    db?.close();
  }
}
