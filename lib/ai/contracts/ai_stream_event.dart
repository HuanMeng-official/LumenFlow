import 'ai_tool.dart';

sealed class AIStreamEvent {
  const AIStreamEvent();
}

class AIReasoningDelta extends AIStreamEvent {
  final String text;

  const AIReasoningDelta(this.text);
}

class AIAnswerDelta extends AIStreamEvent {
  final String text;

  const AIAnswerDelta(this.text);
}

/// Emitted once when a provider has assembled a complete set of tool calls.
class AIToolCallsComplete extends AIStreamEvent {
  final List<AIToolCall> calls;

  const AIToolCallsComplete(this.calls);
}

/// Emitted by the agent loop after a tool has executed.
class AIToolResultEvent extends AIStreamEvent {
  final AIToolCall call;
  final AIToolResult result;

  const AIToolResultEvent({required this.call, required this.result});
}
