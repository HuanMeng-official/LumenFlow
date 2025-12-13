import 'dart:io';

enum AttachmentType {
  image,
  document,
  audio,
  video,
  other,
}

class Attachment {
  final String id;
  final String fileName;
  final String? filePath;
  final String? url;
  final AttachmentType type;
  final int? fileSize;
  final String? mimeType;
  final DateTime createdAt;

  Attachment({
    required this.id,
    required this.fileName,
    this.filePath,
    this.url,
    required this.type,
    this.fileSize,
    this.mimeType,
    DateTime? createdAt,
  }) : createdAt = createdAt ?? DateTime.now();

  factory Attachment.fromJson(Map<String, dynamic> json) {
    return Attachment(
      id: json['id'],
      fileName: json['fileName'],
      filePath: json['filePath'],
      url: json['url'],
      type: AttachmentType.values[json['type']],
      fileSize: json['fileSize'],
      mimeType: json['mimeType'],
      createdAt: DateTime.parse(json['createdAt']),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'fileName': fileName,
      'filePath': filePath,
      'url': url,
      'type': type.index,
      'fileSize': fileSize,
      'mimeType': mimeType,
      'createdAt': createdAt.toIso8601String(),
    };
  }

  static AttachmentType getTypeFromMime(String mimeType) {
    if (mimeType.startsWith('image/')) {
      return AttachmentType.image;
    } else if (mimeType.startsWith('audio/')) {
      return AttachmentType.audio;
    } else if (mimeType.startsWith('video/')) {
      return AttachmentType.video;
    } else if (mimeType.contains('pdf') ||
        mimeType.contains('document') ||
        mimeType.contains('text')) {
      return AttachmentType.document;
    } else {
      return AttachmentType.other;
    }
  }

  static AttachmentType getTypeFromFile(File file) {
    final extension = file.path.toLowerCase().split('.').last;
    switch (extension) {
      case 'jpg':
      case 'jpeg':
      case 'png':
      case 'gif':
      case 'bmp':
      case 'webp':
        return AttachmentType.image;
      case 'mp3':
      case 'wav':
      case 'ogg':
      case 'm4a':
        return AttachmentType.audio;
      case 'mp4':
      case 'mov':
      case 'avi':
      case 'mkv':
      case 'webm':
        return AttachmentType.video;
      case 'pdf':
      case 'doc':
      case 'docx':
      case 'txt':
      case 'md':
        return AttachmentType.document;
      default:
        return AttachmentType.other;
    }
  }
}
