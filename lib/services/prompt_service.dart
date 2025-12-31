import 'dart:convert';
import 'dart:math';
import 'dart:io';
import 'package:flutter/services.dart';
import 'package:flutter/cupertino.dart';
import '../models/prompt_preset.dart';
import 'settings_service.dart';

/// 预设提示词服务，负责加载和管理预设提示词
class PromptService {
  final SettingsService _settingsService = SettingsService();

  /// 获取当前语言对应的预设文件路径
  Future<String> _getPresetsPath() async {
    final locale = await _settingsService.getLocale();
    return 'assets/prompt/presets-$locale.json';
  }

  /// 加载文件内容（支持XML、TXT等文本文件）
  Future<String> _loadFileContent(String filePath) async {
    try {
      final fullPath = 'assets/prompt/$filePath';
      debugPrint('Attempting to load file from: $fullPath');

      // 方法1: 使用rootBundle
      final content = await rootBundle.loadString(fullPath);
      debugPrint('Successfully loaded file via rootBundle: $fullPath, length: ${content.length} chars, ${utf8.encode(content).length} bytes');
      debugPrint('First 100 chars: ${content.substring(0, min(content.length, 100))}');
      if (content.length > 200) {
        debugPrint('Last 100 chars: ${content.substring(max(0, content.length - 100))}');
      }
      return content;
    } catch (e) {
      debugPrint('Failed to load file at assets/prompt/$filePath via rootBundle: $e');
      debugPrint('Error type: ${e.runtimeType}');

      // 方法2: 尝试直接文件读取作为备用
      try {
        final directPath = '${Directory.current.path}/$filePath';
        debugPrint('Trying alternative method with direct file path: $directPath');
        final file = File(directPath);
        if (await file.exists()) {
          final content = await file.readAsString();
          debugPrint('Successfully loaded file via direct file access, length: ${content.length}');
          return content;
        } else {
          debugPrint('File does not exist at: $directPath');
        }
      } catch (e2) {
        debugPrint('Alternative file loading also failed: $e2');
      }

      return '';
    }
  }

  /// 从JSON文件加载预设提示词列表
  Future<List<PromptPreset>> loadPresets() async {
    try {
      final presetsPath = await _getPresetsPath();
      debugPrint('Loading presets from: $presetsPath');
      final String jsonString = await rootBundle.loadString(presetsPath);
      debugPrint('JSON loaded, length: ${jsonString.length}');
      final List<dynamic> jsonList = jsonDecode(jsonString) as List<dynamic>;
      debugPrint('JSON parsed, ${jsonList.length} preset(s) found');
      final List<PromptPreset> presets = jsonList
          .map((item) => PromptPreset.fromJson(item as Map<String, dynamic>))
          .toList();

      // 处理文件引用（XML、TXT等）
      final List<PromptPreset> processedPresets = [];
      for (final preset in presets) {
        String systemPrompt = preset.systemPrompt;
        debugPrint('Processing preset: ${preset.name}, systemPrompt: ${systemPrompt.length > 50 ? '${systemPrompt.substring(0, 50)}...' : systemPrompt}');

        final trimmedPrompt = systemPrompt.trim();
        // 尝试将system_prompt作为文件路径加载
        debugPrint('Attempting to load file content from path: "$trimmedPrompt"');
        final fileContent = await _loadFileContent(trimmedPrompt);
        if (fileContent.isNotEmpty) {
          debugPrint('File content loaded successfully, length: ${fileContent.length} chars');
          systemPrompt = fileContent;
        } else {
          // 文件加载失败，检查是否是文件路径（包含路径分隔符或扩展名）
          final bool looksLikeFilePath = trimmedPrompt.contains('/') ||
                                         trimmedPrompt.contains('\\') ||
                                         trimmedPrompt.contains('.xml') ||
                                         trimmedPrompt.contains('.txt');
          if (looksLikeFilePath) {
            debugPrint('Warning: File path "$trimmedPrompt" exists but file could not be loaded or is empty');
            // 保持原始路径字符串，让用户知道问题
          } else {
            debugPrint('No file path detected, using as direct system prompt text');
            // 当作直接文本使用
          }
        }
        // 创建新的PromptPreset实例（因为原始实例的systemPrompt是final）
        final processedPreset = PromptPreset(
          id: preset.id,
          name: preset.name,
          description: preset.description,
          systemPrompt: systemPrompt,
          icon: preset.icon,
        );
        processedPresets.add(processedPreset);
      }

      debugPrint('Presets loading completed, ${processedPresets.length} preset(s) processed');
      // 调试：检查最终处理后的预设
      for (final preset in processedPresets) {
        final length = preset.systemPrompt.length;
        final preview = length > 100 ? '${preset.systemPrompt.substring(0, 100)}...' : preset.systemPrompt;
        debugPrint('Final preset: ${preset.name}, systemPrompt length: $length, preview: "$preview"');
      }
      return processedPresets;
    } catch (e) {
      debugPrint('Failed to load presets from JSON: $e');
      return [];
    }
  }

  /// 根据ID查找预设提示词
  Future<PromptPreset?> findPresetById(String id) async {
    final presets = await loadPresets();
    try {
      return presets.firstWhere((preset) => preset.id == id);
    } catch (e) {
      return null;
    }
  }

  /// 获取默认预设提示词（第一个）
  Future<PromptPreset?> getDefaultPreset() async {
    final presets = await loadPresets();
    return presets.isNotEmpty ? presets.first : null;
  }
}