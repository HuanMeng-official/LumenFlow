import '../l10n/app_localizations.dart';

/// 把归档/世界书/头像相关的底层异常映射成用户可读的本地化文案。
String lumenflowErrorMessage(Object error, AppLocalizations l10n) {
  if (error is FormatException) {
    final message = error.message;
    if (message.contains('Legacy lumenflow v1')) {
      return l10n.lumenflowLegacyUnsupported;
    }
    if (message.contains('Missing character/character.xml') ||
        message.contains('Missing character')) {
      return l10n.lumenflowMissingCharacter;
    }
    if (message.contains('world info') ||
        message.contains('world_info') ||
        message.contains('world info format')) {
      return l10n.lumenflowWorldInfoInvalid;
    }
    if (message.contains('avatar') || message.contains('PNG')) {
      return l10n.lumenflowAvatarInvalid;
    }
    return l10n.lumenflowInvalidArchive;
  }
  return error.toString();
}
