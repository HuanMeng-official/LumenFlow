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

/// Streams an Anthropic Messages request with client tools.
class ClaudeToolProvider implements AIStreamingProvider {
  ClaudeToolProvider({
    http.Client Function()? clientFactory,
    this.connectionTimeout = const Duration(seconds: 30),
    this.streamingTimeout = const Duration(minutes: 5),
    this.retryBaseDelay = const Duration(seconds: 1),
    this.maxRetries = 3,
    this.anthropicVersion = '2026-10-21',
  }) : _clientFactory = clientFactory ?? http.Client.new;

  final http.Client Function() _clientFactory;
  final Duration connectionTimeout;
  final Duration streamingTimeout;
  final Duration retryBaseDelay;
  final int maxRetries;
  final String anthropicVersion;

  /// Raw assistant content blocks from the previous response. Thinking blocks
  /// carry signatures and must be sent back unchanged during tool use.
  List<Map<String, dynamic>>? _pendingAssistantBlocks;

  @override
  Stream<AIStreamEvent> stream(AIRequest request) async* {
    request.cancellationToken?.throwIfCancelled();

    final client = _clientFactory();
    final decoder = SseDecoder();
    final blocks = <int, Map<String, dynamic>>{};
    final builders = <int, _ToolCallBuilder>{};
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
              final calls = _buildToolCalls(builders, blocks);
              _pendingAssistantBlocks = _buildAssistantBlocks(blocks);
              if (calls.isNotEmpty) {
                yield AIToolCallsComplete(calls);
              }
              return;
            }

            final parsed = _parseEvent(
              data,
              event.event,
              blocks,
              builders,
              answer,
              reasoning,
            );
            for (final parsedEvent in parsed.events) {
              yield parsedEvent;
            }
            if (parsed.terminal) {
              sawTerminal = true;
              final calls = _buildToolCalls(builders, blocks);
              _pendingAssistantBlocks = _buildAssistantBlocks(blocks);
              if (calls.isNotEmpty) {
                yield AIToolCallsComplete(calls);
              }
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
            blocks,
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

        final calls = _buildToolCalls(builders, blocks);
        _pendingAssistantBlocks = _buildAssistantBlocks(blocks);
        if (calls.isNotEmpty) {
          yield AIToolCallsComplete(calls);
        }
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
    Map<int, Map<String, dynamic>> blocks,
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
    final type = map['type']?.toString() ?? eventName;

    switch (type) {
      case 'error':
        throw _errorFromPayload(map['error'] ?? map);
      case 'content_block_start':
        final index = (map['index'] as num?)?.toInt() ?? blocks.length;
        final rawBlock = map['content_block'];
        if (rawBlock is Map) {
          final block = rawBlock.cast<String, dynamic>();
          blocks[index] = block;
          if (block['type'] == 'tool_use') {
            final builder = builders.putIfAbsent(index, _ToolCallBuilder.new);
            final id = block['id'];
            if (id is String && id.isNotEmpty) builder.id = id;
            final name = block['name'];
            if (name is String && name.isNotEmpty) builder.name = name;
            final input = block['input'];
            if (input is Map && input.isNotEmpty) {
              builder.arguments.write(jsonEncode(input));
            }
          }
        }
        return (events: const [], terminal: false);
      case 'content_block_delta':
        final index = (map['index'] as num?)?.toInt() ?? 0;
        final delta = map['delta'];
        if (delta is! Map) {
          return (events: const [], terminal: false);
        }
        final deltaMap = delta.cast<String, dynamic>();
        final block = blocks.putIfAbsent(
          index,
          () => <String, dynamic>{'type': 'text', 'text': ''},
        );
        final events = <AIStreamEvent>[];

        switch (deltaMap['type']) {
          case 'text_delta':
            final text = deltaMap['text'];
            if (text is String && text.isNotEmpty) {
              block['text'] = '${block['text'] ?? ''}$text';
              answer.write(text);
              events.add(AIAnswerDelta(text));
            }
          case 'thinking_delta':
            final thinking = deltaMap['thinking'];
            if (thinking is String && thinking.isNotEmpty) {
              block['thinking'] = '${block['thinking'] ?? ''}$thinking';
              reasoning.write(thinking);
              events.add(AIReasoningDelta(thinking));
            }
          case 'signature_delta':
            final signature = deltaMap['signature'];
            if (signature is String && signature.isNotEmpty) {
              block['signature'] =
                  '${block['signature'] ?? ''}$signature';
            }
          case 'input_json_delta':
            final partial = deltaMap['partial_json'];
            if (partial is String) {
              builders
                  .putIfAbsent(index, _ToolCallBuilder.new)
                  .arguments
                  .write(partial);
            }
        }

        return (events: events, terminal: false);
      case 'content_block_stop':
        final index = (map['index'] as num?)?.toInt() ?? 0;
        final builder = builders[index];
        final block = blocks[index];
        if (builder != null && block != null) {
          final arguments = builder.arguments.toString();
          if (arguments.trim().isNotEmpty) {
            try {
              final parsed = jsonDecode(arguments);
              if (parsed is Map) {
                block['input'] = parsed;
              }
            } catch (_) {
              // Keep the original input; execution will report the error.
            }
          }
        }
        return (events: const [], terminal: false);
      case 'message_stop':
        return (events: const [], terminal: true);
      case 'message_delta':
      case 'message_start':
      case 'ping':
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

    final content = map['content'];
    if (content is! List) {
      throw const AIError(
        type: AIErrorType.invalidResponse,
        message: 'Response contains no content',
      );
    }

    final blocks = <int, Map<String, dynamic>>{};
    final builders = <int, _ToolCallBuilder>{};
    final answer = StringBuffer();
    final reasoning = StringBuffer();

    for (var index = 0; index < content.length; index++) {
      final raw = content[index];
      if (raw is! Map) continue;
      final block = raw.cast<String, dynamic>();
      blocks[index] = block;

      switch (block['type']) {
        case 'text':
          final text = block['text'];
          if (text is String && text.isNotEmpty) {
            answer.write(text);
          }
        case 'thinking':
          final thinking = block['thinking'];
          if (thinking is String && thinking.isNotEmpty) {
            reasoning.write(thinking);
          }
        case 'tool_use':
          final builder = builders.putIfAbsent(index, _ToolCallBuilder.new);
          final id = block['id'];
          if (id is String && id.isNotEmpty) builder.id = id;
          final name = block['name'];
          if (name is String && name.isNotEmpty) builder.name = name;
          final input = block['input'];
          if (input is Map) {
            builder.arguments.write(jsonEncode(input));
          }
      }
    }

    final calls = _buildToolCalls(builders, blocks);
    _pendingAssistantBlocks = _buildAssistantBlocks(blocks);

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

  List<Map<String, dynamic>>? _buildAssistantBlocks(
    Map<int, Map<String, dynamic>> blocks,
  ) {
    if (blocks.isEmpty) return null;

    final result = <Map<String, dynamic>>[];
    final indexes = blocks.keys.toList()..sort();

    for (final index in indexes) {
      final block = blocks[index]!;
      final type = block['type'];
      if (type == 'text') {
        final text = block['text'];
        if (text is String && text.isEmpty) continue;
        result.add(block);
      } else if (type == 'thinking') {
        final thinking = block['thinking'];
        if (thinking is String && thinking.isEmpty) continue;
        result.add(block);
      } else if (type == 'tool_use' || type == 'redacted_thinking') {
        result.add(block);
      }
    }

    return result.isEmpty ? null : result;
  }

  List<AIToolCall> _buildToolCalls(
    Map<int, _ToolCallBuilder> builders,
    Map<int, Map<String, dynamic>> blocks,
  ) {
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
          blocks[index]?['input'] = decoded;
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

  http.Request _buildRequest(AIRequest request) {
    final httpRequest = http.Request('POST', _resolveUrl(request.endpoint));

    httpRequest.headers['Content-Type'] = 'application/json';
    httpRequest.headers['Accept'] = 'text/event-stream, application/json';
    if (request.apiKey.isNotEmpty) {
      httpRequest.headers['X-Api-Key'] = request.apiKey;
    }
    httpRequest.headers['anthropic-version'] = anthropicVersion;
    httpRequest.headers.addAll(request.headers);

    final messages = _buildMessages(request);
    final body = <String, dynamic>{
      'model': request.model,
      'max_tokens': request.maxTokens,
      'messages': messages.messages,
      'stream': true,
      if (messages.system.isNotEmpty) 'system': messages.system,
      if (request.tools.isNotEmpty) 'tools': _buildTools(request.tools),
      if (request.tools.isNotEmpty)
        'tool_choice': _toolChoice(request.toolChoice),
    };

    httpRequest.body = jsonEncode(body);
    return httpRequest;
  }

  ({List<Map<String, dynamic>> messages, String system}) _buildMessages(
    AIRequest request,
  ) {
    final messages = <Map<String, dynamic>>[];
    final system = StringBuffer();

    var index = 0;
    while (index < request.messages.length) {
      final message = request.messages[index];

      switch (message.role) {
        case AIMessageRole.system:
          if (system.isNotEmpty) system.write('\n\n');
          system.write(message.content);
          index++;
        case AIMessageRole.user:
          messages.add({
            'role': 'user',
            'content': [
              {'type': 'text', 'text': message.content},
            ],
          });
          index++;
        case AIMessageRole.assistant:
          final pending = _pendingAssistantBlocks;
          if (message.toolCalls.isEmpty) {
            if (message.content.trim().isNotEmpty) {
              messages.add({
                'role': 'assistant',
                'content': [
                  {'type': 'text', 'text': message.content},
                ],
              });
            }
          } else if (pending != null &&
              _blocksMatch(pending, message.toolCalls)) {
            messages.add({'role': 'assistant', 'content': pending});
            _pendingAssistantBlocks = null;
          } else {
            final content = <Map<String, dynamic>>[];
            if (message.content.trim().isNotEmpty) {
              content.add({'type': 'text', 'text': message.content});
            }
            for (final call in message.toolCalls) {
              content.add({
                'type': 'tool_use',
                'id': call.id,
                'name': call.name,
                'input': _decodeArguments(call.argumentsJson),
              });
            }
            messages.add({'role': 'assistant', 'content': content});
          }
          index++;
        case AIMessageRole.tool:
          final content = <Map<String, dynamic>>[];
          while (index < request.messages.length &&
              request.messages[index].role == AIMessageRole.tool) {
            final toolMessage = request.messages[index];
            content.add({
              'type': 'tool_result',
              'tool_use_id': toolMessage.toolCallId ?? '',
              'content': toolMessage.content,
              if (toolMessage.isError) 'is_error': true,
            });
            index++;
          }
          messages.add({'role': 'user', 'content': content});
      }
    }

    return (messages: messages, system: system.toString());
  }

  bool _blocksMatch(
    List<Map<String, dynamic>> blocks,
    List<AIToolCall> calls,
  ) {
    final ids = blocks
        .where((block) => block['type'] == 'tool_use')
        .map((block) => block['id']?.toString())
        .whereType<String>()
        .toSet();
    return ids.length == calls.length &&
        calls.every((call) => ids.contains(call.id));
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

  List<Map<String, dynamic>> _buildTools(List<AIToolDefinition> tools) {
    return tools
        .map(
          (tool) => {
            'name': tool.name,
            'description': tool.description,
            'input_schema': tool.inputSchema,
          },
        )
        .toList();
  }

  Map<String, dynamic> _toolChoice(AIToolChoice choice) {
    switch (choice) {
      case AIToolChoice.auto:
        return const {'type': 'auto'};
      case AIToolChoice.none:
        return const {'type': 'auto'};
      case AIToolChoice.required:
        return const {'type': 'any'};
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
    if (!path.endsWith('/messages')) {
      path = '$path/messages';
    }

    return uri.replace(path: path);
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
