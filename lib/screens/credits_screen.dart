import 'package:cupertino_ui/cupertino_ui.dart';

import '../l10n/app_localizations.dart';
import '../utils/app_theme.dart';
import '../widgets/settings/settings_page_scaffold.dart';
import '../widgets/settings/settings_section.dart';

/// 鸣谢页面（原生 Apple 分组卡片样式，适配桌面与移动端）。
class CreditsScreen extends StatefulWidget {
  final bool embedded;
  final String? previousPageTitle;

  const CreditsScreen({
    super.key,
    this.embedded = false,
    this.previousPageTitle,
  });

  @override
  State<CreditsScreen> createState() => _CreditsScreenState();
}

class _CreditsScreenState extends State<CreditsScreen> {
  final List<Contributor> _contributors = const [
    Contributor(
      name: '幻梦official',
      roleKey: 'creditsMainDeveloper',
      avatarAsset: 'assets/image/huanmeng.jpg',
    ),
    Contributor(
      name: '浮沫',
      roleKey: 'creditsAppImprovementSuggestions',
      avatarAsset: 'assets/image/fumo.jpg',
    ),
    Contributor(
      name: '浅唱ヾ落雨殇',
      roleKey: 'creditsAppImprovementAndCode',
      avatarAsset: 'assets/image/qianchangluoyushang.jpg',
    ),
    Contributor(
      name: '枫下之秋',
      roleKey: 'creditsBugTestingAndCode',
      avatarAsset: 'assets/image/fengxiazhiqiu.jpg',
    ),
  ];

  String _roleLabel(String key, AppLocalizations l10n) {
    return switch (key) {
      'creditsMainDeveloper' => l10n.creditsMainDeveloper,
      'creditsAppImprovementSuggestions' =>
        l10n.creditsAppImprovementSuggestions,
      'creditsAppImprovementAndCode' => l10n.creditsAppImprovementAndCode,
      'creditsBugTestingAndCode' => l10n.creditsBugTestingAndCode,
      _ => '',
    };
  }

  Widget _buildContributorTile(
    BuildContext context,
    Contributor contributor,
    AppLocalizations l10n,
  ) {
    final fontFallback =
        cjkFontFallbackForLocale(Localizations.maybeLocaleOf(context));
    final roleText = _roleLabel(contributor.roleKey, l10n);

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      child: Row(
        children: [
          Container(
            width: 42,
            height: 42,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              border: Border.all(
                color: AppTokens.separator(context),
                width: 0.5,
              ),
            ),
            child: ClipOval(
              child: Image.asset(
                contributor.avatarAsset,
                width: 42,
                height: 42,
                fit: BoxFit.cover,
                errorBuilder: (_, _, _) => Container(
                  width: 42,
                  height: 42,
                  color: AppTokens.fill(context),
                  child: Icon(
                    CupertinoIcons.person_fill,
                    size: 20,
                    color: AppTokens.labelSecondary(context),
                  ),
                ),
              ),
            ),
          ),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  contributor.name,
                  style: TextStyle(
                    fontSize: 15.5,
                    fontWeight: FontWeight.w600,
                    fontFamilyFallback: fontFallback,
                    color: AppTokens.label(context),
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  roleText,
                  style: TextStyle(
                    fontSize: 13.5,
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

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;

    return SettingsPageScaffold(
      title: l10n.credits,
      previousPageTitle: widget.previousPageTitle,
      embedded: widget.embedded,
      child: ListView(
        padding: const EdgeInsets.only(bottom: 32),
        children: [
          SettingsSection(
            title: l10n.contributors,
            footer: l10n.creditsDescription,
            children: [
              for (final contributor in _contributors)
                _buildContributorTile(context, contributor, l10n),
            ],
          ),
        ],
      ),
    );
  }
}

/// 贡献者数据模型
class Contributor {
  final String name;
  final String roleKey;
  final String avatarAsset;

  const Contributor({
    required this.name,
    required this.roleKey,
    required this.avatarAsset,
  });
}
