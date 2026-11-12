import '../../models/attachment.dart';

/// Name of the request-scoped tool that reads text attachments.
const String attachmentReadToolName = 'builtin__read_attachment';

class AttachmentToolEntry {
  const AttachmentToolEntry({
    required this.id,
    required this.attachment,
  });

  final String id;
  final Attachment attachment;
}

/// A per-request view of text attachments.
///
/// It deliberately exposes short ids instead of file paths so the model can
/// only read attachments from the current user message.
class AttachmentToolContext {
  AttachmentToolContext.fromEntries(List<AttachmentToolEntry> entries)
      : entries = List.unmodifiable(entries);

  final List<AttachmentToolEntry> entries;

  /// Returns null unless every attachment is text-like.
  static AttachmentToolContext? fromTextAttachments(
    List<Attachment> attachments,
  ) {
    if (attachments.isEmpty) return null;
    if (!attachments.every(isTextAttachment)) return null;

    return AttachmentToolContext.fromEntries([
      for (var index = 0; index < attachments.length; index++)
        AttachmentToolEntry(
          id: 'att${index + 1}',
          attachment: attachments[index],
        ),
    ]);
  }

  static bool isTextAttachment(Attachment attachment) {
    final mimeType = attachment.mimeType?.trim().toLowerCase() ?? '';
    if (mimeType.startsWith('text/')) return true;

    final fileName = attachment.fileName.toLowerCase();
    final dot = fileName.lastIndexOf('.');
    if (dot < 0 || dot == fileName.length - 1) return false;
    return _textExtensions.contains(fileName.substring(dot));
  }

  static const Set<String> _textExtensions = {
    '.txt',
    '.md',
    '.markdown',
    '.csv',
    '.tsv',
    '.json',
    '.jsonl',
    '.xml',
    '.yaml',
    '.yml',
    '.toml',
    '.ini',
    '.log',
    '.cfg',
    '.conf',
    '.html',
    '.htm',
    '.css',
    '.scss',
    '.js',
    '.ts',
    '.jsx',
    '.tsx',
    '.dart',
    '.py',
    '.java',
    '.kt',
    '.swift',
    '.c',
    '.h',
    '.cpp',
    '.hpp',
    '.cs',
    '.go',
    '.rs',
    '.rb',
    '.php',
    '.sh',
    '.bash',
    '.ps1',
    '.sql',
    '.tex',
    '.rst',
  };

  String get manifest {
    final buffer = StringBuffer(
      '[Attachments available via $attachmentReadToolName]\n'
      'Use $attachmentReadToolName with an id below to read a file.\n',
    );
    for (final entry in entries) {
      final attachment = entry.attachment;
      buffer.writeln(
        '- ${entry.id}: ${attachment.fileName} '
        '(${attachment.mimeType ?? 'unknown MIME type'}, '
        '${_formatSize(attachment.fileSize)})',
      );
    }
    return buffer.toString().trimRight();
  }

  AttachmentToolEntry? resolve(String id) {
    for (final entry in entries) {
      if (entry.id == id) return entry;
    }
    return null;
  }

  static String _formatSize(int? bytes) {
    if (bytes == null) return 'unknown size';
    if (bytes < 1024) return '$bytes B';
    if (bytes < 1024 * 1024) {
      return '${(bytes / 1024).toStringAsFixed(1)} KB';
    }
    return '${(bytes / (1024 * 1024)).toStringAsFixed(1)} MB';
  }
}
