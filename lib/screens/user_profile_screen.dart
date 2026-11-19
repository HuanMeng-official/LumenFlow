import 'dart:io';

import 'package:cupertino_ui/cupertino_ui.dart';
import 'package:image_picker/image_picker.dart';
import 'package:intl/intl.dart';

import '../l10n/app_localizations.dart';
import '../models/user_profile.dart';
import '../services/user_service.dart';
import '../utils/app_theme.dart';
import '../widgets/avatar_widget.dart';
import '../widgets/settings/settings_input_tile.dart';
import '../widgets/settings/settings_page_scaffold.dart';
import '../widgets/settings/settings_section.dart';

/// 个人档案设置页，支持头像、用户名、性别与生日配置。
class UserProfileScreen extends StatefulWidget {
  final bool embedded;
  final String? previousPageTitle;

  const UserProfileScreen({
    super.key,
    this.embedded = false,
    this.previousPageTitle,
  });

  @override
  State<UserProfileScreen> createState() => _UserProfileScreenState();
}

class _UserProfileScreenState extends State<UserProfileScreen> {
  final UserService _userService = UserService();
  final TextEditingController _usernameController = TextEditingController();
  final ImagePicker _imagePicker = ImagePicker();

  UserProfile? _userProfile;
  String? _gender;
  DateTime? _birthday;
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadUserProfile();
  }

  @override
  void dispose() {
    _usernameController.dispose();
    super.dispose();
  }

  Future<void> _loadUserProfile() async {
    final profile = await _userService.getUserProfile();
    if (!mounted) return;
    setState(() {
      _userProfile = profile;
      _usernameController.text = profile.username;
      _gender = profile.gender;
      _birthday = profile.birthday;
      _isLoading = false;
    });
  }

  Future<void> _onUsernameChanged() async {
    if (_userProfile == null || _usernameController.text.trim().isEmpty) return;
    final newUsername = _usernameController.text.trim();
    if (newUsername == _userProfile!.username) return;

    final updated = _userProfile!.copyWith(username: newUsername);
    await _userService.saveUserProfile(updated);
    if (!mounted) return;
    setState(() => _userProfile = updated);
  }

  Future<void> _onGenderChanged(String? newValue) async {
    if (newValue == null || newValue == _gender) return;
    setState(() => _gender = newValue);
    if (_userProfile == null) return;

    final updated = _userProfile!.copyWith(gender: newValue);
    await _userService.saveUserProfile(updated);
    if (!mounted) return;
    setState(() => _userProfile = updated);
  }

  Future<void> _onBirthdayChanged(DateTime? newDate) async {
    if (newDate == _birthday) return;
    setState(() => _birthday = newDate);
    if (_userProfile == null) return;

    final updated = _userProfile!.copyWith(birthday: newDate);
    await _userService.saveUserProfile(updated);
    if (!mounted) return;
    setState(() => _userProfile = updated);
  }

  Future<void> _showBirthdayPicker() async {
    final l10n = AppLocalizations.of(context)!;
    final initialDate =
        _birthday ?? DateTime.now().subtract(const Duration(days: 18 * 365));

    await showCupertinoModalPopup<void>(
      context: context,
      builder: (popupContext) => Container(
        height: 300,
        color: AppTokens.elevatedSurface(popupContext),
        child: Column(
          children: [
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
              decoration: BoxDecoration(
                border: Border(
                  bottom: BorderSide(
                    color: AppTokens.separator(popupContext),
                    width: 0.5,
                  ),
                ),
              ),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  CupertinoButton(
                    padding: const EdgeInsets.symmetric(horizontal: 8),
                    onPressed: () => Navigator.pop(popupContext),
                    child: Text(l10n.cancel),
                  ),
                  Text(
                    l10n.selectBirthday,
                    style: const TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  CupertinoButton(
                    padding: const EdgeInsets.symmetric(horizontal: 8),
                    onPressed: () => Navigator.pop(popupContext),
                    child: Text(l10n.confirm),
                  ),
                ],
              ),
            ),
            Expanded(
              child: CupertinoDatePicker(
                mode: CupertinoDatePickerMode.date,
                initialDateTime: initialDate,
                minimumDate: DateTime(1900),
                maximumDate: DateTime.now(),
                onDateTimeChanged: _onBirthdayChanged,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _updateAvatarWithImage(String path) async {
    if (_userProfile == null) return;
    await _userService.deleteAvatarImage(_userProfile?.avatarPath);
    final savedPath = await _userService.saveAvatarImage(File(path));
    final updated = UserProfile(
      id: _userProfile!.id,
      username: _userProfile!.username,
      avatarPath: savedPath,
      avatarEmoji: null,
      gender: _userProfile!.gender,
      birthday: _userProfile!.birthday,
      createdAt: _userProfile!.createdAt,
      updatedAt: DateTime.now(),
    );
    await _userService.saveUserProfile(updated);
    if (!mounted) return;
    setState(() => _userProfile = updated);
  }

  Future<void> _resetAvatar() async {
    if (_userProfile == null) return;
    await _userService.deleteAvatarImage(_userProfile?.avatarPath);
    final updated = UserProfile(
      id: _userProfile!.id,
      username: _userProfile!.username,
      avatarPath: null,
      avatarEmoji: null,
      gender: _userProfile!.gender,
      birthday: _userProfile!.birthday,
      createdAt: _userProfile!.createdAt,
      updatedAt: DateTime.now(),
    );
    await _userService.saveUserProfile(updated);
    if (!mounted) return;
    setState(() => _userProfile = updated);
  }

  Future<void> _pickImage(ImageSource source) async {
    final l10n = AppLocalizations.of(context)!;
    try {
      final image = await _imagePicker.pickImage(
        source: source,
        maxWidth: 320,
        maxHeight: 320,
        imageQuality: 85,
      );
      if (image != null && mounted) {
        await _updateAvatarWithImage(image.path);
      }
    } catch (e) {
      if (!mounted) return;
      _showErrorDialog(
        source == ImageSource.camera ? l10n.takePhotoFailed : l10n.pickAvatarFailed,
        e.toString(),
      );
    }
  }

  void _showAvatarOptions() {
    final l10n = AppLocalizations.of(context)!;
    final isIosSimulator = Platform.isIOS &&
        Platform.environment.containsKey('SIMULATOR_DEVICE_NAME');
    final cameraAvailable =
        !isIosSimulator && _imagePicker.supportsImageSource(ImageSource.camera);

    showCupertinoModalPopup<void>(
      context: context,
      builder: (sheetContext) => CupertinoActionSheet(
        title: Text(l10n.selectAvatar),
        actions: [
          CupertinoActionSheetAction(
            onPressed: () {
              Navigator.pop(sheetContext);
              _pickImage(ImageSource.gallery);
            },
            child: Text(l10n.selectFromGallery),
          ),
          if (cameraAvailable)
            CupertinoActionSheetAction(
              onPressed: () {
                Navigator.pop(sheetContext);
                _pickImage(ImageSource.camera);
              },
              child: Text(l10n.takePhoto),
            ),
          if ((_userProfile?.avatarPath?.isNotEmpty ?? false) ||
              (_userProfile?.avatarEmoji?.isNotEmpty ?? false))
            CupertinoActionSheetAction(
              isDestructiveAction: true,
              onPressed: () {
                Navigator.pop(sheetContext);
                _resetAvatar();
              },
              child: Text(l10n.clear),
            ),
        ],
        cancelButton: CupertinoActionSheetAction(
          onPressed: () => Navigator.pop(sheetContext),
          child: Text(l10n.cancel),
        ),
      ),
    );
  }

  void _showErrorDialog(String title, String message) {
    final l10n = AppLocalizations.of(context)!;
    showCupertinoDialog<void>(
      context: context,
      builder: (dialogContext) => CupertinoAlertDialog(
        title: Text(title),
        content: Text(message),
        actions: [
          CupertinoDialogAction(
            child: Text(l10n.ok),
            onPressed: () => Navigator.pop(dialogContext),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;

    if (_isLoading || _userProfile == null) {
      return SettingsPageScaffold(
        title: l10n.userProfile,
        previousPageTitle: widget.previousPageTitle,
        embedded: widget.embedded,
        child: const Center(child: CupertinoActivityIndicator()),
      );
    }

    final formattedBirthday = _birthday != null
        ? DateFormat.yMMMd().format(_birthday!)
        : l10n.selectBirthday;

    return SettingsPageScaffold(
      title: l10n.userProfile,
      previousPageTitle: widget.previousPageTitle,
      embedded: widget.embedded,
      child: ListView(
        padding: const EdgeInsets.only(bottom: 32),
        children: [
          const SizedBox(height: 24),
          Center(
            child: Column(
              children: [
                CupertinoButton(
                  padding: EdgeInsets.zero,
                  onPressed: _showAvatarOptions,
                  child: AvatarWidget(userProfile: _userProfile!, size: 88),
                ),
                const SizedBox(height: 6),
                CupertinoButton(
                  padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
                  onPressed: _showAvatarOptions,
                  child: Text(
                    l10n.tapToChangeAvatar,
                    style: TextStyle(
                      fontSize: 13.5,
                      color: AppTokens.accent(context),
                    ),
                  ),
                ),
              ],
            ),
          ),
          SettingsSection(
            title: l10n.userInfo,
            footer: l10n.aboutUserProfileContent,
            children: [
              SettingsInputTile(
                title: l10n.username,
                controller: _usernameController,
                placeholder: l10n.enterYourUsername,
                subtitle: l10n.usernameHint,
                onChanged: (_) => _onUsernameChanged(),
              ),
              Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 16,
                  vertical: 14,
                ),
                child: Row(
                  children: [
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            l10n.gender,
                            style: TextStyle(
                              fontSize: 16,
                              fontWeight: FontWeight.w500,
                              color: AppTokens.label(context),
                            ),
                          ),
                          const SizedBox(height: 2),
                          Text(
                            l10n.genderHint,
                            style: TextStyle(
                              fontSize: 13,
                              color: AppTokens.labelSecondary(context),
                            ),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(width: 12),
                    CupertinoSlidingSegmentedControl<String>(
                      groupValue: (_gender == 'male' || _gender == 'female')
                          ? _gender
                          : null,
                      children: {
                        'male': Padding(
                          padding: const EdgeInsets.symmetric(horizontal: 10),
                          child: Text(
                            l10n.male,
                            style: const TextStyle(fontSize: 13),
                          ),
                        ),
                        'female': Padding(
                          padding: const EdgeInsets.symmetric(horizontal: 10),
                          child: Text(
                            l10n.female,
                            style: const TextStyle(fontSize: 13),
                          ),
                        ),
                      },
                      onValueChanged: _onGenderChanged,
                    ),
                  ],
                ),
              ),
              GestureDetector(
                behavior: HitTestBehavior.opaque,
                onTap: _showBirthdayPicker,
                child: Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 16,
                    vertical: 14,
                  ),
                  child: Row(
                    children: [
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              l10n.birthday,
                              style: TextStyle(
                                fontSize: 16,
                                fontWeight: FontWeight.w500,
                                color: AppTokens.label(context),
                              ),
                            ),
                            const SizedBox(height: 2),
                            Text(
                              l10n.birthdayHint,
                              style: TextStyle(
                                fontSize: 13,
                                color: AppTokens.labelSecondary(context),
                              ),
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(width: 12),
                      Text(
                        formattedBirthday,
                        style: TextStyle(
                          fontSize: 14.5,
                          color: _birthday != null
                              ? AppTokens.label(context)
                              : AppTokens.labelSecondary(context),
                        ),
                      ),
                      const SizedBox(width: 4),
                      Icon(
                        CupertinoIcons.chevron_right,
                        size: 16,
                        color: AppTokens.labelTertiary(context),
                      ),
                    ],
                  ),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}
