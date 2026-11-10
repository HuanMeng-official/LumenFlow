import 'dart:io';

import 'package:flutter/foundation.dart';

import '../models/preset_load_result.dart';
import '../models/prompt_preset.dart';
import 'prompt_service.dart';
import 'settings_service.dart';

/// 全局角色预设仓库。
///
/// 聊天页和预设管理页共享同一份列表与加载问题；任何写操作完成后都会
/// [notifyListeners]，因此管理页导入后切回聊天页即可看到新预设。
class PresetRepository extends ChangeNotifier {
  PresetRepository({
    PromptService? promptService,
    SettingsService? settingsService,
  }) : _promptService = promptService ?? PromptService(),
       _settingsService = settingsService ?? SettingsService();

  static final PresetRepository instance = PresetRepository();

  final PromptService _promptService;
  final SettingsService _settingsService;

  List<PromptPreset> _presets = const [];
  List<PresetLoadIssue> _issues = const [];
  bool _isLoading = false;
  bool _isLoaded = false;
  String? _loadedLocale;
  Future<void>? _loadFuture;

  List<PromptPreset> get presets => _presets;
  List<PresetLoadIssue> get issues => _issues;
  bool get isLoading => _isLoading;

  PromptService get promptService => _promptService;

  /// 确保列表已加载；语言变化或 [force] 时重新加载。
  Future<void> ensureLoaded({bool force = false}) async {
    final active = _loadFuture;
    if (active != null) {
      await active;
      if (!force) return;
    }

    final future = _ensureLoaded(force: force);
    _loadFuture = future;
    try {
      await future;
    } finally {
      if (identical(_loadFuture, future)) {
        _loadFuture = null;
      }
    }
  }

  Future<void> _ensureLoaded({required bool force}) async {
    final locale = await _settingsService.getLocale();
    if (!force && _isLoaded && _loadedLocale == locale) return;

    _isLoading = true;
    notifyListeners();
    try {
      final result = await _promptService.loadPresets();
      _presets = result.presets;
      _issues = result.issues;
      _loadedLocale = locale;
      _isLoaded = true;
      for (final issue in result.issues) {
        debugPrint('Prompt preset issue: $issue');
      }
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  Future<PromptPreset> importPreset(
    File file, {
    String? name,
    String? description,
    String? author,
    String? version,
    String? icon,
    String? language,
    List<String>? tags,
    bool allowDuplicate = false,
  }) async {
    final preset = await _promptService.importPresetFromXml(
      file,
      name: name,
      description: description,
      author: author,
      version: version,
      icon: icon,
      language: language,
      tags: tags,
      allowDuplicate: allowDuplicate,
    );
    await ensureLoaded(force: true);
    return preset;
  }

  Future<PromptPreset> importTextPreset(
    File file, {
    String? name,
    String? description,
    String? author,
    String? version,
    String? icon,
    String? language,
    List<String>? tags,
    bool allowDuplicate = false,
  }) async {
    final preset = await _promptService.importPresetFromText(
      file,
      name: name,
      description: description,
      author: author,
      version: version,
      icon: icon,
      language: language,
      tags: tags,
      allowDuplicate: allowDuplicate,
    );
    await ensureLoaded(force: true);
    return preset;
  }

  Future<void> updatePreset(PromptPreset preset) async {
    await _promptService.updateUserPreset(preset);
    await ensureLoaded(force: true);
  }

  Future<PromptPreset> duplicatePreset(
    PromptPreset source, {
    required String name,
  }) async {
    final preset = await _promptService.duplicatePreset(source, name: name);
    await ensureLoaded(force: true);
    return preset;
  }

  Future<void> deletePreset(String id) async {
    await _promptService.deleteUserPreset(id);
    await ensureLoaded(force: true);
  }
}
