import 'dart:convert';
import 'package:flutter/services.dart';
import 'package:flutter/material.dart';
import '../models/prompt_preset.dart';

/// 预设提示词服务，负责加载和管理预设提示词
class PromptService {
  static const String _presetsPath = 'assets/prompt/presets.json';

  /// 从JSON文件加载预设提示词列表
  Future<List<PromptPreset>> loadPresets() async {
    try {
      final String jsonString = await rootBundle.loadString(_presetsPath);
      final List<dynamic> jsonList = jsonDecode(jsonString) as List<dynamic>;
      return jsonList
          .map((item) => PromptPreset.fromJson(item as Map<String, dynamic>))
          .toList();
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