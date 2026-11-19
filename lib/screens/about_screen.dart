import 'dart:math' as math;

import 'package:cupertino_ui/cupertino_ui.dart';
import 'package:url_launcher/url_launcher.dart';

import '../l10n/app_localizations.dart';
import '../services/version_service.dart';
import '../utils/app_theme.dart';
import '../widgets/settings/settings_page_scaffold.dart';
import '../widgets/settings/settings_section.dart';

/// 关于页面（原生 Apple 分组列表样式，适配桌面与移动端）。
class AboutScreen extends StatefulWidget {
  final bool embedded;
  final String? previousPageTitle;

  const AboutScreen({
    super.key,
    this.embedded = false,
    this.previousPageTitle,
  });

  @override
  State<AboutScreen> createState() => _AboutScreenState();
}

class _AboutScreenState extends State<AboutScreen> {
  final VersionService _versionService = VersionService();
  late final Future<Map<String, String>> _versionInfo;

  @override
  void initState() {
    super.initState();
    _versionInfo = _versionService.getVersionInfo();
  }

  Future<void> _openDeveloperLink() async {
    final url = Uri.parse('https://github.com/HuanMeng-official');
    if (await canLaunchUrl(url)) {
      await launchUrl(url, mode: LaunchMode.externalApplication);
    }
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;

    return SettingsPageScaffold(
      title: l10n.about,
      previousPageTitle: widget.previousPageTitle,
      embedded: widget.embedded,
      child: FutureBuilder<Map<String, String>>(
        future: _versionInfo,
        builder: (context, snapshot) {
          final version = snapshot.data?['version'] ?? '1.0.5';
          final buildDate = snapshot.data?['buildDate'] ?? '';

          return ListView(
            padding: const EdgeInsets.only(bottom: 36),
            children: [
              _buildAppHeader(context, l10n, version),
              SettingsSection(
                title: l10n.appInfo,
                children: [
                  _buildInfoRow(context, l10n.version, version),
                  if (buildDate.isNotEmpty)
                    _buildInfoRow(context, l10n.buildDate, buildDate),
                  _buildDeveloperRow(context, l10n.developer, '幻梦official'),
                ],
              ),
              SettingsSection(
                title: l10n.features,
                children: [
                  _buildFeatureRow(
                    context,
                    title: l10n.intelligentConversation,
                    description: l10n.intelligentConversationDesc,
                    icon: CupertinoIcons.chat_bubble_2_fill,
                  ),
                  _buildFeatureRow(
                    context,
                    title: l10n.fileProcessing,
                    description: l10n.fileProcessingDesc,
                    icon: CupertinoIcons.folder_fill,
                  ),
                  _buildFeatureRow(
                    context,
                    title: l10n.historyRecords,
                    description: l10n.historyRecordsDesc,
                    icon: CupertinoIcons.clock_fill,
                  ),
                  _buildFeatureRow(
                    context,
                    title: l10n.customSettings,
                    description: l10n.customSettingsDesc,
                    icon: CupertinoIcons.slider_horizontal_3,
                  ),
                ],
              ),
              SettingsSection(
                title: l10n.licenses,
                children: [
                  _buildLicenseRow(context, 'Flutter', 'BSD 3-Clause License'),
                  _buildLicenseRow(context, 'Cupertino Icons', 'MIT License'),
                  _buildLicenseRow(context, 'HTTP', 'Apache License 2.0'),
                  _buildLicenseRow(
                    context,
                    'Shared Preferences',
                    'Apache License 2.0',
                  ),
                ],
              ),
              SettingsSection(
                title: l10n.sponsor,
                children: [
                  _buildSponsorRow(context, l10n),
                ],
              ),
              _buildCopyrightFooter(context, l10n),
            ],
          );
        },
      ),
    );
  }

  Widget _buildAppHeader(
    BuildContext context,
    AppLocalizations l10n,
    String version,
  ) {
    final fontFallback =
        cjkFontFallbackForLocale(Localizations.maybeLocaleOf(context));

    return Padding(
      padding: const EdgeInsets.fromLTRB(24, 28, 24, 10),
      child: Column(
        children: [
          Container(
            width: 76,
            height: 76,
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(18),
              border: Border.all(
                color: AppTokens.separator(context),
                width: 0.5,
              ),
            ),
            child: ClipRRect(
              borderRadius: BorderRadius.circular(18),
              child: Image.asset(
                'assets/logo.png',
                fit: BoxFit.cover,
                width: 76,
                height: 76,
                errorBuilder: (_, _, _) => Container(
                  color: AppTokens.accentSoft(context),
                  child: Icon(
                    CupertinoIcons.chat_bubble_2_fill,
                    size: 36,
                    color: AppTokens.accent(context),
                  ),
                ),
              ),
            ),
          ),
          const SizedBox(height: 14),
          Text(
            l10n.appTitle,
            style: TextStyle(
              fontSize: 24,
              fontWeight: FontWeight.w700,
              fontFamilyFallback: fontFallback,
              color: AppTokens.label(context),
            ),
          ),
          const SizedBox(height: 4),
          Text(
            l10n.appSubtitle,
            textAlign: TextAlign.center,
            style: TextStyle(
              fontSize: 13.5,
              fontFamilyFallback: fontFallback,
              color: AppTokens.labelSecondary(context),
            ),
          ),
          const SizedBox(height: 10),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 11, vertical: 3.5),
            decoration: BoxDecoration(
              color: AppTokens.fill(context),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Text(
              'v$version',
              style: TextStyle(
                fontSize: 12,
                fontWeight: FontWeight.w500,
                color: AppTokens.labelSecondary(context),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildInfoRow(BuildContext context, String title, String value) {
    final fontFallback =
        cjkFontFallbackForLocale(Localizations.maybeLocaleOf(context));

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 13),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(
            title,
            style: TextStyle(
              fontSize: 15.5,
              fontWeight: FontWeight.w500,
              fontFamilyFallback: fontFallback,
              color: AppTokens.label(context),
            ),
          ),
          const SizedBox(width: 12),
          Flexible(
            child: Text(
              value,
              textAlign: TextAlign.right,
              style: TextStyle(
                fontSize: 15,
                fontFamilyFallback: fontFallback,
                color: AppTokens.labelSecondary(context),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildDeveloperRow(BuildContext context, String title, String value) {
    final fontFallback =
        cjkFontFallbackForLocale(Localizations.maybeLocaleOf(context));
    final accent = AppTokens.accent(context);

    return GestureDetector(
      behavior: HitTestBehavior.opaque,
      onTap: _openDeveloperLink,
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 13),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(
              title,
              style: TextStyle(
                fontSize: 15.5,
                fontWeight: FontWeight.w500,
                fontFamilyFallback: fontFallback,
                color: AppTokens.label(context),
              ),
            ),
            const SizedBox(width: 12),
            Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  value,
                  style: TextStyle(
                    fontSize: 15,
                    fontWeight: FontWeight.w500,
                    fontFamilyFallback: fontFallback,
                    color: accent,
                  ),
                ),
                const SizedBox(width: 4),
                Icon(
                  CupertinoIcons.arrow_up_right_square,
                  size: 15,
                  color: accent,
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildFeatureRow(
    BuildContext context, {
    required String title,
    required String description,
    required IconData icon,
  }) {
    final fontFallback =
        cjkFontFallbackForLocale(Localizations.maybeLocaleOf(context));

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 13),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            width: 28,
            height: 28,
            decoration: BoxDecoration(
              color: AppTokens.accentSoft(context),
              borderRadius: BorderRadius.circular(7),
            ),
            child: Icon(icon, size: 15, color: AppTokens.accent(context)),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: TextStyle(
                    fontSize: 15.5,
                    fontWeight: FontWeight.w500,
                    fontFamilyFallback: fontFallback,
                    color: AppTokens.label(context),
                  ),
                ),
                const SizedBox(height: 3),
                Text(
                  description,
                  style: TextStyle(
                    fontSize: 13,
                    height: 1.4,
                    fontFamilyFallback: fontFallback,
                    color: AppTokens.labelSecondary(context),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildLicenseRow(
    BuildContext context,
    String library,
    String license,
  ) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(
            library,
            style: TextStyle(
              fontSize: 15,
              fontWeight: FontWeight.w500,
              color: AppTokens.label(context),
            ),
          ),
          Text(
            license,
            style: TextStyle(
              fontSize: 13,
              color: AppTokens.labelSecondary(context),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSponsorRow(BuildContext context, AppLocalizations l10n) {
    final qrSize = math.min(MediaQuery.sizeOf(context).width * 0.45, 200.0);
    final fontFallback =
        cjkFontFallbackForLocale(Localizations.maybeLocaleOf(context));

    return Padding(
      padding: const EdgeInsets.all(20),
      child: Column(
        children: [
          Center(
            child: Container(
              padding: const EdgeInsets.all(10),
              decoration: BoxDecoration(
                color: CupertinoColors.white,
                borderRadius: BorderRadius.circular(AppTokens.radiusMd),
                border: Border.all(
                  color: AppTokens.separator(context),
                  width: 0.5,
                ),
              ),
              child: Image.asset(
                'assets/collection_code.png',
                width: qrSize,
                height: qrSize,
                fit: BoxFit.contain,
                errorBuilder: (_, _, _) => SizedBox(
                  width: qrSize,
                  height: qrSize,
                  child: const Icon(
                    CupertinoIcons.qrcode,
                    size: 48,
                    color: CupertinoColors.systemGrey,
                  ),
                ),
              ),
            ),
          ),
          const SizedBox(height: 12),
          Text(
            l10n.sponsorDesc,
            textAlign: TextAlign.center,
            style: TextStyle(
              fontSize: 13,
              height: 1.4,
              fontFamilyFallback: fontFallback,
              color: AppTokens.labelSecondary(context),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildCopyrightFooter(BuildContext context, AppLocalizations l10n) {
    final secondary = AppTokens.labelTertiary(context);
    final fontFallback =
        cjkFontFallbackForLocale(Localizations.maybeLocaleOf(context));

    return Padding(
      padding: const EdgeInsets.fromLTRB(24, 24, 24, 8),
      child: Column(
        children: [
          Text(
            l10n.copyright,
            textAlign: TextAlign.center,
            style: TextStyle(
              fontSize: 12.5,
              fontFamilyFallback: fontFallback,
              color: secondary,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            l10n.copyrightNotice,
            textAlign: TextAlign.center,
            style: TextStyle(
              fontSize: 12,
              fontFamilyFallback: fontFallback,
              color: secondary,
            ),
          ),
          const SizedBox(height: 2),
          Text(
            l10n.copyrightTerms,
            textAlign: TextAlign.center,
            style: TextStyle(
              fontSize: 12,
              fontFamilyFallback: fontFallback,
              color: secondary,
            ),
          ),
        ],
      ),
    );
  }
}
