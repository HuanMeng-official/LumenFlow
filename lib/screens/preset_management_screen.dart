import 'dart:io';

import 'package:flutter/cupertino.dart';
import 'package:file_picker/file_picker.dart';
import 'package:url_launcher/url_launcher.dart';
import '../services/prompt_service.dart';
import '../services/http_server_service.dart';
import '../models/prompt_preset.dart';
import '../l10n/app_localizations.dart';

/// 预设管理界面
///
/// 显示内置预设和用户预设，支持导入XML文件作为新预设
class PresetManagementScreen extends StatefulWidget {
  const PresetManagementScreen({super.key});

  @override
  State<PresetManagementScreen> createState() => _PresetManagementScreenState();
}

class _PresetManagementScreenState extends State<PresetManagementScreen> {
  final PromptService _promptService = PromptService();
  final HttpServerService _httpServerService = HttpServerService();

  List<PromptPreset> _builtInPresets = [];
  List<PromptPreset> _userPresets = [];
  bool _isLoading = true;
  String? _errorMessage;

  // HTTP服务器状态
  bool _isHttpServerRunning = false;
  String? _httpServerUrl;

  @override
  void initState() {
    super.initState();
    _loadPresets();
    _initHttpServerState();
  }

  /// 初始化HTTP服务器状态
  void _initHttpServerState() {
    // 设置初始状态
    _isHttpServerRunning = _httpServerService.isRunning;
    _httpServerUrl = _httpServerService.serverUrl;

    // 监听状态变化
    _httpServerService.isRunningNotifier.addListener(_updateHttpServerRunningState);
    _httpServerService.serverUrlNotifier.addListener(_updateHttpServerUrlState);
  }

  /// 更新HTTP服务器运行状态
  void _updateHttpServerRunningState() {
    if (mounted) {
      setState(() {
        _isHttpServerRunning = _httpServerService.isRunningNotifier.value;
      });
    }
  }

  /// 更新HTTP服务器URL状态
  void _updateHttpServerUrlState() {
    if (mounted) {
      setState(() {
        _httpServerUrl = _httpServerService.serverUrlNotifier.value;
      });
    }
  }

  @override
  void dispose() {
    // 移除监听器
    _httpServerService.isRunningNotifier.removeListener(_updateHttpServerRunningState);
    _httpServerService.serverUrlNotifier.removeListener(_updateHttpServerUrlState);
    super.dispose();
  }

  /// 切换HTTP服务器状态
  Future<void> _toggleHttpServer() async {
    final l10n = AppLocalizations.of(context)!;
    try {
      await _httpServerService.toggle();
    } catch (e) {
      if (mounted) {
        _showErrorMessage(l10n.httpServerOperationFailed(e.toString()));
      }
    }
  }

  /// 加载预设列表
  Future<void> _loadPresets() async {
    if (!mounted) return;
    if (mounted) {
      setState(() {
        _isLoading = true;
        _errorMessage = null;
      });
    }

    try {
      // 分别加载内置预设和用户预设
      // 注意：由于loadPresets返回合并列表，我们需要分别获取
      // 这里我们直接调用内部方法或通过其他方式区分
      // 暂时先加载所有预设，然后根据ID前缀区分
      final allPresets = await _promptService.loadPresets();
      if (mounted) {
        setState(() {
          _builtInPresets = allPresets.where((preset) => !preset.id.startsWith('user_')).toList();
          _userPresets = allPresets.where((preset) => preset.id.startsWith('user_')).toList();
        });
      }
    } catch (e) {
      if (mounted) {
        final l10n = AppLocalizations.of(context)!;
        setState(() {
          _errorMessage = l10n.loadPresetsFailed(e.toString());
        });
      }
    } finally {
      if (mounted) {
        setState(() {
          _isLoading = false;
        });
      }
    }
  }

  /// 导入XML文件
  Future<void> _importXmlFile() async {
    if (!mounted) return;
    final l10n = AppLocalizations.of(context)!;
    try {
      final result = await FilePicker.platform.pickFiles(
        type: FileType.custom,
        allowedExtensions: ['xml'],
        allowMultiple: false,
      );

      if (result == null || result.files.isEmpty) return;

      final platformFile = result.files.first;
      if (platformFile.path == null || platformFile.path!.isEmpty) {
        if (mounted) {
          _showErrorMessage(l10n.filePathError);
        }
        return;
      }
      // 需要将PlatformFile转换为File
      // 由于FilePicker返回的是PlatformFile，我们需要使用其路径创建File对象
      final xmlFile = File(platformFile.path!);

      // 显示导入对话框，允许用户编辑预设信息
      final preset = await _showImportDialog(xmlFile);
      if (preset != null) {
        // 导入成功，重新加载列表
        await _loadPresets();
        // 导入成功，已重新加载列表
      }
    } catch (e) {
      if (mounted) {
        _showErrorMessage(l10n.importFailedError(e.toString()));
      }
    }
  }

  /// 显示导入对话框
  Future<PromptPreset?> _showImportDialog(File xmlFile) async {
    if (!mounted) return null;
    final l10n = AppLocalizations.of(context)!;
    String? name;
    String? description;
    String? author;

    return await showCupertinoModalPopup<PromptPreset?>(
      context: context,
      builder: (context) {
        return CupertinoAlertDialog(
          title: Text(l10n.importPresetDialogTitle),
          content: Column(
            children: [
              CupertinoTextField(
                placeholder: l10n.presetNamePlaceholder,
                onChanged: (value) => name = value,
              ),
              const SizedBox(height: 8),
              CupertinoTextField(
                placeholder: l10n.descriptionPlaceholder,
                onChanged: (value) => description = value,
              ),
              const SizedBox(height: 8),
              CupertinoTextField(
                placeholder: l10n.authorPlaceholder,
                onChanged: (value) => author = value,
              ),
            ],
          ),
          actions: [
            CupertinoDialogAction(
              child: Text(l10n.cancel),
              onPressed: () => Navigator.pop(context),
            ),
            CupertinoDialogAction(
              child: Text(l10n.importButton),
              onPressed: () async {
                final dialogContext = context;
                try {
                  final preset = await _promptService.importPresetFromXml(
                    xmlFile,
                    name: name,
                    description: description,
                    author: author,
                  );
                  if (mounted) {
                    // ignore: use_build_context_synchronously
                    Navigator.pop(dialogContext, preset);
                  }
                } catch (e) {
                  if (mounted) {
                    // ignore: use_build_context_synchronously
                    Navigator.pop(dialogContext);
                    _showErrorMessage(l10n.importFailedError(e.toString()));
                  }
                }
              },
            ),
          ],
        );
      },
    );
  }

  /// 删除用户预设
  Future<void> _deleteUserPreset(PromptPreset preset) async {
    if (!mounted) return;
    final l10n = AppLocalizations.of(context)!;
    final confirmed = await showCupertinoModalPopup<bool>(
      context: context,
      builder: (context) => CupertinoAlertDialog(
        title: Text(l10n.deletePresetDialogTitle),
        content: Text(l10n.deletePresetConfirm(preset.name)),
        actions: [
          CupertinoDialogAction(
            child: Text(l10n.cancel),
            onPressed: () => Navigator.pop(context, false),
          ),
          CupertinoDialogAction(
            child: Text(l10n.delete),
            onPressed: () => Navigator.pop(context, true),
          ),
        ],
      ),
    );

    if (confirmed == true) {
      try {
        await _promptService.deleteUserPreset(preset.id);
        if (mounted) {
          await _loadPresets();
          // 删除成功，已重新加载列表
        }
      } catch (e) {
        if (mounted) {
          _showErrorMessage(l10n.deleteFailedError(e.toString()));
        }
      }
    }
  }

  /// 显示错误消息
  void _showErrorMessage(String message) {
    showCupertinoSnackBar(
      context: context,
      message: message,
      duration: const Duration(seconds: 3),
    );
  }

  /// 打开角色卡生成器网页
  Future<void> _launchRoleCardGenerator() async {
    final l10n = AppLocalizations.of(context)!;

    if (!_isHttpServerRunning) {
      // 服务器未运行，询问是否启动
      final confirmed = await showCupertinoModalPopup<bool>(
        context: context,
        builder: (context) => CupertinoAlertDialog(
          title: Text(l10n.httpServerNotRunningTitle),
          content: Text(l10n.httpServerNotRunningMessage),
          actions: [
            CupertinoDialogAction(
              child: Text(l10n.cancel),
              onPressed: () => Navigator.pop(context, false),
            ),
            CupertinoDialogAction(
              child: Text(l10n.startServerButton),
              onPressed: () => Navigator.pop(context, true),
            ),
          ],
        ),
      );

      if (confirmed != true) {
        return; // 用户取消
      }

      // 启动服务器
      await _toggleHttpServer();

      // 等待服务器启动
      await Future.delayed(const Duration(milliseconds: 500));
    }

    // 现在服务器应该运行了，打开URL
    final url = Uri.parse('http://127.0.0.1:5050/');
    try {
      if (!await launchUrl(url)) {
        throw Exception('Could not launch $url');
      }
    } catch (e) {
      if (mounted) {
        _showErrorMessage(l10n.openLinkFailed(e.toString()));
      }
    }
  }

  /// 为子部件添加分隔线
  List<Widget> _addDividers(List<Widget> children) {
    final List<Widget> dividedChildren = [];
    for (int i = 0; i < children.length; i++) {
      dividedChildren.add(children[i]);
      if (i < children.length - 1) {
        dividedChildren.add(
          Container(
            height: 0.5,
            margin: const EdgeInsets.symmetric(horizontal: 16),
            color: CupertinoColors.systemGrey4,
          ),
        );
      }
    }
    return dividedChildren;
  }

  Widget _buildSection(BuildContext context, String title, List<Widget> children) {
    final brightness = CupertinoTheme.of(context).brightness;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.fromLTRB(16, 20, 16, 8),
          child: Text(
            title,
            style: const TextStyle(
              fontSize: 13,
              color: CupertinoColors.systemGrey,
              fontWeight: FontWeight.w500,
            ),
          ),
        ),
        Container(
          margin: const EdgeInsets.symmetric(horizontal: 16),
          decoration: BoxDecoration(
            color: brightness == Brightness.dark
                ? CupertinoColors.systemBackground.darkColor
                : CupertinoColors.systemBackground.color,
            borderRadius: BorderRadius.circular(12),
            border: Border.all(
              color: CupertinoColors.systemGrey4,
              width: 0.5,
            ),
          ),
          child: Column(
            children: _addDividers(children),
          ),
        ),
      ],
    );
  }

  /// 构建预设列表项
  Widget _buildPresetItem(PromptPreset preset, bool isUserPreset) {
    final brightness = CupertinoTheme.of(context).brightness;
    final isDarkMode = brightness == Brightness.dark;

    return GestureDetector(
      onTap: () {
        // 可以查看详情或编辑
        _showPresetDetails(preset);
      },
      child: Container(
        padding: const EdgeInsets.all(16),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // 图标
            Container(
              width: 36,
              height: 36,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                border: Border.all(
                  color: CupertinoColors.systemGrey.withAlpha(3),
                  width: 1,
                ),
              ),
              child: Icon(
                CupertinoIcons.person_fill,
                size: 20,
                color: CupertinoColors.activeBlue,
              ),
            ),
            const SizedBox(width: 12),
            // 名称和描述
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    preset.name,
                    style: TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.w500,
                      color: isDarkMode
                          ? CupertinoColors.label.darkColor
                          : CupertinoColors.label.color,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    preset.description,
                    style: TextStyle(
                      fontSize: 14,
                      color: isDarkMode
                          ? CupertinoColors.systemGrey.darkColor
                          : CupertinoColors.systemGrey,
                    ),
                  ),
                ],
              ),
            ),
            // 删除按钮（仅用户预设）
            if (isUserPreset)
              CupertinoButton(
                padding: EdgeInsets.zero,
                onPressed: () => _deleteUserPreset(preset),
                child: const Icon(
                  CupertinoIcons.delete,
                  color: CupertinoColors.destructiveRed,
                ),
              ),
          ],
        ),
      ),
    );
  }

  /// 显示预设详情
  void _showPresetDetails(PromptPreset preset) {
    final l10n = AppLocalizations.of(context)!;
    showCupertinoModalPopup(
      context: context,
      builder: (context) => CupertinoAlertDialog(
        title: Text(preset.name),
        content: SingleChildScrollView(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text('${l10n.authorLabel} ${preset.author}'),
              Text('${l10n.versionLabel} ${preset.version}'),
              const SizedBox(height: 8),
              Text('${l10n.descriptionLabel} ${preset.description}'),
              const SizedBox(height: 8),
              Text(l10n.systemPromptLabel),
              Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: CupertinoColors.systemGrey6,
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Text(
                  preset.systemPrompt.length > 200
                      ? '${preset.systemPrompt.substring(0, 200)}...'
                      : preset.systemPrompt,
                  style: const TextStyle(fontFamily: 'Menlo', fontSize: 12),
                ),
              ),
            ],
          ),
        ),
        actions: [
          CupertinoDialogAction(
            child: Text(l10n.closeButton),
            onPressed: () => Navigator.pop(context),
          ),
        ],
      ),
    );
  }

  /// 显示Cupertino风格的消息条
  void showCupertinoSnackBar({
    required BuildContext context,
    required String message,
    Duration duration = const Duration(seconds: 2),
  }) {
    final overlay = Overlay.of(context);
    final overlayEntry = OverlayEntry(
      builder: (context) => Positioned(
        top: MediaQuery.of(context).padding.top + 50,
        left: 16,
        right: 16,
        child: CupertinoAlertDialog(
          content: Text(message),
        ),
      ),
    );

    overlay.insert(overlayEntry);
    Future.delayed(duration, () => overlayEntry.remove());
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;

    return CupertinoPageScaffold(
      navigationBar: CupertinoNavigationBar(
        middle: Text(l10n.presetManagement),
        trailing: CupertinoButton(
          padding: EdgeInsets.zero,
          onPressed: _importXmlFile,
          child: const Icon(CupertinoIcons.add),
        ),
      ),
      child: SafeArea(
        child: _isLoading
            ? const Center(child: CupertinoActivityIndicator())
            : _errorMessage != null
                ? Center(child: Text(_errorMessage!))
                : ListView(
                    children: [
                      // 内置预设部分
                      if (_builtInPresets.isNotEmpty)
                        _buildSection(
                          context,
                          l10n.builtInPresets,
                          _builtInPresets
                              .map((preset) => _buildPresetItem(preset, false))
                              .toList(),
                        ),
                      // 用户预设部分
                      if (_userPresets.isNotEmpty)
                        _buildSection(
                          context,
                          l10n.userPresets,
                          _userPresets
                              .map((preset) => _buildPresetItem(preset, true))
                              .toList(),
                        ),
                      // 空状态
                      if (_builtInPresets.isEmpty && _userPresets.isEmpty)
                        Padding(
                          padding: const EdgeInsets.all(32),
                          child: Column(
                            children: [
                              Icon(
                                CupertinoIcons.doc_text,
                                size: 64,
                                color: CupertinoColors.systemGrey3,
                              ),
                              const SizedBox(height: 16),
                              Text(
                                l10n.noPresetsAvailable,
                                style: TextStyle(
                                  color: CupertinoColors.secondaryLabel.resolveFrom(context),
                                ),
                              ),
                              const SizedBox(height: 8),
                              Text(
                                l10n.importXmlHint,
                                style: TextStyle(
                                  color: CupertinoColors.secondaryLabel.resolveFrom(context),
                                ),
                              ),
                            ],
                          ),
                        ),
                      Padding(
                        padding: const EdgeInsets.symmetric(vertical: 24, horizontal: 16),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            // HTTP服务器开关行
                            Row(
                              mainAxisAlignment: MainAxisAlignment.spaceBetween,
                              children: [
                                Row(
                                  children: [
                                    Transform.scale(
                                      scale: 0.8,
                                      child: CupertinoSwitch(
                                        value: _isHttpServerRunning,
                                        onChanged: (value) async {
                                          await _toggleHttpServer();
                                        },
                                      ),
                                    ),
                                    const SizedBox(width: 8),
                                    Column(
                                      crossAxisAlignment: CrossAxisAlignment.start,
                                      children: [
                                        Text(
                                          l10n.httpServerSwitchLabel,
                                          style: TextStyle(
                                            fontSize: 14,
                                            fontWeight: FontWeight.w500,
                                            color: CupertinoTheme.of(context).brightness == Brightness.dark
                                                ? CupertinoColors.label.darkColor
                                                : CupertinoColors.label.color,
                                          ),
                                        ),
                                        Text(
                                          _isHttpServerRunning
                                              ? (_httpServerUrl ?? l10n.httpServerStatusRunning)
                                              : l10n.httpServerStatusStopped,
                                          style: TextStyle(
                                            fontSize: 12,
                                            color: _isHttpServerRunning
                                                ? CupertinoColors.systemGreen
                                                : CupertinoColors.systemRed,
                                          ),
                                        ),
                                      ],
                                    ),
                                  ],
                                ),
                                if (_isHttpServerRunning && _httpServerUrl != null)
                                  GestureDetector(
                                    onTap: _launchRoleCardGenerator,
                                    child: Text(
                                      l10n.openGeneratorButton,
                                      style: TextStyle(
                                        fontSize: 14,
                                        color: CupertinoColors.link,
                                        decoration: TextDecoration.underline,
                                      ),
                                    ),
                                  ),
                              ],
                            ),
                            const SizedBox(height: 12),
                            // 链接说明
                            Text(
                              l10n.httpServerDescription,
                              style: TextStyle(
                                fontSize: 12,
                                color: CupertinoColors.secondaryLabel.resolveFrom(context),
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
      ),
    );
  }
}
