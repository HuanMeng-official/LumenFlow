import 'dart:convert';

import 'lumenflow_archive.dart';

/// 对话归档中的角色卡文件。
class CharacterArchiveFiles {
  const CharacterArchiveFiles({
    this.meta,
    required this.xml,
    this.worldInfo,
    this.avatar,
  });

  final List<int>? meta;
  final List<int> xml;
  final List<int>? worldInfo;
  final List<int>? avatar;
}

/// 对话 `.lumenflow` 归档的纯构建/解析层。
class ConversationArchivePayload {
  const ConversationArchivePayload({
    required this.conversation,
    required this.attachments,
    this.character,
  });

  final Map<String, dynamic> conversation;
  final Map<String, List<int>> attachments;
  final CharacterArchiveFiles? character;

  static ConversationArchivePayload parse(LumenflowArchive archive) {
    if (archive.manifest.type != LumenflowArchiveType.conversation) {
      throw const FormatException('Not a conversation archive');
    }

    final conversationBytes =
        archive.files['conversation/conversation.json'];
    if (conversationBytes == null) {
      throw const FormatException(
        'Missing conversation/conversation.json',
      );
    }

    final decoded = jsonDecode(utf8.decode(conversationBytes));
    if (decoded is! Map) {
      throw const FormatException('Invalid conversation JSON');
    }

    final attachments = <String, List<int>>{};
    for (final entry in archive.files.entries) {
      if (entry.key.startsWith('conversation/attachments/')) {
        attachments[entry.key] = entry.value;
      }
    }

    final xml = archive.files['character/character.xml'];
    CharacterArchiveFiles? character;
    if (xml != null) {
      character = CharacterArchiveFiles(
        meta: archive.files['character/meta.json'],
        xml: xml,
        worldInfo: archive.files['character/world_info.json'],
        avatar: archive.files['character/avatar.png'],
      );
    } else if (archive.manifest.includesCharacter) {
      throw const FormatException('Missing character/character.xml');
    }

    return ConversationArchivePayload(
      conversation: decoded.cast<String, dynamic>(),
      attachments: attachments,
      character: character,
    );
  }

  static List<int> buildArchive({
    required Map<String, dynamic> conversation,
    required Map<String, List<int>> attachments,
    CharacterArchiveFiles? character,
    required String title,
    required String language,
    String appVersion = 'unknown',
  }) {
    final files = <LumenflowArchiveFile>[
      LumenflowArchiveFile(
        path: 'conversation/conversation.json',
        role: 'conversation',
        bytes: utf8.encode(jsonEncode(conversation)),
      ),
      for (final entry in attachments.entries)
        LumenflowArchiveFile(
          path: _attachmentArchivePath(entry.key),
          role: 'attachment',
          bytes: entry.value,
        ),
      if (character != null) ...[
        if (character.meta != null)
          LumenflowArchiveFile(
            path: 'character/meta.json',
            role: 'meta',
            bytes: character.meta!,
          ),
        LumenflowArchiveFile(
          path: 'character/character.xml',
          role: 'character',
          bytes: character.xml,
        ),
        if (character.worldInfo != null)
          LumenflowArchiveFile(
            path: 'character/world_info.json',
            role: 'world_info',
            bytes: character.worldInfo!,
          ),
        if (character.avatar != null)
          LumenflowArchiveFile(
            path: 'character/avatar.png',
            role: 'avatar',
            bytes: character.avatar!,
          ),
      ],
    ];

    final manifest = LumenflowManifest(
      type: LumenflowArchiveType.conversation,
      created: DateTime.now().toUtc(),
      appVersion: appVersion,
      title: title,
      language: language,
      includesCharacter: character != null,
      files: const [],
    );

    return LumenflowArchive.write(manifest, files);
  }

  static String _attachmentArchivePath(String key) {
    final normalized = key.replaceAll('\\', '/');
    if (normalized.startsWith('conversation/attachments/')) {
      return normalized;
    }
    final relative = normalized.startsWith('/')
        ? normalized.substring(1)
        : normalized;
    return 'conversation/attachments/$relative';
  }
}
