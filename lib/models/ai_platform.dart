/// AI平台配置模型
///
/// 支持多个AI平台（如OpenAI、Claude、DeepSeek等）的配置管理
/// 每个平台包含API端点、密钥、可用模型列表和默认模型等信息
class AIPlatform {
  /// 平台唯一标识
  final String id;

  /// 平台名称
  final String name;

  /// 平台类型
  final String type; // 'openai', 'claude', 'gemini', 'deepseek'

  /// API端点URL
  final String endpoint;

  /// API密钥
  final String apiKey;

  /// 可用模型列表
  final List<String> availableModels;

  /// 当前选中的默认模型
  final String defaultModel;

  /// 配置是否启用（可用于切换平台）
  final bool enabled;

  /// 最后模型列表更新时间
  final DateTime? lastModelUpdate;

  /// 平台图标标识
  final String icon;

  AIPlatform({
    required this.id,
    required this.name,
    required this.type,
    required this.endpoint,
    required this.apiKey,
    required this.availableModels,
    required this.defaultModel,
    this.enabled = true,
    this.lastModelUpdate,
    this.icon = 'default',
  });

  /// 从JSON创建AIPlatform实例
  factory AIPlatform.fromJson(Map<String, dynamic> json) {
    return AIPlatform(
      id: json['id'] as String,
      name: json['name'] as String,
      type: json['type'] as String,
      endpoint: json['endpoint'] as String,
      apiKey: json['apiKey'] as String,
      availableModels: (json['availableModels'] as List<dynamic>)
          .map((e) => e as String)
          .toList(),
      defaultModel: json['defaultModel'] as String,
      enabled: json['enabled'] as bool? ?? true,
      lastModelUpdate: json['lastModelUpdate'] != null
          ? DateTime.parse(json['lastModelUpdate'] as String)
          : null,
      icon: json['icon'] as String? ?? 'default',
    );
  }

  /// 转换为JSON
  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'name': name,
      'type': type,
      'endpoint': endpoint,
      'apiKey': apiKey,
      'availableModels': availableModels,
      'defaultModel': defaultModel,
      'enabled': enabled,
      'lastModelUpdate': lastModelUpdate?.toIso8601String(),
      'icon': icon,
    };
  }

  /// 创建拷贝
  AIPlatform copyWith({
    String? id,
    String? name,
    String? type,
    String? endpoint,
    String? apiKey,
    List<String>? availableModels,
    String? defaultModel,
    bool? enabled,
    DateTime? lastModelUpdate,
    String? icon,
  }) {
    return AIPlatform(
      id: id ?? this.id,
      name: name ?? this.name,
      type: type ?? this.type,
      endpoint: endpoint ?? this.endpoint,
      apiKey: apiKey ?? this.apiKey,
      availableModels: availableModels ?? this.availableModels,
      defaultModel: defaultModel ?? this.defaultModel,
      enabled: enabled ?? this.enabled,
      lastModelUpdate: lastModelUpdate ?? this.lastModelUpdate,
      icon: icon ?? this.icon,
    );
  }

  /// 创建预设平台配置
  static AIPlatform createDefaultPlatform(String type) {
    switch (type) {
      case 'openai':
        return AIPlatform(
          id: 'openai',
          name: 'OpenAI',
          type: 'openai',
          endpoint: 'https://api.openai.com/v1',
          apiKey: '',
          availableModels: [],
          defaultModel: '',
          icon: 'openai',
        );
      case 'claude':
        return AIPlatform(
          id: 'claude',
          name: 'Claude (Anthropic)',
          type: 'claude',
          endpoint: 'https://api.anthropic.com',
          apiKey: '',
          availableModels: [],
          defaultModel: '',
          icon: 'claude',
        );
      case 'deepseek':
        return AIPlatform(
          id: 'deepseek',
          name: 'DeepSeek',
          type: 'deepseek',
          endpoint: 'https://api.deepseek.com',
          apiKey: '',
          availableModels: [],
          defaultModel: '',
          icon: 'deepseek',
        );
      case 'gemini':
        return AIPlatform(
          id: 'gemini',
          name: 'Google Gemini',
          type: 'gemini',
          endpoint: 'https://generativelanguage.googleapis.com/v1beta',
          apiKey: '',
          availableModels: [],
          defaultModel: '',
          icon: 'gemini',
        );
      default:
        throw ArgumentError('Unknown platform type: $type');
    }
  }

  /// 检查配置是否完整（有API密钥）
  bool get isConfigured => apiKey.isNotEmpty;

  /// 获取显示名称
  String get displayName => isConfigured ? name : '$name (未配置)';
}
