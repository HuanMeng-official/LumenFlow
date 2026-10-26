import '../ai/agent/agent_runner.dart';
import '../ai/contracts/ai_error.dart';
import '../ai/contracts/ai_message.dart';
import '../ai/contracts/ai_request.dart';
import '../ai/contracts/ai_stream_event.dart';
import '../ai/contracts/ai_tool_executor.dart';
import '../ai/providers/chat_completions_profile.dart';
import '../ai/providers/chat_completions_tool_provider.dart';
import '../ai/providers/claude_tool_provider.dart';
import '../ai/providers/gemini_tool_provider.dart';
import '../ai/providers/responses_tool_provider.dart';
import '../models/active_platform_config.dart';
import '../models/message.dart';

/// Runs a tool-capable provider turn and emits the legacy map protocol
/// consumed by [ChatSendController].
class ToolChatService {
  ToolChatService({
    required this.executor,
    this._providerFactory,
    this.maxIterations = 5,
  });

  final AIToolExecutor executor;
  final AIStreamingProvider Function(ActivePlatformConfig config)?
      _providerFactory;
  final int maxIterations;

  Stream<Map<String, dynamic>> run({
    required ActivePlatformConfig config,
    required String message,
    required List<Message> history,
    required String systemPrompt,
    required double temperature,
    required int maxTokens,
    required bool thinkingMode,
    required bool enableHistory,
    required int historyContextLength,
  }) async* {
    final provider = _providerFactory?.call(config) ?? _createProvider(config);

    final messages = <AIMessage>[AIMessage.system(systemPrompt)];

    if (enableHistory) {
      final filtered = history
          .where(
            (message) =>
                message.status != MessageStatus.error &&
                message.content.trim().isNotEmpty,
          )
          .toList();

      final maxMessages = historyContextLength * 2;
      final recent = filtered.length > maxMessages
          ? filtered.sublist(filtered.length - maxMessages)
          : filtered;

      for (final historical in recent) {
        messages.add(
          historical.isUser
              ? AIMessage.user(historical.content)
              : AIMessage.assistant(historical.content),
        );
      }
    }

    messages.add(AIMessage.user(message));

    final request = AIRequest(
      model: config.model,
      endpoint: config.endpoint,
      apiKey: config.apiKey,
      messages: messages,
      temperature: temperature,
      maxTokens: maxTokens,
      thinkingMode: thinkingMode,
      tools: executor.tools,
      toolChoice: AIToolChoice.auto,
    );

    final runner = AgentRunner(
      provider: provider,
      executor: executor,
      maxIterations: maxIterations,
    );

    await for (final event in runner.run(request)) {
      if (event is AIReasoningDelta) {
        yield {'type': 'reasoning', 'content': event.text};
      } else if (event is AIAnswerDelta) {
        yield {'type': 'answer', 'content': event.text};
      } else if (event is AIToolCallsComplete) {
        for (final call in event.calls) {
          yield {
            'type': 'tool_call',
            'name': call.name,
            'arguments': call.argumentsJson,
          };
        }
      } else if (event is AIToolResultEvent) {
        yield {
          'type': 'tool_result',
          'name': event.result.name,
          'isError': event.result.isError,
        };
      }
    }
  }

  AIStreamingProvider _createProvider(ActivePlatformConfig config) {
    final chatProfile = ChatCompletionsProfiles.forType(config.apiType);
    if (chatProfile != null) {
      return ChatCompletionsToolProvider(profile: chatProfile);
    }

    final responsesProfile = ResponsesToolProfiles.forType(config.apiType);
    if (responsesProfile != null) {
      return ResponsesToolProvider(profile: responsesProfile);
    }

    if (config.apiType == 'claude') {
      return ClaudeToolProvider();
    }
    if (config.apiType == 'gemini') {
      return GeminiToolProvider();
    }

    throw AIError(
      type: AIErrorType.unsupported,
      message: 'Platform ${config.apiType} does not support tools',
    );
  }
}
