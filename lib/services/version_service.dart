import 'dart:convert';
import 'package:flutter/services.dart' show rootBundle;

/// 版本信息服务，用于获取应用版本和构建信息
class VersionService {
  static const String _versionFallback = '1.0.5';
  static final DateTime _buildDate = DateTime.now();

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
  String getBuildDate() {
    return '${_buildDate.year}-${_buildDate.month.toString().padLeft(2, '0')}-${_buildDate.day.toString().padLeft(2, '0')}';
  }

  /// 获取完整的版本信息
  /// 包含版本号和构建日期
  Future<Map<String, String>> getVersionInfo() async {
    final version = await getAppVersion();
    final buildDate = getBuildDate();

    return {
      'version': version,
      'buildDate': buildDate,
    };
  }
}