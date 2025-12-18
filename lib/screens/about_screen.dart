import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import '../services/version_service.dart';

/// 关于页面，展示应用信息和版权声明
///
/// 包含内容：
/// - 应用名称和版本
/// - 应用描述
/// - 开发者信息
/// - 版权声明
/// - 开源许可信息
class AboutScreen extends StatefulWidget {
  const AboutScreen({super.key});

  @override
  State<AboutScreen> createState() => _AboutScreenState();
}

class _AboutScreenState extends State<AboutScreen> {
  final VersionService _versionService = VersionService();
  late Future<Map<String, String>> _versionInfo;

  @override
  void initState() {
    super.initState();
    _versionInfo = _versionService.getVersionInfo();
  }

  @override
  Widget build(BuildContext context) {
    final brightness = CupertinoTheme.of(context).brightness;
    final isDarkMode = brightness == Brightness.dark;

    return CupertinoPageScaffold(
      navigationBar: const CupertinoNavigationBar(
        middle: Text('关于'),
      ),
      child: SafeArea(
        child: FutureBuilder<Map<String, String>>(
          future: _versionInfo,
          builder: (context, snapshot) {
            final version = snapshot.data?['version'] ?? '1.0.5';
            final buildDate = snapshot.data?['buildDate'] ?? '2025-12-18';

            return ListView(
              children: [
                // 应用Logo和名称部分
                _buildAppHeader(isDarkMode, version),
                // 应用信息部分
                _buildSection(context, '应用信息', [
                  _buildInfoTile('版本', version),
                  _buildInfoTile('构建日期', buildDate),
                  _buildInfoTile('开发者', '幻梦official'),
                ]),
                // 功能介绍部分
                _buildSection(context, '功能特性', [
                  _buildDescriptionTile(
                    '智能对话',
                    '支持与多种AI模型进行自然语言对话',
                    icon: CupertinoIcons.chat_bubble_2_fill,
                  ),
                  _buildDescriptionTile(
                    '文件处理',
                    '支持上传图片、文档等多种文件格式',
                    icon: CupertinoIcons.folder_fill,
                  ),
                  _buildDescriptionTile(
                    '历史记录',
                    '自动保存对话历史，支持上下文记忆',
                    icon: CupertinoIcons.clock_fill,
                  ),
                  _buildDescriptionTile(
                    '自定义设置',
                    '灵活配置API参数、主题和个性化选项',
                    icon: CupertinoIcons.settings_solid,
                  ),
                ]),
                // 开源许可部分
                _buildSection(context, '开源许可', [
                  _buildLicenseTile('Flutter', 'BSD 3-Clause License'),
                  _buildLicenseTile('Cupertino Icons', 'MIT License'),
                  _buildLicenseTile('HTTP', 'Apache License 2.0'),
                  _buildLicenseTile('Shared Preferences', 'Apache License 2.0'),
                ]),
                // 版权声明
                _buildCopyrightSection(isDarkMode),
              ],
            );
          },
        ),
      ),
    );
  }

  Widget _buildAppHeader(bool isDarkMode, String version) {
    return Container(
      padding: const EdgeInsets.all(32),
      child: Column(
        children: [
          Container(
            width: 80,
            height: 80,
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(20),
            ),
            child: ClipRRect(
              borderRadius: BorderRadius.circular(20),
              child: Image.asset(
                'assets/logo.png',
                fit: BoxFit.cover,
                width: 80,
                height: 80,
              ),
            ),
          ),
          const SizedBox(height: 16),
          const Text(
            '流光',
            style: TextStyle(
              fontSize: 28,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 4),
          const Text(
            'Chat With Your AI',
            style: TextStyle(
              fontSize: 14,
              color: CupertinoColors.systemGrey,
            ),
          ),
          const SizedBox(height: 8),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
            decoration: BoxDecoration(
              color: isDarkMode
                  ? CupertinoColors.systemGrey6.darkColor
                  : CupertinoColors.systemGrey6.color,
              borderRadius: BorderRadius.circular(12),
            ),
            child: Text(
              'v$version',
              style: const TextStyle(
                fontSize: 12,
                color: CupertinoColors.systemGrey,
              ),
            ),
          ),
        ],
      ),
    );
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

  Widget _buildInfoTile(String title, String value) {
    return Container(
      padding: const EdgeInsets.all(16),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(
            title,
            style: const TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.w500,
            ),
          ),
          Text(
            value,
            style: const TextStyle(
              fontSize: 16,
              color: CupertinoColors.systemGrey,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildDescriptionTile(String title, String description, {IconData? icon}) {
    return Container(
      padding: const EdgeInsets.all(16),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          if (icon != null)
            Padding(
              padding: const EdgeInsets.only(top: 2, right: 12),
              child: Icon(
                icon,
                size: 20,
                color: CupertinoColors.systemBlue,
              ),
            ),
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
                const SizedBox(height: 4),
                Text(
                  description,
                  style: const TextStyle(
                    fontSize: 14,
                    color: CupertinoColors.systemGrey,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildLicenseTile(String library, String license) {
    return Container(
      padding: const EdgeInsets.all(16),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  library,
                  style: const TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.w500,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  license,
                  style: const TextStyle(
                    fontSize: 13,
                    color: CupertinoColors.systemGrey,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildCopyrightSection(bool isDarkMode) {
    return Container(
      margin: const EdgeInsets.all(16),
      padding: const EdgeInsets.all(16),
      child: Column(
        children: [
          const Text(
            '© 2025 幻梦official',
            style: TextStyle(
              fontSize: 14,
              color: CupertinoColors.systemGrey,
            ),
          ),
          const SizedBox(height: 8),
          const Text(
            '本应用仅供学习和研究使用',
            style: TextStyle(
              fontSize: 13,
              color: CupertinoColors.systemGrey,
            ),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 4),
          const Text(
            '使用前请确保遵守相关API服务条款',
            style: TextStyle(
              fontSize: 13,
              color: CupertinoColors.systemGrey,
            ),
            textAlign: TextAlign.center,
          ),
        ],
      ),
    );
  }

}