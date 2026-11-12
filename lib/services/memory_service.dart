import 'dart:async';

import '../models/conversation_memory.dart';
import '../models/memory_note.dart';
import '../models/message.dart';
import '../utils/memory_fingerprint.dart';
import 'memory_policy.dart';
import 'memory_prompt.dart';
import 'memory_update.dart';

/// 记忆持久化的最小接口，便于测试和替换存储。
abstract class MemoryStore {
  Future<ConversationMemory?> load(String conversationId);

  Future<void> save(String conversationId, ConversationMemory memory);
}

/// 记忆更新模型的最小接口。
abstract class MemoryUpdateClient {
  Future<String> generateMemoryUpdate({
    required String systemPrompt,
    required String userPrompt,
  });
}

/// 主动记忆便签的最小存储接口。
abstract class MemoryNoteStore {
  Future<List<MemoryNote>> loadPendingNotes(String conversationId);

  Future<void> markNotesProcessed(
    String conversationId,
    List<String> noteIds,
  );
}

enum MemoryStatusStage { updating, rebuilding, failed }

typedef MemoryStatusCallback =
    void Function(MemoryStatusStage stage, {int? current, int? total});

/// 滚动记忆编排：
/// - 校验现有记忆的覆盖边界和内容指纹；
/// - 发送前补齐必须覆盖的旧消息；
/// - 回复完成后后台提前覆盖，减少下一次发送的等待；
/// - 模型输出异常时保留已有记忆，绝不写入半成品。
class MemoryService {
  MemoryService({
    required this.store,
    required this.client,
    this.noteStore,
    this.chunkSize = MemoryPolicy.chunkSize,
    this.rebuildChunkSize = MemoryPolicy.rebuildChunkSize,
    this.reserve = MemoryPolicy.reserve,
    this.updateTimeout = const Duration(seconds: 30),
    DateTime Function()? clock,
    String Function(String prefix)? idGenerator,
  }) : _clock = clock ?? DateTime.now,
       _idGenerator = idGenerator ?? _defaultIdGenerator;

  final MemoryStore store;
  final MemoryUpdateClient client;
  final MemoryNoteStore? noteStore;
  final int chunkSize;
  final int rebuildChunkSize;
  final int reserve;

  /// 单次记忆更新调用的上限，避免发送前无限等待。
  final Duration updateTimeout;
  final DateTime Function() _clock;
  final String Function(String prefix) _idGenerator;

  // 静态锁：发送前 ensure 和回复后后台更新可能来自不同 MemoryService 实例，
  // 必须按会话串行，否则会并发写同一份记忆。
  static final Map<String, Future<void>> _locks = {};
  static int _idCounter = 0;

  static String _defaultIdGenerator(String prefix) =>
      '${prefix}_${DateTime.now().microsecondsSinceEpoch}_${_idCounter++}';

  /// 发送前调用：保证记忆覆盖所有即将滑出原文窗口的消息，并返回注入块。
  Future<String> ensureUpToDate({
    required String conversationId,
    required List<Message> eligibleMessages,
    required int historyRounds,
    bool enabled = true,
    bool roleplayMode = false,
    String characterName = '',
    String characterDescription = '',
    MemoryStatusCallback? onStatus,
  }) {
    return _synchronized(conversationId, () async {
      if (!enabled) return '';

      final eligible = _eligible(eligibleMessages);
      final required = MemoryPolicy.requiredCoverage(
        eligibleCount: eligible.length,
        historyRounds: historyRounds,
      );
      final loaded =
          await store.load(conversationId) ?? ConversationMemory.empty();
      var memory = loaded;
      var covered = _coveredCount(memory, eligible);
      var rebuilding = false;

      if (covered < 0) {
        memory = ConversationMemory.empty();
        covered = 0;
        rebuilding = true;
        await store.save(conversationId, memory);
      }

      if (covered >= required) {
        return formatMemoryBlock(memory);
      }

      final pendingNotes = noteStore == null
          ? const <MemoryNote>[]
          : await noteStore!.loadPendingNotes(conversationId);
      final updated = await _updateTo(
        conversationId: conversationId,
        eligible: eligible,
        memory: memory,
        covered: covered,
        targetCoverage: required,
        rebuilding: rebuilding,
        pendingNotes: pendingNotes,
        roleplayMode: roleplayMode,
        characterName: characterName,
        characterDescription: characterDescription,
        onStatus: onStatus,
      );
      return formatMemoryBlock(updated);
    });
  }

  /// 回复完成后调用：提前覆盖到窗口之外一个 reserve，正常情况不会阻塞发送。
  Future<void> updateInBackground({
    required String conversationId,
    required List<Message> eligibleMessages,
    required int historyRounds,
    bool enabled = true,
    bool roleplayMode = false,
    String characterName = '',
    String characterDescription = '',
    MemoryStatusCallback? onStatus,
  }) {
    return _synchronized(conversationId, () async {
      if (!enabled) return;

      final eligible = _eligible(eligibleMessages);
      final required = MemoryPolicy.requiredCoverage(
        eligibleCount: eligible.length,
        historyRounds: historyRounds,
      );
      if (required <= 0) return;

      final loaded =
          await store.load(conversationId) ?? ConversationMemory.empty();
      var memory = loaded;
      var covered = _coveredCount(memory, eligible);
      var rebuilding = false;

      if (covered < 0) {
        memory = ConversationMemory.empty();
        covered = 0;
        rebuilding = true;
        await store.save(conversationId, memory);
      }

      final due =
          covered < required ||
          MemoryPolicy.shouldUpdateInBackground(
            coveredCount: covered,
            requiredCoverage: required,
            reserve: reserve,
            chunkSize: chunkSize,
          );
      if (!due) return;

      final pendingNotes = noteStore == null
          ? const <MemoryNote>[]
          : await noteStore!.loadPendingNotes(conversationId);

      var target = MemoryPolicy.targetCoverage(
        eligibleCount: eligible.length,
        historyRounds: historyRounds,
        reserve: reserve,
      );
      // 后台提前覆盖可以吃掉一部分原文窗口做缓冲，但至少留最新一条原文；
      // 否则最新回复会同时出现在“记忆”和“最近对话”里，浪费 token。
      final maxTarget = eligible.length - 1;
      if (target > maxTarget && maxTarget >= required) {
        target = maxTarget;
      }
      await _updateTo(
        conversationId: conversationId,
        eligible: eligible,
        memory: memory,
        covered: covered,
        targetCoverage: target,
        rebuilding: rebuilding,
        pendingNotes: pendingNotes,
        roleplayMode: roleplayMode,
        characterName: characterName,
        characterDescription: characterDescription,
        onStatus: onStatus,
      );
    });
  }

  Future<ConversationMemory> _updateTo({
    required String conversationId,
    required List<Message> eligible,
    required ConversationMemory memory,
    required int covered,
    required int targetCoverage,
    required bool rebuilding,
    List<MemoryNote> pendingNotes = const [],
    bool roleplayMode = false,
    String characterName = '',
    String characterDescription = '',
    MemoryStatusCallback? onStatus,
  }) async {
    final target = targetCoverage > eligible.length
        ? eligible.length
        : targetCoverage;
    if (covered >= target) return memory;

    // 首次整理/重建时用更大的块，避免很长的旧会话要调用几十次模型。
    final effectiveChunkSize =
        (rebuilding || (memory.isEmpty && covered == 0))
        ? (rebuildChunkSize > chunkSize ? rebuildChunkSize : chunkSize)
        : chunkSize;
    final totalChunks = ((target - covered) / effectiveChunkSize).ceil();
    var state = memory;
    var cursor = covered;
    var chunkNumber = 0;
    var notesMerged = false;

    while (cursor < target) {
      chunkNumber++;
      onStatus?.call(
        rebuilding ? MemoryStatusStage.rebuilding : MemoryStatusStage.updating,
        current: chunkNumber,
        total: totalChunks,
      );

      final end = cursor + effectiveChunkSize > target
          ? target
          : cursor + effectiveChunkSize;
      final chunk = eligible.sublist(cursor, end);

      String raw;
      try {
        raw = await client
            .generateMemoryUpdate(
              systemPrompt: buildMemoryUpdateSystemPrompt(),
              userPrompt: buildMemoryUpdateUserPrompt(
                memory: state,
                chunk: chunk,
                pendingNotes: pendingNotes,
                roleplayMode: roleplayMode,
                characterName: characterName,
                characterDescription: characterDescription,
              ),
            )
            .timeout(updateTimeout);
      } catch (_) {
        onStatus?.call(MemoryStatusStage.failed);
        return state;
      }

      final update = MemoryUpdateParser.parse(raw);
      if (update == null) {
        onStatus?.call(MemoryStatusStage.failed);
        return state;
      }

      final applyBase =
          roleplayMode && chunkNumber == 1 && state.roleplay != null
          ? state.copyWith(
              roleplay: state.roleplay!.copyWith(newFactIds: const []),
            )
          : state;
      state = MemoryUpdateApplier.apply(
        applyBase,
        update,
        nextFactId: () => _idGenerator('fact'),
        nextRejectedId: () => _idGenerator('rej'),
        now: _clock(),
      );
      state = state.copyWith(
        coveredUntilMessageId: chunk.last.id,
        fingerprint: computeMemoryFingerprint(eligible.sublist(0, end)),
      );
      await store.save(conversationId, state);
      notesMerged = true;
      cursor = end;
    }

    if (notesMerged && pendingNotes.isNotEmpty) {
      await noteStore?.markNotesProcessed(
        conversationId,
        pendingNotes.map((note) => note.id).toList(growable: false),
      );
    }

    return state;
  }

  List<Message> _eligible(List<Message> messages) {
    return messages
        .where(
          (message) =>
              message.status != MessageStatus.error &&
              message.content.trim().isNotEmpty,
        )
        .toList(growable: false);
  }

  /// 返回记忆实际覆盖的消息条数；-1 表示边界缺失或指纹不匹配，需要重建。
  int _coveredCount(ConversationMemory memory, List<Message> eligible) {
    final boundary = memory.coveredUntilMessageId;
    if (boundary == null) {
      return memory.isEmpty ? 0 : -1;
    }
    final index = eligible.indexWhere((message) => message.id == boundary);
    if (index == -1) return -1;

    final fingerprint = memory.fingerprint;
    if (fingerprint == null) return -1;
    final current = computeMemoryFingerprint(eligible.sublist(0, index + 1));
    if (current != fingerprint) return -1;
    return index + 1;
  }

  Future<T> _synchronized<T>(
    String conversationId,
    Future<T> Function() action,
  ) async {
    final previous = _locks[conversationId];
    final gate = Completer<void>();
    _locks[conversationId] = gate.future;

    if (previous != null) {
      await previous.catchError((_) {});
    }

    try {
      return await action();
    } finally {
      gate.complete();
      if (identical(_locks[conversationId], gate.future)) {
        _locks.remove(conversationId);
      }
    }
  }
}
