class PromptPreset {
  final String id;
  final String name;
  final String description;
  final String systemPrompt;
  final String icon;

  const PromptPreset({
    required this.id,
    required this.name,
    required this.description,
    required this.systemPrompt,
    this.icon = 'person.fill',
  });

  /// 从JSON创建PromptPreset
  factory PromptPreset.fromJson(Map<String, dynamic> json) {
    return PromptPreset(
      id: json['id'] as String,
      name: json['name'] as String,
      description: json['description'] as String,
      systemPrompt: json['systemPrompt'] as String,
      icon: json['icon'] as String? ?? 'person.fill',
    );
  }

  /// 转换为JSON
  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'name': name,
      'description': description,
      'systemPrompt': systemPrompt,
      'icon': icon,
    };
  }

  @override
  String toString() {
    return 'PromptPreset(id: $id, name: $name)';
  }
}