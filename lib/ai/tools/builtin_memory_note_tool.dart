import 'dart:convert';

import '../contracts/ai_tool.dart';
import '../contracts/ai_tool_executor.dart';
import '../../models/memory_note.dart';

typedef MemoryNoteSink = Future<void> Function(MemoryNoteDraft draft);

/// 让对话模型在事件发生的当下留下一条记忆便签。
///
/// 便签只追加、不直接改正式账本；后台维护模型负责把它合并进记忆。
class MemoryNoteTool implements AIToolExecutor {
  MemoryNoteTool({required this.sink});

  static const String toolName = 'remember_note';

  static const AIToolDefinition definition = AIToolDefinition(
    name: toolName,
    description:
        'Save one durable thing that must survive context compression: a new '
        'agreement, rule, decision, critical fact, important emotional turning '
        'point, or a rejected proposal with its reason. Use only for durable '
        'information, not small talk or every turn. Write in the conversation '
        'language; put exact original wording in quote.',
    inputSchema: {
      'type': 'object',
      'properties': {
        'kind': {
          'type': 'string',
          'enum': ['agreement', 'fact', 'decision', 'emotion', 'rejected'],
          'description':
              'agreement=promise/rule, fact=critical setting or fact, '
              'decision=conclusion, emotion=relationship/emotional turn, '
              'rejected=proposal that was rejected',
        },
        'text': {
          'type': 'string',
          'description': 'Concise note in the conversation language.',
        },
        'quote': {
          'type': 'string',
          'description': 'Exact original wording, when available.',
        },
        'reason': {
          'type': 'string',
          'description': 'For rejected notes: why it was rejected.',
        },
      },
      'required': ['kind', 'text'],
      'additionalProperties': false,
    },
  );

  final MemoryNoteSink sink;

  @override
  List<AIToolDefinition> get tools => const [definition];

  @override
  Future<AIToolResult> execute(AIToolCall call) async {
    final kind = parseMemoryNoteKind(call.arguments['kind']);
    final text = (call.arguments['text'] as String?)?.trim() ?? '';

    if (kind == null) {
      return _error(
        call,
        'Unknown note kind. Use agreement, fact, decision, emotion, or rejected.',
      );
    }
    if (text.isEmpty) {
      return _error(call, 'Note text is empty.');
    }

    final draft = MemoryNoteDraft(
      kind: kind,
      text: text,
      quote: _trimOrNull(call.arguments['quote']),
      reason: _trimOrNull(call.arguments['reason']),
    );

    try {
      await sink(draft);
    } catch (error) {
      return _error(call, 'Failed to record note: $error');
    }

    return AIToolResult(
      toolCallId: call.id,
      name: call.name,
      content: jsonEncode({'status': 'recorded', 'kind': kind.name}),
    );
  }

  static String? _trimOrNull(Object? value) {
    if (value is! String) return null;
    final trimmed = value.trim();
    return trimmed.isEmpty ? null : trimmed;
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
