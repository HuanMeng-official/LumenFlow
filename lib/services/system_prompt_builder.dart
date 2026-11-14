/// 组合系统提示词。
///
/// 顺序固定为：基础提示 → 自定义提示 → 角色卡前世界书 → 角色预设 →
/// 角色卡后世界书 → 主动记忆提示 → 按需检索提示 → 世界书 → 记忆。
/// 记忆放最后，既更靠近对话、又能让演变后的状态压过静态人设。
String composeSystemPrompt({
  required String basePrompt,
  required String customPrompt,
  required String presetPrompt,
  String beforePresetPrompt = '',
  String afterPresetPrompt = '',
  String noteInstruction = '',
  String recallInstruction = '',
  String worldInfoBlock = '',
  String memoryBlock = '',
}) {
  final sections = <String>[
    basePrompt,
    customPrompt,
    beforePresetPrompt,
    presetPrompt,
    afterPresetPrompt,
    noteInstruction,
    recallInstruction,
    worldInfoBlock,
    memoryBlock,
  ].map((section) => section.trim()).where((section) => section.isNotEmpty);

  return sections.join('\n\n');
}
