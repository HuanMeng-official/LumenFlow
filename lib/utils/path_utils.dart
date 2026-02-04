import 'dart:io';
import 'package:flutter/foundation.dart';
import 'package:path_provider/path_provider.dart';

/// 路径工具类，提供跨平台的应用数据目录访问
class PathUtils {
  /// 获取应用数据目录
  ///
  /// 平台特定行为：
  /// - Android: 返回应用文档目录 (getApplicationDocumentsDirectory)
  /// - Windows/Linux/macOS: 返回用户主目录下的 `.lumenflow` 隐藏文件夹
  static Future<Directory> getAppDataDirectory() async {
    if (Platform.isAndroid) {
      // Android 平台使用标准应用文档目录
      return await getApplicationDocumentsDirectory();
    } else {
      // 桌面平台使用用户主目录下的 .lumenflow 文件夹
      final String? homeDir;

      if (Platform.isWindows) {
        homeDir = Platform.environment['USERPROFILE'];
      } else {
        // Linux, macOS, 其他 Unix 系统
        homeDir = Platform.environment['HOME'];
      }

      if (homeDir == null) {
        // 如果无法获取用户主目录，回退到当前工作目录
        return Directory.current;
      }

      final appDataDir = Directory('$homeDir/.lumenflow');
      if (!await appDataDir.exists()) {
        await appDataDir.create(recursive: true);
      }

      return appDataDir;
    }
  }

  /// 获取数据库文件路径
  static Future<String> getDatabasePath() async {
    final appDir = await getAppDataDirectory();
    return '${appDir.path}/conversations.db';
  }

  /// 获取附件目录路径
  static Future<String> getAttachmentsDirPath() async {
    final appDir = await getAppDataDirectory();
    final attachmentsDir = Directory('${appDir.path}/attachments');
    if (!await attachmentsDir.exists()) {
      await attachmentsDir.create(recursive: true);
    }
    return attachmentsDir.path;
  }

  /// 获取头像目录路径
  static Future<String> getAvatarsDirPath() async {
    final appDir = await getAppDataDirectory();
    final avatarsDir = Directory('${appDir.path}/avatars');
    if (!await avatarsDir.exists()) {
      await avatarsDir.create(recursive: true);
    }
    return avatarsDir.path;
  }

  /// 迁移旧数据到新位置（如果需要）
  ///
  /// 检查旧的应用文档目录中是否存在数据文件，如果存在且新位置不存在，
  /// 则将数据迁移到新位置。仅适用于桌面平台。
  static Future<void> migrateOldDataIfNeeded() async {
    // Android 平台不需要迁移（位置不变）
    if (Platform.isAndroid) {
      return;
    }

    final oldAppDir = await getApplicationDocumentsDirectory();
    final newAppDir = await getAppDataDirectory();

    // 如果新旧目录相同，不需要迁移
    if (oldAppDir.path == newAppDir.path) {
      return;
    }

    // 检查旧数据库文件是否存在
    final oldDbFile = File('${oldAppDir.path}/conversations.db');
    final newDbFile = File('${newAppDir.path}/conversations.db');

    if (await oldDbFile.exists() && !await newDbFile.exists()) {
      debugPrint('迁移数据库文件: ${oldDbFile.path} -> ${newDbFile.path}');
      await oldDbFile.copy(newDbFile.path);
    }

    // 迁移附件目录
    final oldAttachmentsDir = Directory('${oldAppDir.path}/attachments');
    final newAttachmentsDir = Directory('${newAppDir.path}/attachments');
    if (await oldAttachmentsDir.exists() && !await newAttachmentsDir.exists()) {
      debugPrint('迁移附件目录: ${oldAttachmentsDir.path} -> ${newAttachmentsDir.path}');
      await _copyDirectory(oldAttachmentsDir, newAttachmentsDir);
    }

    // 迁移头像目录
    final oldAvatarsDir = Directory('${oldAppDir.path}/avatars');
    final newAvatarsDir = Directory('${newAppDir.path}/avatars');
    if (await oldAvatarsDir.exists() && !await newAvatarsDir.exists()) {
      debugPrint('迁移头像目录: ${oldAvatarsDir.path} -> ${newAvatarsDir.path}');
      await _copyDirectory(oldAvatarsDir, newAvatarsDir);
    }
  }

  /// 复制目录及其所有内容
  static Future<void> _copyDirectory(Directory source, Directory destination) async {
    if (!await destination.exists()) {
      await destination.create(recursive: true);
    }

    final files = await source.list().toList();
    for (final file in files) {
      if (file is File) {
        final destFile = File('${destination.path}/${file.path.split('/').last}');
        await file.copy(destFile.path);
      } else if (file is Directory) {
        final destSubDir = Directory('${destination.path}/${file.path.split('/').last}');
        await _copyDirectory(file, destSubDir);
      }
    }
  }
}