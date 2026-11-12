import 'dart:convert';

import '../contracts/ai_tool.dart';
import '../contracts/ai_tool_executor.dart';
import '../../services/memory_recall.dart';

typedef MemoryRecallHandler =
    Future<MemoryRecallResult> Function(String query);

/// 让对话模型按需翻旧消息和完整记忆账本。
class MemoryRecallTool implements AIToolExecutor {
  MemoryRecallTool({required this.handler});

  static const String toolName = 'recall';

  static const AIToolDefinition definition = AIToolDefinition(
    name: toolName,
    description:
        'Search older messages and the full memory ledger for a specific past '
        'detail, exact quote, previous agreement, or rejected proposal. Use '
        'only when the user asks about something from earlier that is not in '
        'your current context. Pass 1-5 short keywords or an exact phrase, not '
        'a full question. If the result is empty, say you cannot find it; do '
        'not invent.',
    inputSchema: {
      'type': 'object',
      'properties': {
        'query': {
          'type': 'string',
          'description': '1-5 short keywords or an exact phrase.',
        },
      },
      'required': ['query'],
      'additionalProperties': false,
    },
  );

  final MemoryRecallHandler handler;

  @override
  List<AIToolDefinition> get tools => const [definition];

  @override
  Future<AIToolResult> execute(AIToolCall call) async {
    final query = (call.arguments['query'] as String?)?.trim() ?? '';
    if (query.isEmpty) {
      return _error(call, 'Recall query is empty.');
    }

    try {
      final result = await handler(query);
      return AIToolResult(
        toolCallId: call.id,
        name: call.name,
        content: jsonEncode(result.toJson()),
      );
    } catch (error) {
      return _error(call, 'Recall failed: $error');
    }
  }

  static AIToolResult _error(AIToolCall call, String message) {
    return AIToolResult(
      toolCallId: call.id,
      name: call.name,
      content: jsonEncode({'status': 'error', 'message': message}),
      isError: true,
    );
  }
}
