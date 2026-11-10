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
    this.contentHash,
    this.language,
    this.tags = const [],
    this.createdAt,
    this.updatedAt,
    this.isBroken = false,
    this.brokenReason,
  });

  bool get hasPromptFile => promptFile != null && promptFile!.isNotEmpty;

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
