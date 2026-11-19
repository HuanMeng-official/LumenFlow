import 'package:cupertino_ui/cupertino_ui.dart';

import '../../utils/app_theme.dart';

/// 设置子页面的统一外壳。
///
/// 移动端保留 `CupertinoPageScaffold` 和分组底色；桌面嵌入模式渲染 52px 细分隔顶栏。
class SettingsPageScaffold extends StatelessWidget {
  final String title;
  final String? embeddedTitle;
  final String? previousPageTitle;
  final Widget? trailing;
  final bool embedded;
  final Widget child;

  const SettingsPageScaffold({
    super.key,
    required this.title,
    this.embeddedTitle,
    this.previousPageTitle,
    this.trailing,
    this.embedded = false,
    required this.child,
  });

  @override
  Widget build(BuildContext context) {
    final groupedBg = AppTokens.groupedBg(context);

    if (!embedded) {
      return CupertinoPageScaffold(
        backgroundColor: groupedBg,
        navigationBar: CupertinoNavigationBar(
          backgroundColor: AppTokens.bg(context),
          previousPageTitle: previousPageTitle,
          middle: Text(title),
          trailing: trailing,
          border: Border(
            bottom: BorderSide(
              color: AppTokens.separator(context),
              width: 0.5,
            ),
          ),
        ),
        child: SafeArea(child: child),
      );
    }

    return ColoredBox(
      color: groupedBg,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Container(
            height: 52,
            padding: const EdgeInsets.symmetric(horizontal: 20),
            decoration: BoxDecoration(
              color: AppTokens.bg(context),
              border: Border(
                bottom: BorderSide(
                  color: AppTokens.separator(context),
                  width: 0.5,
                ),
              ),
            ),
            child: Row(
              children: [
                Expanded(
                  child: Text(
                    embeddedTitle ?? title,
                    style: TextStyle(
                      fontSize: 17,
                      fontWeight: FontWeight.w600,
                      color: AppTokens.label(context),
                    ),
                  ),
                ),
                ?trailing,
              ],
            ),
          ),
          Expanded(
            child: SafeArea(
              top: false,
              child: Center(
                child: ConstrainedBox(
                  constraints: const BoxConstraints(maxWidth: 720),
                  child: child,
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
