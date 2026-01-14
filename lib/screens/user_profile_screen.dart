import 'dart:io';
import 'package:flutter/cupertino.dart';
import 'package:image_picker/image_picker.dart';
import '../l10n/app_localizations.dart';
import '../models/user_profile.dart';
import '../services/user_service.dart';
import '../widgets/avatar_widget.dart';

/// 用户信息设置页面
///
/// 设置更改实时保存，无需手动点击保存按钮
class UserProfileScreen extends StatefulWidget {
  const UserProfileScreen({super.key});

  @override
  State<UserProfileScreen> createState() => _UserProfileScreenState();
}

class _UserProfileScreenState extends State<UserProfileScreen> {
  final UserService _userService = UserService();
  final TextEditingController _usernameController = TextEditingController();
  final ImagePicker _imagePicker = ImagePicker();

  UserProfile? _userProfile;
  String? _gender;
  bool _isLoading = true;

  final List<String> _emojiAvatars = [
    '😊',
    '😎',
    '🤗',
    '😇',
    '🥰',
    '😋',
    '🤓',
    '😴',
    '🤔',
    '😏',
    '😌',
    '😴',
    '🙂',
    '😉',
    '😁',
    '😄',
    '🥳',
    '🤩',
    '😍',
    '🤨',
    '🧐',
    '🤗',
    '🤭',
    '😶',
    '🦸‍♂️',
    '🦸‍♀️',
    '🧙‍♂️',
    '🧙‍♀️',
    '👨‍💻',
    '👩‍💻',
    '👨‍🎨',
    '👩‍🎨',
  ];

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
    setState(() {
      _userProfile = profile;
      _usernameController.text = profile.username;
      _gender = profile.gender;
      _isLoading = false;
    });
  }

  /// 实时保存用户名变更（防抖）
  Future<void> _onUsernameChanged() async {
    if (_userProfile == null || _usernameController.text.trim().isEmpty) return;

    final newUsername = _usernameController.text.trim();
    if (newUsername == _userProfile!.username) return;

    final updatedProfile = _userProfile!.copyWith(username: newUsername);
    await _userService.saveUserProfile(updatedProfile);
    setState(() {
      _userProfile = updatedProfile;
    });
  }

  /// 实时保存性别变更
  Future<void> _onGenderChanged(String? newValue) async {
    if (newValue == null || newValue == _gender) return;

    setState(() {
      _gender = newValue;
    });

    if (_userProfile != null) {
      final updatedProfile = _userProfile!.copyWith(gender: newValue);
      await _userService.saveUserProfile(updatedProfile);
      setState(() {
        _userProfile = updatedProfile;
      });
    }
  }

  /// 实时保存并更新头像
  Future<void> _updateAvatarWithImage(String newAvatarPath) async {
    if (_userProfile == null) return;

    await _userService.deleteAvatarImage(_userProfile?.avatarPath);
    final savedPath = await _userService.saveAvatarImage(File(newAvatarPath));

    setState(() {
      _userProfile = _userProfile!.copyWith(avatarPath: savedPath, avatarEmoji: null);
    });
    await _userService.saveUserProfile(_userProfile!);
  }

  /// 实时保存并更新表情头像
  Future<void> _updateAvatarWithEmoji(String emoji) async {
    if (_userProfile == null) return;

    await _userService.deleteAvatarImage(_userProfile?.avatarPath);

    setState(() {
      _userProfile = _userProfile!.copyWith(avatarEmoji: emoji, avatarPath: null);
    });
    await _userService.saveUserProfile(_userProfile!);
  }

  Widget _buildDropdownTile(
    String title, {
    required String? value,
    required Map<String, String> options,
    String? subtitle,
    ValueChanged<String?>? onChanged,
  }) {
    final currentLabel = value != null ? (options[value] ?? value) : '';
    final brightness = CupertinoTheme.of(context).brightness;
    final isEnabled = onChanged != null;

    return Container(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            title,
            style: const TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.w500,
            ),
          ),
          if (subtitle != null) ...[
            const SizedBox(height: 4),
            Text(
              subtitle,
              style: TextStyle(
                fontSize: 13,
                color: brightness == Brightness.dark
                    ? CupertinoColors.systemGrey.darkColor
                    : CupertinoColors.systemGrey,
              ),
            ),
          ],
          const SizedBox(height: 12),
          CupertinoButton(
            padding: EdgeInsets.zero,
            onPressed: onChanged != null
                ? () {
                    showCupertinoModalPopup<void>(
                      context: context,
                      builder: (BuildContext context) {
                        final popupBrightness = CupertinoTheme.of(context).brightness;
                        return CupertinoActionSheet(
                          title: Text(title),
                          message: subtitle != null ? Text(subtitle) : null,
                          actions: [
                            for (final entry in options.entries)
                              CupertinoActionSheetAction(
                                onPressed: () {
                                  Navigator.pop(context);
                                  onChanged(entry.key);
                                },
                                child: Text(
                                  entry.value,
                                  style: TextStyle(
                                    color: value == entry.key
                                        ? (popupBrightness == Brightness.dark
                                            ? CupertinoColors.activeBlue.darkColor
                                            : CupertinoColors.activeBlue.color)
                                        : (popupBrightness == Brightness.dark
                                            ? CupertinoColors.label.darkColor
                                            : CupertinoColors.label.color),
                                  ),
                                ),
                              ),
                          ],
                          cancelButton: CupertinoActionSheetAction(
                            onPressed: () {
                              Navigator.pop(context);
                            },
                            child: Text(
                              AppLocalizations.of(context)!.cancel,
                              style: TextStyle(
                                color: popupBrightness == Brightness.dark
                                    ? CupertinoColors.systemRed.darkColor
                                    : CupertinoColors.systemRed.color,
                              ),
                            ),
                          ),
                        );
                      },
                    );
                  }
                : null,
            child: Container(
              width: double.infinity,
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
              decoration: BoxDecoration(
                color: isEnabled
                    ? (CupertinoTheme.of(context).brightness == Brightness.dark
                        ? CupertinoColors.systemGrey6.darkColor
                        : CupertinoColors.systemGrey6.color)
                    : (CupertinoTheme.of(context).brightness == Brightness.dark
                        ? CupertinoColors.tertiarySystemFill.darkColor
                        : CupertinoColors.tertiarySystemFill.color),
                borderRadius: BorderRadius.circular(8),
              ),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    currentLabel.isNotEmpty ? currentLabel : AppLocalizations.of(context)!.selectGender,
                    style: TextStyle(
                      fontSize: 16,
                      color: isEnabled
                          ? (brightness == Brightness.dark
                              ? CupertinoColors.label.darkColor
                              : CupertinoColors.label.color)
                          : (brightness == Brightness.dark
                              ? CupertinoColors.tertiaryLabel.darkColor
                              : CupertinoColors.tertiaryLabel.color),
                    ),
                  ),
                  Icon(
                    CupertinoIcons.chevron_down,
                    size: 18,
                    color: isEnabled
                        ? (brightness == Brightness.dark
                            ? CupertinoColors.systemGrey.darkColor
                            : CupertinoColors.systemGrey)
                        : (brightness == Brightness.dark
                            ? CupertinoColors.tertiaryLabel.darkColor
                            : CupertinoColors.tertiaryLabel.color),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Future<void> _pickImageFromGallery() async {
    try {
      final XFile? image = await _imagePicker.pickImage(
        source: ImageSource.gallery,
        maxWidth: 300,
        maxHeight: 300,
        imageQuality: 80,
      );

      if (image != null && mounted) {
        await _updateAvatarWithImage(image.path);
      }
    } catch (e) {
      if (mounted) {
        final l10n = AppLocalizations.of(context)!;
        _showErrorDialog(l10n.pickAvatarFailed, e.toString());
      }
    }
  }

  Future<void> _pickImageFromCamera() async {
    try {
      final XFile? image = await _imagePicker.pickImage(
        source: ImageSource.camera,
        maxWidth: 300,
        maxHeight: 300,
        imageQuality: 80,
      );

      if (image != null && mounted) {
        await _updateAvatarWithImage(image.path);
      }
    } catch (e) {
      if (mounted) {
        final l10n = AppLocalizations.of(context)!;
        _showErrorDialog(l10n.takePhotoFailed, e.toString());
      }
    }
  }

  void _selectEmojiAvatar() {
    final l10n = AppLocalizations.of(context)!;
    final screenHeight = MediaQuery.of(context).size.height;
    final popupHeight = (screenHeight * 0.4).clamp(250.0, 400.0).toDouble();

    showCupertinoModalPopup(
      context: context,
      builder: (context) {
        final brightness = CupertinoTheme.of(context).brightness;
        return Container(
          height: popupHeight,
          color: brightness == Brightness.dark
              ? CupertinoColors.systemBackground.darkColor
              : CupertinoColors.systemBackground.color,
          child: Column(
            children: [
              Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  border: Border(
                    bottom: BorderSide(
                      color: brightness == Brightness.dark
                          ? CupertinoColors.systemGrey4.darkColor
                          : CupertinoColors.systemGrey4.color,
                      width: 0.5,
                    ),
                  ),
                ),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    CupertinoButton(
                      child: Text(l10n.cancel),
                      onPressed: () => Navigator.pop(context),
                    ),
                    Text(
                      l10n.selectEmojiAvatar,
                      style: const TextStyle(
                        fontSize: 17,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                    const SizedBox(width: 60),
                  ],
                ),
              ),
              Expanded(
                child: Builder(
                  builder: (context) {
                    final screenWidth = MediaQuery.of(context).size.width;
                    final crossAxisCount = (screenWidth / 50).floor().clamp(5, 10);
                    return GridView.builder(
                      padding: const EdgeInsets.all(16),
                      gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
                        crossAxisCount: crossAxisCount,
                        mainAxisSpacing: 12,
                        crossAxisSpacing: 12,
                      ),
                      itemCount: _emojiAvatars.length,
                      itemBuilder: (context, index) {
                        final emoji = _emojiAvatars[index];
                        return CupertinoButton(
                          padding: EdgeInsets.zero,
                          child: Container(
                            decoration: BoxDecoration(
                              color: _userProfile?.avatarEmoji == emoji
                                  ? CupertinoColors.systemBlue.withValues(alpha: 0.2)
                                  : (brightness == Brightness.dark
                                      ? CupertinoColors.systemGrey6.darkColor
                                      : CupertinoColors.systemGrey6.color),
                              borderRadius: BorderRadius.circular(8),
                            ),
                            child: Center(
                              child: Text(
                                emoji,
                                style: const TextStyle(fontSize: 24),
                              ),
                            ),
                          ),
                          onPressed: () async {
                            final navigator = Navigator.of(context);
                            await _updateAvatarWithEmoji(emoji);
                            if (mounted) {
                              navigator.pop();
                            }
                          },
                        );
                      },
                    );
                  },
                ),
              ),
            ],
          ),
        );
      },
    );
  }

  void _showAvatarOptions() {
    final l10n = AppLocalizations.of(context)!;
    showCupertinoModalPopup(
      context: context,
      builder: (context) => CupertinoActionSheet(
        title: Text(l10n.selectAvatar),
        actions: [
          CupertinoActionSheetAction(
            child: Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                const Icon(CupertinoIcons.photo_on_rectangle, size: 20),
                const SizedBox(width: 8),
                Text(l10n.selectFromGallery),
              ],
            ),
            onPressed: () {
              Navigator.pop(context);
              _pickImageFromGallery();
            },
          ),
          CupertinoActionSheetAction(
            child: Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                const Icon(CupertinoIcons.camera, size: 20),
                const SizedBox(width: 8),
                Text(l10n.takePhoto),
              ],
            ),
            onPressed: () {
              Navigator.pop(context);
              _pickImageFromCamera();
            },
          ),
          CupertinoActionSheetAction(
            child: Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                const Icon(CupertinoIcons.smiley, size: 20),
                const SizedBox(width: 8),
                Text(l10n.selectEmoji),
              ],
            ),
            onPressed: () {
              Navigator.pop(context);
              _selectEmojiAvatar();
            },
          ),
        ],
        cancelButton: CupertinoActionSheetAction(
          child: Text(l10n.cancel),
          onPressed: () => Navigator.pop(context),
        ),
      ),
    );
  }

  void _showErrorDialog(String title, String message) {
    final l10n = AppLocalizations.of(context)!;
    showCupertinoDialog(
      context: context,
      builder: (context) => CupertinoAlertDialog(
        title: Text(title),
        content: Text(message),
        actions: [
          CupertinoDialogAction(
            child: Text(l10n.ok),
            onPressed: () => Navigator.pop(context),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final brightness = CupertinoTheme.of(context).brightness;

    if (_isLoading) {
      return CupertinoPageScaffold(
        navigationBar: CupertinoNavigationBar(
          middle: Text(l10n.userInfo),
        ),
        child: const Center(child: CupertinoActivityIndicator()),
      );
    }
    if (_userProfile == null) {
      return CupertinoPageScaffold(
        navigationBar: CupertinoNavigationBar(
          middle: Text(l10n.userInfo),
        ),
        child: Center(child: Text(l10n.loading)),
      );
    }

    return CupertinoPageScaffold(
      navigationBar: CupertinoNavigationBar(
        middle: Text(l10n.userInfo),
      ),
      child: SafeArea(
        child: ListView(
          children: [
            const SizedBox(height: 32),
            Center(
              child: Column(
                children: [
                  CupertinoButton(
                    onPressed: _showAvatarOptions,
                    child: Stack(
                      children: [
                        AvatarWidget(
                          userProfile: _userProfile!,
                          size: 100,
                        ),
                        Positioned(
                          right: 0,
                          bottom: 0,
                          child: Container(
                            width: 32,
                            height: 32,
                            decoration: BoxDecoration(
                              color: CupertinoColors.systemBlue,
                              borderRadius: BorderRadius.circular(16),
                              border: Border.all(
                                color: brightness == Brightness.dark
                                    ? CupertinoColors.systemBackground.darkColor
                                    : CupertinoColors.systemBackground.color,
                                width: 2,
                              ),
                            ),
                            child: const Icon(
                              CupertinoIcons.camera,
                              color: CupertinoColors.white,
                              size: 16,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    l10n.tapToChangeAvatar,
                    style: TextStyle(
                      fontSize: 14,
                      color: brightness == Brightness.dark
                          ? CupertinoColors.systemGrey.darkColor
                          : CupertinoColors.systemGrey.color,
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 32),
            Container(
              margin: const EdgeInsets.symmetric(horizontal: 16),
              decoration: BoxDecoration(
                color: brightness == Brightness.dark
                    ? CupertinoColors.systemBackground.darkColor
                    : CupertinoColors.systemBackground.color,
                borderRadius: BorderRadius.circular(12),
                border: Border.all(
                  color: brightness == Brightness.dark
                      ? CupertinoColors.systemGrey4.darkColor
                      : CupertinoColors.systemGrey4.color,
                  width: 0.5,
                ),
              ),
              child: Container(
                padding: const EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      l10n.username,
                      style: const TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      l10n.usernameHint,
                      style: TextStyle(
                        fontSize: 13,
                        color: brightness == Brightness.dark
                            ? CupertinoColors.systemGrey.darkColor
                            : CupertinoColors.systemGrey.color,
                      ),
                    ),
                    const SizedBox(height: 12),
                    CupertinoTextField(
                      controller: _usernameController,
                      placeholder: l10n.enterYourUsername,
                      decoration: BoxDecoration(
                        color: brightness == Brightness.dark
                            ? CupertinoColors.systemGrey6.darkColor
                            : CupertinoColors.systemGrey6.color,
                        borderRadius: BorderRadius.circular(8),
                      ),
                      padding: const EdgeInsets.symmetric(
                        horizontal: 16, vertical: 12,
                      ),
                      onChanged: (_) => _onUsernameChanged(),
                    ),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 16),
            Container(
              margin: const EdgeInsets.symmetric(horizontal: 16),
              decoration: BoxDecoration(
                color: brightness == Brightness.dark
                    ? CupertinoColors.systemBackground.darkColor
                    : CupertinoColors.systemBackground.color,
                borderRadius: BorderRadius.circular(12),
                border: Border.all(
                  color: brightness == Brightness.dark
                      ? CupertinoColors.systemGrey4.darkColor
                      : CupertinoColors.systemGrey4.color,
                  width: 0.5,
                ),
              ),
              child: _buildDropdownTile(
                l10n.gender,
                value: _gender,
                options: {
                  'male': l10n.male,
                  'female': l10n.female,
                },
                subtitle: l10n.genderHint,
                onChanged: _onGenderChanged,
              ),
            ),
            Container(
              margin: const EdgeInsets.all(16),
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: brightness == Brightness.dark
                    ? CupertinoColors.systemGrey6.darkColor
                    : CupertinoColors.systemGrey6.color,
                borderRadius: BorderRadius.circular(12),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    l10n.aboutUserProfile,
                    style: const TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    l10n.aboutUserProfileContent,
                    style: TextStyle(
                      fontSize: 14,
                      color: brightness == Brightness.dark
                          ? CupertinoColors.systemGrey.darkColor
                          : CupertinoColors.systemGrey.color,
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
