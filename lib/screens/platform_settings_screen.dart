import 'dart:convert';
import 'dart:io';
import 'package:flutter/cupertino.dart';
import 'package:flutter_svg/flutter_svg.dart';
import '../l10n/app_localizations.dart';
import '../models/ai_platform.dart';
import '../services/settings_service.dart';

/// 模型与平台配置界面
///
/// 用户提供统一的界面来管理多个AI平台的配置：
/// - 添加、编辑、删除平台配置
/// - 配置API端点、密钥
/// - 自动获取/刷新平台模型列表
/// - 选择默认模型
/// - 点击切换当前使用的平台
class PlatformSettingsScreen extends StatefulWidget {
  const PlatformSettingsScreen({super.key});

  @override
  State<PlatformSettingsScreen> createState() => _PlatformSettingsScreenState();
}

class _PlatformSettingsScreenState extends State<PlatformSettingsScreen> {
  final SettingsService _settingsService = SettingsService();
  List<AIPlatform> _platforms = [];
  String? _currentPlatformId;
  bool _isLoading = true;
  final Set<String> _loadingPlatforms = {};

  /// 可用的平台类型列表
  /// 添加新平台时只需在此列表中添加类型名称
  static const List<String> _availablePlatformTypes = [
    'openai',
    'claude',
    'deepseek',
    'gemini',
    'siliconflow',
    'minimax',
    'zhipu',
    'kimi',
    'lmstudio',
    'other',
    // 未来添加新平台在这里添加即可，例如：
    // 'ollama',
    // 'perplexity',
  ];

  @override
  void initState() {
    super.initState();
    _loadData();
  }

  /// 加载平台配置数据
  Future<void> _loadData() async {
    setState(() {
      _isLoading = true;
    });

    // 尝试迁移旧版本配置
    await _settingsService.migrateLegacySettings();

    final platforms = await _settingsService.getPlatforms();
    final currentId = await _settingsService.getCurrentPlatformId();

    debugPrint('加载平台数据完成: ${platforms.length}个平台');
    for (var i = 0; i < platforms.length; i++) {
      final p = platforms[i];
      debugPrint('平台[$i]: id=${p.id}, name=${p.name}, 默认模型=${p.defaultModel}, 模型数=${p.availableModels.length}');
    }

    setState(() {
      _platforms = platforms;
      _currentPlatformId = currentId;
      _isLoading = false;
    });
  }

  /// 显示添加/编辑平台对话框
  Future<void> _showPlatformDialog([AIPlatform? platform]) async {
    final l10n = AppLocalizations.of(context)!;
    final isEdit = platform != null;

    final nameController = TextEditingController(text: platform?.name ?? '');
    final endpointController = TextEditingController(text: platform?.endpoint ?? '');
    final apiKeyController = TextEditingController(text: platform?.apiKey ?? '');
    String selectedType = platform?.type ?? 'openai';

    final result = await showCupertinoDialog<bool>(
      context: context,
      builder: (context) => StatefulBuilder(
        builder: (context, setDialogState) => CupertinoAlertDialog(
          title: Text(isEdit ? l10n.editPlatform : l10n.addPlatform),
          content: SizedBox(
            width: double.maxFinite,
            child: SingleChildScrollView(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(l10n.platformType),
                  const SizedBox(height: 8),
                  SizedBox(
                    height: 70, // 减小高度
                    child: GridView.builder(
                      gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                        crossAxisCount: 5, // 一行5个图标
                        mainAxisSpacing: 8, // 减小垂直间距
                        crossAxisSpacing: 8, // 减小水平间距
                        childAspectRatio: 1, // 正方形图标
                      ),
                      itemCount: _availablePlatformTypes.length,
                      itemBuilder: (context, index) {
                        final type = _availablePlatformTypes[index];
                        final platform = AIPlatform.createDefaultPlatform(type);
                        return _buildPlatformTypeButton(
                          type,
                          platform.name,
                          'assets/platform/$type.svg',
                          selectedType,
                          (value) {
                            setDialogState(() {
                              selectedType = value;
                              endpointController.text =
                                  AIPlatform.createDefaultPlatform(value).endpoint;
                            });
                          },
                        );
                      },
                    ),
                  ),
                  const SizedBox(height: 8),
                  CupertinoTextField(
                    controller: nameController,
                    placeholder: l10n.platformNamePlaceholder,
                    prefix: const Padding(
                      padding: EdgeInsets.only(left: 8),
                      child: Icon(CupertinoIcons.tag, size: 20),
                    ),
                    padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                    decoration: BoxDecoration(
                      color: CupertinoColors.systemGrey6,
                      borderRadius: BorderRadius.circular(8),
                    ),
                  ),
                  const SizedBox(height: 12),
                  CupertinoTextField(
                    controller: endpointController,
                    placeholder: l10n.endpointPlaceholder,
                    prefix: const Padding(
                      padding: EdgeInsets.only(left: 8),
                      child: Icon(CupertinoIcons.link, size: 20),
                    ),
                    padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                    decoration: BoxDecoration(
                      color: CupertinoColors.systemGrey6,
                      borderRadius: BorderRadius.circular(8),
                    ),
                  ),
                  const SizedBox(height: 12),
                  CupertinoTextField(
                    controller: apiKeyController,
                    placeholder: l10n.apiKeyPlaceholder,
                    prefix: const Padding(
                      padding: EdgeInsets.only(left: 8),
                      child: Icon(CupertinoIcons.lock, size: 20),
                    ),
                    obscureText: true,
                    padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                    decoration: BoxDecoration(
                      color: CupertinoColors.systemGrey6,
                      borderRadius: BorderRadius.circular(8),
                    ),
                  ),
                ],
              ),
            ),
          ),
          actions: [
            CupertinoDialogAction(
              child: Text(l10n.cancel),
              onPressed: () => Navigator.pop(context, false),
            ),
            CupertinoDialogAction(
              isDefaultAction: true,
              child: Text(isEdit ? l10n.save : l10n.addPlatform),
              onPressed: () {
                if (nameController.text.trim().isEmpty) {
                  return;
                }
                if (endpointController.text.trim().isEmpty) {
                  return;
                }
                Navigator.pop(context, true);
              },
            ),
          ],
        ),
      ),
    );

    if (result == true && mounted) {
      final newPlatform = AIPlatform(
        id: platform?.id ?? DateTime.now().millisecondsSinceEpoch.toString(),
        name: nameController.text.trim(),
        type: selectedType,
        endpoint: endpointController.text.trim(),
        apiKey: apiKeyController.text.trim(),
        availableModels: platform?.availableModels ?? AIPlatform.createDefaultPlatform(selectedType).availableModels,
        defaultModel: platform?.defaultModel ?? AIPlatform.createDefaultPlatform(selectedType).defaultModel,
        enabled: true,
        lastModelUpdate: platform?.lastModelUpdate,
        icon: selectedType,
      );

      await _settingsService.savePlatform(newPlatform);
      await _loadData();
    }
  }

  /// 构建平台类型选择按钮
  Widget _buildPlatformTypeButton(
    String type,
    String label,
    String svgPath,
    String currentType,
    Function(String) onTap,
  ) {
    final isSelected = type == currentType;
    final brightness = CupertinoTheme.of(context).brightness;

    return GestureDetector(
      onTap: () => onTap(type),
      child: Container(
        padding: const EdgeInsets.all(10),
        decoration: BoxDecoration(
          color: isSelected
              ? (brightness == Brightness.dark
                  ? CupertinoColors.activeBlue.darkColor
                  : CupertinoColors.activeBlue.color)
              : (brightness == Brightness.dark
                  ? CupertinoColors.systemGrey6.darkColor
                  : CupertinoColors.systemGrey6.color),
          borderRadius: BorderRadius.circular(10),
          border: Border.all(
            color: isSelected
                ? CupertinoColors.transparent
                : (brightness == Brightness.dark
                    ? CupertinoColors.systemGrey5.darkColor
                    : CupertinoColors.systemGrey5.color),
            width: 1,
          ),
        ),
        child: SizedBox(
          width: 40,
          height: 40,
          child: SvgPicture.asset(
            svgPath,
            colorFilter: ColorFilter.mode(
              isSelected
                  ? CupertinoColors.white
                  : (brightness == Brightness.dark
                      ? CupertinoColors.label.darkColor
                      : CupertinoColors.label.color),
              BlendMode.srcIn,
            ),
          ),
        ),
      ),
    );
  }

  /// 显示模型选择和刷新对话框
  Future<void> _showModelsDialog(AIPlatform platform) async {
    final l10n = AppLocalizations.of(context)!;
    String? selectedModel = platform.defaultModel;
    List<String> models = List.from(platform.availableModels);

    // 根据屏幕大小动态计算对话框高度
    final screenHeight = MediaQuery.of(context).size.height;
    final dialogHeight = (screenHeight * 0.6).clamp(200.0, 600.0).toDouble();
    final listHeight = (dialogHeight - 180.0).toDouble();

    final result = await showCupertinoDialog<Object>(
      context: context,
      builder: (context) => StatefulBuilder(
        builder: (context, setDialogState) => CupertinoAlertDialog(
          title: Text('${l10n.manageModels} - ${platform.name}'),
          content: SizedBox(
            width: double.maxFinite,
            height: dialogHeight,
            child: Column(
              children: [
                // 当前选择的模型
                Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: CupertinoColors.systemGrey6,
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Row(
                    children: [
                      const Icon(CupertinoIcons.checkmark_circle, color: CupertinoColors.systemGreen),
                      const SizedBox(width: 8),
                      Expanded(
                        child: Text(
                          selectedModel ?? l10n.noModelSelected,
                          style: const TextStyle(fontWeight: FontWeight.w500),
                        ),
                      ),
                    ],
                  ),
                ),
                // 添加模型按钮
                CupertinoButton(
                  padding: const EdgeInsets.symmetric(vertical: 12),
                  onPressed: () async {
                    final addController = TextEditingController();
                    final addResult = await showCupertinoDialog<String>(
                      context: context,
                      builder: (context) => CupertinoAlertDialog(
                        title: Text(l10n.addModelTitle),
                        content: SizedBox(
                          width: MediaQuery.of(context).size.width * 0.8,
                          child: CupertinoTextField(
                            controller: addController,
                            placeholder: l10n.modelNamePh,
                            autofocus: true,
                          ),
                        ),
                        actions: [
                          CupertinoDialogAction(
                            child: Text(l10n.cancel),
                            onPressed: () => Navigator.pop(context),
                          ),
                          CupertinoDialogAction(
                            isDefaultAction: true,
                            child: Text(l10n.add),
                            onPressed: () {
                              if (addController.text.trim().isNotEmpty) {
                                Navigator.pop(context, addController.text.trim());
                              }
                            },
                          ),
                        ],
                      ),
                    );
                    if (addResult != null && mounted) {
                      setDialogState(() {
                        if (!models.contains(addResult)) {
                          models.add(addResult);
                        }
                      });
                    }
                  },
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Container(
                        padding: const EdgeInsets.all(6),
                        decoration: BoxDecoration(
                          color: CupertinoColors.activeBlue,
                          shape: BoxShape.circle,
                        ),
                        child: const Icon(CupertinoIcons.add, color: CupertinoColors.white, size: 16),
                      ),
                      const SizedBox(width: 8),
                      Text(l10n.addNewModel),
                    ],
                  ),
                ),
                const SizedBox(height: 8),
                // 模型列表
                SizedBox(
                  height: listHeight,
                  child: models.isEmpty
                      ? Center(
                          child: Column(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              const Icon(CupertinoIcons.doc_text_search, size: 32, color: CupertinoColors.systemGrey),
                              const SizedBox(height: 8),
                              Text(l10n.noModelsAvailable),
                            ],
                          ),
                        )
                      : ListView.builder(
                          itemCount: models.length,
                          itemBuilder: (context, index) {
                            final model = models[index];
                            final isSelected = model == selectedModel;
                            return GestureDetector(
                              onTap: () {
                                setDialogState(() {
                                  selectedModel = model;
                                });
                              },
                              child: Container(
                                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
                                decoration: BoxDecoration(
                                  color: isSelected ? CupertinoColors.activeBlue.withValues(alpha: 0.08) : null,
                                ),
                                child: Row(
                                  children: [
                                    Container(
                                      width: 20,
                                      height: 20,
                                      decoration: BoxDecoration(
                                        shape: BoxShape.circle,
                                        border: Border.all(
                                          color: isSelected ? CupertinoColors.activeBlue : CupertinoColors.systemGrey4,
                                        ),
                                      ),
                                      child: isSelected
                                          ? const Center(
                                              child: Icon(CupertinoIcons.check_mark, size: 14, color: CupertinoColors.activeBlue),
                                            )
                                          : null,
                                    ),
                                    const SizedBox(width: 12),
                                    Expanded(
                                      child: Text(model),
                                    ),
                                    CupertinoButton(
                                      padding: EdgeInsets.zero,
                                      minimumSize: const Size(28, 28),
                                      onPressed: () async {
                                        final confirm = await showCupertinoDialog<bool>(
                                          context: context,
                                          builder: (context) => CupertinoAlertDialog(
                                            title: Text(l10n.deleteModelTitle),
                                            content: Text(l10n.deleteModelConfirm(model)),
                                            actions: [
                                              CupertinoDialogAction(
                                                child: Text(l10n.cancel),
                                                onPressed: () => Navigator.pop(context, false),
                                              ),
                                              CupertinoDialogAction(
                                                isDestructiveAction: true,
                                                child: Text(l10n.delete),
                                                onPressed: () => Navigator.pop(context, true),
                                              ),
                                            ],
                                          ),
                                        );
                                        if (confirm == true && mounted) {
                                          setDialogState(() {
                                            models.removeAt(index);
                                            if (selectedModel == model) {
                                              selectedModel = models.isNotEmpty ? models.first : null;
                                            }
                                          });
                                        }
                                      },
                                      child: const Icon(CupertinoIcons.delete, size: 20, color: CupertinoColors.systemRed),
                                    ),
                                  ],
                                ),
                              ),
                            );
                          },
                        ),
                ),
                const SizedBox(height: 8),
              ],
            ),
          ),
          actions: [
            CupertinoDialogAction(
              child: Text(l10n.cancel),
              onPressed: () => Navigator.pop(context, false),
            ),
            CupertinoDialogAction(
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(CupertinoIcons.refresh, size: 16, color: CupertinoColors.activeBlue),
                  const SizedBox(width: 4),
                  Text(l10n.refreshModels),
                ],
              ),
              onPressed: () async {
                Navigator.pop(context, true);
                // 刷新模型列表
                await _refreshPlatformModels(platform);
              },
            ),
            if (selectedModel != null)
              CupertinoDialogAction(
                isDefaultAction: true,
                child: Text(l10n.save),
                onPressed: () {
                  Navigator.pop(context, 'save');
                },
              ),
          ],
        ),
      ),
    );

    if (result == 'save' && mounted) {
      // 保存更新后的模型列表和默认模型
      final updatedPlatform = platform.copyWith(
        availableModels: models,
        defaultModel: selectedModel ?? '',
        lastModelUpdate: DateTime.now(),
      );
      debugPrint('保存平台配置: id=${platform.id}, name=${platform.name}');
      debugPrint('原默认模型: ${platform.defaultModel}, 新默认模型: $selectedModel');
      debugPrint('原模型列表: ${platform.availableModels.length}个');
      debugPrint('新模型列表: ${models.length}个');
      await _settingsService.savePlatform(updatedPlatform);

      // 如果更新的平台是当前平台，同步更新全局模型设置
      final currentPlatformId = await _settingsService.getCurrentPlatformId();
      if (platform.id == currentPlatformId && updatedPlatform.defaultModel.isNotEmpty) {
        await _settingsService.setModel(updatedPlatform.defaultModel);
      }

      await _loadData();
    } else if (result == true && mounted) {
      // 刷新后重新加载
      await _loadData();
    }
  }

  /// 刷新平台模型列表
  Future<List<String>?> _refreshPlatformModels(AIPlatform platform) async {
    final l10n = AppLocalizations.of(context)!;

    if (platform.apiKey.isEmpty) {
      _showError(l10n.configureApiKeyFirst);
      return null;
    }

    setState(() {
      _loadingPlatforms.add(platform.id);
    });

    try {
      final models = await _fetchModelsFromApi(platform);
      if (mounted) {
        // 只更新模型列表，不自动设置默认模型
        // 保留原来的默认模型，如果原模型不在新列表中，则清空默认模型
        final newDefaultModel = models.contains(platform.defaultModel)
            ? platform.defaultModel
            : null;

        await _settingsService.updatePlatformModels(
          platform.id,
          models,
          newDefaultModel: newDefaultModel,
        );

        // 如果刷新的平台是当前平台，同步更新全局模型设置
        final currentPlatformId = await _settingsService.getCurrentPlatformId();
        if (platform.id == currentPlatformId && newDefaultModel != null && newDefaultModel.isNotEmpty) {
          await _settingsService.setModel(newDefaultModel);
        }

        await _loadData();
        _showSuccess(l10n.modelsRefreshed);
        return models;
      }
      return null;
    } catch (e) {
      if (mounted) {
        _showError(l10n.refreshModelsError(e.toString()));
      }
      return null;
    } finally {
      if (mounted) {
        setState(() {
          _loadingPlatforms.remove(platform.id);
        });
      }
    }
  }

  /// 从API获取模型列表
  Future<List<String>> _fetchModelsFromApi(AIPlatform platform) async {
    final client = HttpClient();

    if (platform.type == 'gemini') {
      try {
        // URL: https://generativelanguage.googleapis.com/v1beta/models?key=XXX
        var endpoint = platform.endpoint;
        if (endpoint.endsWith('/')) {
          endpoint = endpoint.substring(0, endpoint.length - 1);
        }
        final modelsUrl = '$endpoint/models?key=${platform.apiKey}';

        final request = await client.getUrl(Uri.parse(modelsUrl));
        final response = await request.close();
        final responseBody = await response.transform(utf8.decoder).join();

        if (response.statusCode != 200) {
          throw Exception('API returned error: ${response.statusCode}\nURL: $modelsUrl\n$responseBody');
        }

        final data = jsonDecode(responseBody);
        // 排除 embedding、imagen、veo、tts 等专用模型
        if (data is Map && data.containsKey('models')) {
          final modelsData = data['models'] as List;
          final excludedPatterns = [
            'embedding',    // text embedding 模型
            'imagen',       // image generation 模型
            'veo',          // video generation 模型
            '-tts',         // TTS 模型
            'robotics',     // 机器人专用模型
            'computer-use', // 计算机使用专用模型
            'nano-banana',  // 图像生成模型
            'aqa',          // Attributed Question Answering
            'deep-research', // 深度研究专用模型
          ];
          return modelsData
              .where((m) {
                final name = m['name'] as String? ?? '';
                final methods = m['supportedGenerationMethods'] as List? ?? [];
                if (!methods.contains('generateContent')) return false;
                for (final pattern in excludedPatterns) {
                  if (name.contains(pattern)) return false;
                }
                return true;
              })
              .map((m) => m['name'] as String)
              .toList();
        }

        throw Exception('API returned invalid format');
      } finally {
        client.close();
      }
    }

    // ZhiPu 使用直接路径
    if (platform.type == 'zhipu') {
      try {
        final modelsUrl = '${platform.endpoint}/models';
        final request = await client.getUrl(Uri.parse(modelsUrl));
        request.headers.add('Authorization', 'Bearer ${platform.apiKey}');

        final response = await request.close();
        final responseBody = await response.transform(utf8.decoder).join();

        if (response.statusCode != 200) {
          throw Exception('API returned error: ${response.statusCode}\n$responseBody');
        }

        final data = jsonDecode(responseBody);
        if (data is Map && data.containsKey('data')) {
          final modelsData = data['data'] as List;
          return modelsData.map((m) => m['id'] as String).toList();
        }

        throw Exception('API returned invalid format');
      } finally {
        client.close();
      }
    }

    // 其他平台使用 OpenAI 兼容格式
    try {
      // 构建正确的模型列表URL
      String modelsUrl;
      if (platform.endpoint.endsWith('/v1')) {
        modelsUrl = '${platform.endpoint}/models';
      } else if (platform.endpoint.contains('/v1/')) {
        modelsUrl = '$platform.endpoint/models';
      } else {
        modelsUrl = '${platform.endpoint}/v1/models';
      }

      final request = await client.getUrl(Uri.parse(modelsUrl));
      request.headers.add('Authorization', 'Bearer ${platform.apiKey}');

      final response = await request.close();
      final responseBody = await response.transform(utf8.decoder).join();

      if (response.statusCode != 200) {
        throw Exception('API returned error: ${response.statusCode}\n$responseBody');
      }

      final data = jsonDecode(responseBody);
      if (data is Map && data.containsKey('data')) {
        final modelsData = data['data'] as List;
        return modelsData.map((m) => m['id'] as String).toList();
      }

      throw Exception('API returned invalid format');
    } finally {
      client.close();
    }
  }

  /// 删除平台
  Future<void> _deletePlatform(AIPlatform platform) async {
    final l10n = AppLocalizations.of(context)!;
    final result = await showCupertinoDialog<bool>(
      context: context,
      builder: (context) => CupertinoAlertDialog(
        title: Text(l10n.deletePlatform),
        content: Text(l10n.deletePlatformConfirm(platform.name)),
        actions: [
          CupertinoDialogAction(
            child: Text(l10n.cancel),
            onPressed: () => Navigator.pop(context, false),
          ),
          CupertinoDialogAction(
            isDestructiveAction: true,
            child: Text(l10n.delete),
            onPressed: () => Navigator.pop(context, true),
          ),
        ],
      ),
    );

    if (result == true && mounted) {
      await _settingsService.deletePlatform(platform.id);
      await _loadData();
    }
  }

  /// 切换当前平台
  Future<void> _switchPlatform(AIPlatform platform) async {
    final l10n = AppLocalizations.of(context)!;

    // 检查平台是否已配置
    if (!platform.isConfigured) {
      _showError(l10n.configureApiKeyFirst);
      return;
    }

    // 检查是否有选择模型
    if (platform.defaultModel.isEmpty) {
      _showError(l10n.selectModelFirst);
      return;
    }

    // 显示加载状态，让用户知道正在处理
    setState(() {
      _isLoading = true;
    });

    // 更新平台ID
    await _settingsService.setCurrentPlatformId(platform.id);

    // 同时更新旧的API设置到新平台，确保立即生效
    await _settingsService.setApiEndpoint(platform.endpoint);
    await _settingsService.setApiKey(platform.apiKey);
    await _settingsService.setModel(platform.defaultModel);
    await _settingsService.setApiType(platform.type);

    // 刷新页面显示并确保状态已更新
    final newCurrentId = await _settingsService.getCurrentPlatformId();
    setState(() {
      _currentPlatformId = newCurrentId;
      _isLoading = false;
    });

    if (mounted) {
      _showSuccess(l10n.switchedToPlatform(platform.name));
    }
  }

  void _showError(String message) {
    showCupertinoDialog(
      context: context,
      builder: (context) => CupertinoAlertDialog(
        title: Text(AppLocalizations.of(context)!.error),
        content: Text(message),
        actions: [
          CupertinoDialogAction(
            child: Text(AppLocalizations.of(context)!.ok),
            onPressed: () => Navigator.pop(context),
          ),
        ],
      ),
    );
  }

  void _showSuccess(String message) {
    showCupertinoDialog(
      context: context,
      builder: (context) => CupertinoAlertDialog(
        title: Text(AppLocalizations.of(context)!.saveSuccess),
        content: Text(message),
        actions: [
          CupertinoDialogAction(
            child: Text(AppLocalizations.of(context)!.ok),
            onPressed: () => Navigator.pop(context),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;

    return CupertinoPageScaffold(
      navigationBar: CupertinoNavigationBar(
        middle: Text(l10n.platformAndModel),
        trailing: CupertinoButton(
          padding: EdgeInsets.zero,
          onPressed: _showPlatformDialog,
          child: const Icon(CupertinoIcons.add),
        ),
      ),
      child: SafeArea(
        child: _isLoading
            ? const Center(child: CupertinoActivityIndicator())
            : _platforms.isEmpty
                ? _buildEmptyState()
                : ListView.builder(
                    padding: const EdgeInsets.all(16),
                    itemCount: _platforms.length,
                    itemBuilder: (context, index) {
                      final platform = _platforms[index];
                      final isCurrent = platform.id == _currentPlatformId;
                      final isLoading = _loadingPlatforms.contains(platform.id);
                      return _buildPlatformCard(platform, isCurrent, isLoading);
                    },
                  ),
      ),
    );
  }

  Widget _buildPlatformCard(AIPlatform platform, bool isCurrent, bool isLoading) {
    final l10n = AppLocalizations.of(context)!;
    final brightness = CupertinoTheme.of(context).brightness;

    return GestureDetector(
      onTap: platform.isConfigured && platform.defaultModel.isNotEmpty && !isCurrent
          ? () => _switchPlatform(platform)
          : null,
      child: Container(
        margin: const EdgeInsets.only(bottom: 12),
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: brightness == Brightness.dark
              ? CupertinoColors.systemBackground.darkColor
              : CupertinoColors.systemBackground.color,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(
            color: isCurrent
                ? CupertinoColors.activeBlue
                : CupertinoColors.systemGrey4,
            width: isCurrent ? 2 : 1,
          ),
        ),
        child: Row(
          children: [
            _buildPlatformIcon(platform.type),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Text(
                        platform.name,
                        style: TextStyle(
                          fontSize: 17,
                          fontWeight: isCurrent ? FontWeight.w600 : FontWeight.normal,
                        ),
                      ),
                      if (isCurrent) ...[
                        const SizedBox(width: 8),
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                          decoration: BoxDecoration(
                            color: CupertinoColors.activeBlue,
                            borderRadius: BorderRadius.circular(4),
                          ),
                          child: Text(
                            l10n.current,
                            style: const TextStyle(
                              fontSize: 11,
                              color: CupertinoColors.white,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                        ),
                      ],
                    ],
                  ),
                  const SizedBox(height: 4),
                  Row(
                    children: [
                      Icon(
                        platform.apiKey.isNotEmpty
                            ? CupertinoIcons.checkmark_circle_fill
                            : CupertinoIcons.circle_fill,
                        size: 14,
                        color: platform.apiKey.isNotEmpty
                            ? CupertinoColors.systemGreen
                            : CupertinoColors.systemGrey,
                      ),
                      const SizedBox(width: 4),
                      Text(
                        platform.apiKey.isNotEmpty ? l10n.configured : l10n.notConfigured,
                        style: TextStyle(
                          fontSize: 13,
                          color: brightness == Brightness.dark
                              ? CupertinoColors.systemGrey.darkColor
                              : CupertinoColors.systemGrey,
                        ),
                      ),
                      if (platform.defaultModel.isNotEmpty) ...[
                        const SizedBox(width: 8),
                        const Icon(
                          CupertinoIcons.bolt_fill,
                          size: 14,
                          color: CupertinoColors.systemOrange,
                        ),
                        const SizedBox(width: 4),
                        Text(
                          platform.defaultModel,
                          style: const TextStyle(
                            fontSize: 13,
                            color: CupertinoColors.activeBlue,
                          ),
                          overflow: TextOverflow.ellipsis,
                        ),
                      ],
                    ],
                  ),
                ],
              ),
            ),
            if (platform.apiKey.isNotEmpty && isCurrent)
              CupertinoButton(
                padding: EdgeInsets.zero,
                minimumSize: const Size(32, 32),
                onPressed: isLoading ? null : () => _refreshPlatformModels(platform),
                child: isLoading
                    ? const CupertinoActivityIndicator(radius: 8)
                    : const Icon(
                        CupertinoIcons.refresh,
                        size: 20,
                        color: CupertinoColors.systemBlue,
                      ),
              ),
            const SizedBox(width: 8),
            CupertinoButton(
              padding: EdgeInsets.zero,
              minimumSize: const Size(32, 32),
              onPressed: () => _showPlatformOptions(platform),
              child: const Icon(
                CupertinoIcons.ellipsis,
                color: CupertinoColors.systemGrey,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildEmptyState() {
    final l10n = AppLocalizations.of(context)!;
    final brightness = CupertinoTheme.of(context).brightness;

    return Column(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        const SizedBox(height: 60),
        Icon(
          CupertinoIcons.cube_box,
          size: 80,
          color: brightness == Brightness.dark
              ? CupertinoColors.systemGrey.darkColor
              : CupertinoColors.systemGrey3,
        ),
        const SizedBox(height: 24),
        Text(
          l10n.noPlatformsConfigured,
          style: TextStyle(
            fontSize: 22,
            fontWeight: FontWeight.w600,
            color: brightness == Brightness.dark
                ? CupertinoColors.label.darkColor
                : CupertinoColors.label.color,
          ),
        ),
        const SizedBox(height: 8),
        Text(
          l10n.addPlatformHint,
          style: TextStyle(
            fontSize: 15,
            color: brightness == Brightness.dark
                ? CupertinoColors.secondaryLabel.darkColor
                : CupertinoColors.secondaryLabel.color,
          ),
          textAlign: TextAlign.center,
        ),
        const SizedBox(height: 32),
        CupertinoButton.filled(
          onPressed: _showPlatformDialog,
          borderRadius: BorderRadius.circular(12),
          padding: const EdgeInsets.symmetric(horizontal: 32, vertical: 12),
          child: Text(l10n.addPlatform),
        ),
        const SizedBox(height: 20),
      ],
    );
  }

  void _showPlatformOptions(AIPlatform platform) {
    final l10n = AppLocalizations.of(context)!;
    showCupertinoModalPopup(
      context: context,
      builder: (context) => CupertinoActionSheet(
        actions: [
          CupertinoActionSheetAction(
            child: Text(l10n.manageModels),
            onPressed: () {
              Navigator.pop(context);
              _showModelsDialog(platform);
            },
          ),
          CupertinoActionSheetAction(
            child: Text(l10n.edit),
            onPressed: () {
              Navigator.pop(context);
              _showPlatformDialog(platform);
            },
          ),
          CupertinoActionSheetAction(
            isDestructiveAction: true,
            child: Text(l10n.delete),
            onPressed: () {
              Navigator.pop(context);
              _deletePlatform(platform);
            },
          ),
        ],
        cancelButton: CupertinoActionSheetAction(
          child: Text(l10n.cancel),
          onPressed: () => Navigator.pop(context),
        ),
      ),
    );
  }

  /// 构建平台图标
  Widget _buildPlatformIcon(String type) {
    return SizedBox(
      width: 32,
      height: 32,
      child: SvgPicture.asset(
        'assets/platform/$type.svg',
        fit: BoxFit.contain,
        placeholderBuilder: (context) => Container(
          padding: const EdgeInsets.all(6),
          decoration: BoxDecoration(
            color: _getPlatformColor(type).withValues(alpha: 0.15),
            borderRadius: BorderRadius.circular(8),
          ),
          child: Icon(
            _getFallbackIcon(type),
            color: _getPlatformColor(type),
            size: 20,
          ),
        ),
      ),
    );
  }

  /// 获取备用图标（当SVG不存在时使用）
  IconData _getFallbackIcon(String type) {
    switch (type) {
      case 'openai':
        return CupertinoIcons.cloud;
      case 'claude':
        return CupertinoIcons.bolt;
      case 'deepseek':
        return CupertinoIcons.search;
      case 'gemini':
        return CupertinoIcons.star_fill;
      case 'siliconflow':
        return CupertinoIcons.flame_fill;
      case 'minimax':
        return CupertinoIcons.sparkles;
      case 'zhipu':
        return CupertinoIcons.heart_fill;
      case 'kimi':
        return CupertinoIcons.moon_fill;
      case 'lmstudio':
        return CupertinoIcons.building_2_fill;
      case 'other':
        return CupertinoIcons.question_circle;
      default:
        return CupertinoIcons.cube_box;
    }
  }

  /// 获取平台颜色（用于备用图标）
  Color _getPlatformColor(String type) {
    switch (type) {
      case 'openai':
        return const Color(0xFF10A37F);
      case 'claude':
        return const Color(0xFFCC785C);
      case 'deepseek':
        return const Color(0xFF4D6BFE);
      case 'gemini':
        return const Color(0xFF4285F4);
      case 'siliconflow':
        return const Color(0xFF5865F2);
      case 'minimax':
        return const Color(0xFFD4367A);
      case 'zhipu':
        return const Color(0xFFE11D48);
      case 'kimi':
        return const Color(0xFF6B57FF);
      case 'lmstudio':
        return const Color(0xFF00BFFF);
      case 'other':
        return const Color(0xFF8E8E93);
      default:
        return CupertinoColors.systemBlue;
    }
  }
}
