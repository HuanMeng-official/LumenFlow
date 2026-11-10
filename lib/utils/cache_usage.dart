/// 把不同服务商的 usage 字段归一化成一行调试日志。
///
/// 只用于 kDebugMode 下验证缓存是否命中，不参与业务逻辑。
String? describeCacheUsage(Object? usage) {
  if (usage is! Map) return null;

  final input = usage['input_tokens'] ?? usage['prompt_tokens'];
  final inputDetails = usage['input_tokens_details'];
  final promptDetails = usage['prompt_tokens_details'];
  final cacheRead =
      usage['cache_read_input_tokens'] ??
      usage['prompt_cache_hit_tokens'] ??
      (inputDetails is Map ? inputDetails['cached_tokens'] : null) ??
      (promptDetails is Map ? promptDetails['cached_tokens'] : null);
  final cacheWrite =
      usage['cache_creation_input_tokens'] ?? usage['prompt_cache_miss_tokens'];

  if (input == null && cacheRead == null && cacheWrite == null) {
    return null;
  }
  return 'input=$input cache_write=$cacheWrite cache_read=$cacheRead';
}
