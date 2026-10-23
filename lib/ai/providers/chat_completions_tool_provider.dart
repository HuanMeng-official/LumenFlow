import 'dart:async';
import 'dart:convert';
import 'dart:io';

import 'package:http/http.dart' as http;

import '../contracts/ai_error.dart';
import '../contracts/ai_request.dart';
import '../contracts/ai_stream_event.dart';
import '../contracts/ai_tool.dart';
import '../contracts/cancellation_token.dart';
import '../transport/sse_decoder.dart';
import 'chat_completions_profile.dart';

abstract class AIStreamingProvider {
  Stream<AIStreamEvent> stream(AIRequest request);
}

class _ToolCallBuilder {
  String? id;
  String name = '';
  final StringBuffer arguments = StringBuffer();
}

/// Streams an OpenAI Chat Completions request with optional tool definitions.
class ChatCompletionsToolProvider implements AIStreamingProvider {
  ChatCompletionsToolProvider({
    required this.profile,
    http.Client Function()? clientFactory,
    this.connectionTimeout = const Duration(seconds: 30),
    this.streamingTimeout = const Duration(minutes: 5),
    this.retryBaseDelay = const Duration(seconds: 1),
    this.maxRetries = 3,
  }) : _clientFactory = clientFactory ?? http.Client.new;

  final ChatCompletionsProfile profile;
  final http.Client Function() _clientFactory;
  final Duration connectionTimeout;
  final Duration streamingTimeout;
  final Duration retryBaseDelay;
  final int maxRetries;

  @override
  Stream<AIStreamEvent> stream(AIRequest request) async* {
    request.cancellationToken?.throwIfCancelled();

    if (!profile.supportsTools && request.tools.isNotEmpty) {
      throw const AIError(
        type: AIErrorType.unsupported,
        message: 'Provider does not support tools',
      );
    }

    final client = _clientFactory();
    final toolBuilders = <int, _ToolCallBuilder>{};
    final decoder = SseDecoder();
    var sawTerminal = false;

    try {
      final response = await _sendWithRetry(client, request);
      final contentType = (response.headers['content-type'] ??
              response.headers['Content-Type'] ??
              '')
          .toLowerCase();

      if (contentType.contains('application/json')) {
        final body = await response.stream
            .bytesToString()
            .timeout(streamingTimeout);
        yield* _parseNonStreamingBody(body, toolBuilders);
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
              yield* _emitToolCalls(toolBuilders);
              return;
            }

            final parsed = _parseData(data, toolBuilders);
            if (parsed.terminal) sawTerminal = true;
            for (final parsedEvent in parsed.events) {
              yield parsedEvent;
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

          final parsed = _parseData(data, toolBuilders);
          if (parsed.terminal) sawTerminal = true;
          for (final parsedEvent in parsed.events) {
            yield parsedEvent;
          }
        }

        if (!sawTerminal) {
          throw const AIError(
            type: AIErrorType.invalidResponse,
            message: 'Stream ended before completion',
          );
        }

        yield* _emitToolCalls(toolBuilders);
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

  Stream<AIStreamEvent> _parseNonStreamingBody(
    String body,
    Map<int, _ToolCallBuilder> builders,
  ) async* {
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

    final error = json['error'];
    if (error != null) {
      throw _errorFromPayload(error);
    }

    final choices = json['choices'];
    if (choices is! List || choices.isEmpty) {
      throw const AIError(
        type: AIErrorType.invalidResponse,
        message: 'Response contains no choices',
      );
    }

    final choice = choices.first;
    if (choice is! Map) {
      throw const AIError(
        type: AIErrorType.invalidResponse,
        message: 'Invalid choice in response',
      );
    }

    final message = choice['message'];
    if (message is! Map) {
      throw const AIError(
        type: AIErrorType.invalidResponse,
        message: 'Response contains no message',
      );
    }

    final messageMap = message.cast<String, dynamic>();
    final reasoning = profile.reasoningDelta(messageMap);
    if (reasoning != null && reasoning.isNotEmpty) {
      yield AIReasoningDelta(reasoning);
    }

    final content = messageMap['content'];
    if (content is String && content.isNotEmpty) {
      yield AIAnswerDelta(content);
    }

    final toolCalls = messageMap['tool_calls'];
    if (toolCalls is List) {
      var index = 0;
      for (final raw in toolCalls) {
        if (raw is! Map) continue;
        final map = raw.cast<String, dynamic>();
        final function = map['function'];
        if (function is! Map) continue;

        final name = function['name']?.toString() ?? '';
        if (name.isEmpty) continue;

        final id = map['id']?.toString() ?? 'call_$index';
        final arguments = function['arguments']?.toString() ?? '';
        builders[index++] = _ToolCallBuilder()
          ..id = id
          ..name = name
          ..arguments.write(arguments);
      }
    }

    yield* _emitToolCalls(builders);
  }

  ({List<AIStreamEvent> events, bool terminal}) _parseData(
    String data,
    Map<int, _ToolCallBuilder> builders,
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

    final error = json['error'];
    if (error != null) {
      throw _errorFromPayload(error);
    }

    final choices = json['choices'];
    if (choices is! List || choices.isEmpty) {
      return (events: const [], terminal: false);
    }

    final choice = choices.first;
    if (choice is! Map) {
      return (events: const [], terminal: false);
    }

    final terminal = choice['finish_reason'] != null;
    final delta = choice['delta'];
    if (delta is! Map) {
      return (events: const [], terminal: terminal);
    }

    final deltaMap = delta.cast<String, dynamic>();
    final events = <AIStreamEvent>[];

    final reasoning = profile.reasoningDelta(deltaMap);
    if (reasoning != null && reasoning.isNotEmpty) {
      events.add(AIReasoningDelta(reasoning));
    }

    final content = deltaMap['content'];
    if (content is String && content.isNotEmpty) {
      events.add(AIAnswerDelta(content));
    }

    final toolCalls = deltaMap['tool_calls'];
    if (toolCalls is List) {
      for (final raw in toolCalls) {
        if (raw is! Map) continue;
        final map = raw.cast<String, dynamic>();
        final index = (map['index'] as num?)?.toInt() ?? 0;
        final builder = builders.putIfAbsent(index, _ToolCallBuilder.new);

        final id = map['id'];
        if (id is String && id.isNotEmpty) {
          builder.id = id;
        }

        final function = map['function'];
        if (function is Map) {
          final name = function['name'];
          if (name is String && name.isNotEmpty) {
            builder.name = name;
          }
          final arguments = function['arguments'];
          if (arguments is String) {
            builder.arguments.write(arguments);
          }
        }
      }
    }

    return (events: events, terminal: terminal);
  }

  AIError _errorFromPayload(dynamic error) {
    if (error is Map) {
      final message = error['message']?.toString() ?? 'Provider error';
      final code = (error['code'] as num?)?.toInt();
      final AIErrorType type;
      if (code == 429) {
        type = AIErrorType.rateLimit;
      } else if (code != null && code >= 500) {
        type = AIErrorType.server;
      } else {
        type = AIErrorType.invalidResponse;
      }
      return AIError(type: type, message: message, statusCode: code);
    }
    return AIError(
      type: AIErrorType.invalidResponse,
      message: error.toString(),
    );
  }

  Stream<AIStreamEvent> _emitToolCalls(
    Map<int, _ToolCallBuilder> builders,
  ) async* {
    final calls = _buildToolCalls(builders);
    if (calls.isNotEmpty) {
      yield AIToolCallsComplete(calls);
    }
  }

  List<AIToolCall> _buildToolCalls(Map<int, _ToolCallBuilder> builders) {
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
          id: builder.id ?? 'call_$index',
          name: builder.name,
          argumentsJson: argumentsJson,
        ),
      );
    }

    return calls;
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
    final uri = _resolveUrl(request.endpoint);
    final httpRequest = http.Request('POST', uri);

    httpRequest.headers['Content-Type'] = 'application/json';
    httpRequest.headers['Accept'] = 'text/event-stream, application/json';
    if (request.apiKey.isNotEmpty) {
      httpRequest.headers['Authorization'] = 'Bearer ${request.apiKey}';
    }
    httpRequest.headers.addAll(request.headers);

    final body = <String, dynamic>{
      'model': request.model,
      'messages': request.messages.map((m) => m.toOpenAIJson()).toList(),
      'stream': true,
      profile.tokenField: request.maxTokens,
      'temperature': profile.temperature(request),
    };

    body.addAll(profile.thinkingFields(request));
    body.addAll(profile.extraFields(request));

    if (request.tools.isNotEmpty) {
      body['tools'] = request.tools.map((t) => t.toOpenAIJson()).toList();
      body['tool_choice'] = request.toolChoice.name;
    }

    httpRequest.body = jsonEncode(body);
    return httpRequest;
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

    final path = uri.path.replaceFirst(RegExp(r'/+$'), '');
    if (path.endsWith(profile.path)) {
      return uri;
    }

    return uri.replace(path: '$path${profile.path}');
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
