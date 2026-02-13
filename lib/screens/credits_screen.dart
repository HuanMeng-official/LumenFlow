import 'package:flutter/cupertino.dart';
import '../l10n/app_localizations.dart';

/// 鸣谢页面，展示应用贡献者名单
///
/// 包含内容：
/// - 主要开发者
/// - 应用改进建议者
/// - 代码贡献者
/// - Bug测试者
class CreditsScreen extends StatefulWidget {
  const CreditsScreen({super.key});

  @override
  State<CreditsScreen> createState() => _CreditsScreenState();
}

class _CreditsScreenState extends State<CreditsScreen> {
  /// 贡献者数据
  final List<Contributor> _contributors = [
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

  /// 构建单个贡献者条目
  Widget _buildContributorTile(BuildContext context, Contributor contributor) {
    final l10n = AppLocalizations.of(context)!;
    final brightness = CupertinoTheme.of(context).brightness;
    final isDarkMode = brightness == Brightness.dark;

    String roleText;
    switch (contributor.roleKey) {
      case 'creditsMainDeveloper':
        roleText = l10n.creditsMainDeveloper;
        break;
      case 'creditsAppImprovementSuggestions':
        roleText = l10n.creditsAppImprovementSuggestions;
        break;
      case 'creditsAppImprovementAndCode':
        roleText = l10n.creditsAppImprovementAndCode;
        break;
      case 'creditsBugTestingAndCode':
        roleText = l10n.creditsBugTestingAndCode;
        break;
      default:
        roleText = '';
    }

    return Container(
      padding: const EdgeInsets.all(16),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // 头像
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
            child: ClipOval(
              child: Image.asset(
                contributor.avatarAsset,
                width: 34,
                height: 34,
                fit: BoxFit.cover,
                errorBuilder: (context, error, stackTrace) {
                  return Container(
                    width: 34,
                    height: 34,
                    color: CupertinoColors.systemGrey.withAlpha(2),
                    child: Icon(
                      CupertinoIcons.person_fill,
                      size: 20,
                      color: CupertinoColors.systemGrey,
                    ),
                  );
                },
              ),
            ),
          ),
          const SizedBox(width: 12),
          // 姓名和角色
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  contributor.name,
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
                  roleText,
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
        ],
      ),
    );
  }

  /// 构建带框的区域（类似about_screen.dart中的样式）
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

  /// 构建鸣谢说明文本
  Widget _buildDescriptionText(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final brightness = CupertinoTheme.of(context).brightness;
    final isDarkMode = brightness == Brightness.dark;

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      child: Text(
        l10n.creditsDescription,
        style: TextStyle(
          fontSize: 14,
          color: isDarkMode
              ? CupertinoColors.systemGrey.darkColor
              : CupertinoColors.systemGrey,
        ),
        textAlign: TextAlign.center,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;

    // 构建贡献者部件列表
    final contributorTiles = _contributors
        .map((contributor) => _buildContributorTile(context, contributor))
        .toList();

    return CupertinoPageScaffold(
      navigationBar: CupertinoNavigationBar(
        middle: Text(l10n.credits),
      ),
      child: SafeArea(
        child: ListView(
          children: [
            // 鸣谢说明
            _buildDescriptionText(context),
            // 贡献者列表（带框区域）
            _buildSection(context, l10n.contributors, contributorTiles),
          ],
        ),
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
