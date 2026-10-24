import 'dart:async';
import 'dart:convert';
import 'dart:io';

import 'package:http/http.dart' as http;

import '../contracts/ai_error.dart';
import '../contracts/ai_message.dart';
import '../contracts/ai_request.dart';
import '../contracts/ai_stream_event.dart';
import '../contracts/ai_tool.dart';
import '../contracts/cancellation_token.dart';
import '../transport/sse_decoder.dart';
import 'chat_completions_tool_provider.dart' show AIStreamingProvider;

/// Per-platform differences for the OpenAI Responses protocol.
class ResponsesToolProfile {
  const ResponsesToolProfile({
    required this.id,
    required this.useInstructions,
    this.reasoningBuilder,
    this.extraHeaders = const {},
  });

  final String id;

  /// OpenAI/OpenRouter/LM Studio use top-level `instructions`.
  /// Grok expects system messages inside `input` instead.
  final bool useInstructions;

  final Map<String, dynamic> Function(AIRequest request)? reasoningBuilder;
  final Map<String, String> extraHeaders;

  Map<String, dynamic> reasoning(AIRequest request) {
    return reasoningBuilder?.call(request) ?? const {};
  }
}

class ResponsesToolProfiles {
  static final ResponsesToolProfile openai = ResponsesToolProfile(
    id: 'openai',
    useInstructions: true,
    reasoningBuilder: (request) => request.thinkingMode
        ? const {'effort': 'medium', 'summary': 'auto'}
        : const {},
  );

  static final ResponsesToolProfile grok = ResponsesToolProfile(
    id: 'grok',
    // Grok accepts system/user/assistant in any order inside `input`.
    useInstructions: false,
  );

  static final ResponsesToolProfile openrouter = ResponsesToolProfile(
    id: 'openrouter',
    useInstructions: true,
    reasoningBuilder: (request) => request.thinkingMode
        ? const {'effort': 'medium', 'summary': 'auto', 'enabled': true}
        : const {},
  );

  static final ResponsesToolProfile lmstudio = ResponsesToolProfile(
    id: 'lmstudio',
    useInstructions: true,
    reasoningBuilder: (request) => request.thinkingMode
        ? const {'effort': 'medium', 'summary': 'auto'}
        : const {},
  );

  static ResponsesToolProfile? forType(String type) {
    switch (type) {
      case 'openai':
        return openai;
      case 'grok':
        return grok;
      case 'openrouter':
        return openrouter;
      case 'lmstudio':
        return lmstudio;
      default:
        return null;
    }
  }

  static bool supports(String type) => forType(type) != null;
}

class _ToolCallBuilder {
  String? id;
  String? itemId;
  String name = '';
  final StringBuffer arguments = StringBuffer();

  void setArguments(String value) {
    arguments.clear();
    arguments.write(value);
  }
}

/// Streams a Responses API request with function tools.
class ResponsesToolProvider implements AIStreamingProvider {
  ResponsesToolProvider({
    required this.profile,
    http.Client Function()? clientFactory,
    this.connectionTimeout = const Duration(seconds: 30),
    this.streamingTimeout = const Duration(minutes: 5),
    this.retryBaseDelay = const Duration(seconds: 1),
    this.maxRetries = 3,
  }) : _clientFactory = clientFactory ?? http.Client.new;

  final ResponsesToolProfile profile;
  final http.Client Function() _clientFactory;
  final Duration connectionTimeout;
  final Duration streamingTimeout;
  final Duration retryBaseDelay;
  final int maxRetries;

  @override
  Stream<AIStreamEvent> stream(AIRequest request) async* {
    request.cancellationToken?.throwIfCancelled();

    final client = _clientFactory();
    final builders = <Object, _ToolCallBuilder>{};
    final decoder = SseDecoder();
    final answer = StringBuffer();
    final reasoning = StringBuffer();
    var sawTerminal = false;

    try {
      final response = await _sendWithRetry(client, request);
      final contentType =
          (response.headers['content-type'] ??
                  response.headers['Content-Type'] ??
                  '')
              .toLowerCase();

      if (contentType.contains('application/json')) {
        final body = await response.stream
            .bytesToString()
            .timeout(streamingTimeout);
        yield* _parseNonStreamingBody(body);
        return;
      }

      if (contentType.isNotEmpty &&
          !contentType.contains('text/event-stream')) {
        throw AIError(
          type: AIErrorType.invalidResponse,
          message: 'Unexpected response content type: $contentType',
        );
      }

      final iterator = StreamIterator<String>(
        response.stream.timeout(streamingTimeout).transform(utf8.decoder),
      );

      try {
        while (true) {
          final hasNext = await _nextOrCancel(
            iterator,
            request.cancellationToken,
          );
          if (!hasNext) break;

          for (final event in decoder.add(iterator.current)) {
            final data = event.data.trim();
            if (data.isEmpty) continue;

            if (data == '[DONE]') {
              sawTerminal = true;
              yield* _emitToolCalls(builders);
              return;
            }

            final parsed = _parseEvent(
              data,
              event.event,
              builders,
              answer,
              reasoning,
            );
            for (final parsedEvent in parsed.events) {
              yield parsedEvent;
            }
            if (parsed.terminal) {
              sawTerminal = true;
              yield* _emitToolCalls(builders);
              return;
            }
          }
        }

        for (final event in decoder.flush()) {
          final data = event.data.trim();
          if (data.isEmpty) continue;

          if (data == '[DONE]') {
            sawTerminal = true;
            continue;
          }

          final parsed = _parseEvent(
            data,
            event.event,
            builders,
            answer,
            reasoning,
          );
          for (final parsedEvent in parsed.events) {
            yield parsedEvent;
          }
          if (parsed.terminal) {
            sawTerminal = true;
          }
        }

        if (!sawTerminal) {
          throw const AIError(
            type: AIErrorType.invalidResponse,
            message: 'Stream ended before completion',
          );
        }

        yield* _emitToolCalls(builders);
      } finally {
        await iterator.cancel();
      }
    } on AIError {
      rethrow;
    } on TimeoutException catch (error) {
      throw AIError(
        type: AIErrorType.timeout,
        message: error.message ?? 'Streaming timed out',
        cause: error,
      );
    } on SocketException catch (error) {
      throw AIError(
        type: AIErrorType.network,
        message: error.message,
        cause: error,
      );
    } on http.ClientException catch (error) {
      throw AIError(
        type: AIErrorType.network,
        message: error.message,
        cause: error,
      );
    } on FormatException catch (error) {
      throw AIError(
        type: AIErrorType.invalidResponse,
        message: error.message,
        cause: error,
      );
    } catch (error) {
      throw AIError(
        type: AIErrorType.invalidResponse,
        message: error.toString(),
        cause: error,
      );
    } finally {
      client.close();
    }
  }

  ({List<AIStreamEvent> events, bool terminal}) _parseEvent(
    String data,
    String? eventName,
    Map<Object, _ToolCallBuilder> builders,
    StringBuffer answer,
    StringBuffer reasoning,
  ) {
    dynamic json;
    try {
      json = jsonDecode(data);
    } catch (_) {
      return (events: const [], terminal: false);
    }
    if (json is! Map) {
      return (events: const [], terminal: false);
    }

    final map = json.cast<String, dynamic>();
    final type = map['type']?.toString() ?? eventName;

    if (type == 'error') {
      throw _errorFromPayload(map['error'] ?? map);
    }

    switch (type) {
      case 'response.output_text.delta':
        return _appendDelta(map['delta'], answer, reasoning: false);
      case 'response.output_text.done':
        return (
          events: _reconcile(map['text'], answer, reasoning: false),
          terminal: false,
        );
      case 'response.reasoning_text.delta':
      case 'response.reasoning_summary_text.delta':
        return _appendDelta(map['delta'], reasoning, reasoning: true);
      case 'response.reasoning_text.done':
      case 'response.reasoning_summary_text.done':
        return (
          events: _reconcile(map['text'], reasoning, reasoning: true),
          terminal: false,
        );
      case 'response.content_part.delta':
        final part = map['part'];
        if (part is Map && part['type'] == 'output_text') {
          return _appendDelta(map['delta'], answer, reasoning: false);
        }
        return (events: const [], terminal: false);
      case 'response.output_item.added':
      case 'response.output_item.done':
        final item = map['item'];
        if (item is Map) {
          _handleOutputItem(map, item.cast<String, dynamic>(), builders);
        }
        return (events: const [], terminal: false);
      case 'response.function_call_arguments.delta':
        final key = map['output_index'] ?? map['item_id'];
        if (key == null) return (events: const [], terminal: false);
        final builder = builders.putIfAbsent(key, _ToolCallBuilder.new);
        final delta = map['delta'];
        if (delta is String) {
          builder.arguments.write(delta);
        }
        return (events: const [], terminal: false);
      case 'response.function_call_arguments.done':
        final key = map['output_index'] ?? map['item_id'];
        if (key == null) return (events: const [], terminal: false);
        final builder = builders.putIfAbsent(key, _ToolCallBuilder.new);
        final arguments = map['arguments'];
        if (arguments is String) {
          builder.setArguments(arguments);
        }
        return (events: const [], terminal: false);
      case 'response.completed':
      case 'response.done':
      case 'response.incomplete':
        final events = _collectCompletedResponse(
          map['response'] ?? map,
          builders,
          answer,
          reasoning,
        );
        return (events: events, terminal: true);
      case 'response.failed':
        final response = map['response'];
        final error = response is Map
            ? response['error'] ?? response
            : map['error'] ?? map;
        throw _errorFromPayload(error);
      default:
        return (events: const [], terminal: false);
    }
  }

  void _handleOutputItem(
    Map<String, dynamic> event,
    Map<String, dynamic> item,
    Map<Object, _ToolCallBuilder> builders,
  ) {
    if (item['type'] != 'function_call') return;

    final key =
        event['output_index'] ?? item['id'] ?? item['call_id'] ?? builders.length;
    final builder = builders.putIfAbsent(key, _ToolCallBuilder.new);

    final id = item['call_id'] ?? item['id'];
    if (id is String && id.isNotEmpty) {
      builder.id = id;
    }
    final itemId = item['id'];
    if (itemId is String && itemId.isNotEmpty) {
      builder.itemId = itemId;
    }
    final name = item['name'];
    if (name is String && name.isNotEmpty) {
      builder.name = name;
    }
    final arguments = item['arguments'];
    if (arguments is String && arguments.isNotEmpty) {
      builder.setArguments(arguments);
    }
  }

  List<AIStreamEvent> _collectCompletedResponse(
    dynamic rawResponse,
    Map<Object, _ToolCallBuilder> builders,
    StringBuffer answer,
    StringBuffer reasoning,
  ) {
    if (rawResponse is! Map) return const [];
    final response = rawResponse.cast<String, dynamic>();
    final output = response['output'];
    if (output is! List) {
      final outputText = response['output_text'];
      if (outputText is String && outputText.isNotEmpty) {
        return _reconcile(outputText, answer, reasoning: false);
      }
      return const [];
    }

    final completedAnswer = StringBuffer();
    final completedReasoning = StringBuffer();

    for (var index = 0; index < output.length; index++) {
      final rawItem = output[index];
      if (rawItem is! Map) continue;
      final item = rawItem.cast<String, dynamic>();

      switch (item['type']) {
        case 'function_call':
          _handleOutputItem(
            {'output_index': index},
            item,
            builders,
          );
        case 'message':
          _collectMessageParts(item, completedAnswer, completedReasoning);
        case 'reasoning':
          _collectReasoningParts(item, completedReasoning);
      }
    }

    if (completedAnswer.isEmpty) {
      final outputText = response['output_text'];
      if (outputText is String && outputText.isNotEmpty) {
        completedAnswer.write(outputText);
      }
    }

    final events = <AIStreamEvent>[];
    events.addAll(
      _reconcile(
        completedReasoning.toString(),
        reasoning,
        reasoning: true,
      ),
    );
    events.addAll(
      _reconcile(
        completedAnswer.toString(),
        answer,
        reasoning: false,
      ),
    );
    return events;
  }

  void _collectMessageParts(
    Map<String, dynamic> item,
    StringBuffer answer,
    StringBuffer reasoning,
  ) {
    final content = item['content'];
    if (content is! List) return;

    for (final raw in content) {
      if (raw is! Map) continue;
      final part = raw.cast<String, dynamic>();
      final text = part['text'];
      if (text is! String || text.isEmpty) continue;
      if (part['type'] == 'output_text' || part['type'] == 'text') {
        answer.write(text);
      }
    }
  }

  void _collectReasoningParts(
    Map<String, dynamic> item,
    StringBuffer reasoning,
  ) {
    final summary = item['summary'];
    if (summary is List) {
      for (final raw in summary) {
        if (raw is! Map) continue;
        final text = raw['text'];
        if (text is String && text.isNotEmpty) {
          reasoning.write(text);
        }
      }
    }

    final content = item['content'];
    if (content is List) {
      for (final raw in content) {
        if (raw is! Map) continue;
        final text = raw['text'];
        if (text is String && text.isNotEmpty) {
          reasoning.write(text);
        }
      }
    }
  }

  ({List<AIStreamEvent> events, bool terminal}) _appendDelta(
    dynamic raw,
    StringBuffer buffer, {
    required bool reasoning,
  }) {
    if (raw is! String || raw.isEmpty) {
      return (events: const [], terminal: false);
    }

    buffer.write(raw);
    return (
      events: [
        reasoning ? AIReasoningDelta(raw) : AIAnswerDelta(raw),
      ],
      terminal: false,
    );
  }

  List<AIStreamEvent> _reconcile(
    dynamic raw,
    StringBuffer buffer, {
    required bool reasoning,
  }) {
    if (raw is! String || raw.isEmpty) return const [];

    final current = buffer.toString();
    if (raw == current) return const [];

    if (raw.startsWith(current)) {
      final remaining = raw.substring(current.length);
      if (remaining.isEmpty) return const [];
      buffer.write(remaining);
      return [
        reasoning ? AIReasoningDelta(remaining) : AIAnswerDelta(remaining),
      ];
    }

    if (current.isEmpty) {
      buffer.write(raw);
      return [reasoning ? AIReasoningDelta(raw) : AIAnswerDelta(raw)];
    }

    return const [];
  }

  Stream<AIStreamEvent> _parseNonStreamingBody(String body) async* {
    dynamic json;
    try {
      json = jsonDecode(body);
    } catch (error) {
      throw AIError(
        type: AIErrorType.invalidResponse,
        message: 'Invalid JSON response',
        cause: error,
      );
    }

    if (json is! Map) {
      throw const AIError(
        type: AIErrorType.invalidResponse,
        message: 'Invalid JSON response',
      );
    }

    final map = json.cast<String, dynamic>();
    final error = map['error'];
    if (error != null) {
      throw _errorFromPayload(error);
    }

    final output = map['output'];
    if (output is! List) {
      throw const AIError(
        type: AIErrorType.invalidResponse,
        message: 'Response contains no output',
      );
    }

    final builders = <Object, _ToolCallBuilder>{};
    final answer = StringBuffer();
    final reasoning = StringBuffer();

    for (var index = 0; index < output.length; index++) {
      final rawItem = output[index];
      if (rawItem is! Map) continue;
      final item = rawItem.cast<String, dynamic>();

      switch (item['type']) {
        case 'function_call':
          _handleOutputItem({'output_index': index}, item, builders);
        case 'message':
          _collectMessageParts(item, answer, reasoning);
        case 'reasoning':
          _collectReasoningParts(item, reasoning);
      }
    }

    final outputText = map['output_text'];
    if (outputText is String &&
        outputText.isNotEmpty &&
        answer.isEmpty) {
      answer.write(outputText);
    }

    if (reasoning.isNotEmpty) {
      yield AIReasoningDelta(reasoning.toString());
    }
    if (answer.isNotEmpty) {
      yield AIAnswerDelta(answer.toString());
    }
    yield* _emitToolCalls(builders);
  }

  Stream<AIStreamEvent> _emitToolCalls(
    Map<Object, _ToolCallBuilder> builders,
  ) async* {
    final calls = <AIToolCall>[];
    var index = 0;

    for (final builder in builders.values) {
      if (builder.name.isEmpty) continue;

      final argumentsJson = builder.arguments.toString();
      if (argumentsJson.trim().isNotEmpty) {
        try {
          final decoded = jsonDecode(argumentsJson);
          if (decoded is! Map) {
            throw const FormatException('arguments must be an object');
          }
        } catch (error) {
          throw AIError(
            type: AIErrorType.invalidResponse,
            message: 'Invalid tool call arguments for ${builder.name}',
            cause: error,
          );
        }
      }

      calls.add(
        AIToolCall(
          id: builder.id ?? 'call_$index',
          name: builder.name,
          argumentsJson: argumentsJson,
          providerItemId: builder.itemId,
        ),
      );
      index++;
    }

    if (calls.isNotEmpty) {
      yield AIToolCallsComplete(calls);
    }
  }

  AIError _errorFromPayload(dynamic error) {
    if (error is Map) {
      final message = error['message']?.toString() ?? 'Provider error';
      final code = error['code'];
      final type = error['type']?.toString() ?? '';
      final numericCode = code is num ? code.toInt() : null;

      final AIErrorType errorType;
      if (numericCode == 401 ||
          numericCode == 403 ||
          type.contains('authentication')) {
        errorType = AIErrorType.authentication;
      } else if (numericCode == 429 || type.contains('rate_limit')) {
        errorType = AIErrorType.rateLimit;
      } else if ((numericCode != null && numericCode >= 500) ||
          type.contains('server')) {
        errorType = AIErrorType.server;
      } else {
        errorType = AIErrorType.invalidResponse;
      }

      return AIError(
        type: errorType,
        message: message,
        statusCode: numericCode,
      );
    }

    return AIError(
      type: AIErrorType.invalidResponse,
      message: error.toString(),
    );
  }

  Future<bool> _nextOrCancel(
    StreamIterator<String> iterator,
    CancellationToken? token,
  ) {
    final next = iterator.moveNext();
    if (token == null) return next;

    token.throwIfCancelled();
    return Future.any<bool>([
      next,
      token.whenCancelled.then<bool>((_) {
        throw const AIError(
          type: AIErrorType.cancelled,
          message: 'Request cancelled',
        );
      }),
    ]);
  }

  Future<http.StreamedResponse> _sendWithRetry(
    http.Client client,
    AIRequest request,
  ) async {
    Object? lastError;

    for (var attempt = 0; attempt <= maxRetries; attempt++) {
      request.cancellationToken?.throwIfCancelled();

      try {
        final response = await client
            .send(_buildRequest(request))
            .timeout(connectionTimeout);

        if (response.statusCode == 200) {
          return response;
        }

        final body = await response.stream
            .transform(utf8.decoder)
            .join()
            .timeout(connectionTimeout);
        final error = _errorFromResponse(response.statusCode, body);

        if (!error.isRetryable || attempt == maxRetries) {
          throw error;
        }
        lastError = error;
      } on AIError catch (error) {
        if (!error.isRetryable || attempt == maxRetries) rethrow;
        lastError = error;
      } on TimeoutException catch (error) {
        lastError = AIError(
          type: AIErrorType.timeout,
          message: 'Connection timed out',
          cause: error,
        );
      } on SocketException catch (error) {
        lastError = AIError(
          type: AIErrorType.network,
          message: error.message,
          cause: error,
        );
      } on http.ClientException catch (error) {
        lastError = AIError(
          type: AIErrorType.network,
          message: error.message,
          cause: error,
        );
      } on FormatException catch (error) {
        throw AIError(
          type: AIErrorType.invalidResponse,
          message: error.message,
          cause: error,
        );
      } on TypeError catch (error) {
        throw AIError(
          type: AIErrorType.invalidResponse,
          message: error.toString(),
          cause: error,
        );
      } catch (error) {
        lastError = AIError(
          type: AIErrorType.network,
          message: error.toString(),
          cause: error,
        );
      }

      if (attempt < maxRetries && retryBaseDelay > Duration.zero) {
        final delay = retryBaseDelay * (1 << attempt);
        final token = request.cancellationToken;
        if (token == null) {
          await Future<void>.delayed(delay);
        } else {
          token.throwIfCancelled();
          await Future.any<void>([
            Future<void>.delayed(delay),
            token.whenCancelled.then<void>((_) {
              throw const AIError(
                type: AIErrorType.cancelled,
                message: 'Request cancelled',
              );
            }),
          ]);
        }
      }
    }

    final error = lastError;
    if (error is AIError) throw error;
    throw AIError(
      type: AIErrorType.network,
      message: error?.toString() ?? 'Request failed',
    );
  }

  http.Request _buildRequest(AIRequest request) {
    final httpRequest = http.Request('POST', _resolveUrl(request.endpoint));

    httpRequest.headers['Content-Type'] = 'application/json';
    httpRequest.headers['Accept'] = 'text/event-stream, application/json';
    if (request.apiKey.isNotEmpty) {
      httpRequest.headers['Authorization'] = 'Bearer ${request.apiKey}';
    }
    httpRequest.headers.addAll(profile.extraHeaders);
    httpRequest.headers.addAll(request.headers);

    final input = _buildInput(request);
    final body = <String, dynamic>{
      'model': request.model,
      'input': input.items,
      'temperature': request.temperature,
      'max_output_tokens': request.maxTokens,
      'stream': true,
      if (input.instructions.isNotEmpty) 'instructions': input.instructions,
      if (request.tools.isNotEmpty) 'tools': _buildTools(request.tools),
      if (request.tools.isNotEmpty)
        'tool_choice': _toolChoice(request.toolChoice),
    };

    final reasoning = profile.reasoning(request);
    if (reasoning.isNotEmpty) {
      body['reasoning'] = reasoning;
    }

    httpRequest.body = jsonEncode(body);
    return httpRequest;
  }

  ({List<Map<String, dynamic>> items, String instructions}) _buildInput(
    AIRequest request,
  ) {
    final items = <Map<String, dynamic>>[];
    final instructions = StringBuffer();

    for (final message in request.messages) {
      switch (message.role) {
        case AIMessageRole.system:
          if (profile.useInstructions) {
            if (instructions.isNotEmpty) {
              instructions.write('\n\n');
            }
            instructions.write(message.content);
          } else {
            items.add({'role': 'system', 'content': message.content});
          }
        case AIMessageRole.user:
          items.add({'role': 'user', 'content': message.content});
        case AIMessageRole.assistant:
          if (message.content.trim().isNotEmpty) {
            items.add({'role': 'assistant', 'content': message.content});
          }
          for (final call in message.toolCalls) {
            items.add({
              'type': 'function_call',
              if (call.providerItemId != null) 'id': call.providerItemId,
              'call_id': call.id,
              'name': call.name,
              'arguments': call.argumentsJson,
            });
          }
        case AIMessageRole.tool:
          items.add({
            'type': 'function_call_output',
            'call_id': message.toolCallId ?? '',
            'output': message.content,
          });
      }
    }

    return (items: items, instructions: instructions.toString());
  }

  List<Map<String, dynamic>> _buildTools(List<AIToolDefinition> tools) {
    return tools
        .map(
          (tool) => {
            'type': 'function',
            'name': tool.name,
            'description': tool.description,
            'parameters': tool.inputSchema,
          },
        )
        .toList();
  }

  String _toolChoice(AIToolChoice choice) {
    switch (choice) {
      case AIToolChoice.auto:
        return 'auto';
      case AIToolChoice.none:
        return 'none';
      case AIToolChoice.required:
        return 'required';
    }
  }

  Uri _resolveUrl(String endpoint) {
    final raw = endpoint.trim();
    if (raw.isEmpty) {
      throw const AIError(
        type: AIErrorType.unsupported,
        message: 'API endpoint is empty',
      );
    }

    final uri = Uri.tryParse(raw);
    if (uri == null || !uri.hasScheme) {
      throw const AIError(
        type: AIErrorType.invalidResponse,
        message: 'Invalid API endpoint',
      );
    }

    var path = uri.path;
    if (path.endsWith('/')) {
      path = path.substring(0, path.length - 1);
    }
    if (!path.endsWith('/responses')) {
      path = '$path/responses';
    }

    return uri.replace(path: path);
  }

  AIError _errorFromResponse(int statusCode, String body) {
    var message = body.trim();

    try {
      final json = jsonDecode(body);
      if (json is Map) {
        final error = json['error'];
        if (error is Map && error['message'] != null) {
          message = error['message'].toString();
        } else if (json['message'] != null) {
          message = json['message'].toString();
        } else if (error != null) {
          message = error.toString();
        }
      }
    } catch (_) {
      // Keep the raw body as the message.
    }

    if (message.isEmpty) {
      message = 'HTTP $statusCode';
    }

    AIErrorType type;
    if (statusCode == 401 || statusCode == 403) {
      type = AIErrorType.authentication;
    } else if (statusCode == 429) {
      type = AIErrorType.rateLimit;
    } else if (statusCode >= 500) {
      type = AIErrorType.server;
    } else {
      type = AIErrorType.invalidResponse;
    }

    return AIError(type: type, message: message, statusCode: statusCode);
  }
}
