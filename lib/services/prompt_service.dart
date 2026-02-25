import 'dart:convert';
import 'dart:math';
import 'dart:io';
import 'package:flutter/services.dart';
import 'package:flutter/cupertino.dart';
import 'package:path/path.dart' as path;
import '../models/prompt_preset.dart';
import 'settings_service.dart';
import '../utils/path_utils.dart';

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

  /// 获取用户预设存储目录
  Future<Directory> _getUserPresetsDirectory() async {
    final appDataDir = await PathUtils.getAppDataDirectory();
    final userPresetsDir = Directory(path.join(appDataDir.path, 'user_prompts'));
    if (!await userPresetsDir.exists()) {
      await userPresetsDir.create(recursive: true);
    }
    return userPresetsDir;
  }

  /// 获取用户预设JSON文件路径
  Future<File> _getUserPresetsFile() async {
    final dir = await _getUserPresetsDirectory();
    return File(path.join(dir.path, 'user_presets.json'));
  }

  /// 加载用户预设列表
  Future<List<PromptPreset>> loadUserPresets() async {
    try {
      final userPresetsFile = await _getUserPresetsFile();
      if (!await userPresetsFile.exists()) {
        return [];
      }
      final String jsonString = await userPresetsFile.readAsString();
      final List<dynamic> jsonList = jsonDecode(jsonString) as List<dynamic>;
      final List<PromptPreset> presets = jsonList
          .map((item) => PromptPreset.fromJson(item as Map<String, dynamic>))
          .toList();

      // 处理文件引用（XML、TXT等）
      final List<PromptPreset> processedPresets = [];
      for (final preset in presets) {
        String systemPrompt = preset.systemPrompt;
        final trimmedPrompt = systemPrompt.trim();

        // 尝试将system_prompt作为文件路径加载（相对于用户预设目录）
        final fileContent = await _loadUserFileContent(trimmedPrompt);
        if (fileContent.isNotEmpty) {
          systemPrompt = fileContent;
        } else {
          // 检查是否是文件路径
          final bool looksLikeFilePath = trimmedPrompt.contains('/') ||
                                         trimmedPrompt.contains('\\') ||
                                         trimmedPrompt.contains('.xml') ||
                                         trimmedPrompt.contains('.txt');
          if (looksLikeFilePath) {
            debugPrint('Warning: User file path "$trimmedPrompt" could not be loaded or is empty');
          }
        }
        final processedPreset = PromptPreset(
          id: preset.id,
          name: preset.name,
          description: preset.description,
          author: preset.author,
          version: preset.version,
          systemPrompt: systemPrompt,
          icon: preset.icon,
        );
        processedPresets.add(processedPreset);
      }
      return processedPresets;
    } catch (e) {
      debugPrint('Failed to load user presets: $e');
      return [];
    }
  }

  /// 加载用户文件内容（从用户预设目录）
  Future<String> _loadUserFileContent(String filePath) async {
    try {
      final userPresetsDir = await _getUserPresetsDirectory();
      final fullPath = path.join(userPresetsDir.path, filePath);
      final file = File(fullPath);
      if (await file.exists()) {
        final content = await file.readAsString();
        return content;
      }
    } catch (e) {
      debugPrint('Failed to load user file: $e');
    }
    return '';
  }

  /// 保存用户预设列表到JSON文件
  Future<void> _saveUserPresets(List<PromptPreset> presets) async {
    try {
      final userPresetsFile = await _getUserPresetsFile();
      final jsonList = presets.map((preset) => preset.toJson()).toList();
      final jsonString = jsonEncode(jsonList);
      await userPresetsFile.writeAsString(jsonString);
    } catch (e) {
      debugPrint('Failed to save user presets: $e');
    }
  }

  /// 导入XML文件作为用户预设
  Future<PromptPreset> importPresetFromXml(File xmlFile, {
    String? name,
    String? description,
    String? author,
    String? version,
  }) async {
    try {
      // 读取XML内容
      final xmlContent = await xmlFile.readAsString();
      if (xmlContent.isEmpty) {
        throw Exception('XML文件为空');
      }

      // 尝试从XML中提取角色名称
      String extractedName = name ?? _extractRoleNameFromXml(xmlContent);
      if (extractedName.isEmpty) {
        extractedName = path.basenameWithoutExtension(xmlFile.path);
      }

      // 生成唯一ID
      final id = 'user_${DateTime.now().millisecondsSinceEpoch}';

      // 将XML文件复制到用户预设目录
      final userPresetsDir = await _getUserPresetsDirectory();
      final fileName = '$id.xml';
      final destFile = File(path.join(userPresetsDir.path, fileName));
      await destFile.writeAsString(xmlContent);

      // 创建预设对象
      final preset = PromptPreset(
        id: id,
        name: extractedName,
        description: description ?? '用户导入的预设',
        author: author ?? '用户',
        version: version ?? 'v1.0',
        systemPrompt: fileName, // 存储相对路径
        icon: 'person.fill',
      );

      // 添加到用户预设列表
      final currentPresets = await loadUserPresets();
      currentPresets.add(preset);
      await _saveUserPresets(currentPresets);

      debugPrint('Preset imported successfully: ${preset.name} (ID: ${preset.id})');
      return preset;
    } catch (e) {
      debugPrint('Failed to import preset from XML: $e');
      rethrow;
    }
  }

  /// 从XML内容中提取角色名称
  String _extractRoleNameFromXml(String xmlContent) {
    try {
      final roleNameMatch = RegExp(r'<role_name>(.*?)</role_name>').firstMatch(xmlContent);
      if (roleNameMatch != null) {
        return roleNameMatch.group(1)!.trim();
      }
    } catch (e) {
      debugPrint('Failed to extract role name from XML: $e');
    }
    return '';
  }

  /// 删除用户预设
  Future<void> deleteUserPreset(String id) async {
    try {
      final currentPresets = await loadUserPresets();
      final presetToDelete = currentPresets.firstWhere((preset) => preset.id == id);

      // 删除关联的XML文件
      final userPresetsDir = await _getUserPresetsDirectory();
      final fileName = presetToDelete.systemPrompt.trim();
      final xmlFile = File(path.join(userPresetsDir.path, fileName));
      if (await xmlFile.exists()) {
        await xmlFile.delete();
      }

      // 从列表中移除
      currentPresets.removeWhere((preset) => preset.id == id);
      await _saveUserPresets(currentPresets);

      debugPrint('User preset deleted: $id');
    } catch (e) {
      debugPrint('Failed to delete user preset: $e');
      rethrow;
    }
  }

  /// 从JSON文件加载内置预设提示词列表
  Future<List<PromptPreset>> _loadBuiltInPresets() async {
    try {
      final presetsPath = await _getPresetsPath();
      debugPrint('Loading built-in presets from: $presetsPath');
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
          author: preset.author,
          version: preset.version,
          systemPrompt: systemPrompt,
          icon: preset.icon,
        );
        processedPresets.add(processedPreset);
      }

      debugPrint('Built-in presets loading completed, ${processedPresets.length} preset(s) processed');
      // 调试：检查最终处理后的预设
      for (final preset in processedPresets) {
        final length = preset.systemPrompt.length;
        final preview = length > 100 ? '${preset.systemPrompt.substring(0, 100)}...' : preset.systemPrompt;
        debugPrint('Final preset: ${preset.name}, systemPrompt length: $length, preview: "$preview"');
      }
      return processedPresets;
    } catch (e) {
      debugPrint('Failed to load built-in presets from JSON: $e');
      return [];
    }
  }

  /// 从JSON文件加载预设提示词列表（包含内置和用户预设）
  Future<List<PromptPreset>> loadPresets() async {
    final builtInPresets = await _loadBuiltInPresets();
    final userPresets = await loadUserPresets();
    final allPresets = [...builtInPresets, ...userPresets];
    debugPrint('Total presets loaded: ${allPresets.length} (${builtInPresets.length} built-in, ${userPresets.length} user)');
    return allPresets;
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