import 'dart:async';
import 'dart:convert';
import 'dart:io';

import 'package:flutter/foundation.dart';
import 'package:http/http.dart' as http;

import '../l10n/app_localizations.dart';
import 'ai_provider.dart';

/// HTTP Provider 共享基类
///
/// 收敛各 AI Provider 之间逐字节相同的 HTTP 样板：
/// 超时配置、重试配置、错误解析、指数退避重试执行器。
///
/// 平台特有的部分（endpoint 路径、请求体构造、SSE 事件映射、响应解析）
/// 仍由各子类自行实现。
///
/// 注意：超时参数以实例 getter 形式提供，而非 static const。
/// Dart 的静态成员不被继承，子类无法无前缀引用父类的 static const。
abstract class HttpProviderBase extends AIProvider {
  /// 连接超时
  Duration get connectionTimeout => const Duration(seconds: 30);

  /// 读取超时
  Duration get readTimeout => const Duration(seconds: 60);

  /// 流式响应超时
  Duration get streamingTimeout => const Duration(minutes: 5);

  /// 最大重试次数
  static const int _maxRetries = 3;

  /// 重试基础延迟（毫秒）
  static const int _retryBaseDelayMs = 1000;

  /// 重试最大延迟（毫秒）
  static const int _retryMaxDelayMs = 10000;

  /// 创建HTTP客户端
  @protected
  http.Client createHttpClient() {
    return http.Client();
  }

  /// 解析错误响应
  ///
  /// 对空响应体与无法解析为 JSON 的响应体（网关 502 页面、限流页面等）
  /// 做了保护，避免向上抛出 FormatException 而掩盖真实的 HTTP 错误。
  @protected
  Exception parseError(
      String responseBody, int statusCode, AppLocalizations l10n) {
    if (responseBody.trim().isEmpty) {
      return Exception(l10n.providerInvalidResponseFormatWithCode(statusCode));
    }

    try {
      final errorData = jsonDecode(responseBody);
      if (errorData is! Map<String, dynamic>) {
        return Exception(l10n.providerInvalidResponseFormatWithCode(statusCode));
      }

      final errorMessage = errorData['error']?['message']?.toString() ??
          errorData['message']?.toString() ??
          errorData['error']?.toString() ??
          l10n.providerUnknownError;
      return Exception(l10n.providerApiError(errorMessage, statusCode));
    } catch (e) {
      return Exception(
          '${l10n.providerApiError(responseBody, statusCode)}\n${l10n.providerInvalidResponseFormat}: $e');
    }
  }

  /// 判断错误是否可重试
  bool _isRetryableError(dynamic error, int? statusCode) {
    if (error is SocketException ||
        error is TimeoutException ||
        error is TlsException ||
        error is HttpException ||
        error.toString().contains('Connection') ||
        error.toString().contains('timeout') ||
        error.toString().contains('socket') ||
        error.toString().contains('handshake')) {
      return true;
    }

    if (statusCode != null && statusCode >= 500 && statusCode < 600) {
      return true;
    }

    if (statusCode == 429) {
      return true;
    }

    return false;
  }

  /// 计算重试延迟时间（指数退避）
  int _calculateRetryDelay(int retryCount) {
    final delay = _retryBaseDelayMs * (1 << retryCount);
    return delay > _retryMaxDelayMs ? _retryMaxDelayMs : delay;
  }

  /// 带重试的执行函数
  @protected
  Future<T> executeWithRetry<T>(
    Future<T> Function() execute, {
    void Function(dynamic error, int retryCount, int delayMs)? onRetry,
    required AppLocalizations l10n,
  }) async {
    int attempt = 0;
    dynamic lastError;
    int? lastStatusCode;

    while (attempt <= _maxRetries) {
      try {
        return await execute();
      } catch (error) {
        lastError = error;

        if (error is http.Response) {
          lastStatusCode = error.statusCode;
        } else if (error.toString().contains('statusCode')) {
          final match =
              RegExp(r'statusCode[:\s]*(\d+)').firstMatch(error.toString());
          if (match != null) {
            lastStatusCode = int.tryParse(match.group(1)!);
          }
        }

        if (attempt < _maxRetries &&
            _isRetryableError(error, lastStatusCode)) {
          final delayMs = _calculateRetryDelay(attempt);
          if (onRetry != null) {
            onRetry(error, attempt + 1, delayMs);
          }
          await Future.delayed(Duration(milliseconds: delayMs));
          attempt++;
          continue;
        }

        rethrow;
      }
    }

    throw lastError ?? Exception(l10n.providerUnknownError);
  }
}
