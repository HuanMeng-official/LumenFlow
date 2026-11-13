import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:sqlite3/sqlite3.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../models/conversation.dart';
import '../models/conversation_memory.dart';
import '../models/memory_note.dart';
import '../models/message.dart';
import '../models/roleplay_memory.dart';
import '../models/attachment.dart';
import 'dart:async';
import '../utils/path_utils.dart';

/// 数据库管理类，使用 sqlite3 实现对话数据与记忆的持久化存储。
///
/// 数据库结构：
/// - `conversations`：对话元数据和对话级设置（思考模式、预设角色、置顶）。
/// - `messages`：消息正文、思考内容、多版本回复和工具调用记录。
/// - `attachments`：消息附件（文件、图片等）。
/// - `conversation_memory`：长会话的滚动记忆、情绪快照和记忆账本。
/// - `conversation_memory_notes`：模型主动写入、等待合并的记忆便签。
/// - `settings`：应用级键值数据，例如当前对话 ID 和迁移标记。
///
/// 特性：
/// - 单例模式，全局共享数据库连接。
/// - 启用外键约束，确保对话、消息和附件之间的数据完整性。
/// - 同一 isolate 内使用异步写锁串行化写操作（sqlite3 非 isolate-safe）。
/// - 打开数据库时自动建表，并通过 `PRAGMA user_version` 前向迁移结构。
/// - 支持从 SharedPreferences 迁移旧版本数据。
///
/// 重要提示：
/// - 此类设计为仅在主 isolate 使用。
/// - 未来如需跨 isolate 访问，需要使用专门的 DB isolate 模式。
/// - 记忆表刻意不使用外键级联，避免 `INSERT OR REPLACE` 对话时误删记忆。
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
  ///
  /// - v1：初始结构，包含 `conversations`、`messages`、`attachments` 和
  ///   `settings` 表。
  /// - v2：对话级设置（思考模式、预设角色开关与 ID、置顶），以及消息的
  ///   多版本字段（`variants`、`active_variant_index`）。
  /// - v3：新增 `conversation_memory`，用于长会话的滚动记忆。
  /// - v4：新增 `conversation_memory_notes`，用于模型主动写入、等待合并的
  ///   记忆便签。
  /// - v5：`conversation_memory` 新增 `roleplay_state`，保存角色扮演的
  ///   结构化状态。
  /// - v6：`messages` 新增 `tool_calls`，保存每轮回复的工具调用与结果。
  static const int schemaVersion = 6;

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

    final messageColumns = db
        .select('PRAGMA table_info(messages)')
        .map((row) => row['name'] as String)
        .toSet();
    if (!messageColumns.contains('variants')) {
      db.execute('ALTER TABLE messages ADD COLUMN variants TEXT');
    }
    if (!messageColumns.contains('active_variant_index')) {
      db.execute(
        'ALTER TABLE messages ADD COLUMN active_variant_index INTEGER NOT NULL DEFAULT 0',
      );
    }
    if (!messageColumns.contains('tool_calls')) {
      db.execute('ALTER TABLE messages ADD COLUMN tool_calls TEXT');
    }

    final memoryColumns = db
        .select('PRAGMA table_info(conversation_memory)')
        .map((row) => row['name'] as String)
        .toSet();
    if (memoryColumns.isNotEmpty &&
        !memoryColumns.contains('roleplay_state')) {
      db.execute(
        'ALTER TABLE conversation_memory ADD COLUMN roleplay_state TEXT',
      );
    }

    if (currentVersion < schemaVersion) {
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
        variants TEXT,
        active_variant_index INTEGER NOT NULL DEFAULT 0,
        tool_calls TEXT,
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

    // 会话记忆表。注意：这里故意不对 conversations 建 ON DELETE CASCADE，
    // 因为 updateConversation 使用 INSERT OR REPLACE，而 SQLite 的 REPLACE
    // 会先删除旧行，触发级联删除，导致每次保存会话都把记忆清空。
    // 删除会话时在 deleteConversation 里手动清理。
    db.execute('''
      CREATE TABLE IF NOT EXISTS conversation_memory (
        conversation_id TEXT PRIMARY KEY,
        summary TEXT NOT NULL DEFAULT '',
        emotional_state TEXT NOT NULL DEFAULT '',
        facts TEXT NOT NULL DEFAULT '[]',
        rejected TEXT NOT NULL DEFAULT '[]',
        covered_until_message_id TEXT,
        fingerprint TEXT,
        updated_at INTEGER,
        roleplay_state TEXT
      )
    ''');

    // 对话模型主动留下的记忆便签，追加式存储，后台维护模型合并后标记为
    // processed。同样不使用 CASCADE 外键，避免 INSERT OR REPLACE 误删。
    db.execute('''
      CREATE TABLE IF NOT EXISTS conversation_memory_notes (
        id TEXT PRIMARY KEY,
        conversation_id TEXT NOT NULL,
        kind TEXT NOT NULL,
        text TEXT NOT NULL,
        quote TEXT,
        reason TEXT,
        source_message_id TEXT,
        created_at INTEGER NOT NULL,
        status TEXT NOT NULL DEFAULT 'pending'
      )
    ''');

    // 创建索引
    db.execute('CREATE INDEX IF NOT EXISTS idx_messages_conversation ON messages(conversation_id)');
    db.execute('CREATE INDEX IF NOT EXISTS idx_attachments_message ON attachments(message_id)');
    db.execute('CREATE INDEX IF NOT EXISTS idx_conversations_updated ON conversations(updated_at)');
    db.execute(
      'CREATE INDEX IF NOT EXISTS idx_memory_notes_conversation '
      'ON conversation_memory_notes(conversation_id, status)',
    );
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
            INSERT OR REPLACE INTO messages (
              id, conversation_id, content, reasoning_content, is_user,
              timestamp, status, variants, active_variant_index, tool_calls
            )
            VALUES (?, ?, ?, ?, ?, ?, ?, ?, ?, ?)
          ''', [
            message.id,
            conversation.id,
            message.content,
            message.reasoningContent,
            message.isUser ? 1 : 0,
            message.timestamp.millisecondsSinceEpoch,
            message.status.index,
            message.variants.isEmpty
                ? null
                : jsonEncode(message.variants.map((v) => v.toJson()).toList()),
            message.activeVariantIndex,
            message.toolCalls.isEmpty
                ? null
                : jsonEncode(message.toolCalls.map((call) => call.toJson()).toList()),
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

  /// 按标题、消息正文或思考内容搜索对话。
  Future<List<Conversation>> searchConversations(String query) async {
    final trimmed = query.trim();
    if (trimmed.isEmpty) return getConversations();

    final db = await this.db;
    final result = db.select('''
      SELECT c.id, c.title, c.created_at, c.updated_at,
             c.thinking_mode, c.prompt_preset_enabled, c.prompt_preset_id,
             c.is_pinned
      FROM conversations c
      WHERE instr(lower(c.title), lower(?)) > 0
         OR EXISTS (
           SELECT 1
           FROM messages m
           WHERE m.conversation_id = c.id
             AND (
               instr(lower(m.content), lower(?)) > 0
               OR instr(lower(COALESCE(m.reasoning_content, '')), lower(?)) > 0
             )
         )
      ORDER BY c.is_pinned DESC, c.updated_at DESC
    ''', [trimmed, trimmed, trimmed]);

    return result.map((row) {
      return Conversation(
        id: row['id'] as String,
        title: row['title'] as String,
        createdAt: DateTime.fromMillisecondsSinceEpoch(row['created_at'] as int),
        updatedAt: DateTime.fromMillisecondsSinceEpoch(row['updated_at'] as int),
        messages: [],
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
      SELECT id, content, reasoning_content, is_user, timestamp, status,
             variants, active_variant_index, tool_calls
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

      final variantsJson = msgRow['variants'] as String?;
      final variants = variantsJson == null || variantsJson.isEmpty
          ? <MessageVariant>[]
          : (jsonDecode(variantsJson) as List)
                .map(
                  (value) => MessageVariant.fromJson(
                    (value as Map).cast<String, dynamic>(),
                  ),
                )
                .toList();
      final rawVariantIndex = msgRow['active_variant_index'] as int? ?? 0;
      final activeVariantIndex = variants.isEmpty
          ? 0
          : rawVariantIndex.clamp(0, variants.length - 1);
      final toolCallsJson = msgRow['tool_calls'] as String?;
      final toolCalls = toolCallsJson == null || toolCallsJson.isEmpty
          ? <MessageToolCall>[]
          : (jsonDecode(toolCallsJson) as List)
                .map(
                  (value) => MessageToolCall.fromJson(
                    (value as Map).cast<String, dynamic>(),
                  ),
                )
                .toList();

      messages.add(Message(
        id: messageId,
        content: msgRow['content'] as String,
        reasoningContent: msgRow['reasoning_content'] as String?,
        isUser: (msgRow['is_user'] as int) == 1,
        timestamp: DateTime.fromMillisecondsSinceEpoch(msgRow['timestamp'] as int),
        status: MessageStatus.values[msgRow['status'] as int],
        attachments: attachments,
        variants: variants,
        activeVariantIndex: activeVariantIndex,
        toolCalls: toolCalls,
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

  /// 原子导入一个完整对话（包含消息和附件）。
  Future<void> importConversation(Conversation conversation) async {
    await _synchronized(() async {
      final db = await this.db;

      db.execute('BEGIN IMMEDIATE TRANSACTION');
      try {
        db.execute('''
          INSERT INTO conversations (
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

        for (final message in conversation.messages) {
          _insertMessageRow(db, conversation.id, message);
          for (final attachment in message.attachments) {
            _insertAttachmentRow(db, message.id, attachment);
          }
        }

        db.execute('COMMIT');
      } catch (_) {
        db.execute('ROLLBACK');
        rethrow;
      }
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
      $verb INTO messages (
        id, conversation_id, content, reasoning_content, is_user,
        timestamp, status, variants, active_variant_index, tool_calls
      )
      VALUES (?, ?, ?, ?, ?, ?, ?, ?, ?, ?)
    ''', [
      message.id,
      conversationId,
      message.content,
      message.reasoningContent,
      message.isUser ? 1 : 0,
      message.timestamp.millisecondsSinceEpoch,
      message.status.index,
      message.variants.isEmpty
          ? null
          : jsonEncode(message.variants.map((v) => v.toJson()).toList()),
      message.activeVariantIndex,
      message.toolCalls.isEmpty
          ? null
          : jsonEncode(message.toolCalls.map((call) => call.toJson()).toList()),
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
            INSERT OR REPLACE INTO messages (
              id, conversation_id, content, reasoning_content, is_user,
              timestamp, status, variants, active_variant_index, tool_calls
            )
            VALUES (?, ?, ?, ?, ?, ?, ?, ?, ?, ?)
          ''', [
            message.id,
            conversation.id,
            message.content,
            message.reasoningContent,
            message.isUser ? 1 : 0,
            message.timestamp.millisecondsSinceEpoch,
            message.status.index,
            message.variants.isEmpty
                ? null
                : jsonEncode(message.variants.map((v) => v.toJson()).toList()),
            message.activeVariantIndex,
            message.toolCalls.isEmpty
                ? null
                : jsonEncode(message.toolCalls.map((call) => call.toJson()).toList()),
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
          SET content = ?, reasoning_content = ?, is_user = ?, timestamp = ?,
              status = ?, variants = ?, active_variant_index = ?, tool_calls = ?
          WHERE id = ?
        ''', [
          message.content,
          message.reasoningContent,
          message.isUser ? 1 : 0,
          message.timestamp.millisecondsSinceEpoch,
          message.status.index,
          message.variants.isEmpty
              ? null
              : jsonEncode(message.variants.map((v) => v.toJson()).toList()),
          message.activeVariantIndex,
          message.toolCalls.isEmpty
              ? null
              : jsonEncode(message.toolCalls.map((call) => call.toJson()).toList()),
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

  /// 删除对话（连带清理记忆，因为没有用 CASCADE 外键）。
  Future<void> deleteConversation(String conversationId) async {
    await _synchronized(() async {
      final db = await this.db;
      db.execute('BEGIN IMMEDIATE TRANSACTION');
      try {
        db.execute(
          'DELETE FROM conversation_memory WHERE conversation_id = ?',
          [conversationId],
        );
        db.execute(
          'DELETE FROM conversation_memory_notes WHERE conversation_id = ?',
          [conversationId],
        );
        db.execute('DELETE FROM conversations WHERE id = ?', [conversationId]);
        db.execute('COMMIT');
      } catch (_) {
        db.execute('ROLLBACK');
        rethrow;
      }
    });
  }

  /// 读取会话记忆；不存在时返回 null。
  Future<ConversationMemory?> getConversationMemory(
    String conversationId,
  ) async {
    final db = await this.db;
    final result = db.select(
      'SELECT * FROM conversation_memory WHERE conversation_id = ?',
      [conversationId],
    );
    if (result.isEmpty) return null;

    final row = result.first;
    return ConversationMemory(
      summary: row['summary'] as String? ?? '',
      emotionalState: row['emotional_state'] as String? ?? '',
      facts: _decodeFacts(row['facts'] as String?),
      rejected: _decodeRejected(row['rejected'] as String?),
      roleplay: _decodeRoleplay(row['roleplay_state'] as String?),
      coveredUntilMessageId: row['covered_until_message_id'] as String?,
      fingerprint: row['fingerprint'] as String?,
      updatedAt: row['updated_at'] == null
          ? null
          : DateTime.fromMillisecondsSinceEpoch(row['updated_at'] as int),
    );
  }

  /// 写入/覆盖会话记忆。
  ///
  /// 会话已被删除时直接忽略，避免后台记忆更新在删除之后写回孤儿数据。
  Future<void> saveConversationMemory(
    String conversationId,
    ConversationMemory memory,
  ) async {
    await _synchronized(() async {
      final db = await this.db;
      db.execute('BEGIN IMMEDIATE TRANSACTION');
      try {
        final existing = db.select(
          'SELECT 1 FROM conversations WHERE id = ?',
          [conversationId],
        );
        if (existing.isEmpty) {
          db.execute('COMMIT');
          return;
        }

        db.execute(
          '''
          INSERT OR REPLACE INTO conversation_memory (
            conversation_id, summary, emotional_state, facts, rejected,
            covered_until_message_id, fingerprint, updated_at, roleplay_state
          ) VALUES (?, ?, ?, ?, ?, ?, ?, ?, ?)
          ''',
          [
            conversationId,
            memory.summary,
            memory.emotionalState,
            jsonEncode(memory.facts.map((fact) => fact.toJson()).toList()),
            jsonEncode(
              memory.rejected.map((entry) => entry.toJson()).toList(),
            ),
            memory.coveredUntilMessageId,
            memory.fingerprint,
            (memory.updatedAt ?? DateTime.now()).millisecondsSinceEpoch,
            memory.roleplay == null
                ? null
                : jsonEncode(memory.roleplay!.toJson()),
          ],
        );
        db.execute('COMMIT');
      } catch (_) {
        db.execute('ROLLBACK');
        rethrow;
      }
    });
  }

  /// 删除会话记忆，不影响会话本身。
  Future<void> deleteConversationMemory(String conversationId) async {
    await _synchronized(() async {
      final db = await this.db;
      db.execute(
        'DELETE FROM conversation_memory WHERE conversation_id = ?',
        [conversationId],
      );
    });
  }

  /// 追加一条对话模型主动记录的记忆便签。
  Future<void> appendMemoryNote(MemoryNote note) async {
    await _synchronized(() async {
      final db = await this.db;
      db.execute('BEGIN IMMEDIATE TRANSACTION');
      try {
        final existing = db.select(
          'SELECT 1 FROM conversations WHERE id = ?',
          [note.conversationId],
        );
        if (existing.isEmpty) {
          db.execute('COMMIT');
          return;
        }

        db.execute(
          '''
          INSERT OR REPLACE INTO conversation_memory_notes (
            id, conversation_id, kind, text, quote, reason,
            source_message_id, created_at, status
          ) VALUES (?, ?, ?, ?, ?, ?, ?, ?, ?)
          ''',
          [
            note.id,
            note.conversationId,
            note.kind.name,
            note.text,
            note.quote,
            note.reason,
            note.sourceMessageId,
            note.createdAt.millisecondsSinceEpoch,
            note.status.name,
          ],
        );
        db.execute('COMMIT');
      } catch (_) {
        db.execute('ROLLBACK');
        rethrow;
      }
    });
  }

  /// 读取会话的记忆便签；[onlyPending] 为 true 时只返回待合并条目。
  Future<List<MemoryNote>> getMemoryNotes(
    String conversationId, {
    bool onlyPending = false,
  }) async {
    final db = await this.db;
    final statusFilter = onlyPending ? "AND status = 'pending'" : '';
    final rows = db.select(
      '''
      SELECT id, conversation_id, kind, text, quote, reason,
             source_message_id, created_at, status
      FROM conversation_memory_notes
      WHERE conversation_id = ? $statusFilter
      ORDER BY created_at ASC
      ''',
      [conversationId],
    );

    return rows
        .map(
          (row) => MemoryNote(
            id: row['id'] as String,
            conversationId: row['conversation_id'] as String,
            kind:
                parseMemoryNoteKind(row['kind']) ?? MemoryNoteKind.fact,
            text: row['text'] as String,
            quote: row['quote'] as String?,
            reason: row['reason'] as String?,
            sourceMessageId: row['source_message_id'] as String?,
            createdAt: DateTime.fromMillisecondsSinceEpoch(
              row['created_at'] as int,
            ),
            status: parseMemoryNoteStatus(row['status']),
          ),
        )
        .toList();
  }

  /// 标记便签已被后台维护模型合并。
  Future<void> markMemoryNotesProcessed(
    String conversationId,
    Iterable<String> noteIds,
  ) async {
    final ids = noteIds.toList(growable: false);
    if (ids.isEmpty) return;

    await _synchronized(() async {
      final db = await this.db;
      final placeholders = List.filled(ids.length, '?').join(', ');
      db.execute(
        'UPDATE conversation_memory_notes SET status = ? '
        'WHERE conversation_id = ? AND id IN ($placeholders)',
        [MemoryNoteStatus.processed.name, conversationId, ...ids],
      );
    });
  }

  static RoleplayMemory? _decodeRoleplay(String? raw) {
    if (raw == null || raw.isEmpty) return null;
    try {
      final decoded = jsonDecode(raw);
      if (decoded is! Map) return null;
      final roleplay = RoleplayMemory.fromJson(
        decoded.cast<String, dynamic>(),
      );
      return roleplay.isEmpty ? null : roleplay;
    } catch (_) {
      return null;
    }
  }

  static List<MemoryFact> _decodeFacts(String? raw) {
    if (raw == null || raw.isEmpty) return const [];
    try {
      final decoded = jsonDecode(raw);
      if (decoded is! List) return const [];
      return decoded
          .whereType<Map>()
          .map((value) => MemoryFact.fromJson(value.cast<String, dynamic>()))
          .toList();
    } catch (_) {
      return const [];
    }
  }

  static List<RejectedProposal> _decodeRejected(String? raw) {
    if (raw == null || raw.isEmpty) return const [];
    try {
      final decoded = jsonDecode(raw);
      if (decoded is! List) return const [];
      return decoded
          .whereType<Map>()
          .map(
            (value) =>
                RejectedProposal.fromJson(value.cast<String, dynamic>()),
          )
          .toList();
    } catch (_) {
      return const [];
    }
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
