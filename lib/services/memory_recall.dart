import '../models/conversation_memory.dart';
import '../models/message.dart';
import 'conversation_service.dart';

class MemoryRecallMessage {
  const MemoryRecallMessage({
    required this.id,
    required this.role,
    required this.timestampMs,
    required this.snippet,
  });

  final String id;
  final String role;
  final int timestampMs;
  final String snippet;

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'role': role,
      'timestamp': timestampMs,
      'snippet': snippet,
    };
  }
}

class MemoryRecallEntry {
  const MemoryRecallEntry({
    required this.type,
    required this.status,
    required this.id,
    required this.text,
    this.quote,
    this.reason,
  });

  final String type;
  final String status;
  final String id;
  final String text;
  final String? quote;
  final String? reason;

  Map<String, dynamic> toJson() {
    return {
      'type': type,
      'status': status,
      'id': id,
      'text': text,
      'quote': quote,
      'reason': reason,
    };
  }
}

class MemoryRecallResult {
  const MemoryRecallResult({
    required this.query,
    required this.messages,
    required this.memory,
  });

  final String query;
  final List<MemoryRecallMessage> messages;
  final List<MemoryRecallEntry> memory;

  Map<String, dynamic> toJson() {
    return {
      'query': query,
      'messages': messages.map((item) => item.toJson()).toList(),
      'memory': memory.map((item) => item.toJson()).toList(),
    };
  }
}

/// 按需检索旧消息和完整记忆账本。
///
/// 只做本地关键词/子串匹配，不调用模型、不联网。检索范围是原文窗口之外的
/// 旧消息，以及包含已废止、已否决条目的完整账本。
class MemoryRecallService {
  MemoryRecallService(this._conversationService);

  final ConversationService _conversationService;

  Future<MemoryRecallResult> search({
    required String conversationId,
    required String query,
    Set<String> excludeMessageIds = const {},
    int maxMessages = 8,
    int maxMemory = 8,
  }) async {
    final conversation = await _conversationService.getConversationById(
      conversationId,
    );
    final memory = await _conversationService.getConversationMemory(
      conversationId,
    );

    return MemoryRecallService.searchData(
      messages: conversation?.messages ?? const [],
      memory: memory,
      query: query,
      excludeMessageIds: excludeMessageIds,
      maxMessages: maxMessages,
      maxMemory: maxMemory,
    );
  }

  static MemoryRecallResult searchData({
    required List<Message> messages,
    required ConversationMemory? memory,
    required String query,
    Set<String> excludeMessageIds = const {},
    int maxMessages = 8,
    int maxMemory = 8,
  }) {
    final normalizedQuery = query.trim();
    if (normalizedQuery.isEmpty) {
      return MemoryRecallResult(
        query: normalizedQuery,
        messages: const [],
        memory: const [],
      );
    }

    final terms = _searchTerms(normalizedQuery);
    final messageHits = <_ScoredMessage>[];
    for (final message in messages) {
      if (excludeMessageIds.contains(message.id)) continue;
      if (message.status == MessageStatus.error) continue;
      final content = message.content.trim();
      if (content.isEmpty) continue;

      final score = _score(content, terms);
      if (score <= 0) continue;
      messageHits.add(
        _ScoredMessage(
          message: message,
          score: score,
          snippet: _snippet(content, terms, 220),
        ),
      );
    }

    messageHits.sort((a, b) {
      final byScore = b.score.compareTo(a.score);
      if (byScore != 0) return byScore;
      return b.message.timestamp.compareTo(a.message.timestamp);
    });

    final memoryHits = <_ScoredEntry>[];
    if (memory != null) {
      for (final fact in memory.facts) {
        final haystack = '${fact.text}\n${fact.quote ?? ''}';
        final score = _score(haystack, terms);
        if (score <= 0) continue;
        memoryHits.add(
          _ScoredEntry(
            score: score,
            entry: MemoryRecallEntry(
              type: 'fact',
              status: fact.status.name,
              id: fact.id,
              text: fact.text,
              quote: fact.quote,
            ),
          ),
        );
      }

      for (final entry in memory.rejected) {
        final haystack = '${entry.proposal}\n${entry.reason}';
        final score = _score(haystack, terms);
        if (score <= 0) continue;
        memoryHits.add(
          _ScoredEntry(
            score: score,
            entry: MemoryRecallEntry(
              type: 'rejected',
              status: entry.status.name,
              id: entry.id,
              text: entry.proposal,
              reason: entry.reason,
            ),
          ),
        );
      }
    }

    memoryHits.sort((a, b) => b.score.compareTo(a.score));

    return MemoryRecallResult(
      query: normalizedQuery,
      messages: messageHits
          .take(maxMessages)
          .map(
            (hit) => MemoryRecallMessage(
              id: hit.message.id,
              role: hit.message.isUser ? 'user' : 'assistant',
              timestampMs: hit.message.timestamp.millisecondsSinceEpoch,
              snippet: hit.snippet,
            ),
          )
          .toList(),
      memory: memoryHits
          .take(maxMemory)
          .map((hit) => hit.entry)
          .toList(),
    );
  }

  static List<String> _searchTerms(String query) {
    final terms = <String>{query.toLowerCase()};
    for (final part in query.toLowerCase().split(
      RegExp(r'[\s,，。;；、!?！？:：]+'),
    )) {
      final trimmed = part.trim();
      if (trimmed.isNotEmpty) terms.add(trimmed);
    }
    return terms.toList(growable: false);
  }

  static int _score(String haystack, List<String> terms) {
    final lower = haystack.toLowerCase();
    var score = 0;
    for (final term in terms) {
      if (term.isNotEmpty && lower.contains(term)) {
        score += term.length >= 2 ? 2 : 1;
      }
    }
    return score;
  }

  static String _snippet(String text, List<String> terms, int maxChars) {
    final lower = text.toLowerCase();
    var index = -1;
    for (final term in terms) {
      final found = lower.indexOf(term);
      if (found != -1 && (index == -1 || found < index)) {
        index = found;
      }
    }
    if (index == -1) index = 0;

    final start = index > 60 ? index - 60 : 0;
    final end = start + maxChars > text.length ? text.length : start + maxChars;
    final snippet = text
        .substring(start, end)
        .replaceAll(RegExp(r'\s+'), ' ')
        .trim();

    return '${start > 0 ? '…' : ''}$snippet${end < text.length ? '…' : ''}';
  }
}

class _ScoredMessage {
  const _ScoredMessage({
    required this.message,
    required this.score,
    required this.snippet,
  });

  final Message message;
  final int score;
  final String snippet;
}

class _ScoredEntry {
  const _ScoredEntry({required this.score, required this.entry});

  final int score;
  final MemoryRecallEntry entry;
}
