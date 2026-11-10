import '../models/prompt_preset.dart';

/// 按语言或标签过滤预设。language 与 tag 同时传入时取标签优先。
List<PromptPreset> filterPresets(
  List<PromptPreset> presets, {
  String? language,
  String? tag,
}) {
  if (tag != null && tag.isNotEmpty) {
    return presets
        .where((preset) => preset.tags.contains(tag))
        .toList(growable: false);
  }
  if (language != null && language.isNotEmpty) {
    return presets
        .where((preset) => preset.language == language)
        .toList(growable: false);
  }
  return List<PromptPreset>.of(presets);
}
