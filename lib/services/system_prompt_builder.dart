/// 组合系统提示词。
///
/// 顺序固定为：基础提示 → 自定义提示 → 角色预设 → 主动记忆提示 →
/// 按需检索提示 → 记忆。记忆放最后，既更靠近对话、又能让演变后的状态压过
/// 静态人设，同时保留稳定前缀的缓存收益。
String composeSystemPrompt({
  required String basePrompt,
  required String customPrompt,
  required String presetPrompt,
  String noteInstruction = '',
  String recallInstruction = '',
  String memoryBlock = '',
}) {
  final sections = <String>[
    basePrompt,
    customPrompt,
    presetPrompt,
    noteInstruction,
    recallInstruction,
    memoryBlock,
  ].map((section) => section.trim()).where((section) => section.isNotEmpty);

  return sections.join('\n\n');
}
