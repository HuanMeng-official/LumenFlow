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

/// Streams a Gemini generateContent request with function declarations.
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

  /// Raw model parts from the previous response. Gemini 3 thought signatures
  /// must be passed back unchanged during tool use.
  List<Map<String, dynamic>>? _pendingModelParts;

  @override
  Stream<AIStreamEvent> stream(AIRequest request) async* {
    request.cancellationToken?.throwIfCancelled();

    final client = _clientFactory();
    final decoder = SseDecoder();
    final answer = StringBuffer();
    final reasoning = StringBuffer();
    final modelParts = <Map<String, dynamic>>[];
    final calls = <AIToolCall>[];
    var sawChunk = false;
    _pendingDeltaEvents.clear();

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
            if (data.isEmpty || data == '[DONE]') continue;

            final parsed = _parseChunk(
              data,
              answer,
              reasoning,
              modelParts,
              calls,
            );
            sawChunk = sawChunk || parsed;
            for (final parsedEvent in _drainDeltaEvents()) {
              yield parsedEvent;
            }
          }
        }

        for (final event in decoder.flush()) {
          final data = event.data.trim();
          if (data.isEmpty || data == '[DONE]') continue;
          final parsed = _parseChunk(
            data,
            answer,
            reasoning,
            modelParts,
            calls,
          );
          sawChunk = sawChunk || parsed;
          for (final parsedEvent in _drainDeltaEvents()) {
            yield parsedEvent;
          }
        }

        if (!sawChunk) {
          throw const AIError(
            type: AIErrorType.invalidResponse,
            message: 'Stream ended before any response was received',
          );
        }

        _pendingModelParts = modelParts.isEmpty ? null : modelParts;
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

  // Delta events are collected by _parseChunk and drained after each chunk.
  final List<AIStreamEvent> _pendingDeltaEvents = [];

  List<AIStreamEvent> _drainDeltaEvents() {
    final events = List<AIStreamEvent>.from(_pendingDeltaEvents);
    _pendingDeltaEvents.clear();
    return events;
  }

  bool _parseChunk(
    String data,
    StringBuffer answer,
    StringBuffer reasoning,
    List<Map<String, dynamic>> modelParts,
    List<AIToolCall> calls,
  ) {
    dynamic json;
    try {
      json = jsonDecode(data);
    } catch (_) {
      return false;
    }
    if (json is! Map) return false;

    final map = json.cast<String, dynamic>();
    final error = map['error'];
    if (error != null) {
      throw _errorFromPayload(error);
    }

    final candidates = map['candidates'];
    if (candidates is! List || candidates.isEmpty) return false;

    final candidate = candidates.first;
    if (candidate is! Map) return false;

    final content = candidate['content'];
    if (content is! Map) return true;

    final parts = content['parts'];
    if (parts is! List) return true;

    for (final rawPart in parts) {
      if (rawPart is! Map) continue;
      final part = rawPart.cast<String, dynamic>();

      final functionCall = part['functionCall'];
      if (functionCall is Map) {
        final callMap = functionCall.cast<String, dynamic>();
        final name = callMap['name']?.toString() ?? '';
        if (name.isEmpty) continue;
        final args = callMap['args'];
        final argumentsJson = args is Map ? jsonEncode(args) : '{}';
        final index = calls.length;
        calls.add(
          AIToolCall(
            id: 'gemini_call_$index',
            name: name,
            argumentsJson: argumentsJson,
          ),
        );
        modelParts.add(part);
        continue;
      }

      final text = part['text'];
      if (text is String && text.isNotEmpty) {
        final isThought = part['thought'] == true;
        if (isThought) {
          reasoning.write(text);
          _pendingDeltaEvents.add(AIReasoningDelta(text));
        } else {
          answer.write(text);
          _pendingDeltaEvents.add(AIAnswerDelta(text));
        }
        modelParts.add(part);
      } else if (part['thoughtSignature'] != null) {
        modelParts.add(part);
      }
    }

    return true;
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

    final candidates = map['candidates'];
    if (candidates is! List || candidates.isEmpty) {
      throw const AIError(
        type: AIErrorType.invalidResponse,
        message: 'Response contains no candidates',
      );
    }

    final answer = StringBuffer();
    final reasoning = StringBuffer();
    final modelParts = <Map<String, dynamic>>[];
    final calls = <AIToolCall>[];

    _parseChunk(
      jsonEncode(map),
      answer,
      reasoning,
      modelParts,
      calls,
    );

    final events = List<AIStreamEvent>.from(_pendingDeltaEvents);
    _pendingDeltaEvents.clear();

    _pendingModelParts = modelParts.isEmpty ? null : modelParts;
    if (calls.isNotEmpty) {
      events.add(AIToolCallsComplete(calls));
    }

    for (final event in events) {
      yield event;
    }
  }

  http.Request _buildRequest(AIRequest request) {
    final httpRequest = http.Request(
      'POST',
      _resolveUrl(request.endpoint, request.model, request.apiKey),
    );

    httpRequest.headers['Content-Type'] = 'application/json';
    httpRequest.headers['Accept'] = 'text/event-stream, application/json';
    if (request.apiKey.isNotEmpty) {
      httpRequest.headers['x-goog-api-key'] = request.apiKey;
    }
    httpRequest.headers.addAll(request.headers);

    final built = _buildContents(request);
    final body = <String, dynamic>{
      'contents': built.contents,
      'generationConfig': _buildGenerationConfig(request),
      if (built.system.isNotEmpty)
        'system_instruction': {
          'parts': [
            {'text': built.system},
          ],
        },
      if (request.tools.isNotEmpty)
        'tools': [
          {
            'functionDeclarations': request.tools
                .map(
                  (tool) => {
                    'name': tool.name,
                    'description': tool.description,
                    'parameters': tool.inputSchema,
                  },
                )
                .toList(),
          },
        ],
      if (request.tools.isNotEmpty)
        'toolConfig': {
          'functionCallingConfig': {
            'mode': _toolChoice(request.toolChoice),
          },
        },
    };

    httpRequest.body = jsonEncode(body);
    return httpRequest;
  }

  ({List<Map<String, dynamic>> contents, String system}) _buildContents(
    AIRequest request,
  ) {
    final contents = <Map<String, dynamic>>[];
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
          contents.add({
            'role': 'user',
            'parts': [
              {'text': message.content},
            ],
          });
          index++;
        case AIMessageRole.assistant:
          final parts = <Map<String, dynamic>>[];
          final pending = _pendingModelParts;
          if (message.toolCalls.isNotEmpty &&
              pending != null &&
              _partsMatch(pending, message.toolCalls)) {
            parts.addAll(pending);
            _pendingModelParts = null;
          } else {
            if (message.content.trim().isNotEmpty) {
              parts.add({'text': message.content});
            }
            for (final call in message.toolCalls) {
              parts.add({
                'functionCall': {
                  'name': call.name,
                  'args': _decodeArguments(call.argumentsJson),
                },
              });
            }
          }
          if (parts.isNotEmpty) {
            contents.add({'role': 'model', 'parts': parts});
          }
          index++;
        case AIMessageRole.tool:
          final parts = <Map<String, dynamic>>[];
          while (index < request.messages.length &&
              request.messages[index].role == AIMessageRole.tool) {
            final toolMessage = request.messages[index];
            final name = toolMessage.name ?? '';
            parts.add({
              'functionResponse': {
                'name': name,
                'response': {
                  'name': name,
                  'content': _decodeContent(toolMessage.content),
                },
              },
            });
            index++;
          }
          if (parts.isNotEmpty) {
            contents.add({'role': 'user', 'parts': parts});
          }
      }
    }

    return (contents: contents, system: system.toString());
  }

  bool _partsMatch(
    List<Map<String, dynamic>> parts,
    List<AIToolCall> calls,
  ) {
    final names = parts
        .map((part) => part['functionCall'])
        .whereType<Map>()
        .map((call) => call['name']?.toString())
        .whereType<String>()
        .toList();
    if (names.length != calls.length) return false;

    final sortedNames = names.toList()..sort();
    final sortedCalls = calls.map((call) => call.name).toList()..sort();
    for (var i = 0; i < sortedNames.length; i++) {
      if (sortedNames[i] != sortedCalls[i]) return false;
    }
    return true;
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

  dynamic _decodeContent(String content) {
    if (content.trim().isEmpty) return content;
    try {
      return jsonDecode(content);
    } catch (_) {
      return content;
    }
  }

  Map<String, dynamic> _buildGenerationConfig(AIRequest request) {
    final config = <String, dynamic>{
      'temperature': request.temperature,
      'maxOutputTokens': request.maxTokens,
    };

    final isGemini3Plus = request.model.startsWith('gemini-3') ||
        request.model.startsWith('gemini-4');
    if (isGemini3Plus) {
      config['thinkingConfig'] = {
        'thinkingLevel': request.thinkingMode ? 'high' : 'low',
        'includeThoughts': request.thinkingMode,
      };
    } else if (request.thinkingMode) {
      config['thinkingConfig'] = {
        'thinkingBudget': -1,
        'includeThoughts': true,
      };
    }

    return config;
  }

  String _toolChoice(AIToolChoice choice) {
    switch (choice) {
      case AIToolChoice.auto:
        return 'AUTO';
      case AIToolChoice.none:
        return 'NONE';
      case AIToolChoice.required:
        return 'ANY';
    }
  }

  Uri _resolveUrl(String endpoint, String model, String apiKey) {
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
    if (path.endsWith('/')) {
      path = path.substring(0, path.length - 1);
    }

    final modelPath = model.contains('/') ? model : 'models/$model';
    if (path.contains('/models/')) {
      final marker = path.indexOf(':');
      if (marker >= 0) {
        path = path.substring(0, marker);
      }
      if (!path.endsWith(':streamGenerateContent')) {
        path = '$path:streamGenerateContent';
      }
    } else {
      path = '$path/$modelPath:streamGenerateContent';
    }

    final query = Map<String, String>.from(uri.queryParameters);
    query['alt'] = 'sse';
    if (apiKey.isNotEmpty) {
      query['key'] = apiKey;
    }
    uri = uri.replace(path: path, queryParameters: query);

    return uri;
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
      } else if (numericCode == 429 ||
          status == 'RESOURCE_EXHAUSTED') {
        type = AIErrorType.rateLimit;
      } else if ((numericCode != null && numericCode >= 500) ||
          status == 'INTERNAL' ||
          status == 'UNAVAILABLE') {
        type = AIErrorType.server;
      } else {
        type = AIErrorType.invalidResponse;
      }

      return AIError(
        type: type,
        message: message,
        statusCode: numericCode,
      );
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
