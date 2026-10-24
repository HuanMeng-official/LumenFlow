import 'ai_tool.dart';

enum AIMessageRole { system, user, assistant, tool }

/// A provider-neutral chat message, including assistant tool calls and
/// tool results.
class AIMessage {
  final AIMessageRole role;
  final String content;
  final String? reasoningContent;
  final List<AIToolCall> toolCalls;
  final String? toolCallId;
  final String? name;
  final bool isError;

  const AIMessage._({
    required this.role,
    required this.content,
    this.reasoningContent,
    this.toolCalls = const [],
    this.toolCallId,
    this.name,
    this.isError = false,
  });

  const AIMessage.system(String content)
      : this._(role: AIMessageRole.system, content: content);

  const AIMessage.user(String content)
      : this._(role: AIMessageRole.user, content: content);

  const AIMessage.assistant(
    String content, {
    List<AIToolCall> toolCalls = const [],
  }) : this._(
          role: AIMessageRole.assistant,
          content: content,
          toolCalls: toolCalls,
        );

  const AIMessage.tool({
    required String toolCallId,
    required String content,
    String? name,
    bool isError = false,
  }) : this._(
          role: AIMessageRole.tool,
          content: content,
          toolCallId: toolCallId,
          name: name,
          isError: isError,
        );

  Map<String, dynamic> toOpenAIJson() {
    final json = <String, dynamic>{
      'role': role.name,
      'content': content,
    };

    if (toolCalls.isNotEmpty) {
      json['tool_calls'] = toolCalls
          .map((call) => {
                'id': call.id,
                'type': 'function',
                'function': {
                  'name': call.name,
                  'arguments': call.argumentsJson,
                },
              })
          .toList();
    }

    if (toolCallId != null) {
      json['tool_call_id'] = toolCallId;
    }
    if (name != null) {
      json['name'] = name;
    }

    return json;
  }
}
