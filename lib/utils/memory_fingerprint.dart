import 'dart:convert';

import 'package:crypto/crypto.dart';

import '../models/message.dart';

/// 对被记忆覆盖的消息做内容指纹。
///
/// 会话保存会整表重写消息；单看“边界消息还在不在”无法发现中间某条被编辑
/// 或删除。指纹变化即视为记忆失效，需要重建。
String computeMemoryFingerprint(Iterable<Message> messages) {
  final buffer = StringBuffer();
  for (final message in messages) {
    buffer
      ..write(message.id)
      ..write('|')
      ..write(message.timestamp.millisecondsSinceEpoch)
      ..write('|')
      ..write(message.isUser ? 'u' : 'a')
      ..write('|')
      ..write(message.content)
      ..write('\n');
  }
  return sha256.convert(utf8.encode(buffer.toString())).toString();
}
