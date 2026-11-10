import 'prompt_preset.dart';

/// 角色卡导入校验中的阻断性错误。
enum PresetValidationError {
  emptyFile,
  fileTooLarge,
  invalidUtf8,
  invalidXml,
  invalidRoot,
}

/// 角色卡导入校验中的警告（可继续导入）。
enum PresetValidationWarning { missingRoleName }

/// 角色卡文件校验结果。
class PresetValidationResult {
  const PresetValidationResult({
    required this.errors,
    required this.warnings,
    this.content = '',
    this.extractedName,
    this.contentHash,
  });

  final List<PresetValidationError> errors;
  final List<PresetValidationWarning> warnings;

  /// 规范化换行和首尾空白后的 XML 文本。
  final String content;

  /// 从 `<role_name>` 提取的名称。
  final String? extractedName;

  /// 规范化内容的 sha256。
  final String? contentHash;

  bool get isValid => errors.isEmpty;
}

/// 导入被校验错误拒绝时抛出。
class PresetValidationException implements Exception {
  const PresetValidationException(this.validation);

  final PresetValidationResult validation;

  @override
  String toString() => 'PresetValidationException(${validation.errors})';
}

/// 发现重复角色卡时抛出，调用方可确认后以 allowDuplicate 重新导入。
class PresetDuplicateException implements Exception {
  const PresetDuplicateException({
    required this.existing,
    required this.validation,
  });

  final PromptPreset existing;
  final PresetValidationResult validation;

  @override
  String toString() => 'PresetDuplicateException($existing)';
}
