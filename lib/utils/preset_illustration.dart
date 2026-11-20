import 'dart:io';

import 'package:flutter/painting.dart';
import 'package:path/path.dart' as path;

import '../models/prompt_preset.dart';

/// 内置角色卡的立绘资源路径（相对 `assets/prompt/`）。
///
/// 优先使用预设里显式声明的 `illustration_file`；旧内置数据没有该字段时，
/// 回退到 `characters/img/illustration/<角色卡文件名>.png`。
String? builtInIllustrationAssetPath(PromptPreset preset) {
  final explicit = preset.illustrationFile?.trim();
  if (explicit != null && explicit.isNotEmpty) return explicit;
  final promptFile = preset.promptFile?.trim();
  if (promptFile == null || promptFile.isEmpty) return null;
  final base = path.basenameWithoutExtension(promptFile).toLowerCase();
  return 'characters/img/illustration/$base.png';
}

/// 解析角色卡的立绘图片源：支持按当前成长阶段优先读取阶段差分图，缺失时回退默认立绘。
ImageProvider? presetIllustrationProvider(
  PromptPreset preset, {
  String? stageId,
}) {
  final stageKey = stageId?.trim();
  if (stageKey != null && stageKey.isNotEmpty) {
    final stageFilePath = preset.stageIllustrationPaths[stageKey];
    if (stageFilePath != null &&
        stageFilePath.isNotEmpty &&
        File(stageFilePath).existsSync()) {
      return FileImage(File(stageFilePath));
    }
    if (!preset.isUserPreset) {
      final stageAsset = preset.growthConfig
          ?.stageById(stageKey)
          ?.illustrationFile
          ?.trim();
      if (stageAsset != null && stageAsset.isNotEmpty) {
        return AssetImage('assets/prompt/$stageAsset');
      }
    }
  }
  final filePath = preset.illustrationPath;
  if (filePath != null && filePath.isNotEmpty && File(filePath).existsSync()) {
    return FileImage(File(filePath));
  }
  if (preset.isUserPreset) return null;
  final assetPath = builtInIllustrationAssetPath(preset);
  return assetPath == null ? null : AssetImage('assets/prompt/$assetPath');
}
