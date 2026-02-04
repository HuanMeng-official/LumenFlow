import 'dart:convert';
import 'dart:io';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:path/path.dart' as path;
import '../utils/path_utils.dart';
import '../models/user_profile.dart';

class UserService {
  static const String _userProfileKey = 'user_profile';

  Future<UserProfile> getUserProfile() async {
    final prefs = await SharedPreferences.getInstance();
    final profileString = prefs.getString(_userProfileKey);

    if (profileString == null) {
      final defaultProfile = UserProfile.getDefault();
      await saveUserProfile(defaultProfile);
      return defaultProfile;
    }

    return UserProfile.fromJson(jsonDecode(profileString));
  }

  Future<void> saveUserProfile(UserProfile profile) async {
    final prefs = await SharedPreferences.getInstance();
    final updatedProfile = profile.copyWith(updatedAt: DateTime.now());
    await prefs.setString(_userProfileKey, jsonEncode(updatedProfile.toJson()));
  }

  Future<String> saveAvatarImage(File imageFile) async {
    final avatarsDirPath = await PathUtils.getAvatarsDirPath();
    final avatarDir = Directory(avatarsDirPath);

    final fileName =
        'avatar_${DateTime.now().millisecondsSinceEpoch}${path.extension(imageFile.path)}';
    final savedFile = File('${avatarDir.path}/$fileName');

    await imageFile.copy(savedFile.path);

    return savedFile.path;
  }

  Future<void> deleteAvatarImage(String? avatarPath) async {
    if (avatarPath == null) return;

    final file = File(avatarPath);
    if (await file.exists()) {
      await file.delete();
    }
  }
}
