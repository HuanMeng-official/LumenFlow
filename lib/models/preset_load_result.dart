import 'prompt_preset.dart';

/// 预设加载过程中可恢复的问题类型。
enum PresetIssueType {
  /// 所有可尝试的语言都没有内置预设元数据文件。
  builtInMetaMissing,

  /// 用户预设 JSON 无法解析（已尝试备份原文件）。
  userJsonCorrupt,

  /// 预设引用的角色卡文件不存在。
  cardFileMissing,

  /// 角色卡文件存在但读取失败。
  cardFileUnreadable,
}

/// 一条预设加载问题。
class PresetLoadIssue {
  const PresetLoadIssue({
    required this.type,
    required this.message,
    this.presetId,
  });

  final PresetIssueType type;

  /// 供日志和详情展示的原始诊断信息。
  final String message;

  /// 相关问题关联的预设 ID（如角色卡文件缺失时）。
  final String? presetId;

  @override
  String toString() => 'PresetLoadIssue($type, presetId: $presetId, $message)';
}

/// 预设加载结果：成功的预设与不阻断加载的问题。
class PresetLoadResult {
  const PresetLoadResult({required this.presets, this.issues = const []});

  final List<PromptPreset> presets;
  final List<PresetLoadIssue> issues;

  bool get hasIssues => issues.isNotEmpty;
}
