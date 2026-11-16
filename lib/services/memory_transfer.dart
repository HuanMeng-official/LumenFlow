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
    // 分叉/导入只保留了记忆边界之前的消息。此时原摘要、情绪、账本都
    // 描述的是边界之后（分支里不存在）的事件，不能只清空覆盖边界留着
    // 它们，否则会在更早的分支里出现“未来记忆”。
    return ConversationMemory.empty();
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
    // 边界消息存在但不可用于记忆（错误/空消息）时同样丢弃整份记忆。
    return ConversationMemory.empty();
  }

  return memory.copyWith(
    facts: facts,
    rejected: rejected,
    coveredUntilMessageId: mappedBoundary,
    fingerprint: computeMemoryFingerprint(eligible.sublist(0, index + 1)),
  );
}
