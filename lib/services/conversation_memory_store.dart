import '../models/conversation_memory.dart';
import '../models/memory_note.dart';
import 'conversation_service.dart';
import 'memory_service.dart';

/// 用 [ConversationService] 的 SQLite 存储实现记忆持久化。
class ConversationMemoryStore implements MemoryStore, MemoryNoteStore {
  ConversationMemoryStore(this._conversationService);

  final ConversationService _conversationService;

  @override
  Future<ConversationMemory?> load(String conversationId) =>
      _conversationService.getConversationMemory(conversationId);

  @override
  Future<void> save(
    String conversationId,
    ConversationMemory memory,
  ) => _conversationService.saveConversationMemory(conversationId, memory);

  @override
  Future<List<MemoryNote>> loadPendingNotes(String conversationId) =>
      _conversationService.getMemoryNotes(
        conversationId,
        onlyPending: true,
      );

  @override
  Future<void> markNotesProcessed(
    String conversationId,
    List<String> noteIds,
  ) => _conversationService.markMemoryNotesProcessed(
    conversationId,
    noteIds,
  );
}
