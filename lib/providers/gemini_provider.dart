import 'dart:async';
import 'dart:convert';
import 'dart:io';

import 'package:flutter/foundation.dart';
import 'package:http/http.dart' as http;

import 'ai_provider.dart';
import 'http_provider_base.dart';
import '../ai/transport/sse_decoder.dart';
import '../models/message.dart';
import '../models/attachment.dart';
import '../services/file_service.dart';
import '../services/settings_service.dart';
import '../l10n/app_localizations.dart';

/// Google Gemini provider using the Interactions API.
class GeminiProvider extends HttpProviderBase {
  final SettingsService _settingsService = SettingsService();
  final FileService _fileService = FileService();

  @override
  Future<Map<String, dynamic>> sendMessage({
    required String message,
    required List<Message> chatHistory,
    required List<Attachment> attachments,
    required String systemPrompt,
    required double temperature,
    required int maxTokens,
    bool thinkingMode = false,
    required AppLocalizations l10n,
  }) async {
    return await executeWithRetry<Map<String, dynamic>>(
      () async {
        final client = createHttpClient();
        try {
          final apiEndpoint = await _settingsService.getApiEndpoint();
          final apiKey = await _settingsService.getApiKey();
          final model = _normalizeModel(await _settingsService.getModel());
          final enableHistory = await _settingsService.getEnableHistory();
          final historyContextLength = await _settingsService
              .getHistoryContextLength();

          final input = await _buildInput(
            message: message,
            chatHistory: chatHistory,
            attachments: attachments,
            enableHistory: enableHistory,
            historyContextLength: historyContextLength,
            l10n: l10n,
          );

          final requestBody = <String, dynamic>{
            'model': model,
            'input': input,
            'store': false,
            if (systemPrompt.isNotEmpty) 'system_instruction': systemPrompt,
            'generation_config': _buildGenerationConfig(
              model: model,
              maxTokens: maxTokens,
              thinkingMode: thinkingMode,
              temperature: temperature,
            ),
          };

          final response = await client
              .post(
                _resolveUrl(apiEndpoint),
                headers: _headers(apiKey),
                body: jsonEncode(requestBody),
              )
              .timeout(connectionTimeout + readTimeout);

          if (response.statusCode == 200) {
            return _parseResponse(response.body, l10n);
          }
          throw parseError(response.body, response.statusCode, l10n);
        } finally {
          client.close();
        }
      },
      onRetry: (error, retryCount, delayMs) {
        debugPrint('Gemini API请求失败，第$retryCount次重试，延迟${delayMs}ms: $error');
      },
      l10n: l10n,
    );
  }

  @override
  Stream<Map<String, dynamic>> sendMessageStreaming({
    required String message,
    required List<Message> chatHistory,
    required List<Attachment> attachments,
    required String systemPrompt,
    required double temperature,
    required int maxTokens,
    bool thinkingMode = false,
    required AppLocalizations l10n,
  }) async* {
    final client = createHttpClient();
    try {
      final apiEndpoint = await _settingsService.getApiEndpoint();
      final apiKey = await _settingsService.getApiKey();
      final model = _normalizeModel(await _settingsService.getModel());
      final enableHistory = await _settingsService.getEnableHistory();
      final historyContextLength = await _settingsService
          .getHistoryContextLength();

      final input = await _buildInput(
        message: message,
        chatHistory: chatHistory,
        attachments: attachments,
        enableHistory: enableHistory,
        historyContextLength: historyContextLength,
        l10n: l10n,
      );

      final requestBody = <String, dynamic>{
        'model': model,
        'input': input,
        'stream': true,
        'store': false,
        if (systemPrompt.isNotEmpty) 'system_instruction': systemPrompt,
        'generation_config': _buildGenerationConfig(
          model: model,
          maxTokens: maxTokens,
          thinkingMode: thinkingMode,
          temperature: temperature,
        ),
      };

      final request = http.Request('POST', _resolveUrl(apiEndpoint));
      request.headers.addAll(_headers(apiKey));
      request.body = jsonEncode(requestBody);

      final streamedResponse = await client
          .send(request)
          .timeout(connectionTimeout);

      if (streamedResponse.statusCode != 200) {
        final errorBody = await streamedResponse.stream
            .transform(utf8.decoder)
            .join()
            .timeout(readTimeout);
        throw parseError(errorBody, streamedResponse.statusCode, l10n);
      }

      final contentType =
          (streamedResponse.headers['content-type'] ??
                  streamedResponse.headers['Content-Type'] ??
                  '')
              .toLowerCase();

      if (contentType.contains('application/json')) {
        final body = await streamedResponse.stream.bytesToString().timeout(
          streamingTimeout,
        );
        final parsed = _parseResponse(body, l10n);
        final reasoning = parsed['reasoningContent']?.toString() ?? '';
        if (reasoning.isNotEmpty) {
          yield {'type': 'reasoning', 'content': reasoning};
        }
        final content = parsed['content']?.toString() ?? '';
        if (content.isNotEmpty) {
          yield {'type': 'answer', 'content': content};
        }
        return;
      }

      if (contentType.isNotEmpty &&
          !contentType.contains('text/event-stream')) {
        throw Exception(
          'Unexpected Gemini response content type: $contentType',
        );
      }

      final decoder = SseDecoder();
      final stepTypes = <int, String>{};

      await for (final chunk
          in streamedResponse.stream
              .timeout(streamingTimeout)
              .transform(utf8.decoder)) {
        for (final event in decoder.add(chunk)) {
          if (event.data.trim().isEmpty) continue;
          final parsed = _parseStreamingEvent(
            event.data.trim(),
            event.event,
            stepTypes,
          );
          for (final output in parsed.events) {
            yield output;
          }
          if (parsed.terminal) return;
        }
      }

      for (final event in decoder.flush()) {
        if (event.data.trim().isEmpty) continue;
        final parsed = _parseStreamingEvent(
          event.data.trim(),
          event.event,
          stepTypes,
        );
        for (final output in parsed.events) {
          yield output;
        }
        if (parsed.terminal) return;
      }
    } finally {
      client.close();
    }
  }

  ({List<Map<String, dynamic>> events, bool terminal}) _parseStreamingEvent(
    String data,
    String? eventName,
    Map<int, String> stepTypes,
  ) {
    final events = <Map<String, dynamic>>[];
    if (data == '[DONE]') {
      return (events: events, terminal: true);
    }

    dynamic json;
    try {
      json = jsonDecode(data);
    } catch (_) {
      return (events: events, terminal: false);
    }
    if (json is! Map) {
      return (events: events, terminal: false);
    }

    final map = json.cast<String, dynamic>();
    final type =
        map['type']?.toString() ?? map['event_type']?.toString() ?? eventName;

    if (type == 'error' || type == 'interaction.failed') {
      final interaction = map['interaction'];
      final error = interaction is Map
          ? interaction['error'] ?? interaction
          : map['error'] ?? map;
      throw Exception(
        error is Map
            ? (error['message']?.toString() ?? 'Gemini API error')
            : error.toString(),
      );
    }

    if (type == 'interaction.status_update') {
      final status = map['status']?.toString() ?? '';
      if (status == 'failed' || status == 'cancelled') {
        throw Exception('Gemini interaction $status');
      }
      return (events: events, terminal: false);
    }

    if (type == 'step.start') {
      final index = (map['index'] as num?)?.toInt() ?? 0;
      final step = map['step'];
      if (step is Map) {
        final stepMap = step.cast<String, dynamic>();
        final stepType = stepMap['type']?.toString() ?? '';
        stepTypes[index] = stepType;

        if (stepType == 'model_output') {
          for (final text in _extractTexts(stepMap['content'])) {
            events.add({'type': 'answer', 'content': text});
          }
        } else if (stepType == 'thought') {
          for (final text in _extractTexts(stepMap['summary'])) {
            events.add({'type': 'reasoning', 'content': text});
          }
        }
      }
    } else if (type == 'step.delta') {
      final index = (map['index'] as num?)?.toInt() ?? 0;
      final delta = map['delta'];
      if (delta is Map) {
        final deltaMap = delta.cast<String, dynamic>();
        final deltaType = deltaMap['type']?.toString() ?? '';

        if (deltaType == 'text') {
          final text = deltaMap['text'];
          if (text is String && text.isNotEmpty) {
            final stepType = stepTypes[index] ?? 'model_output';
            events.add({
              'type': stepType == 'thought' ? 'reasoning' : 'answer',
              'content': text,
            });
          }
        } else if (deltaType == 'thought' || deltaType == 'thought_summary') {
          final texts = _extractTexts(deltaMap['content']).toList();
          final text = deltaMap['text'];
          if (texts.isEmpty && text is String && text.isNotEmpty) {
            texts.add(text);
          }
          for (final thought in texts) {
            events.add({'type': 'reasoning', 'content': thought});
          }
        }
      }
    } else if (type == 'interaction.completed') {
      final interaction = map['interaction'];
      final status = interaction is Map
          ? interaction['status']?.toString() ?? ''
          : '';
      if (status == 'failed') {
        throw Exception('Gemini interaction failed');
      }
      if (status == 'cancelled') {
        throw Exception('Gemini interaction cancelled');
      }
      return (events: events, terminal: true);
    }

    return (events: events, terminal: false);
  }

  @override
  Future<String> generateConversationTitle(
    List<Message> messages, {
    required AppLocalizations l10n,
  }) async {
    final apiEndpoint = await _settingsService.getApiEndpoint();
    final apiKey = await _settingsService.getApiKey();
    final model = _normalizeModel(await _settingsService.getModel());

    final summaryMessages = messages.take(6).toList();
    final conversationSummary = summaryMessages
        .map((msg) {
          final role = msg.isUser ? l10n.providerUser : l10n.providerAi;
          return '$role: ${msg.content.trim()}';
        })
        .join('\n');

    final requestBody = <String, dynamic>{
      'model': model,
      'store': false,
      'input': [
        {
          'type': 'user_input',
          'content': [
            {
              'type': 'text',
              'text': l10n.providerTitleGenUserPrompt(conversationSummary),
            },
          ],
        },
      ],
      'system_instruction': l10n.providerTitleGenSystemPrompt,
      'generation_config': {
        // max_output_tokens covers thinking + answer, so leave room for
        // reasoning before the short title is produced.
        'max_output_tokens': 512,
        'thinking_level': 'low',
        'thinking_summaries': 'none',
      },
    };

    final client = createHttpClient();
    try {
      final response = await client
          .post(
            _resolveUrl(apiEndpoint),
            headers: _headers(apiKey),
            body: jsonEncode(requestBody),
          )
          .timeout(connectionTimeout + readTimeout);

      if (response.statusCode != 200) {
        throw parseError(response.body, response.statusCode, l10n);
      }

      final parsed = _parseResponse(response.body, l10n);
      var title = parsed['content']?.toString().trim() ?? '';

      if (title.startsWith('"') ||
          title.startsWith("'") ||
          title.startsWith('|')) {
        title = title.substring(1);
      }
      if (title.endsWith('"') || title.endsWith("'") || title.endsWith('|')) {
        title = title.substring(0, title.length - 1);
      }
      if (title.length > 20) {
        title = '${title.substring(0, 20)}...';
      }
      return title;
    } finally {
      client.close();
    }
  }

  Future<List<Map<String, dynamic>>> _buildInput({
    required String message,
    required List<Message> chatHistory,
    required List<Attachment> attachments,
    required bool enableHistory,
    required int historyContextLength,
    required AppLocalizations l10n,
  }) async {
    final input = <Map<String, dynamic>>[];

    if (enableHistory && chatHistory.isNotEmpty) {
      final recentHistory = chatHistory
          .where(
            (msg) =>
                msg.status != MessageStatus.error &&
                msg.content.trim().isNotEmpty,
          )
          .toList()
          .reversed
          .take(historyContextLength * 2)
          .toList()
          .reversed
          .toList();

      for (final historyMessage in recentHistory) {
        input.add({
          'type': historyMessage.isUser ? 'user_input' : 'model_output',
          'content': [
            {'type': 'text', 'text': historyMessage.content},
          ],
        });
      }
    }

    final currentContent = <Map<String, dynamic>>[];
    if (message.isNotEmpty) {
      currentContent.add({'type': 'text', 'text': message});
    }
    if (attachments.isNotEmpty) {
      currentContent.addAll(await _prepareAttachments(attachments, l10n));
    }
    if (currentContent.isNotEmpty) {
      input.add({'type': 'user_input', 'content': currentContent});
    }

    return input;
  }

  Future<List<Map<String, dynamic>>> _prepareAttachments(
    List<Attachment> attachments,
    AppLocalizations l10n,
  ) async {
    final content = <Map<String, dynamic>>[];

    final totalSize = attachments.fold<int>(
      0,
      (sum, attachment) => sum + (attachment.fileSize ?? 0),
    );
    if (totalSize > AIProvider.maxTotalAttachmentsSize) {
      throw Exception(
        l10n.providerTotalSizeExceeded(
          AIProvider.maxTotalAttachmentsSize ~/ (1024 * 1024),
        ),
      );
    }

    for (final attachment in attachments) {
      try {
        if (attachment.filePath == null ||
            !await _fileService.fileExists(attachment.filePath!)) {
          content.add({
            'type': 'text',
            'text': l10n.providerFileNotFound(attachment.fileName),
          });
          continue;
        }

        final file = File(attachment.filePath!);
        final fileSize =
            attachment.fileSize ??
            await _fileService.getFileSize(attachment.filePath!);

        if (fileSize > AIProvider.maxFileSizeForBase64) {
          content.add({
            'type': 'text',
            'text': l10n.providerFileTooLarge(
              attachment.fileName,
              formatFileSize(fileSize),
            ),
          });
          continue;
        }

        final mimeType = attachment.mimeType?.toLowerCase() ?? '';
        final isImage = mimeType.startsWith('image/');
        final isVideo = mimeType.startsWith('video/');
        final isAudio = mimeType.startsWith('audio/');
        final isPdf = mimeType == 'application/pdf';

        if (isImage || isVideo || isAudio || isPdf) {
          try {
            final base64Data = await _fileService.getFileBase64(file);
            var cleanBase64 = base64Data;
            if (base64Data.contains(',')) {
              cleanBase64 = base64Data.split(',').last;
            }
            content.add({
              'type': isPdf
                  ? 'document'
                  : isImage
                  ? 'image'
                  : isVideo
                  ? 'video'
                  : 'audio',
              'mime_type': mimeType.isNotEmpty
                  ? mimeType
                  : 'application/octet-stream',
              'data': cleanBase64,
            });
          } catch (error) {
            content.add({
              'type': 'text',
              'text': l10n.providerFileProcessError(
                attachment.fileName,
                error.toString(),
              ),
            });
          }
        } else if (fileSize <= AIProvider.maxFileSizeForTextExtraction) {
          try {
            final text = await _fileService.readTextFile(file);
            content.add({
              'type': 'text',
              'text': l10n.providerFileContent(
                attachment.fileName,
                formatFileSize(fileSize),
                text,
              ),
            });
          } catch (error) {
            content.add({
              'type': 'text',
              'text': l10n.providerAttachmentCannotRead(
                attachment.fileName,
                formatFileSize(fileSize),
                attachment.mimeType ?? l10n.unknownMimeType,
              ),
            });
          }
        } else {
          content.add({
            'type': 'text',
            'text': l10n.providerAttachmentInfo(
              attachment.fileName,
              formatFileSize(fileSize),
              attachment.mimeType ?? l10n.unknownMimeType,
            ),
          });
        }
      } catch (error) {
        content.add({
          'type': 'text',
          'text': l10n.providerFileProcessError(
            attachment.fileName,
            error.toString(),
          ),
        });
      }
    }

    return content;
  }

  Map<String, dynamic> _buildGenerationConfig({
    required String model,
    required int maxTokens,
    required bool thinkingMode,
    required double temperature,
  }) {
    return {
      'max_output_tokens': _effectiveMaxTokens(maxTokens),
      'thinking_level': thinkingMode ? 'high' : 'low',
      'thinking_summaries': thinkingMode ? 'auto' : 'none',
      // Gemini 4 and 3.6+ ignore sampling parameters and warn when present.
      if (_supportsSamplingParams(model)) 'temperature': temperature,
    };
  }

  bool _supportsSamplingParams(String model) {
    final name = _normalizeModel(model);
    return !(name.startsWith('gemini-4') ||
        name.startsWith('gemini-3.6') ||
        name.startsWith('gemini-3.7') ||
        name.startsWith('gemini-3.8'));
  }

  int _effectiveMaxTokens(int maxTokens) {
    // Synchronous Interactions requests are capped at 64K output tokens.
    if (maxTokens <= 0) return 1;
    if (maxTokens > 65536) return 65536;
    return maxTokens;
  }

  Map<String, dynamic> _parseResponse(String body, AppLocalizations l10n) {
    dynamic json;
    try {
      json = jsonDecode(body);
    } catch (_) {
      throw Exception(l10n.providerGeminiInvalidFormat);
    }

    if (json is! Map) {
      throw Exception(l10n.providerGeminiInvalidFormat);
    }

    final map = json.cast<String, dynamic>();
    final error = map['error'];
    if (error != null) {
      final message = error is Map
          ? error['message']?.toString() ?? l10n.providerUnknownError
          : error.toString();
      throw Exception(l10n.providerGeminiError(message, 0));
    }

    final steps = map['steps'];
    if (steps is! List) {
      throw Exception(l10n.providerGeminiInvalidFormat);
    }

    final reasoning = StringBuffer();
    final answer = StringBuffer();

    for (final rawStep in steps) {
      if (rawStep is! Map) continue;
      final step = rawStep.cast<String, dynamic>();

      switch (step['type']) {
        case 'thought':
          _collectText(step['summary'], reasoning);
        case 'model_output':
          _collectText(step['content'], answer);
      }
    }

    return {
      'reasoningContent': reasoning.toString().trim(),
      'content': answer.toString().trim(),
    };
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

  void _collectText(dynamic rawContent, StringBuffer buffer) {
    for (final text in _extractTexts(rawContent)) {
      buffer.write(text);
    }
  }

  String _normalizeModel(String model) {
    final trimmed = model.trim();
    return trimmed.startsWith('models/')
        ? trimmed.substring('models/'.length)
        : trimmed;
  }

  Map<String, String> _headers(String apiKey) {
    return {
      'Content-Type': 'application/json',
      if (apiKey.isNotEmpty) 'x-goog-api-key': apiKey,
    };
  }

  Uri _resolveUrl(String endpoint) {
    final raw = endpoint.trim();
    if (raw.isEmpty) {
      throw Exception('Gemini API endpoint is empty');
    }

    var uri = Uri.tryParse(raw);
    if (uri == null || !uri.hasScheme) {
      throw Exception('Invalid Gemini API endpoint');
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
}
