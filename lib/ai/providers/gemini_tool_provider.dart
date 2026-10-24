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

class _ToolCallBuilder {
  String? id;
  String name = '';
  final StringBuffer arguments = StringBuffer();
}

/// Streams a Gemini Interactions request with client tools.
///
/// Tool loops use server-side interaction state: after a function call we send
/// only the matching `function_result` steps plus `previous_interaction_id`.
class GeminiToolProvider implements AIStreamingProvider {
  GeminiToolProvider({
    http.Client Function()? clientFactory,
    this.connectionTimeout = const Duration(seconds: 30),
    this.streamingTimeout = const Duration(minutes: 5),
    this.retryBaseDelay = const Duration(seconds: 1),
    this.maxRetries = 3,
  }) : _clientFactory = clientFactory ?? http.Client.new;

  final http.Client Function() _clientFactory;
  final Duration connectionTimeout;
  final Duration streamingTimeout;
  final Duration retryBaseDelay;
  final int maxRetries;

  String? _previousInteractionId;
  final Set<String> _sentToolResultIds = {};

  @override
  Stream<AIStreamEvent> stream(AIRequest request) async* {
    request.cancellationToken?.throwIfCancelled();

    final client = _clientFactory();
    final decoder = SseDecoder();
    final stepTypes = <int, String>{};
    final builders = <int, _ToolCallBuilder>{};
    final answer = StringBuffer();
    final reasoning = StringBuffer();
    var sawEvent = false;

    try {
      final response = await _sendWithRetry(client, request);
      _markToolResultsSent(request.messages);
      final contentType =
          (response.headers['content-type'] ??
                  response.headers['Content-Type'] ??
                  '')
              .toLowerCase();

      if (contentType.contains('application/json')) {
        final body = await response.stream.bytesToString().timeout(
          streamingTimeout,
        );
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
              yield* _emitToolCalls(builders);
              return;
            }

            sawEvent = true;
            final parsed = _parseEvent(
              data,
              event.event,
              stepTypes,
              builders,
              answer,
              reasoning,
            );
            for (final parsedEvent in parsed.events) {
              yield parsedEvent;
            }
            if (parsed.terminal) {
              yield* _emitToolCalls(builders);
              return;
            }
          }
        }

        for (final event in decoder.flush()) {
          final data = event.data.trim();
          if (data.isEmpty || data == '[DONE]') continue;
          sawEvent = true;
          final parsed = _parseEvent(
            data,
            event.event,
            stepTypes,
            builders,
            answer,
            reasoning,
          );
          for (final parsedEvent in parsed.events) {
            yield parsedEvent;
          }
          if (parsed.terminal) {
            yield* _emitToolCalls(builders);
            return;
          }
        }

        if (!sawEvent) {
          throw const AIError(
            type: AIErrorType.invalidResponse,
            message: 'Stream ended before any event was received',
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
    Map<int, String> stepTypes,
    Map<int, _ToolCallBuilder> builders,
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
    final type =
        map['type']?.toString() ?? map['event_type']?.toString() ?? eventName;
    final events = <AIStreamEvent>[];

    if (type == 'error' || type == 'interaction.failed') {
      final interaction = map['interaction'];
      final error = interaction is Map
          ? interaction['error'] ?? interaction
          : map['error'] ?? map;
      throw _errorFromPayload(error);
    }

    final interaction = map['interaction'];
    if (interaction is Map) {
      final id = interaction['id'];
      if (id is String && id.isNotEmpty) {
        _previousInteractionId = id;
      }
    }
    final interactionId = map['interaction_id'];
    if (interactionId is String && interactionId.isNotEmpty) {
      _previousInteractionId = interactionId;
    }

    if (type == 'interaction.status_update') {
      final status = map['status']?.toString() ?? '';
      if (status == 'failed') {
        throw const AIError(
          type: AIErrorType.invalidResponse,
          message: 'Gemini interaction failed',
        );
      }
      if (status == 'cancelled') {
        throw const AIError(
          type: AIErrorType.cancelled,
          message: 'Gemini interaction cancelled',
        );
      }
      // Keep reading until interaction.completed so we can capture the
      // interaction id even when requires_action is reported early.
      return (events: const [], terminal: false);
    }

    switch (type) {
      case 'step.start':
        final index = (map['index'] as num?)?.toInt() ?? 0;
        final step = map['step'];
        if (step is Map) {
          final stepMap = step.cast<String, dynamic>();
          final stepType = stepMap['type']?.toString() ?? '';
          stepTypes[index] = stepType;
          if (stepType == 'function_call') {
            final builder = builders.putIfAbsent(index, _ToolCallBuilder.new);
            final id = stepMap['id'];
            if (id is String && id.isNotEmpty) builder.id = id;
            final name = stepMap['name'];
            if (name is String && name.isNotEmpty) builder.name = name;
            final arguments = stepMap['arguments'];
            if (arguments is Map && arguments.isNotEmpty) {
              builder.arguments.write(jsonEncode(arguments));
            } else if (arguments is String && arguments.isNotEmpty) {
              builder.arguments.write(arguments);
            }
          } else if (stepType == 'model_output') {
            for (final text in _extractTexts(stepMap['content'])) {
              answer.write(text);
              events.add(AIAnswerDelta(text));
            }
          } else if (stepType == 'thought') {
            for (final text in _extractTexts(stepMap['summary'])) {
              reasoning.write(text);
              events.add(AIReasoningDelta(text));
            }
          }
        }
        return (events: events, terminal: false);

      case 'step.delta':
        final index = (map['index'] as num?)?.toInt() ?? 0;
        final delta = map['delta'];
        if (delta is! Map) {
          return (events: const [], terminal: false);
        }
        final deltaMap = delta.cast<String, dynamic>();
        final deltaType = deltaMap['type']?.toString() ?? '';
        final stepType = stepTypes[index] ?? 'model_output';

        if (deltaType == 'arguments' || deltaType == 'arguments_delta') {
          final partial =
              deltaMap['partial_arguments'] ?? deltaMap['arguments'];
          if (partial is String) {
            builders
                .putIfAbsent(index, _ToolCallBuilder.new)
                .arguments
                .write(partial);
          }
        } else if (deltaType == 'thought_summary' || deltaType == 'thought') {
          final texts = _extractTexts(deltaMap['content']).toList();
          final text = deltaMap['text'];
          if (texts.isEmpty && text is String && text.isNotEmpty) {
            texts.add(text);
          }
          for (final thought in texts) {
            reasoning.write(thought);
            events.add(AIReasoningDelta(thought));
          }
        } else if (deltaType == 'text') {
          final text = deltaMap['text'];
          if (text is String && text.isNotEmpty) {
            if (stepType == 'thought') {
              reasoning.write(text);
              events.add(AIReasoningDelta(text));
            } else {
              answer.write(text);
              events.add(AIAnswerDelta(text));
            }
          }
        }
        return (events: events, terminal: false);

      case 'step.stop':
        final index = (map['index'] as num?)?.toInt() ?? 0;
        final builder = builders[index];
        if (builder != null) {
          final arguments = builder.arguments.toString();
          if (arguments.trim().isNotEmpty) {
            try {
              final decoded = jsonDecode(arguments);
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
        }
        return (events: const [], terminal: false);

      case 'interaction.requires_action':
        return (events: const [], terminal: true);

      case 'interaction.completed':
        final completed = map['interaction'];
        final status = completed is Map
            ? completed['status']?.toString() ?? ''
            : '';
        if (status == 'failed') {
          throw const AIError(
            type: AIErrorType.invalidResponse,
            message: 'Gemini interaction failed',
          );
        }
        if (status == 'cancelled') {
          throw const AIError(
            type: AIErrorType.cancelled,
            message: 'Gemini interaction cancelled',
          );
        }
        return (events: const [], terminal: true);

      default:
        return (events: const [], terminal: false);
    }
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

    final id = map['id'];
    if (id is String && id.isNotEmpty) {
      _previousInteractionId = id;
    }

    final steps = map['steps'];
    if (steps is! List) {
      throw const AIError(
        type: AIErrorType.invalidResponse,
        message: 'Response contains no steps',
      );
    }

    final answer = StringBuffer();
    final reasoning = StringBuffer();
    final calls = <AIToolCall>[];

    for (final rawStep in steps) {
      if (rawStep is! Map) continue;
      final step = rawStep.cast<String, dynamic>();

      switch (step['type']) {
        case 'thought':
          _collectThought(step, reasoning);
        case 'model_output':
          _collectModelOutput(step, answer);
        case 'function_call':
          final name = step['name']?.toString() ?? '';
          if (name.isEmpty) continue;
          final args = step['arguments'];
          calls.add(
            AIToolCall(
              id: step['id']?.toString() ?? 'gemini_call_${calls.length}',
              name: name,
              argumentsJson: args is Map
                  ? jsonEncode(args)
                  : args is String
                  ? args
                  : '{}',
            ),
          );
      }
    }

    if (reasoning.isNotEmpty) {
      yield AIReasoningDelta(reasoning.toString());
    }
    if (answer.isNotEmpty) {
      yield AIAnswerDelta(answer.toString());
    }
    if (calls.isNotEmpty) {
      yield AIToolCallsComplete(calls);
    }
  }

  Iterable<String> _extractTexts(dynamic raw) sync* {
    if (raw == null) return;
    final items = raw is List ? raw : [raw];
    for (final item in items) {
      if (item is! Map) continue;
      final text = item['text'];
      if (text is String && text.isNotEmpty) yield text;
    }
  }

  void _collectThought(Map<String, dynamic> step, StringBuffer buffer) {
    for (final text in _extractTexts(step['summary'])) {
      buffer.write(text);
    }
  }

  void _collectModelOutput(Map<String, dynamic> step, StringBuffer buffer) {
    for (final text in _extractTexts(step['content'])) {
      buffer.write(text);
    }
  }

  Stream<AIStreamEvent> _emitToolCalls(
    Map<int, _ToolCallBuilder> builders,
  ) async* {
    final calls = <AIToolCall>[];
    final indexes = builders.keys.toList()..sort();

    for (final index in indexes) {
      final builder = builders[index]!;
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
          id: builder.id ?? 'gemini_call_$index',
          name: builder.name,
          argumentsJson: argumentsJson,
        ),
      );
    }

    if (calls.isNotEmpty) {
      yield AIToolCallsComplete(calls);
    }
  }

  http.Request _buildRequest(AIRequest request) {
    final httpRequest = http.Request('POST', _resolveUrl(request.endpoint));

    httpRequest.headers['Content-Type'] = 'application/json';
    httpRequest.headers['Accept'] = 'text/event-stream, application/json';
    if (request.apiKey.isNotEmpty) {
      httpRequest.headers['x-goog-api-key'] = request.apiKey;
    }
    httpRequest.headers.addAll(request.headers);

    final built = _buildInput(request);
    final body = <String, dynamic>{
      'model': _normalizeModel(request.model),
      'input': built.input,
      'stream': true,
      'store': true,
      if (built.system.isNotEmpty) 'system_instruction': built.system,
      'generation_config': {
        'max_output_tokens': _effectiveMaxTokens(request.maxTokens),
        'thinking_level': request.thinkingMode ? 'high' : 'low',
        'thinking_summaries': request.thinkingMode ? 'auto' : 'none',
        if (_supportsSamplingParams(request.model))
          'temperature': request.temperature,
        if (request.tools.isNotEmpty)
          'tool_choice': _toolChoice(request.toolChoice),
      },
      if (request.tools.isNotEmpty)
        'tools': request.tools
            .map(
              (tool) => {
                'type': 'function',
                'name': tool.name,
                'description': tool.description,
                'parameters': tool.inputSchema,
              },
            )
            .toList(),
      if (_previousInteractionId != null)
        'previous_interaction_id': _previousInteractionId,
    };

    httpRequest.body = jsonEncode(body);
    return httpRequest;
  }

  ({List<Map<String, dynamic>> input, String system}) _buildInput(
    AIRequest request,
  ) {
    final system = StringBuffer();
    final input = <Map<String, dynamic>>[];

    if (_previousInteractionId == null) {
      for (final message in request.messages) {
        switch (message.role) {
          case AIMessageRole.system:
            if (system.isNotEmpty) system.write('\n\n');
            system.write(message.content);
          case AIMessageRole.user:
            input.add({
              'type': 'user_input',
              'content': [
                {'type': 'text', 'text': message.content},
              ],
            });
          case AIMessageRole.assistant:
            if (message.content.trim().isNotEmpty) {
              input.add({
                'type': 'model_output',
                'content': [
                  {'type': 'text', 'text': message.content},
                ],
              });
            }
            for (final call in message.toolCalls) {
              input.add({
                'type': 'function_call',
                'id': call.id,
                'name': call.name,
                'arguments': _decodeArguments(call.argumentsJson),
              });
            }
          case AIMessageRole.tool:
            input.add(_functionResultStep(message));
        }
      }
      return (input: input, system: system.toString());
    }

    // Subsequent turns only need the new tool results; the interaction state
    // carries the prior user/model/thought/function_call steps.
    for (final message in request.messages) {
      if (message.role == AIMessageRole.system) {
        if (system.isNotEmpty) system.write('\n\n');
        system.write(message.content);
      } else if (message.role == AIMessageRole.tool) {
        final callId = message.toolCallId ?? '';
        if (callId.isNotEmpty && _sentToolResultIds.contains(callId)) {
          continue;
        }
        input.add(_functionResultStep(message));
      }
    }

    return (input: input, system: system.toString());
  }

  int _effectiveMaxTokens(int maxTokens) {
    // Synchronous Interactions requests are capped at 64K output tokens.
    if (maxTokens <= 0) return 1;
    if (maxTokens > 65536) return 65536;
    return maxTokens;
  }

  bool _supportsSamplingParams(String model) {
    final name = _normalizeModel(model);
    return !(name.startsWith('gemini-4') ||
        name.startsWith('gemini-3.6') ||
        name.startsWith('gemini-3.7') ||
        name.startsWith('gemini-3.8'));
  }

  void _markToolResultsSent(List<AIMessage> messages) {
    for (final message in messages) {
      if (message.role != AIMessageRole.tool) continue;
      final callId = message.toolCallId;
      if (callId != null && callId.isNotEmpty) {
        _sentToolResultIds.add(callId);
      }
    }
  }

  String _normalizeModel(String model) {
    final trimmed = model.trim();
    return trimmed.startsWith('models/')
        ? trimmed.substring('models/'.length)
        : trimmed;
  }

  Map<String, dynamic> _decodeArguments(String argumentsJson) {
    if (argumentsJson.trim().isEmpty) return const {};
    try {
      final decoded = jsonDecode(argumentsJson);
      if (decoded is Map<String, dynamic>) return decoded;
    } catch (_) {
      // The executor will report invalid arguments.
    }
    return const {};
  }

  Map<String, dynamic> _functionResultStep(AIMessage message) {
    final name = message.name ?? '';
    return {
      'type': 'function_result',
      'name': name,
      'call_id': message.toolCallId ?? '',
      'result': [
        {'type': 'text', 'text': message.content},
      ],
      if (message.isError) 'is_error': true,
    };
  }

  String _toolChoice(AIToolChoice choice) {
    switch (choice) {
      case AIToolChoice.auto:
        return 'auto';
      case AIToolChoice.none:
        return 'none';
      case AIToolChoice.required:
        return 'any';
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

    var uri = Uri.tryParse(raw);
    if (uri == null || !uri.hasScheme) {
      throw const AIError(
        type: AIErrorType.invalidResponse,
        message: 'Invalid API endpoint',
      );
    }

    var path = uri.path;
    final modelsIndex = path.indexOf('/models/');
    if (modelsIndex >= 0) {
      path = path.substring(0, modelsIndex);
    }
    if (path.endsWith('/')) {
      path = path.substring(0, path.length - 1);
    }
    if (path.endsWith('/models')) {
      path = path.substring(0, path.length - '/models'.length);
    }
    if (!path.endsWith('/interactions')) {
      path = '$path/interactions';
    }

    return uri.replace(path: path);
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

  AIError _errorFromPayload(dynamic error) {
    if (error is Map) {
      final message = error['message']?.toString() ?? 'Provider error';
      final code = error['code'];
      final status = error['status']?.toString() ?? '';
      final numericCode = code is num ? code.toInt() : null;

      final AIErrorType type;
      if (numericCode == 401 ||
          numericCode == 403 ||
          status == 'UNAUTHENTICATED' ||
          status == 'PERMISSION_DENIED') {
        type = AIErrorType.authentication;
      } else if (numericCode == 429 || status == 'RESOURCE_EXHAUSTED') {
        type = AIErrorType.rateLimit;
      } else if ((numericCode != null && numericCode >= 500) ||
          status == 'INTERNAL' ||
          status == 'UNAVAILABLE') {
        type = AIErrorType.server;
      } else {
        type = AIErrorType.invalidResponse;
      }

      return AIError(type: type, message: message, statusCode: numericCode);
    }

    return AIError(
      type: AIErrorType.invalidResponse,
      message: error.toString(),
    );
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
