import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import '../services/settings_service.dart';

class SettingsScreen extends StatefulWidget {
  const SettingsScreen({Key? key}) : super(key: key);

  @override
  State<SettingsScreen> createState() => _SettingsScreenState();
}

class _SettingsScreenState extends State<SettingsScreen> {
  final SettingsService _settingsService = SettingsService();
  final TextEditingController _endpointController = TextEditingController();
  final TextEditingController _apiKeyController = TextEditingController();
  final TextEditingController _modelController = TextEditingController();
  final TextEditingController _maxTokensController = TextEditingController();
  final TextEditingController _historyContextLengthController = TextEditingController();

  double _temperature = SettingsService.defaultTemperature;
  bool _enableHistory = SettingsService.defaultEnableHistory;
  bool _isLoading = true;
  bool _obscureApiKey = true;
  bool _isSaving = false;

  @override
  void initState() {
    super.initState();
    _loadSettings();
  }

  Future<void> _loadSettings() async {
    final endpoint = await _settingsService.getApiEndpoint();
    final apiKey = await _settingsService.getApiKey();
    final model = await _settingsService.getModel();
    final temperature = await _settingsService.getTemperature();
    final maxTokens = await _settingsService.getMaxTokens();
    final enableHistory = await _settingsService.getEnableHistory();
    final historyContextLength = await _settingsService.getHistoryContextLength();

    setState(() {
      _endpointController.text = endpoint;
      _apiKeyController.text = apiKey;
      _modelController.text = model;
      _temperature = temperature;
      _maxTokensController.text = maxTokens.toString();
      _enableHistory = enableHistory;
      _historyContextLengthController.text = historyContextLength.toString();
      _isLoading = false;
    });
  }

  Future<void> _saveSettings() async {
    setState(() {
      _isSaving = true;
    });

    try {
      await _settingsService.setApiEndpoint(_endpointController.text.trim());
      await _settingsService.setApiKey(_apiKeyController.text.trim());
      await _settingsService.setModel(_modelController.text.trim());
      await _settingsService.setTemperature(_temperature);
      await _settingsService.setMaxTokens(
          int.tryParse(_maxTokensController.text) ?? SettingsService.defaultMaxTokens
      );
      await _settingsService.setEnableHistory(_enableHistory);
      await _settingsService.setHistoryContextLength(
          int.tryParse(_historyContextLengthController.text) ?? SettingsService.defaultHistoryContextLength
      );

      if (mounted) {
        showCupertinoDialog(
          context: context,
          builder: (context) => CupertinoAlertDialog(
            title: const Text('保存成功'),
            content: const Text('设置已保存'),
            actions: [
              CupertinoDialogAction(
                child: const Text('确定'),
                onPressed: () => Navigator.pop(context),
              ),
            ],
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        showCupertinoDialog(
          context: context,
          builder: (context) => CupertinoAlertDialog(
            title: const Text('保存失败'),
            content: Text('保存设置时出错: $e'),
            actions: [
              CupertinoDialogAction(
                child: const Text('确定'),
                onPressed: () => Navigator.pop(context),
              ),
            ],
          ),
        );
      }
    } finally {
      setState(() {
        _isSaving = false;
      });
    }
  }

  void _resetToDefaults() {
    showCupertinoDialog(
      context: context,
      builder: (context) => CupertinoAlertDialog(
        title: const Text('重置设置'),
        content: const Text('确定要恢复默认设置吗？这将清除所有当前配置。'),
        actions: [
          CupertinoDialogAction(
            child: const Text('取消'),
            onPressed: () => Navigator.pop(context),
          ),
          CupertinoDialogAction(
            isDestructiveAction: true,
            child: const Text('重置'),
            onPressed: () {
              Navigator.pop(context);
              setState(() {
                _endpointController.text = SettingsService.defaultEndpoint;
                _apiKeyController.clear();
                _modelController.text = SettingsService.defaultModel;
                _temperature = SettingsService.defaultTemperature;
                _maxTokensController.text = SettingsService.defaultMaxTokens.toString();
                _enableHistory = SettingsService.defaultEnableHistory;
                _historyContextLengthController.text = SettingsService.defaultHistoryContextLength.toString();
              });
            },
          ),
        ],
      ),
    );
  }

  void _showEndpointHelp() {
    showCupertinoDialog(
      context: context,
      builder: (context) => CupertinoAlertDialog(
        title: const Text('常用API端点'),
        content: const Text(
            'OpenAI: https://api.openai.com/v1\n\n'
                'Anthropic: https://api.anthropic.com/v1\n\n'
                'DeepSeek: https://api.deepseek.com/v1\n\n'
                '阿里云: https://dashscope.aliyuncs.com/api/v1\n\n'
                '请根据您使用的AI服务提供商填写相应的端点地址。'
        ),
        actions: [
          CupertinoDialogAction(
            child: const Text('确定'),
            onPressed: () => Navigator.pop(context),
          ),
        ],
      ),
    );
  }

  void _showModelHelp() {
    showCupertinoDialog(
      context: context,
      builder: (context) => CupertinoAlertDialog(
        title: const Text('常用模型'),
        content: const Text(
            'OpenAI:\n'
                '• gpt-3.5-turbo\n'
                '• gpt-4\n'
                '• gpt-4-turbo-preview\n\n'
                'Anthropic:\n'
                '• claude-3-sonnet-20240229\n'
                '• claude-3-opus-20240229\n\n'
                'DeepSeek:\n'
                '• deepseek-chat\n'
                '• deepseek-coder\n\n'
                '请根据您的API端点选择对应的模型。'
        ),
        actions: [
          CupertinoDialogAction(
            child: const Text('确定'),
            onPressed: () => Navigator.pop(context),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    if (_isLoading) {
      return const CupertinoPageScaffold(
        navigationBar: CupertinoNavigationBar(
          middle: Text('设置'),
        ),
        child: Center(child: CupertinoActivityIndicator()),
      );
    }

    return CupertinoPageScaffold(
      navigationBar: CupertinoNavigationBar(
        middle: const Text('设置'),
        trailing: _isSaving
            ? const CupertinoActivityIndicator()
            : CupertinoButton(
          padding: EdgeInsets.zero,
          child: const Text('保存'),
          onPressed: _saveSettings,
        ),
      ),
      child: SafeArea(
        child: ListView(
          children: [
            // API设置部分
            _buildSection(
              '基础设置',
              [
                _buildInputTile(
                  'API端点',
                  controller: _endpointController,
                  placeholder: '输入API端点URL',
                  subtitle: '例如: https://api.openai.com/v1',
                  showHelpButton: true,
                  onHelpPressed: _showEndpointHelp,
                  keyboardType: TextInputType.url,
                ),
                _buildInputTile(
                  'API密钥',
                  controller: _apiKeyController,
                  placeholder: '输入API密钥',
                  subtitle: '从AI服务提供商获取的认证密钥',
                  obscureText: _obscureApiKey,
                  showVisibilityToggle: true,
                  onVisibilityToggle: () {
                    setState(() {
                      _obscureApiKey = !_obscureApiKey;
                    });
                  },
                ),
              ],
            ),

            // 模型设置部分
            _buildSection(
              '模型设置',
              [
                _buildInputTile(
                  '模型',
                  controller: _modelController,
                  placeholder: '输入模型名称',
                  subtitle: '例如: gpt-3.5-turbo, claude-3-sonnet-20240229',
                  showHelpButton: true,
                  onHelpPressed: _showModelHelp,
                ),
                _buildInputTile(
                  '最大Token数',
                  controller: _maxTokensController,
                  placeholder: '输入最大Token数',
                  subtitle: '限制单次回复的长度，建议500-4000',
                  keyboardType: TextInputType.number,
                ),
                _buildSliderTile(
                  '温度',
                  value: _temperature,
                  subtitle: '控制回复的随机性，0.0-2.0，数值越高回复越有创意',
                  min: 0.0,
                  max: 2.0,
                  divisions: 20,
                  onChanged: (value) {
                    setState(() {
                      _temperature = value;
                    });
                  },
                ),
              ],
            ),

            // 历史对话设置部分
            _buildSection(
              '历史对话',
              [
                _buildSwitchTile(
                  '启用历史对话',
                  value: _enableHistory,
                  subtitle: '开启后AI会记住之前的对话内容，提供更连贯的回复',
                  onChanged: (value) {
                    setState(() {
                      _enableHistory = value;
                    });
                  },
                ),
                if (_enableHistory)
                  _buildInputTile(
                    '历史对话轮数',
                    controller: _historyContextLengthController,
                    placeholder: '输入历史对话轮数',
                    subtitle: 'AI记住的历史对话轮数，建议5-20轮，过多可能超出Token限制',
                    keyboardType: TextInputType.number,
                  ),
              ],
            ),

            // 其他操作
            _buildSection(
              '其他',
              [
                _buildActionTile(
                  '重置为默认设置',
                  icon: CupertinoIcons.refresh,
                  onTap: _resetToDefaults,
                  isDestructive: true,
                ),
              ],
            ),

            // 说明信息
            Container(
              margin: const EdgeInsets.all(16),
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: CupertinoColors.systemGrey6,
                borderRadius: BorderRadius.circular(12),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: const [
                  Text(
                    '使用说明',
                    style: TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  SizedBox(height: 8),
                  Text(
                    '• API端点：AI服务提供商的API地址，点击帮助按钮查看常用端点\n'
                        '• API密钥：从服务提供商获取的认证密钥，请妥善保管\n'
                        '• 模型：要使用的AI模型名称，不同端点支持不同模型\n'
                        '• Token数：限制单次回复的长度，过小可能导致回复不完整\n'
                        '• 温度：数值越高回复越有创意，建议0.3-1.0\n'
                        '• 历史对话：开启后AI能记住对话上下文，提供更连贯的体验',
                    style: TextStyle(
                      fontSize: 14,
                      color: CupertinoColors.systemGrey,
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

  Widget _buildSection(String title, List<Widget> children) {
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
            color: CupertinoColors.systemBackground,
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

  List<Widget> _addDividers(List<Widget> children) {
    final List<Widget> dividedChildren = [];
    for (int i = 0; i < children.length; i++) {
      dividedChildren.add(children[i]);
      if (i < children.length - 1) {
        dividedChildren.add(
          const Divider(
            height: 1,
            thickness: 0.5,
            color: CupertinoColors.systemGrey4,
            indent: 16,
            endIndent: 16,
          ),
        );
      }
    }
    return dividedChildren;
  }

  Widget _buildInputTile(
      String title, {
        required TextEditingController controller,
        required String placeholder,
        String? subtitle,
        bool obscureText = false,
        bool showVisibilityToggle = false,
        bool showHelpButton = false,
        TextInputType? keyboardType,
        VoidCallback? onVisibilityToggle,
        VoidCallback? onHelpPressed,
      }) {
    return Container(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Expanded(
                child: Text(
                  title,
                  style: const TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ),
              if (showHelpButton)
                CupertinoButton(
                  padding: EdgeInsets.zero,
                  child: const Icon(
                    CupertinoIcons.question_circle,
                    size: 20,
                    color: CupertinoColors.systemBlue,
                  ),
                  onPressed: onHelpPressed,
                ),
            ],
          ),
          if (subtitle != null) ...[
            const SizedBox(height: 4),
            Text(
              subtitle,
              style: const TextStyle(
                fontSize: 13,
                color: CupertinoColors.systemGrey,
              ),
            ),
          ],
          const SizedBox(height: 12),
          CupertinoTextField(
            controller: controller,
            placeholder: placeholder,
            obscureText: obscureText,
            keyboardType: keyboardType,
            suffix: showVisibilityToggle
                ? CupertinoButton(
              padding: EdgeInsets.zero,
              child: Icon(
                obscureText ? CupertinoIcons.eye : CupertinoIcons.eye_slash,
                size: 20,
                color: CupertinoColors.systemGrey,
              ),
              onPressed: onVisibilityToggle,
            )
                : null,
            decoration: BoxDecoration(
              color: CupertinoColors.systemGrey6,
              borderRadius: BorderRadius.circular(8),
            ),
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
          ),
        ],
      ),
    );
  }

  Widget _buildSliderTile(
      String title, {
        required double value,
        String? subtitle,
        required double min,
        required double max,
        int? divisions,
        required ValueChanged<double> onChanged,
      }) {
    return Container(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            '$title (${value.toStringAsFixed(1)})',
            style: const TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.w500,
            ),
          ),
          if (subtitle != null) ...[
            const SizedBox(height: 4),
            Text(
              subtitle,
              style: const TextStyle(
                fontSize: 13,
                color: CupertinoColors.systemGrey,
              ),
            ),
          ],
          const SizedBox(height: 12),
          CupertinoSlider(
            value: value,
            min: min,
            max: max,
            divisions: divisions,
            onChanged: onChanged,
          ),
        ],
      ),
    );
  }

  Widget _buildSwitchTile(
      String title, {
        required bool value,
        String? subtitle,
        required ValueChanged<bool> onChanged,
      }) {
    return Container(
      padding: const EdgeInsets.all(16),
      child: Row(
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: const TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.w500,
                  ),
                ),
                if (subtitle != null) ...[
                  const SizedBox(height: 4),
                  Text(
                    subtitle,
                    style: const TextStyle(
                      fontSize: 13,
                      color: CupertinoColors.systemGrey,
                    ),
                  ),
                ],
              ],
            ),
          ),
          const SizedBox(width: 16),
          CupertinoSwitch(
            value: value,
            onChanged: onChanged,
          ),
        ],
      ),
    );
  }

  Widget _buildActionTile(
      String title, {
        required IconData icon,
        required VoidCallback onTap,
        bool isDestructive = false,
      }) {
    return CupertinoListTile(
      leading: Icon(
        icon,
        color: isDestructive ? CupertinoColors.systemRed : CupertinoColors.systemBlue,
      ),
      title: Text(
        title,
        style: TextStyle(
          color: isDestructive ? CupertinoColors.systemRed : CupertinoColors.label,
        ),
      ),
      trailing: const Icon(CupertinoIcons.chevron_right),
      onTap: onTap,
    );
  }

  @override
  void dispose() {
    _endpointController.dispose();
    _apiKeyController.dispose();
    _modelController.dispose();
    _maxTokensController.dispose();
    _historyContextLengthController.dispose();
    super.dispose();
  }
}