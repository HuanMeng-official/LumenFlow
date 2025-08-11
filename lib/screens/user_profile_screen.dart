import 'dart:io';
import 'package:flutter/cupertino.dart';
import 'package:image_picker/image_picker.dart';
import '../models/user_profile.dart';
import '../services/user_service.dart';
import '../widgets/avatar_widget.dart';

class UserProfileScreen extends StatefulWidget {
  const UserProfileScreen({Key? key}) : super(key: key);

  @override
  State<UserProfileScreen> createState() => _UserProfileScreenState();
}

class _UserProfileScreenState extends State<UserProfileScreen> {
  final UserService _userService = UserService();
  final TextEditingController _usernameController = TextEditingController();
  final ImagePicker _imagePicker = ImagePicker();

  UserProfile? _userProfile;
  bool _isLoading = true;
  bool _isSaving = false;

  final List<String> _emojiAvatars = [
    '😊', '😎', '🤗', '😇', '🥰', '😋', '🤓', '😴',
    '🤔', '😏', '😌', '😊', '🙂', '😉', '😁', '😄',
    '🥳', '🤩', '😍', '🤨', '🧐', '🤗', '🤭', '😶',
    '🦸‍♂️', '🦸‍♀️', '🧙‍♂️', '🧙‍♀️', '👨‍💻', '👩‍💻', '👨‍🎨', '👩‍🎨',
  ];

  @override
  void initState() {
    super.initState();
    _loadUserProfile();
  }

  Future<void> _loadUserProfile() async {
    final profile = await _userService.getUserProfile();
    setState(() {
      _userProfile = profile;
      _usernameController.text = profile.username;
      _isLoading = false;
    });
  }

  Future<void> _saveUserProfile() async {
    if (_userProfile == null || _usernameController.text.trim().isEmpty) return;

    setState(() {
      _isSaving = true;
    });

    try {
      final updatedProfile = _userProfile!.copyWith(
        username: _usernameController.text.trim(),
      );

      await _userService.saveUserProfile(updatedProfile);
      setState(() {
        _userProfile = updatedProfile;
      });

      if (mounted) {
        showCupertinoDialog(
          context: context,
          builder: (context) => CupertinoAlertDialog(
            title: const Text('保存成功'),
            content: const Text('用户信息已保存'),
            actions: [
              CupertinoDialogAction(
                child: const Text('确定'),
                onPressed: () => Navigator.pop(context),
              ),
            ],
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        showCupertinoDialog(
          context: context,
          builder: (context) => CupertinoAlertDialog(
            title: const Text('保存失败'),
            content: Text('保存用户信息时出错: $e'),
            actions: [
              CupertinoDialogAction(
                child: const Text('确定'),
                onPressed: () => Navigator.pop(context),
              ),
            ],
          ),
        );
      }
    } finally {
      setState(() {
        _isSaving = false;
      });
    }
  }

  Future<void> _pickImageFromGallery() async {
    try {
      final XFile? image = await _imagePicker.pickImage(
        source: ImageSource.gallery,
        maxWidth: 300,
        maxHeight: 300,
        imageQuality: 80,
      );

      if (image != null) {
        // 删除旧头像
        await _userService.deleteAvatarImage(_userProfile?.avatarPath);

        // 保存新头像
        final savedPath = await _userService.saveAvatarImage(File(image.path));

        setState(() {
          _userProfile = _userProfile!.copyWith(
            avatarPath: savedPath,
            avatarEmoji: null, // 清除emoji头像
          );
        });
      }
    } catch (e) {
      if (mounted) {
        _showErrorDialog('选择头像失败', e.toString());
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

      if (image != null) {
        // 删除旧头像
        await _userService.deleteAvatarImage(_userProfile?.avatarPath);

        // 保存新头像
        final savedPath = await _userService.saveAvatarImage(File(image.path));

        setState(() {
          _userProfile = _userProfile!.copyWith(
            avatarPath: savedPath,
            avatarEmoji: null, // 清除emoji头像
          );
        });
      }
    } catch (e) {
      if (mounted) {
        _showErrorDialog('拍照失败', e.toString());
      }
    }
  }

  void _selectEmojiAvatar() {
    showCupertinoModalPopup(
      context: context,
      builder: (context) => Container(
        height: 300,
        color: CupertinoColors.systemBackground,
        child: Column(
          children: [
            Container(
              padding: const EdgeInsets.all(16),
              decoration: const BoxDecoration(
                border: Border(
                  bottom: BorderSide(
                    color: CupertinoColors.systemGrey4,
                    width: 0.5,
                  ),
                ),
              ),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  CupertinoButton(
                    child: const Text('取消'),
                    onPressed: () => Navigator.pop(context),
                  ),
                  const Text(
                    '选择表情头像',
                    style: TextStyle(
                      fontSize: 17,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  const SizedBox(width: 60), // 占位符保持居中
                ],
              ),
            ),
            Expanded(
              child: GridView.builder(
                padding: const EdgeInsets.all(16),
                gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                  crossAxisCount: 8,
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
                            ? CupertinoColors.systemBlue.withOpacity(0.2)
                            : CupertinoColors.systemGrey6,
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
                      // 删除旧的图片头像
                      await _userService.deleteAvatarImage(_userProfile?.avatarPath);

                      setState(() {
                        _userProfile = _userProfile!.copyWith(
                          avatarEmoji: emoji,
                          avatarPath: null, // 清除图片头像
                        );
                      });
                      Navigator.pop(context);
                    },
                  );
                },
              ),
            ),
          ],
        ),
      ),
    );
  }

  void _showAvatarOptions() {
    showCupertinoModalPopup(
      context: context,
      builder: (context) => CupertinoActionSheet(
        title: const Text('选择头像'),
        actions: [
          CupertinoActionSheetAction(
            child: const Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(CupertinoIcons.photo_on_rectangle, size: 20),
                SizedBox(width: 8),
                Text('从相册选择'),
              ],
            ),
            onPressed: () {
              Navigator.pop(context);
              _pickImageFromGallery();
            },
          ),
          CupertinoActionSheetAction(
            child: const Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(CupertinoIcons.camera, size: 20),
                SizedBox(width: 8),
                Text('拍照'),
              ],
            ),
            onPressed: () {
              Navigator.pop(context);
              _pickImageFromCamera();
            },
          ),
          CupertinoActionSheetAction(
            child: const Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(CupertinoIcons.smiley, size: 20),
                SizedBox(width: 8),
                Text('选择表情'),
              ],
            ),
            onPressed: () {
              Navigator.pop(context);
              _selectEmojiAvatar();
            },
          ),
        ],
        cancelButton: CupertinoActionSheetAction(
          child: const Text('取消'),
          onPressed: () => Navigator.pop(context),
        ),
      ),
    );
  }

  void _showErrorDialog(String title, String message) {
    showCupertinoDialog(
      context: context,
      builder: (context) => CupertinoAlertDialog(
        title: Text(title),
        content: Text(message),
        actions: [
          CupertinoDialogAction(
            child: const Text('确定'),
            onPressed: () => Navigator.pop(context),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    if (_isLoading) {
      return const CupertinoPageScaffold(
        navigationBar: CupertinoNavigationBar(
          middle: Text('用户信息'),
        ),
        child: Center(child: CupertinoActivityIndicator()),
      );
    }

    return CupertinoPageScaffold(
      navigationBar: CupertinoNavigationBar(
        middle: const Text('用户信息'),
        trailing: _isSaving
            ? const CupertinoActivityIndicator()
            : CupertinoButton(
          padding: EdgeInsets.zero,
          child: const Text('保存'),
          onPressed: _saveUserProfile,
        ),
      ),
      child: SafeArea(
        child: ListView(
          children: [
            const SizedBox(height: 32),
            // 头像部分
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
                                color: CupertinoColors.systemBackground,
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
                  const Text(
                    '点击更换头像',
                    style: TextStyle(
                      fontSize: 14,
                      color: CupertinoColors.systemGrey,
                    ),
                  ),
                ],
              ),
            ),

            const SizedBox(height: 32),

            // 用户名设置
            Container(
              margin: const EdgeInsets.symmetric(horizontal: 16),
              decoration: BoxDecoration(
                color: CupertinoColors.systemBackground,
                borderRadius: BorderRadius.circular(12),
                border: Border.all(
                  color: CupertinoColors.systemGrey4,
                  width: 0.5,
                ),
              ),
              child: Container(
                padding: const EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      '用户名',
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                    const SizedBox(height: 4),
                    const Text(
                      'AI会使用这个名字来称呼你',
                      style: TextStyle(
                        fontSize: 13,
                        color: CupertinoColors.systemGrey,
                      ),
                    ),
                    const SizedBox(height: 12),
                    CupertinoTextField(
                      controller: _usernameController,
                      placeholder: '输入你的用户名',
                      decoration: BoxDecoration(
                        color: CupertinoColors.systemGrey6,
                        borderRadius: BorderRadius.circular(8),
                      ),
                      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                    ),
                  ],
                ),
              ),
            ),

            // 说明信息
            Container(
              margin: const EdgeInsets.all(16),
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: CupertinoColors.systemGrey6,
                borderRadius: BorderRadius.circular(12),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: const [
                  Text(
                    '关于用户信息',
                    style: TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  SizedBox(height: 8),
                  Text(
                    '• 头像：可以选择照片或表情作为头像，会在聊天界面显示\n'
                        '• 用户名：AI会在对话中使用这个名字称呼你\n'
                        '• 所有信息仅存储在本地，不会上传到服务器',
                    style: TextStyle(
                      fontSize: 14,
                      color: CupertinoColors.systemGrey,
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

  @override
  void dispose() {
    _usernameController.dispose();
    super.dispose();
  }
}