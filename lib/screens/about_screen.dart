import 'package:flutter/cupertino.dart';
import 'package:url_launcher/url_launcher.dart';
import '../l10n/app_localizations.dart';
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
    final l10n = AppLocalizations.of(context)!;
    final brightness = CupertinoTheme.of(context).brightness;
    final isDarkMode = brightness == Brightness.dark;

    return CupertinoPageScaffold(
      navigationBar: CupertinoNavigationBar(
        middle: Text(l10n.about),
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
                _buildSection(context, l10n.appInfo, [
                  _buildInfoTile(l10n.version, version),
                  _buildInfoTile(l10n.buildDate, buildDate),
                  _buildDeveloperTile(l10n.developer, '幻梦official'),
                ]),
                // 功能介绍部分
                _buildSection(context, l10n.features, [
                  _buildDescriptionTile(
                    l10n.intelligentConversation,
                    l10n.intelligentConversationDesc,
                    icon: CupertinoIcons.chat_bubble_2_fill,
                  ),
                  _buildDescriptionTile(
                    l10n.fileProcessing,
                    l10n.fileProcessingDesc,
                    icon: CupertinoIcons.folder_fill,
                  ),
                  _buildDescriptionTile(
                    l10n.historyRecords,
                    l10n.historyRecordsDesc,
                    icon: CupertinoIcons.clock_fill,
                  ),
                  _buildDescriptionTile(
                    l10n.customSettings,
                    l10n.customSettingsDesc,
                    icon: CupertinoIcons.settings_solid,
                  ),
                ]),
                // 开源许可部分
                _buildSection(context, l10n.licenses, [
                  _buildLicenseTile('Flutter', 'BSD 3-Clause License'),
                  _buildLicenseTile('Cupertino Icons', 'MIT License'),
                  _buildLicenseTile('HTTP', 'Apache License 2.0'),
                  _buildLicenseTile('Shared Preferences', 'Apache License 2.0'),
                ]),
                // 赞助码部分
                _buildSection(context, l10n.sponsor, [
                  _buildSponsorTile(isDarkMode),
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
    final l10n = AppLocalizations.of(context)!;
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
          Text(
            l10n.appTitle,
            style: const TextStyle(
              fontSize: 28,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            l10n.appSubtitle,
            style: const TextStyle(
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

  Widget _buildDeveloperTile(String title, String value) {
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
          GestureDetector(
            onTap: () async {
              final Uri url = Uri.parse('https://github.com/HuanMeng-official');
              if (await canLaunchUrl(url)) {
                await launchUrl(url, mode: LaunchMode.externalApplication);
              }
            },
            child: Row(
              children: [
                Text(
                  value,
                  style: const TextStyle(
                    fontSize: 16,
                    color: CupertinoColors.activeBlue,
                    decoration: TextDecoration.underline,
                  ),
                ),
                const Icon(
                  CupertinoIcons.link,
                  size: 16,
                  color: CupertinoColors.activeBlue,
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSponsorTile(bool isDarkMode) {
    final l10n = AppLocalizations.of(context)!;
    return Container(
      padding: const EdgeInsets.all(16),
      child: Column(
        children: [
          Center(
            child: Image.asset(
              'assets/collection_code.png',
              width: 200,
              height: 200,
              fit: BoxFit.contain,
            ),
          ),
          const SizedBox(height: 12),
          Text(
            l10n.sponsorDesc,
            style: TextStyle(
              fontSize: 13,
              color: isDarkMode
                  ? CupertinoColors.systemGrey.darkColor
                  : CupertinoColors.systemGrey.color,
            ),
            textAlign: TextAlign.center,
          ),
        ],
      ),
    );
  }

  Widget _buildCopyrightSection(bool isDarkMode) {
    final l10n = AppLocalizations.of(context)!;
    return Container(
      margin: const EdgeInsets.all(16),
      padding: const EdgeInsets.all(16),
      child: Column(
        children: [
          Text(
            l10n.copyright,
            style: const TextStyle(
              fontSize: 14,
              color: CupertinoColors.systemGrey,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            l10n.copyrightNotice,
            style: const TextStyle(
              fontSize: 13,
              color: CupertinoColors.systemGrey,
            ),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 4),
          Text(
            l10n.copyrightTerms,
            style: const TextStyle(
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