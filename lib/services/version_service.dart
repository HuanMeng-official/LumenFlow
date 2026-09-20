import 'dart:convert';
import 'dart:io';
import 'package:flutter/services.dart' show rootBundle;

/// 版本信息服务，用于获取应用版本和构建信息
class VersionService {
  static const String _versionFallback = '1.0.5';

  /// 构建日期，由构建脚本通过 `--dart-define=BUILD_DATE=yyyy-MM-dd` 注入。
  ///
  /// 这是一个编译期常量。构建时刻只有构建脚本知道，运行时无从获取，
  /// 因此不能用 DateTime.now() —— 那样得到的是"这次启动的时间"，
  /// 每次重启都会变，看起来就像日期在每日刷新。
  ///
  /// 直接跑 `flutter run` 或不经脚本执行 `flutter build` 时该值为空串，
  /// 此时回退到可执行文件时间戳。
  static const String _injectedBuildDate =
      String.fromEnvironment('BUILD_DATE', defaultValue: '');

  /// 构建日期缓存，避免重复读取可执行文件状态
  String? _cachedBuildDate;

  /// 获取应用版本号
  /// 从pubspec.yaml文件中读取版本信息
  /// 如果读取失败，返回默认版本号
  Future<String> getAppVersion() async {
    try {
      // 读取pubspec.yaml文件内容
      final pubspecContent = await rootBundle.loadString('pubspec.yaml');

      // 解析版本号
      for (final line in LineSplitter.split(pubspecContent)) {
        if (line.trim().startsWith('version:')) {
          final version = line.split(':')[1].trim();
          // 移除构建号（+后面的部分）
          return version.split('+').first;
        }
      }
    } catch (e) {
      // 如果读取失败，返回默认值
    }

    return _versionFallback;
  }

  /// 获取构建日期
  /// 格式化为YYYY-MM-DD
  Future<String> getBuildDate() async {
    if (_cachedBuildDate != null) {
      return _cachedBuildDate!;
    }

    _cachedBuildDate = _injectedBuildDate.isNotEmpty
        ? _injectedBuildDate
        : await _buildDateFromExecutable();

    return _cachedBuildDate!;
  }

  /// 回退方案：取可执行文件的修改时间
  ///
  /// 桌面平台上该文件在构建时写出，时间戳接近真实构建时间；
  /// Android 上指向已解压的 libapp.so，时间戳是安装时间。
  /// 仅用于未经构建脚本的开发构建。
  Future<String> _buildDateFromExecutable() async {
    try {
      final stat = await File(Platform.resolvedExecutable).stat();
      return _formatDate(stat.modified);
    } catch (e) {
      return '';
    }
  }

  static String _formatDate(DateTime date) {
    final month = date.month.toString().padLeft(2, '0');
    final day = date.day.toString().padLeft(2, '0');
    return '${date.year}-$month-$day';
  }

  /// 获取完整的版本信息
  /// 包含版本号和构建日期
  Future<Map<String, String>> getVersionInfo() async {
    final version = await getAppVersion();
    final buildDate = await getBuildDate();

    return {
      'version': version,
      'buildDate': buildDate,
    };
  }
}
