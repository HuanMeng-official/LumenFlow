import 'package:cupertino_ui/cupertino_ui.dart';

import '../utils/platform_utils.dart';
import 'chat_screen.dart';
import 'desktop/desktop_home_screen.dart';

class AdaptiveHome extends StatelessWidget {
  const AdaptiveHome({super.key});

  @override
  Widget build(BuildContext context) {
    final useDesktop = shouldUseDesktopHome(
      size: MediaQuery.sizeOf(context),
    );
    return useDesktop ? const DesktopHomeScreen() : const ChatScreen();
  }
}
