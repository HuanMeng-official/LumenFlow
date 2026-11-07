import 'package:cupertino_ui/cupertino_ui.dart';

/// 设置子页面的统一外壳。
///
/// 移动端保留 `CupertinoPageScaffold` 和导航栏；桌面嵌入模式去掉导航栏，
/// 只渲染大标题和原有导航栏操作，供两栏设置页的右侧内容区复用。
class SettingsPageScaffold extends StatelessWidget {
  final String title;
  final String? embeddedTitle;
  final Widget? trailing;
  final bool embedded;
  final Widget child;

  const SettingsPageScaffold({
    super.key,
    required this.title,
    this.embeddedTitle,
    this.trailing,
    this.embedded = false,
    required this.child,
  });

  @override
  Widget build(BuildContext context) {
    if (!embedded) {
      return CupertinoPageScaffold(
        navigationBar: CupertinoNavigationBar(
          middle: Text(title),
          trailing: trailing,
        ),
        child: SafeArea(child: child),
      );
    }

    return ColoredBox(
      color: CupertinoColors.systemBackground.resolveFrom(context),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Container(
            height: 52,
            padding: const EdgeInsets.symmetric(horizontal: 16),
            decoration: BoxDecoration(
              border: Border(
                bottom: BorderSide(
                  color: CupertinoColors.systemGrey4.resolveFrom(context),
                  width: 0.5,
                ),
              ),
            ),
            child: Row(
              children: [
                Expanded(
                  child: Text(
                    embeddedTitle ?? title,
                    style: const TextStyle(
                      fontSize: 20,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                ),
                ?trailing,
              ],
            ),
          ),
          Expanded(child: SafeArea(top: false, child: child)),
        ],
      ),
    );
  }
}
