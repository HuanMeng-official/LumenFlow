import 'ai_message.dart';
import 'ai_tool.dart';
import 'cancellation_token.dart';

enum AIToolChoice { auto, none, required }

class AIRequest {
  final String model;
  final String endpoint;
  final String apiKey;
  final List<AIMessage> messages;
  final double temperature;
  final int maxTokens;
  final bool thinkingMode;
  final List<AIToolDefinition> tools;
  final AIToolChoice toolChoice;
  final Map<String, String> headers;
  final CancellationToken? cancellationToken;

  const AIRequest({
    required this.model,
    required this.endpoint,
    required this.apiKey,
    required this.messages,
    this.temperature = 0.7,
    this.maxTokens = 8192,
    this.thinkingMode = false,
    this.tools = const [],
    this.toolChoice = AIToolChoice.auto,
    this.headers = const {},
    this.cancellationToken,
  });

  AIRequest copyWith({
    String? model,
    String? endpoint,
    String? apiKey,
    List<AIMessage>? messages,
    double? temperature,
    int? maxTokens,
    bool? thinkingMode,
    List<AIToolDefinition>? tools,
    AIToolChoice? toolChoice,
    Map<String, String>? headers,
    CancellationToken? cancellationToken,
  }) {
    return AIRequest(
      model: model ?? this.model,
      endpoint: endpoint ?? this.endpoint,
      apiKey: apiKey ?? this.apiKey,
      messages: messages ?? this.messages,
      temperature: temperature ?? this.temperature,
      maxTokens: maxTokens ?? this.maxTokens,
      thinkingMode: thinkingMode ?? this.thinkingMode,
      tools: tools ?? this.tools,
      toolChoice: toolChoice ?? this.toolChoice,
      headers: headers ?? this.headers,
      cancellationToken: cancellationToken ?? this.cancellationToken,
    );
  }
}
