import 'dart:io';
import 'dart:convert';
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
      print('Error saving file and creating attachment: $e');
      return null;
    }
  }

  // 获取文件的Base64编码（用于API上传）
  Future<String> getFileBase64(File file) async {
    final bytes = await file.readAsBytes();
    return base64Encode(bytes);
  }

  // 获取文件内容（文本文件）
  Future<String> readTextFile(File file) async {
    return await file.readAsString();
  }

  // 清理旧附件（可选功能）
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

  // 获取附件目录路径
  Future<String> getAttachmentsDirPath() async {
    final appDir = await getApplicationDocumentsDirectory();
    return '${appDir.path}/$_attachmentsDirName';
  }

  // 检查文件是否存在
  Future<bool> fileExists(String filePath) async {
    final file = File(filePath);
    return await file.exists();
  }

  // 获取文件大小
  Future<int> getFileSize(String filePath) async {
    final file = File(filePath);
    final stats = await file.stat();
    return stats.size;
  }
}