import '../models/conversation_memory.dart';
import '../models/message.dart';
import '../utils/memory_fingerprint.dart';

/// 把导出的记忆接到导入后的新消息 ID 上。
///
/// 导入对话时消息会重新生成 ID，记忆里的覆盖边界和来源消息 ID 必须一起
/// 重映射；指纹也要按新 ID 重新计算，否则下一次发送会被误判为失效。
ConversationMemory remapImportedMemory(
  ConversationMemory memory, {
  required Map<String, String> messageIdMap,
  required List<Message> importedMessages,
}) {
  String? mapId(String? oldId) {
    if (oldId == null) return null;
    return messageIdMap[oldId];
  }

  final facts = <MemoryFact>[
    for (final fact in memory.facts)
      MemoryFact(
        id: fact.id,
        kind: fact.kind,
        text: fact.text,
        quote: fact.quote,
        status: fact.status,
        supersededBy: fact.supersededBy,
        sourceMessageId: mapId(fact.sourceMessageId),
        createdAt: fact.createdAt,
      ),
  ];
  final rejected = <RejectedProposal>[
    for (final entry in memory.rejected)
      RejectedProposal(
        id: entry.id,
        proposal: entry.proposal,
        reason: entry.reason,
        status: entry.status,
        sourceMessageId: mapId(entry.sourceMessageId),
        createdAt: entry.createdAt,
      ),
  ];

  final oldBoundary = memory.coveredUntilMessageId;
  if (oldBoundary == null) {
    return memory.copyWith(
      facts: facts,
      rejected: rejected,
      clearCoverage: true,
    );
  }

  final mappedBoundary = messageIdMap[oldBoundary];
  if (mappedBoundary == null) {
    return memory.copyWith(
      facts: facts,
      rejected: rejected,
      clearCoverage: true,
    );
  }

  final eligible = importedMessages
      .where(
        (message) =>
            message.status != MessageStatus.error &&
            message.content.trim().isNotEmpty,
      )
      .toList(growable: false);
  final index = eligible.indexWhere((message) => message.id == mappedBoundary);
  if (index == -1) {
    return memory.copyWith(
      facts: facts,
      rejected: rejected,
      clearCoverage: true,
    );
  }

  return memory.copyWith(
    facts: facts,
    rejected: rejected,
    coveredUntilMessageId: mappedBoundary,
    fingerprint: computeMemoryFingerprint(eligible.sublist(0, index + 1)),
  );
}
