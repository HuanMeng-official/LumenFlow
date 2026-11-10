import 'package:cupertino_ui/cupertino_ui.dart';

import '../l10n/app_localizations.dart';

/// 统一的「角色不可用」确认框。返回 true 表示关闭角色模式并继续发送。
Future<bool> showPresetUnavailableDialog(
  BuildContext context,
  AppLocalizations l10n,
) async {
  final result = await showCupertinoDialog<bool>(
    context: context,
    builder: (dialogContext) => CupertinoAlertDialog(
      title: Text(l10n.presetUnavailableTitle),
      content: Text(l10n.presetUnavailableMessage),
      actions: [
        CupertinoDialogAction(
          child: Text(l10n.cancel),
          onPressed: () => Navigator.pop(dialogContext, false),
        ),
        CupertinoDialogAction(
          isDefaultAction: true,
          child: Text(l10n.presetDisableAndSend),
          onPressed: () => Navigator.pop(dialogContext, true),
        ),
      ],
    ),
  );
  return result == true;
}
