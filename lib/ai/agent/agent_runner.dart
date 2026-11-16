import '../contracts/ai_error.dart';
import '../contracts/ai_message.dart';
import '../contracts/cancellation_token.dart';
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
    // Provider instances keep tool-loop state (Claude thinking blocks, Gemini
    // interaction ids); reset it so a reused instance cannot leak a previous
    // conversation into this run.
    final resettable = provider;
    if (resettable is ResettableStreamingProvider) {
      resettable.resetState();
    }

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

      final isLastIteration = iteration == maxIterations - 1;
      messages.add(
        AIMessage.assistant(
          answer.toString(),
          reasoningContent: reasoning.toString(),
          toolCalls: toolCalls,
        ),
      );

      for (final call in toolCalls) {
        request.cancellationToken?.throwIfCancelled();
        AIToolResult result;
        try {
          result = await _executeTool(call, request.cancellationToken);
        } catch (error) {
          if (error is AIError && error.type == AIErrorType.cancelled) {
            rethrow;
          }
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

      if (isLastIteration) {
        request.cancellationToken?.throwIfCancelled();
        // Give the model one tool-free turn to summarize the tool results
        // instead of failing the whole request at the iteration limit.
        final finalRequest = request.copyWith(
          messages: messages,
          tools: const [],
          toolChoice: AIToolChoice.none,
        );
        await for (final event in provider.stream(finalRequest)) {
          if (event is AIAnswerDelta || event is AIReasoningDelta) {
            yield event;
          }
        }
        return;
      }
    }

    throw const AIError(
      type: AIErrorType.invalidResponse,
      message: 'Tool call limit reached',
    );
  }

  Future<AIToolResult> _executeTool(
    AIToolCall call,
    CancellationToken? token,
  ) {
    token?.throwIfCancelled();
    final future = executor.execute(call);
    if (token == null) return future;
    return Future.any<AIToolResult>([
      future,
      token.whenCancelled.then<AIToolResult>((_) {
        throw const AIError(
          type: AIErrorType.cancelled,
          message: 'Request cancelled',
        );
      }),
    ]);
  }
}
