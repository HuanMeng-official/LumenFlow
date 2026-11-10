import 'dart:collection';
import 'dart:convert';
import 'dart:io';

import 'package:crypto/crypto.dart';
import 'package:flutter/services.dart';
import 'package:path/path.dart' as path;
import 'package:xml/xml.dart';

import '../models/preset_import_result.dart';
import '../models/preset_load_result.dart';
import '../models/prompt_preset.dart';
import 'settings_service.dart';
import '../utils/path_utils.dart';

/// 预设提示词服务，负责加载和管理预设提示词
class PromptService {
  PromptService({
    SettingsService? settingsService,
    AssetBundle? assetBundle,
    Future<Directory> Function()? appDataDirectoryProvider,
    Future<String?> Function(File)? backupUserPresets,
  }) : _settingsService = settingsService ?? SettingsService(),
       _assetBundle = assetBundle ?? rootBundle,
       _appDataDirectoryProvider =
           appDataDirectoryProvider ?? PathUtils.getAppDataDirectory,
       _backupOverride = backupUserPresets;

  final SettingsService _settingsService;
  final AssetBundle _assetBundle;
  final Future<Directory> Function() _appDataDirectoryProvider;
  final Future<String?> Function(File)? _backupOverride;

  /// 当前语言对应的预设文件路径
  String _getPresetsPath(String locale) {
    return 'assets/prompt/presets-$locale.json';
  }

  /// 内置预设的语言回退链。
  ///
  /// 文言没有独立的内置角色卡，回退到简体中文；其他语言先回退到英文，
  /// 再回退到中文，保证任何受支持的语言都至少能看到内置角色。
  static List<String> localeFallbackChain(String locale) {
    final normalized = locale.trim().toLowerCase();
    final primary = normalized.isEmpty ? 'en' : normalized;
    final chain = primary == 'lzh'
        ? <String>['lzh', 'zh', 'en']
        : <String>[primary, 'en', 'zh'];
    return LinkedHashSet<String>.from(chain).toList(growable: false);
  }

  /// 加载文件内容（支持XML、TXT等文本文件）
  Future<String> _loadFileContent(String filePath) async {
    try {
      final fullPath = 'assets/prompt/$filePath';

      // 方法1: 使用rootBundle
      final content = await _assetBundle.loadString(fullPath);
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

  /// 把角色卡路径中的语言段替换为目标语言。
  ///
  /// 例如 characters/zh/NingXi.xml -> characters/en/NingXi.xml。
  String _cardPathForLocale(String cardPath, String locale) {
    final normalized = cardPath.replaceAll('\\', '/');
    final segments = normalized.split('/');
    final charactersIndex = segments.indexOf('characters');
    if (charactersIndex >= 0 && charactersIndex + 2 < segments.length) {
      segments[charactersIndex + 1] = locale;
      return segments.join('/');
    }
    return normalized;
  }

  /// 获取用户预设存储目录
  Future<Directory> _getUserPresetsDirectory() async {
    final appDataDir = await _appDataDirectoryProvider();
    final userPresetsDir = Directory(
      path.join(appDataDir.path, 'user_prompts'),
    );
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

  /// 加载用户预设列表，并在读取旧格式后迁移到 schema v2。
  Future<PresetLoadResult> loadUserPresets() async {
    final issues = <PresetLoadIssue>[];
    File? userPresetsFile;
    try {
      userPresetsFile = await _getUserPresetsFile();
      if (!await userPresetsFile.exists()) {
        return const PresetLoadResult(presets: []);
      }
      final String jsonString = await userPresetsFile.readAsString();
      final decoded = jsonDecode(jsonString);

      late final List<dynamic> jsonList;
      var needsMigration = false;
      if (decoded is List) {
        // 旧格式：顶层数组。
        jsonList = decoded;
        needsMigration = true;
      } else if (decoded is Map && decoded['presets'] is List) {
        jsonList = decoded['presets'] as List<dynamic>;
        final schemaVersion = decoded['schema_version'];
        needsMigration = schemaVersion is! int || schemaVersion < 2;
      } else {
        throw const FormatException('Invalid user preset document');
      }

      final presets = <PromptPreset>[];
      var hasInvalidEntries = false;
      for (var index = 0; index < jsonList.length; index++) {
        final item = jsonList[index];
        if (item is! Map) {
          hasInvalidEntries = true;
          issues.add(
            PresetLoadIssue(
              type: PresetIssueType.userEntryInvalid,
              message: '#$index: not an object',
            ),
          );
          continue;
        }
        final entry = item.cast<String, dynamic>();
        try {
          presets.add(
            PromptPreset.fromJson(
              entry,
              legacySystemPromptAsFile: needsMigration,
            ),
          );
        } catch (error) {
          hasInvalidEntries = true;
          issues.add(
            PresetLoadIssue(
              type: PresetIssueType.userEntryInvalid,
              presetId: entry['id']?.toString(),
              message: '#$index: $error',
            ),
          );
        }
      }

      final List<PromptPreset> processedPresets = [];
      for (final preset in presets) {
        if (!preset.hasPromptFile) {
          // 内联正文：绝不把 systemPrompt 当路径解析。
          processedPresets.add(preset);
          continue;
        }

        final rawPromptFile = preset.promptFile!.trim();
        final safePromptFile = _sanitizePromptFile(rawPromptFile);
        final fileResult = safePromptFile == null
            ? const _UserFileLoadResult(content: '', exists: true)
            : await _loadUserFileContent(safePromptFile);
        final loaded = fileResult.content.isNotEmpty;

        if (!loaded) {
          issues.add(
            PresetLoadIssue(
              type: fileResult.exists
                  ? PresetIssueType.cardFileUnreadable
                  : PresetIssueType.cardFileMissing,
              presetId: preset.id,
              message: rawPromptFile,
            ),
          );
        }

        // 用 copyWith 保留 language/tags/createdAt/updatedAt 等元数据；
        // 否则任何一次写回都会把这些字段从所有用户预设中抹掉。
        processedPresets.add(
          preset.copyWith(
            systemPrompt: loaded ? fileResult.content : '',
            isBroken: !loaded,
            brokenReason: loaded ? null : rawPromptFile,
          ),
        );
      }

      // 有坏条目时保留原文件，避免迁移把坏条目永久丢弃。
      if (needsMigration && !hasInvalidEntries) {
        final backupName = await _backupUserPresets(userPresetsFile);
        if (backupName == null) {
          issues.add(
            const PresetLoadIssue(
              type: PresetIssueType.userMigrationBackupFailed,
              message: 'backup failed; migration skipped',
            ),
          );
        } else {
          try {
            // 保存解析后的元数据，而不是把文件正文回写进 system_prompt。
            await _saveUserPresets(presets);
          } catch (error) {
            issues.add(
              PresetLoadIssue(
                type: PresetIssueType.userJsonWriteFailed,
                message: error.toString(),
              ),
            );
          }
        }
      }

      return PresetLoadResult(presets: processedPresets, issues: issues);
    } catch (e) {
      String? backupName;
      if (userPresetsFile != null && await userPresetsFile.exists()) {
        backupName = await _backupUserPresets(userPresetsFile);
      }
      issues.add(
        PresetLoadIssue(
          type: PresetIssueType.userJsonCorrupt,
          message: e.toString(),
          backupName: backupName,
        ),
      );
      return PresetLoadResult(presets: const [], issues: issues);
    }
  }

  /// 规范化用户预设文件路径。拒绝绝对路径、盘符和 `..`。
  String? _sanitizePromptFile(String raw) {
    final normalized = raw.replaceAll('\\', '/').trim();
    if (normalized.isEmpty) return null;
    if (path.posix.isAbsolute(normalized)) return null;
    if (RegExp(r'^[A-Za-z]:').hasMatch(normalized)) return null;
    final segments = normalized.split('/');
    if (segments.contains('..')) return null;
    return segments.where((segment) => segment.isNotEmpty).join('/');
  }

  /// 加载用户文件内容（从用户预设目录）
  Future<_UserFileLoadResult> _loadUserFileContent(String filePath) async {
    final safePath = _sanitizePromptFile(filePath);
    if (safePath == null) {
      return const _UserFileLoadResult(content: '', exists: true);
    }
    try {
      final userPresetsDir = await _getUserPresetsDirectory();
      final fullPath = path.join(userPresetsDir.path, safePath);
      if (!path.isWithin(userPresetsDir.path, fullPath)) {
        return const _UserFileLoadResult(content: '', exists: true);
      }
      final file = File(fullPath);
      if (!await file.exists()) {
        return const _UserFileLoadResult(content: '', exists: false);
      }
      return _UserFileLoadResult(
        content: await file.readAsString(),
        exists: true,
      );
    } catch (_) {
      return const _UserFileLoadResult(content: '', exists: true);
    }
  }

  /// 把用户预设 JSON 复制为带时间戳的备份，只保留最近 3 份。
  Future<String?> _backupUserPresets(File file) async {
    final override = _backupOverride;
    if (override != null) return override(file);
    try {
      final stamp = DateTime.now().millisecondsSinceEpoch;
      var backup = File('${file.path}.bak.$stamp');
      var suffix = 1;
      while (await backup.exists()) {
        backup = File('${file.path}.bak.${stamp}_${suffix++}');
      }
      await file.copy(backup.path);
      await _pruneUserPresetBackups(file);
      return path.basename(backup.path);
    } catch (_) {
      return null;
    }
  }

  Future<void> _pruneUserPresetBackups(File source) async {
    try {
      final dir = source.parent;
      final prefix = '${path.basename(source.path)}.bak.';
      final backups =
          (await dir.list().toList())
              .whereType<File>()
              .where((file) => path.basename(file.path).startsWith(prefix))
              .toList()
            ..sort(
              (a, b) => path.basename(b.path).compareTo(path.basename(a.path)),
            );
      for (final stale in backups.skip(3)) {
        await stale.delete();
      }
    } catch (_) {
      // Pruning is best-effort.
    }
  }

  /// 保存用户预设列表到 JSON 文件（schema v2）。
  Future<void> _saveUserPresets(List<PromptPreset> presets) async {
    final userPresetsFile = await _getUserPresetsFile();
    final jsonString = jsonEncode({
      'schema_version': 2,
      'presets': presets
          .map(
            (preset) =>
                (preset.hasPromptFile
                        ? preset.copyWith(systemPrompt: '')
                        : preset)
                    .toJson(),
          )
          .toList(),
    });
    // 写失败必须让调用方知道，否则 UI 会误报导入/编辑成功。
    await userPresetsFile.writeAsString(jsonString);
  }

  /// 角色卡文件大小上限（200 KB）。
  static const int maxPresetFileBytes = 200 * 1024;

  /// 规范化角色卡正文：统一换行并去掉首尾空白。
  static String normalizePresetContent(String content) {
    return content.replaceAll('\r\n', '\n').replaceAll('\r', '\n').trim();
  }

  /// 校验 XML 角色卡文件，返回错误、警告、名称与内容哈希。
  Future<PresetValidationResult> validatePresetFile(File file) async {
    final errors = <PresetValidationError>[];
    List<int> bytes;
    try {
      bytes = await file.readAsBytes();
    } catch (_) {
      return const PresetValidationResult(
        errors: [PresetValidationError.emptyFile],
        warnings: [],
      );
    }

    if (bytes.isEmpty) {
      return const PresetValidationResult(
        errors: [PresetValidationError.emptyFile],
        warnings: [],
      );
    }
    if (bytes.length > maxPresetFileBytes) {
      return const PresetValidationResult(
        errors: [PresetValidationError.fileTooLarge],
        warnings: [],
      );
    }

    String rawContent;
    try {
      rawContent = utf8.decode(bytes);
    } catch (_) {
      return const PresetValidationResult(
        errors: [PresetValidationError.invalidUtf8],
        warnings: [],
      );
    }

    if (rawContent.startsWith('﻿')) {
      rawContent = rawContent.substring(1);
    }
    final normalized = normalizePresetContent(rawContent);
    final contentHash = sha256.convert(utf8.encode(normalized)).toString();

    XmlDocument document;
    try {
      document = XmlDocument.parse(normalized);
    } catch (_) {
      return PresetValidationResult(
        errors: const [PresetValidationError.invalidXml],
        warnings: const [],
        content: normalized,
        contentHash: contentHash,
      );
    }

    if (document.rootElement.name.local != 'system_instruction') {
      errors.add(PresetValidationError.invalidRoot);
    }

    String? extractedName;
    for (final element in document.findAllElements('role_name')) {
      final text = element.innerText.trim();
      if (text.isNotEmpty) {
        extractedName = text;
        break;
      }
    }

    final warnings = <PresetValidationWarning>[
      if (extractedName == null) PresetValidationWarning.missingRoleName,
    ];

    return PresetValidationResult(
      errors: errors,
      warnings: warnings,
      content: normalized,
      extractedName: extractedName,
      contentHash: contentHash,
    );
  }

  /// 查找内容哈希相同的预设。旧预设没有 content_hash 时按当前正文计算。
  Future<PromptPreset?> findPresetByContentHash(String contentHash) async {
    final presets = (await loadPresets()).presets;
    for (final preset in presets) {
      final hash =
          preset.contentHash ??
          sha256
              .convert(utf8.encode(normalizePresetContent(preset.systemPrompt)))
              .toString();
      if (hash == contentHash) return preset;
    }
    return null;
  }

  /// 导入XML文件作为用户预设。
  ///
  /// 校验失败抛出 [PresetValidationException]；内容重复且未允许时抛出
  /// [PresetDuplicateException]。
  Future<PromptPreset> importPresetFromXml(
    File xmlFile, {
    String? name,
    String? description,
    String? author,
    String? version,
    String? icon,
    String? language,
    List<String>? tags,
    bool allowDuplicate = false,
  }) async {
    final validation = await validatePresetFile(xmlFile);
    return _persistImportedPreset(
      sourceFile: xmlFile,
      validation: validation,
      extension: 'xml',
      name: name,
      description: description,
      author: author,
      version: version,
      icon: icon,
      language: language,
      tags: tags,
      allowDuplicate: allowDuplicate,
    );
  }

  /// 校验纯文本预设（.txt）：不要求 XML 结构，只检查编码与大小。
  Future<PresetValidationResult> validateTextFile(File file) async {
    List<int> bytes;
    try {
      bytes = await file.readAsBytes();
    } catch (_) {
      return const PresetValidationResult(
        errors: [PresetValidationError.emptyFile],
        warnings: [],
      );
    }
    if (bytes.isEmpty) {
      return const PresetValidationResult(
        errors: [PresetValidationError.emptyFile],
        warnings: [],
      );
    }
    if (bytes.length > maxPresetFileBytes) {
      return const PresetValidationResult(
        errors: [PresetValidationError.fileTooLarge],
        warnings: [],
      );
    }

    String rawContent;
    try {
      rawContent = utf8.decode(bytes);
    } catch (_) {
      return const PresetValidationResult(
        errors: [PresetValidationError.invalidUtf8],
        warnings: [],
      );
    }
    if (rawContent.startsWith('﻿')) {
      rawContent = rawContent.substring(1);
    }
    final normalized = normalizePresetContent(rawContent);
    if (normalized.isEmpty) {
      return const PresetValidationResult(
        errors: [PresetValidationError.emptyFile],
        warnings: [],
      );
    }

    return PresetValidationResult(
      errors: const [],
      warnings: const [PresetValidationWarning.missingRoleName],
      content: normalized,
      contentHash: sha256.convert(utf8.encode(normalized)).toString(),
    );
  }

  /// 导入纯文本预设。名称优先使用文件名。
  Future<PromptPreset> importPresetFromText(
    File textFile, {
    String? name,
    String? description,
    String? author,
    String? version,
    String? icon,
    String? language,
    List<String>? tags,
    bool allowDuplicate = false,
  }) async {
    final validation = await validateTextFile(textFile);
    return _persistImportedPreset(
      sourceFile: textFile,
      validation: validation,
      extension: 'txt',
      name: name,
      description: description,
      author: author,
      version: version,
      icon: icon,
      language: language,
      tags: tags,
      allowDuplicate: allowDuplicate,
    );
  }

  Future<PromptPreset> _persistImportedPreset({
    required File sourceFile,
    required PresetValidationResult validation,
    required String extension,
    String? name,
    String? description,
    String? author,
    String? version,
    String? icon,
    String? language,
    List<String>? tags,
    bool allowDuplicate = false,
  }) async {
    if (!validation.isValid) {
      throw PresetValidationException(validation);
    }

    if (!allowDuplicate) {
      final existing = await findPresetByContentHash(validation.contentHash!);
      if (existing != null) {
        throw PresetDuplicateException(
          existing: existing,
          validation: validation,
        );
      }
    }

    var extractedName = name?.trim() ?? '';
    if (extractedName.isEmpty) {
      extractedName = validation.extractedName ?? '';
    }
    if (extractedName.isEmpty) {
      extractedName = path.basenameWithoutExtension(sourceFile.path);
    }

    // 生成唯一ID
    final id = 'user_${DateTime.now().microsecondsSinceEpoch}';
    final userPresetsDir = await _getUserPresetsDirectory();
    final fileName = '$id.$extension';
    final destFile = File(path.join(userPresetsDir.path, fileName));
    await destFile.writeAsString(validation.content);

    final now = DateTime.now();
    final preset = PromptPreset(
      id: id,
      name: extractedName,
      description: description ?? '用户导入的预设',
      author: author ?? '用户',
      version: version ?? 'v1.0',
      promptFile: fileName,
      icon: icon ?? 'person.fill',
      contentHash: validation.contentHash,
      language: language,
      tags: tags ?? const [],
      createdAt: now,
      updatedAt: now,
    );

    final currentPresets = List<PromptPreset>.from(
      (await loadUserPresets()).presets,
    );
    currentPresets.add(preset);
    await _saveUserPresets(currentPresets);

    return preset;
  }

  /// 从会话导出快照创建用户预设（不参与重复检测）。
  Future<PromptPreset> importPresetFromSnapshot({
    required String name,
    required String content,
    String? author,
    String? version,
    String? contentHash,
  }) async {
    final normalized = normalizePresetContent(content);
    final normalizedBytes = utf8.encode(normalized);
    if (normalized.isEmpty) {
      throw const PresetValidationException(
        PresetValidationResult(
          errors: [PresetValidationError.emptyFile],
          warnings: [],
        ),
      );
    }
    if (normalizedBytes.length > maxPresetFileBytes) {
      throw const PresetValidationException(
        PresetValidationResult(
          errors: [PresetValidationError.fileTooLarge],
          warnings: [],
        ),
      );
    }

    final id = 'user_${DateTime.now().microsecondsSinceEpoch}';
    final extension = normalized.contains('<system_instruction')
        ? 'xml'
        : 'txt';
    final fileName = '$id.$extension';
    final userPresetsDir = await _getUserPresetsDirectory();
    await File(path.join(userPresetsDir.path, fileName))
        .writeAsString(normalized);

    final now = DateTime.now();
    final preset = PromptPreset(
      id: id,
      name: name,
      description: '',
      author: author ?? '',
      version: version ?? 'v1.0',
      promptFile: fileName,
      icon: 'person.fill',
      contentHash: contentHash ?? sha256.convert(normalizedBytes).toString(),
      createdAt: now,
      updatedAt: now,
    );

    final currentPresets = List<PromptPreset>.from(
      (await loadUserPresets()).presets,
    );
    currentPresets.add(preset);
    await _saveUserPresets(currentPresets);
    return preset;
  }

  /// 更新用户预设的元数据（正文仍由 promptFile 指向的文件提供）。
  Future<void> updateUserPreset(PromptPreset preset) async {
    final currentPresets = List<PromptPreset>.from(
      (await loadUserPresets()).presets,
    );
    final index = currentPresets.indexWhere((item) => item.id == preset.id);
    if (index < 0) {
      throw StateError('Preset not found: ${preset.id}');
    }
    currentPresets[index] = preset.copyWith(updatedAt: DateTime.now());
    await _saveUserPresets(currentPresets);
  }

  /// 复制任意预设（含内置）为用户预设。
  Future<PromptPreset> duplicatePreset(
    PromptPreset source, {
    required String name,
  }) async {
    var content = source.systemPrompt.trim();
    if (content.isEmpty && source.promptFile != null) {
      final loaded = await _loadUserFileContent(source.promptFile!);
      content = loaded.content.trim();
    }
    if (content.isEmpty) {
      throw StateError('Preset has no content: ${source.id}');
    }

    final id = 'user_${DateTime.now().microsecondsSinceEpoch}';
    final extension = source.promptFile?.toLowerCase().endsWith('.txt') ?? false
        ? 'txt'
        : 'xml';
    final fileName = '$id.$extension';
    final userPresetsDir = await _getUserPresetsDirectory();
    await File(path.join(userPresetsDir.path, fileName)).writeAsString(content);

    final now = DateTime.now();
    final preset = PromptPreset(
      id: id,
      name: name,
      description: source.description,
      author: source.author,
      version: source.version,
      promptFile: fileName,
      icon: source.icon,
      contentHash:
          source.contentHash ??
          sha256
              .convert(utf8.encode(normalizePresetContent(content)))
              .toString(),
      language: source.language,
      tags: source.tags,
      createdAt: now,
      updatedAt: now,
    );

    final currentPresets = List<PromptPreset>.from(
      (await loadUserPresets()).presets,
    );
    currentPresets.add(preset);
    await _saveUserPresets(currentPresets);
    return preset;
  }

  /// 删除用户预设
  Future<void> deleteUserPreset(String id) async {
    try {
      final currentPresets = List<PromptPreset>.from(
        (await loadUserPresets()).presets,
      );
      final presetToDelete = currentPresets.firstWhere(
        (preset) => preset.id == id,
      );

      // 删除关联的XML文件
      final fileName = presetToDelete.promptFile;
      if (fileName != null && fileName.isNotEmpty) {
        final safePath = _sanitizePromptFile(fileName);
        if (safePath != null) {
          final userPresetsDir = await _getUserPresetsDirectory();
          final fullPath = path.join(userPresetsDir.path, safePath);
          if (path.isWithin(userPresetsDir.path, fullPath)) {
            final xmlFile = File(fullPath);
            if (await xmlFile.exists()) {
              await xmlFile.delete();
            }
          }
        }
      }

      // 从列表中移除
      currentPresets.removeWhere((preset) => preset.id == id);
      await _saveUserPresets(currentPresets);
    } catch (e) {
      rethrow;
    }
  }

  /// 从JSON文件加载内置预设提示词列表。
  ///
  /// 先沿语言回退链找元数据文件，再用同一个语言解析角色卡正文；
  /// 正文缺失时继续沿链回退，避免文言或小语种界面完全没有内置角色。
  Future<PresetLoadResult> _loadBuiltInPresets() async {
    final locale = await _settingsService.getLocale();
    final chain = localeFallbackChain(locale);

    for (final metadataLocale in chain) {
      try {
        final presetsPath = _getPresetsPath(metadataLocale);
        final String jsonString = await _assetBundle.loadString(presetsPath);
        final List<dynamic> jsonList = jsonDecode(jsonString) as List<dynamic>;
        final List<PromptPreset> presets = jsonList
            .map(
              (item) => PromptPreset.fromJson(
                item as Map<String, dynamic>,
                legacySystemPromptAsFile: true,
              ),
            )
            .toList();

        final cardChain = localeFallbackChain(metadataLocale);
        final issues = <PresetLoadIssue>[];
        final List<PromptPreset> processedPresets = [];
        for (final preset in presets) {
          if (!preset.hasPromptFile) {
            // 内联正文：直接使用，不再尝试按路径加载。
            processedPresets.add(preset);
            continue;
          }

          final rawPromptFile = preset.promptFile!.trim();
          String cardContent = '';
          for (final cardLocale in cardChain) {
            cardContent = await _loadFileContent(
              _cardPathForLocale(rawPromptFile, cardLocale),
            );
            if (cardContent.isNotEmpty) break;
          }
          if (cardContent.isEmpty && rawPromptFile.isNotEmpty) {
            issues.add(
              PresetLoadIssue(
                type: PresetIssueType.cardFileMissing,
                presetId: preset.id,
                message: rawPromptFile,
              ),
            );
          }

          processedPresets.add(
            preset.copyWith(
              systemPrompt: cardContent,
              promptFile: rawPromptFile,
              isBroken: cardContent.isEmpty,
              brokenReason: cardContent.isEmpty ? rawPromptFile : null,
            ),
          );
        }

        return PresetLoadResult(presets: processedPresets, issues: issues);
      } catch (_) {
        // 元数据文件缺失或损坏，继续尝试回退链中的下一个语言。
      }
    }

    return PresetLoadResult(
      presets: const [],
      issues: [
        PresetLoadIssue(
          type: PresetIssueType.builtInMetaMissing,
          message: chain.join(', '),
        ),
      ],
    );
  }

  /// 从JSON文件加载预设提示词列表（包含内置和用户预设）
  Future<PresetLoadResult> loadPresets() async {
    final builtIn = await _loadBuiltInPresets();
    final user = await loadUserPresets();
    return PresetLoadResult(
      presets: [...builtIn.presets, ...user.presets],
      issues: [...builtIn.issues, ...user.issues],
    );
  }

  /// 根据ID查找预设提示词
  Future<PromptPreset?> findPresetById(String id) async {
    final presets = (await loadPresets()).presets;
    try {
      return presets.firstWhere((preset) => preset.id == id);
    } catch (e) {
      return null;
    }
  }

  /// 获取默认预设提示词（第一个）
  Future<PromptPreset?> getDefaultPreset() async {
    final presets = (await loadPresets()).presets;
    return presets.isNotEmpty ? presets.first : null;
  }
}

class _UserFileLoadResult {
  const _UserFileLoadResult({required this.content, required this.exists});

  final String content;
  final bool exists;
}
