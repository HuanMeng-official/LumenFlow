import 'dart:io';
import 'dart:convert';
import 'package:charset/charset.dart';
import 'package:path/path.dart' as path;
import '../utils/path_utils.dart';
import '../models/attachment.dart';

class FileService {
  int _importedAttachmentCounter = 0;
  int _attachmentCounter = 0;

  Future<String> saveAttachment(File file) async {
    final attachmentsDirPath = await PathUtils.getAttachmentsDirPath();
    final attachmentsDir = Directory(attachmentsDirPath);

    final stamp = DateTime.now().microsecondsSinceEpoch;
    final counter = _attachmentCounter++;
    final fileName =
        'attachment_${stamp}_$counter${path.extension(file.path)}';
    final savedFile = File('${attachmentsDir.path}/$fileName');

    await file.copy(savedFile.path);
    return savedFile.path;
  }

  /// 将导入包中的附件字节保存到本地附件目录。
  Future<String> saveAttachmentBytes(List<int> bytes, String fileName) async {
    final attachmentsDirPath = await PathUtils.getAttachmentsDirPath();
    final attachmentsDir = Directory(attachmentsDirPath);
    final extension = path.extension(fileName);
    final stamp = DateTime.now().microsecondsSinceEpoch;
    final counter = _importedAttachmentCounter++;
    final savedFile = File(
      path.join(attachmentsDir.path, 'imported_${stamp}_$counter$extension'),
    );

    await savedFile.writeAsBytes(bytes, flush: true);
    return savedFile.path;
  }

  Future<void> deleteAttachment(String? filePath) async {
    if (filePath == null) return;

    final file = File(filePath);
    if (await file.exists()) {
      await file.delete();
    }
  }

  Future<Attachment> createAttachmentFromFile(
    File file, {
    String? displayName,
  }) async {
    final stats = await file.stat();
    final fileName = displayName ?? path.basename(file.path);
    final extension = path.extension(file.path).toLowerCase();

    String? mimeType;
    if (extension == '.jpg' || extension == '.jpeg') {
      mimeType = 'image/jpeg';
    } else if (extension == '.png') {
      mimeType = 'image/png';
    } else if (extension == '.gif') {
      mimeType = 'image/gif';
    } else if (extension == '.bmp') {
      mimeType = 'image/bmp';
    } else if (extension == '.webp') {
      mimeType = 'image/webp';
    } else if (extension == '.pdf') {
      mimeType = 'application/pdf';
    } else if (extension == '.txt') {
      mimeType = 'text/plain';
    } else if (extension == '.md') {
      mimeType = 'text/markdown';
    } else if (extension == '.doc' || extension == '.docx') {
      mimeType = 'application/msword';
    } else if (extension == '.mp3') {
      mimeType = 'audio/mpeg';
    } else if (extension == '.mp4') {
      mimeType = 'video/mp4';
    } else {
      mimeType = 'application/octet-stream';
    }

    return Attachment(
      id: '${DateTime.now().microsecondsSinceEpoch}_${_attachmentCounter++}',
      fileName: fileName,
      filePath: file.path,
      type: Attachment.getTypeFromFile(file),
      fileSize: stats.size,
      mimeType: mimeType,
    );
  }

  Future<Attachment?> saveFileAndCreateAttachment(
    File file, {
    String? displayName,
  }) async {
    try {
      final savedPath = await saveAttachment(file);
      final savedFile = File(savedPath);
      return await createAttachmentFromFile(
        savedFile,
        displayName: displayName,
      );
    } catch (e) {
      return null;
    }
  }

  Future<String> getFileBase64(File file) async {
    final bytes = await file.readAsBytes();
    return base64Encode(bytes);
  }

  Future<String> getFileDataUrl(File file, String? mimeType) async {
    final bytes = await file.readAsBytes();
    final base64 = base64Encode(bytes);
    final actualMimeType = mimeType ?? 'application/octet-stream';
    return 'data:$actualMimeType;base64,$base64';
  }

  /// Reads a text file, detecting common encodings.
  ///
  /// Dart's default UTF-8 decoder throws on GBK/UTF-16 text, which used to
  /// surface as "cannot read content" to the model. This tries BOMs first,
  /// then strict UTF-8, GBK, and finally Latin-1.
  Future<String> readTextFile(File file) async {
    final bytes = await file.readAsBytes();
    return _decodeTextBytes(bytes);
  }

  static String _decodeTextBytes(List<int> bytes) {
    if (bytes.isEmpty) return '';

    if (_hasUtf8Bom(bytes)) {
      try {
        return utf8.decode(bytes.sublist(3));
      } on FormatException {
        // Fall through to the other decoders.
      }
    }

    if (_hasUtf32Bom(bytes)) {
      try {
        return utf32.decode(bytes);
      } on FormatException {
        // Fall through to the other decoders.
      }
    }

    if (_hasUtf16Bom(bytes)) {
      try {
        return utf16.decode(bytes);
      } on FormatException {
        // Fall through to the other decoders.
      }
    }

    if (_looksBinary(bytes)) {
      throw const FormatException('Binary content cannot be read as text.');
    }

    try {
      return utf8.decode(bytes);
    } on FormatException {
      // Not valid UTF-8.
    }

    try {
      return gbk.decode(bytes);
    } on FormatException {
      // Not valid GBK.
    }

    return latin1.decode(bytes);
  }

  static bool _hasUtf8Bom(List<int> bytes) {
    return bytes.length >= 3 &&
        bytes[0] == 0xEF &&
        bytes[1] == 0xBB &&
        bytes[2] == 0xBF;
  }

  static bool _hasUtf16Bom(List<int> bytes) {
    if (bytes.length < 2) return false;
    return (bytes[0] == 0xFF && bytes[1] == 0xFE) ||
        (bytes[0] == 0xFE && bytes[1] == 0xFF);
  }

  static bool _hasUtf32Bom(List<int> bytes) {
    if (bytes.length < 4) return false;
    return (bytes[0] == 0xFF &&
            bytes[1] == 0xFE &&
            bytes[2] == 0x00 &&
            bytes[3] == 0x00) ||
        (bytes[0] == 0x00 &&
            bytes[1] == 0x00 &&
            bytes[2] == 0xFE &&
            bytes[3] == 0xFF);
  }

  static bool _looksBinary(List<int> bytes) {
    if (_hasBinarySignature(bytes)) return true;
    final limit = bytes.length < 8192 ? bytes.length : 8192;
    for (var index = 0; index < limit; index++) {
      if (bytes[index] == 0) return true;
    }
    return false;
  }

  static bool _hasBinarySignature(List<int> bytes) {
    if (bytes.length >= 5 &&
        bytes[0] == 0x25 &&
        bytes[1] == 0x50 &&
        bytes[2] == 0x44 &&
        bytes[3] == 0x46 &&
        bytes[4] == 0x2D) {
      return true; // %PDF-
    }
    if (bytes.length >= 4 &&
        bytes[0] == 0x50 &&
        bytes[1] == 0x4B &&
        bytes[2] == 0x03 &&
        bytes[3] == 0x04) {
      return true; // ZIP (including docx/xlsx/pptx)
    }
    if (bytes.length >= 4 &&
        bytes[0] == 0xD0 &&
        bytes[1] == 0xCF &&
        bytes[2] == 0x11 &&
        bytes[3] == 0xE0) {
      return true; // OLE (doc/xls/ppt)
    }
    return false;
  }

  Future<void> cleanupOldAttachments({int days = 30}) async {
    final attachmentsDirPath = await PathUtils.getAttachmentsDirPath();
    final attachmentsDir = Directory(attachmentsDirPath);

    if (!await attachmentsDir.exists()) return;

    final cutoffDate = DateTime.now().subtract(Duration(days: days));
    final files = await attachmentsDir.list().toList();

    for (final file in files) {
      if (file is File) {
        final stat = await file.stat();
        if (stat.modified.isBefore(cutoffDate)) {
          await file.delete();
        }
      }
    }
  }

  Future<String> getAttachmentsDirPath() async {
    return await PathUtils.getAttachmentsDirPath();
  }

  Future<bool> fileExists(String filePath) async {
    final file = File(filePath);
    return await file.exists();
  }

  Future<int> getFileSize(String filePath) async {
    final file = File(filePath);
    final stats = await file.stat();
    return stats.size;
  }
}
