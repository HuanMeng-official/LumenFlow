import 'dart:convert';
import 'dart:io';
import 'package:flutter/services.dart';
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

      // 方法1: 使用rootBundle
      final content = await rootBundle.loadString(fullPath);
      return content;
    } catch (_) {
      // 方法2: 尝试直接文件读取作为备用
      try {
        final directPath = '${Directory.current.path}/$filePath';
        final file = File(directPath);
        if (await file.exists()) {
          return await file.readAsString();
        }
      } catch (_) {
        // Direct file access is a best-effort fallback.
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
    } catch (_) {
      // Missing or unreadable files are expected.
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
    } catch (_) {
      // Persisting presets is best-effort.
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

      return preset;
    } catch (e) {
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
    } catch (_) {
      // Invalid XML falls back to an empty role name.
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

    } catch (e) {
      rethrow;
    }
  }

  /// 从JSON文件加载内置预设提示词列表
  Future<List<PromptPreset>> _loadBuiltInPresets() async {
    try {
      final presetsPath = await _getPresetsPath();
      final String jsonString = await rootBundle.loadString(presetsPath);
      final List<dynamic> jsonList = jsonDecode(jsonString) as List<dynamic>;
      final List<PromptPreset> presets = jsonList
          .map((item) => PromptPreset.fromJson(item as Map<String, dynamic>))
          .toList();

      // 处理文件引用（XML、TXT等）
      final List<PromptPreset> processedPresets = [];
      for (final preset in presets) {
        String systemPrompt = preset.systemPrompt;

        final trimmedPrompt = systemPrompt.trim();
        // 尝试将system_prompt作为文件路径加载
        final fileContent = await _loadFileContent(trimmedPrompt);
        if (fileContent.isNotEmpty) {
          systemPrompt = fileContent;
        } else {
          // 文件加载失败，检查是否是文件路径（包含路径分隔符或扩展名）
          final bool looksLikeFilePath = trimmedPrompt.contains('/') ||
                                         trimmedPrompt.contains('\\') ||
                                         trimmedPrompt.contains('.xml') ||
                                         trimmedPrompt.contains('.txt');
          if (looksLikeFilePath) {
            // 保持原始路径字符串，让用户知道问题
          } else {
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

      return processedPresets;
    } catch (e) {
      return [];
    }
  }

  /// 从JSON文件加载预设提示词列表（包含内置和用户预设）
  Future<List<PromptPreset>> loadPresets() async {
    final builtInPresets = await _loadBuiltInPresets();
    final userPresets = await loadUserPresets();
    final allPresets = [...builtInPresets, ...userPresets];
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