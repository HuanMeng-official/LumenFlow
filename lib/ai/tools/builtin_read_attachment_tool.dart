import 'dart:convert';
import 'dart:io';

import '../contracts/ai_tool.dart';
import '../contracts/ai_tool_executor.dart';
import '../../services/file_service.dart';
import 'attachment_tool_context.dart';

/// Reads text attachments from the current user message on demand.
class BuiltInReadAttachmentTool implements AIToolExecutor {
  BuiltInReadAttachmentTool({
    required this.context,
    FileService? fileService,
    this.enabled = true,
  }) : _fileService = fileService ?? FileService();

  static const String toolName = attachmentReadToolName;
  static const int defaultMaxChars = 20000;
  static const int maxCharsLimit = 50000;
  static const int maxReadableBytes = 10 * 1024 * 1024;

  static const AIToolDefinition definition = AIToolDefinition(
    name: toolName,
    description:
        'Read the text content of an attachment from the current user '
        'message. The attachment manifest lists ids such as att1. Use start '
        'and max_chars to page through large files. Only text attachments '
        'can be read.',
    inputSchema: {
      'type': 'object',
      'properties': {
        'id': {
          'type': 'string',
          'description': 'Attachment id from the manifest, for example att1.',
        },
        'start': {
          'type': 'integer',
          'description':
              'Optional zero-based character offset. Defaults to 0.',
        },
        'max_chars': {
          'type': 'integer',
          'description':
              'Maximum characters to return, from 1 to $maxCharsLimit. '
              'Defaults to $defaultMaxChars.',
        },
      },
      'required': ['id'],
    },
  );

  final AttachmentToolContext context;
  final FileService _fileService;
  final bool enabled;

  @override
  List<AIToolDefinition> get tools {
    return enabled ? const [definition] : const [];
  }

  @override
  Future<AIToolResult> execute(AIToolCall call) async {
    final id = call.arguments['id']?.toString().trim() ?? '';
    if (id.isEmpty) {
      return _error(call, 'id is required');
    }

    final entry = context.resolve(id);
    if (entry == null) {
      final ids = context.entries.map((entry) => entry.id).join(', ');
      return _error(
        call,
        'Unknown attachment id "$id". Available ids: $ids.',
      );
    }

    final attachment = entry.attachment;
    final filePath = attachment.filePath;
    if (filePath == null || filePath.isEmpty) {
      return _error(call, 'Attachment "$id" has no file path.');
    }
    if (!await _fileService.fileExists(filePath)) {
      return _error(
        call,
        'Attachment "$id" file not found: ${attachment.fileName}.',
      );
    }

    try {
      final fileSize =
          attachment.fileSize ?? await _fileService.getFileSize(filePath);
      if (fileSize > maxReadableBytes) {
        return _error(
          call,
          'Attachment "$id" is too large to read as text '
          '(limit ${maxReadableBytes ~/ (1024 * 1024)} MB).',
        );
      }

      final start = _readOptionalInt(call.arguments['start'], 'start') ?? 0;
      if (start < 0) {
        throw const FormatException('start must be at least 0.');
      }

      final maxChars =
          _readOptionalInt(call.arguments['max_chars'], 'max_chars') ??
              defaultMaxChars;
      if (maxChars < 1 || maxChars > maxCharsLimit) {
        throw const FormatException(
          'max_chars must be between 1 and $maxCharsLimit.',
        );
      }

      final text = await _fileService.readTextFile(File(filePath));
      final total = text.length;
      final effectiveStart = start > total ? total : start;
      final end = effectiveStart + maxChars > total
          ? total
          : effectiveStart + maxChars;
      final content = text.substring(effectiveStart, end);
      final hasMore = end < total;

      return AIToolResult(
        toolCallId: call.id,
        name: call.name,
        content: jsonEncode({
          'id': id,
          'file_name': attachment.fileName,
          'mime_type': attachment.mimeType,
          'start': effectiveStart,
          'content': content,
          'total_characters': total,
          'has_more': hasMore,
          'next_start': hasMore ? end : null,
        }),
      );
    } on FormatException catch (error) {
      return _error(call, error.message);
    } catch (error) {
      return _error(call, error.toString());
    }
  }

  static int? _readOptionalInt(Object? raw, String key) {
    if (raw == null) return null;
    if (raw is int) return raw;
    if (raw is num) {
      if (raw % 1 != 0) {
        throw FormatException('$key must be an integer.');
      }
      return raw.toInt();
    }
    final parsed = int.tryParse(raw.toString().trim());
    if (parsed == null) {
      throw FormatException('$key must be an integer.');
    }
    return parsed;
  }

  static AIToolResult _error(AIToolCall call, String message) {
    return AIToolResult(
      toolCallId: call.id,
      name: call.name,
      content: jsonEncode({'error': message}),
      isError: true,
    );
  }
}
