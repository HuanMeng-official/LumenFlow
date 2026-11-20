import 'character_growth.dart';
import 'world_info.dart';

class PromptPreset {
  final String id;
  final String name;
  final String description;
  final String author;
  final String version;

  /// 内联的角色卡正文。不会再把该字段当作文件路径解析。
  final String systemPrompt;

  /// 角色卡文件的相对路径（相对 user_prompts/ 或 assets/prompt/）。
  /// 为空表示使用内联正文。
  final String? promptFile;

  final String icon;

  /// 世界书文件的相对路径（相对 user_prompts/ 或 assets/prompt/）。
  final String? worldInfoFile;

  /// 成长配置文件的相对路径（相对 user_prompts/ 或 assets/prompt/）。
  final String? growthFile;

  /// 角色卡头像文件的相对路径（相对 user_prompts/ 或 assets/prompt/）。
  final String? avatarFile;

  /// 角色立绘文件的相对路径（相对 user_prompts/ 或 assets/prompt/）。
  final String? illustrationFile;

  /// 运行期状态：已解析的世界书，不写入 JSON。
  final WorldInfo? worldInfo;

  /// 运行期状态：已解析的成长配置，不写入 JSON。
  final CharacterGrowthConfig? growthConfig;

  /// 运行期状态：头像缓存的绝对路径，不写入 JSON。
  final String? avatarPath;

  /// 运行期状态：立绘缓存的绝对路径，不写入 JSON。
  final String? illustrationPath;

  /// 运行期状态：用户卡按阶段 ID 索引的差分头像绝对路径，不写入 JSON。
  final Map<String, String> stageAvatarPaths;

  /// 运行期状态：用户卡按阶段 ID 索引的差分立绘绝对路径，不写入 JSON。
  final Map<String, String> stageIllustrationPaths;

  /// 运行期状态：是否来自 user_prompts/，不写入 JSON。
  final bool isUserPreset;

  /// 规范化内容的 sha256，用于重复导入检测。
  final String? contentHash;

  /// 角色卡语言；null 表示通用。
  final String? language;

  /// 展示与筛选用标签。
  final List<String> tags;

  final DateTime? createdAt;
  final DateTime? updatedAt;

  /// 运行期状态：角色卡文件缺失或不可读时置为 true。不会写入 JSON。
  final bool isBroken;

  /// 运行期状态：不可用的原因，供详情页展示。
  final String? brokenReason;

  const PromptPreset({
    required this.id,
    required this.name,
    required this.description,
    required this.author,
    required this.version,
    this.systemPrompt = '',
    this.promptFile,
    this.icon = 'person.fill',
    this.worldInfoFile,
    this.growthFile,
    this.avatarFile,
    this.illustrationFile,
    this.worldInfo,
    this.growthConfig,
    this.avatarPath,
    this.illustrationPath,
    this.stageAvatarPaths = const {},
    this.stageIllustrationPaths = const {},
    this.isUserPreset = false,
    this.contentHash,
    this.language,
    this.tags = const [],
    this.createdAt,
    this.updatedAt,
    this.isBroken = false,
    this.brokenReason,
  });

  bool get hasPromptFile => promptFile != null && promptFile!.isNotEmpty;

  bool get hasWorldInfoFile =>
      worldInfoFile != null && worldInfoFile!.isNotEmpty;

  bool get hasGrowthFile => growthFile != null && growthFile!.isNotEmpty;

  bool get hasGrowth => growthConfig != null;

  bool get hasAvatarFile => avatarFile != null && avatarFile!.isNotEmpty;

  bool get hasIllustrationFile =>
      illustrationFile != null && illustrationFile!.isNotEmpty;

  PromptPreset copyWith({
    String? id,
    String? name,
    String? description,
    String? author,
    String? version,
    String? systemPrompt,
    String? promptFile,
    bool clearPromptFile = false,
    String? icon,
    String? worldInfoFile,
    bool clearWorldInfoFile = false,
    String? growthFile,
    bool clearGrowthFile = false,
    String? avatarFile,
    bool clearAvatarFile = false,
    String? illustrationFile,
    bool clearIllustrationFile = false,
    WorldInfo? worldInfo,
    CharacterGrowthConfig? growthConfig,
    bool clearGrowthConfig = false,
    String? avatarPath,
    String? illustrationPath,
    bool clearIllustrationPath = false,
    Map<String, String>? stageAvatarPaths,
    Map<String, String>? stageIllustrationPaths,
    bool? isUserPreset,
    String? contentHash,
    String? language,
    bool clearLanguage = false,
    List<String>? tags,
    DateTime? createdAt,
    DateTime? updatedAt,
    bool? isBroken,
    String? brokenReason,
  }) {
    return PromptPreset(
      id: id ?? this.id,
      name: name ?? this.name,
      description: description ?? this.description,
      author: author ?? this.author,
      version: version ?? this.version,
      systemPrompt: systemPrompt ?? this.systemPrompt,
      promptFile: clearPromptFile ? null : (promptFile ?? this.promptFile),
      icon: icon ?? this.icon,
      worldInfoFile: clearWorldInfoFile
          ? null
          : (worldInfoFile ?? this.worldInfoFile),
      growthFile: clearGrowthFile ? null : (growthFile ?? this.growthFile),
      avatarFile: clearAvatarFile ? null : (avatarFile ?? this.avatarFile),
      illustrationFile: clearIllustrationFile
          ? null
          : (illustrationFile ?? this.illustrationFile),
      worldInfo: worldInfo ?? this.worldInfo,
      growthConfig: clearGrowthConfig
          ? null
          : (growthConfig ?? this.growthConfig),
      avatarPath: avatarPath ?? this.avatarPath,
      illustrationPath: clearIllustrationPath
          ? null
          : (illustrationPath ?? this.illustrationPath),
      stageAvatarPaths: stageAvatarPaths ?? this.stageAvatarPaths,
      stageIllustrationPaths:
          stageIllustrationPaths ?? this.stageIllustrationPaths,
      isUserPreset: isUserPreset ?? this.isUserPreset,
      contentHash: contentHash ?? this.contentHash,
      language: clearLanguage ? null : (language ?? this.language),
      tags: tags ?? this.tags,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
      isBroken: isBroken ?? this.isBroken,
      brokenReason: brokenReason ?? this.brokenReason,
    );
  }

  /// 旧数据中 system_prompt 曾被用作文件路径。只有形如 .xml/.txt 的
  /// 单行字符串才按路径处理，避免把真正的内联正文误判为文件。
  static bool looksLikeLegacyPromptFile(String value) {
    final trimmed = value.trim();
    if (trimmed.isEmpty || trimmed.contains('\n') || trimmed.contains('<')) {
      return false;
    }
    return trimmed.endsWith('.xml') || trimmed.endsWith('.txt');
  }

  /// 从JSON创建PromptPreset。
  ///
  /// [legacySystemPromptAsFile] 仅用于读取旧版内置 JSON / 旧用户数据：
  /// 把符合路径特征的 system_prompt 转成 promptFile。
  factory PromptPreset.fromJson(
    Map<String, dynamic> json, {
    bool legacySystemPromptAsFile = false,
  }) {
    final rawSystemPrompt = json['system_prompt'] as String? ?? '';
    final rawPromptFile = json['prompt_file'] as String?;
    var promptFile = rawPromptFile;
    var systemPrompt = rawSystemPrompt;

    if (promptFile == null &&
        legacySystemPromptAsFile &&
        looksLikeLegacyPromptFile(rawSystemPrompt)) {
      promptFile = rawSystemPrompt.trim();
      systemPrompt = '';
    }

    return PromptPreset(
      id: json['id'] as String,
      name: json['name'] as String,
      description: json['description'] as String,
      author: json['author'] as String? ?? '', // 向后兼容
      version: json['version'] as String? ?? 'v1.0', // 默认版本
      systemPrompt: systemPrompt,
      promptFile: promptFile,
      icon: json['icon'] as String? ?? 'person.fill',
      worldInfoFile: json['world_info_file'] as String?,
      growthFile: json['growth_file'] as String?,
      avatarFile: json['avatar_file'] as String?,
      illustrationFile: json['illustration_file'] as String?,
      contentHash: json['content_hash'] as String?,
      language: json['language'] as String?,
      tags:
          (json['tags'] as List<dynamic>?)?.whereType<String>().toList(
            growable: false,
          ) ??
          const [],
      createdAt: DateTime.tryParse(json['created_at'] as String? ?? ''),
      updatedAt: DateTime.tryParse(json['updated_at'] as String? ?? ''),
    );
  }

  /// 转换为JSON。运行期状态字段不序列化。
  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'name': name,
      'description': description,
      'author': author,
      'version': version,
      'system_prompt': systemPrompt,
      if (promptFile != null) 'prompt_file': promptFile,
      'icon': icon,
      if (worldInfoFile != null) 'world_info_file': worldInfoFile,
      if (growthFile != null) 'growth_file': growthFile,
      if (avatarFile != null) 'avatar_file': avatarFile,
      if (illustrationFile != null) 'illustration_file': illustrationFile,
      if (contentHash != null) 'content_hash': contentHash,
      if (language != null) 'language': language,
      if (tags.isNotEmpty) 'tags': tags,
      if (createdAt != null) 'created_at': createdAt!.toIso8601String(),
      if (updatedAt != null) 'updated_at': updatedAt!.toIso8601String(),
    };
  }

  @override
  String toString() {
    return 'PromptPreset(id: $id, name: $name)';
  }
}
