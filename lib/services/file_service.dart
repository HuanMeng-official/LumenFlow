import 'dart:io';
import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:path_provider/path_provider.dart';
import 'package:path/path.dart' as path;
import '../models/attachment.dart';

class FileService {
  static const String _attachmentsDirName = 'attachments';

  Future<String> saveAttachment(File file) async {
    final appDir = await getApplicationDocumentsDirectory();
    final attachmentsDir = Directory('${appDir.path}/$_attachmentsDirName');

    if (!await attachmentsDir.exists()) {
      await attachmentsDir.create(recursive: true);
    }

    final fileName = 'attachment_${DateTime.now().millisecondsSinceEpoch}${path.extension(file.path)}';
    final savedFile = File('${attachmentsDir.path}/$fileName');

    await file.copy(savedFile.path);
    return savedFile.path;
  }

  Future<void> deleteAttachment(String? filePath) async {
    if (filePath == null) return;

    final file = File(filePath);
    if (await file.exists()) {
      await file.delete();
    }
  }

  Future<Attachment> createAttachmentFromFile(File file) async {
    final stats = await file.stat();
    final fileName = path.basename(file.path);
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
      id: DateTime.now().millisecondsSinceEpoch.toString(),
      fileName: fileName,
      filePath: file.path,
      type: Attachment.getTypeFromFile(file),
      fileSize: stats.size,
      mimeType: mimeType,
    );
  }

  Future<Attachment?> saveFileAndCreateAttachment(File file) async {
    try {
      final savedPath = await saveAttachment(file);
      final savedFile = File(savedPath);
      return await createAttachmentFromFile(savedFile);
    } catch (e) {
      debugPrint('Error saving file and creating attachment: $e');
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

  Future<String> readTextFile(File file) async {
    return await file.readAsString();
  }

  Future<void> cleanupOldAttachments({int days = 30}) async {
    final appDir = await getApplicationDocumentsDirectory();
    final attachmentsDir = Directory('${appDir.path}/$_attachmentsDirName');

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
    final appDir = await getApplicationDocumentsDirectory();
    return '${appDir.path}/$_attachmentsDirName';
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