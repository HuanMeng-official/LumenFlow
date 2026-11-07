import 'package:cupertino_ui/cupertino_ui.dart';

import '../../models/user_profile.dart';
import '../avatar_widget.dart';

class SidebarFooter extends StatelessWidget {
  const SidebarFooter({
    super.key,
    this.userProfile,
  });

  final UserProfile? userProfile;

  @override
  Widget build(BuildContext context) {
    final brightness = CupertinoTheme.of(context).brightness;
    final backgroundColor = brightness == Brightness.dark
        ? CupertinoColors.systemGrey6.darkColor
        : CupertinoColors.systemGrey6.color;
    final iconColor = brightness == Brightness.dark
        ? CupertinoColors.systemGrey.darkColor
        : CupertinoColors.systemGrey.color;

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      decoration: BoxDecoration(
        color: backgroundColor,
        border: Border(
          top: BorderSide(
            color: CupertinoColors.systemGrey4.resolveFrom(context),
            width: 0.5,
          ),
        ),
      ),
      child: Row(
        children: [
          if (userProfile != null)
            AvatarWidget(userProfile: userProfile!, size: 24)
          else
            Container(
              width: 24,
              height: 24,
              decoration: BoxDecoration(
                color: CupertinoColors.systemGrey4.resolveFrom(context),
                borderRadius: BorderRadius.circular(12),
              ),
              child: Icon(
                CupertinoIcons.person_fill,
                size: 13,
                color: iconColor,
              ),
            ),
          const SizedBox(width: 8),
          Expanded(
            child: Text(
              userProfile?.username ?? '',
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: const TextStyle(fontSize: 12),
            ),
          ),
        ],
      ),
    );
  }
}
