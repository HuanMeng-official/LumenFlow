import 'package:cupertino_ui/cupertino_ui.dart';

import '../../models/user_profile.dart';
import '../../utils/app_theme.dart';
import '../avatar_widget.dart';

class SidebarFooter extends StatelessWidget {
  const SidebarFooter({
    super.key,
    this.userProfile,
    this.onOpenProfile,
    this.onOpenSettings,
  });

  final UserProfile? userProfile;
  final VoidCallback? onOpenProfile;
  final VoidCallback? onOpenSettings;

  @override
  Widget build(BuildContext context) {
    final fontFallback =
        cjkFontFallbackForLocale(Localizations.maybeLocaleOf(context));

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 9),
      decoration: BoxDecoration(
        color: AppTokens.sidebarBg(context),
        border: Border(
          top: BorderSide(
            color: AppTokens.separator(context),
            width: 0.5,
          ),
        ),
      ),
      child: Row(
        children: [
          Expanded(
            child: GestureDetector(
              behavior: HitTestBehavior.opaque,
              onTap: onOpenProfile,
              child: Row(
                children: [
                  if (userProfile != null)
                    AvatarWidget(userProfile: userProfile!, size: 26)
                  else
                    Container(
                      width: 26,
                      height: 26,
                      decoration: BoxDecoration(
                        color: AppTokens.fill(context),
                        shape: BoxShape.circle,
                      ),
                      child: Icon(
                        CupertinoIcons.person_fill,
                        size: 13,
                        color: AppTokens.labelSecondary(context),
                      ),
                    ),
                  const SizedBox(width: 9),
                  Expanded(
                    child: Text(
                      (userProfile?.username.trim().isNotEmpty ?? false)
                          ? userProfile!.username
                          : 'LumenFlow',
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: TextStyle(
                        fontSize: 13,
                        fontWeight: FontWeight.w500,
                        fontFamilyFallback: fontFallback,
                        color: AppTokens.label(context),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
          if (onOpenSettings != null)
            CupertinoButton(
              padding: const EdgeInsets.all(6),
              minimumSize: const Size(28, 28),
              onPressed: onOpenSettings,
              child: Icon(
                CupertinoIcons.gear_alt,
                size: 16,
                color: AppTokens.labelSecondary(context),
              ),
            ),
        ],
      ),
    );
  }
}
