import 'package:file_picker/file_picker.dart';
import 'package:flutter/foundation.dart';

/// Android / iOS 的系统选择器按 MIME 类型过滤。`.lumenflow` 没有系统认识的
/// MIME 类型，一旦同时要求 json、xml 等已知类型，系统只显示已知 MIME 的
/// 文件，`.lumenflow` 会被直接过滤掉。
///
/// 移动端退回 `*/*`，由调用方用 [hasAllowedImportExtension] 自行校验扩展名。
bool get useAnyFileTypeForImport {
  return defaultTargetPlatform == TargetPlatform.android ||
      defaultTargetPlatform == TargetPlatform.iOS;
}

Future<PlatformFile?> pickImportFile({
  required List<String> allowedExtensions,
  String? dialogTitle,
}) {
  final unrestricted = useAnyFileTypeForImport;
  return FilePicker.pickFile(
    type: unrestricted ? FileType.any : FileType.custom,
    allowedExtensions: unrestricted ? null : allowedExtensions,
    dialogTitle: dialogTitle,
  );
}

/// 扩展名比较不区分大小写；[allowedExtensions] 不包含点号。
bool hasAllowedImportExtension(
  String fileName,
  Iterable<String> allowedExtensions,
) {
  final lowerName = fileName.toLowerCase();
  return allowedExtensions.any(
    (extension) => lowerName.endsWith('.${extension.toLowerCase()}'),
  );
}
