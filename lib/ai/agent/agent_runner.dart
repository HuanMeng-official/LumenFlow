import '../contracts/ai_error.dart';
import '../contracts/ai_message.dart';
import '../contracts/ai_request.dart';
import '../contracts/ai_stream_event.dart';
import '../contracts/ai_tool.dart';
import '../contracts/ai_tool_executor.dart';
import '../providers/chat_completions_tool_provider.dart';

/// Alternates model calls and tool executions until the model produces a
/// final answer or the iteration budget is exhausted.
class AgentRunner {
  AgentRunner({
    required this.provider,
    required this.executor,
    this.maxIterations = 5,
  });

  final AIStreamingProvider provider;
  final AIToolExecutor executor;
  final int maxIterations;

  Stream<AIStreamEvent> run(AIRequest request) async* {
    final messages = List<AIMessage>.from(request.messages);
    final tools = request.tools.isNotEmpty ? request.tools : executor.tools;

    for (var iteration = 0; iteration < maxIterations; iteration++) {
      final currentRequest = request.copyWith(
        messages: messages,
        tools: tools,
        toolChoice:
            iteration == 0 ? request.toolChoice : AIToolChoice.auto,
      );

      final answer = StringBuffer();
      final reasoning = StringBuffer();
      var toolCalls = const <AIToolCall>[];

      await for (final event in provider.stream(currentRequest)) {
        if (event is AIAnswerDelta) {
          answer.write(event.text);
          yield event;
        } else if (event is AIReasoningDelta) {
          reasoning.write(event.text);
          yield event;
        } else if (event is AIToolCallsComplete) {
          toolCalls = event.calls;
          yield event;
        } else {
          yield event;
        }
      }

      if (toolCalls.isEmpty) {
        return;
      }

      if (iteration == maxIterations - 1) {
        throw const AIError(
          type: AIErrorType.invalidResponse,
          message: 'Tool call limit reached',
        );
      }

      messages.add(
        AIMessage.assistant(
          answer.toString(),
          reasoningContent: reasoning.toString(),
          toolCalls: toolCalls,
        ),
      );

      for (final call in toolCalls) {
        AIToolResult result;
        try {
          result = await executor.execute(call);
        } catch (error) {
          result = AIToolResult(
            toolCallId: call.id,
            name: call.name,
            content: error.toString(),
            isError: true,
          );
        }

        yield AIToolResultEvent(call: call, result: result);
        messages.add(
          AIMessage.tool(
            toolCallId: call.id,
            name: call.name,
            content: result.content,
            isError: result.isError,
          ),
        );
      }
    }

    throw const AIError(
      type: AIErrorType.invalidResponse,
      message: 'Tool call limit reached',
    );
  }
}
