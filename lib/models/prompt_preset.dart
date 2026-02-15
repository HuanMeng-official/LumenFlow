class PromptPreset {
  final String id;
  final String name;
  final String description;
  final String author;
  final String version;
  final String systemPrompt;
  final String icon;

  const PromptPreset({
    required this.id,
    required this.name,
    required this.description,
    required this.author,
    required this.version,
    required this.systemPrompt,
    this.icon = 'person.fill',
  });

  /// 从JSON创建PromptPreset
  factory PromptPreset.fromJson(Map<String, dynamic> json) {
    return PromptPreset(
      id: json['id'] as String,
      name: json['name'] as String,
      description: json['description'] as String,
      author: json['author'] as String? ?? '', // 向后兼容
      version: json['version'] as String? ?? 'v1.0', // 默认版本
      systemPrompt: json['system_prompt'] as String,
      icon: json['icon'] as String? ?? 'person.fill',
    );
  }

  /// 转换为JSON
  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'name': name,
      'description': description,
      'author': author,
      'version': version,
      'system_prompt': systemPrompt,
      'icon': icon,
    };
  }

  @override
  String toString() {
    return 'PromptPreset(id: $id, name: $name)';
  }
}