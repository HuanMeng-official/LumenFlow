/// 记忆覆盖策略的纯计算部分。
///
/// 下游 provider 只保留最近 `historyRounds * 2` 条原文消息。记忆必须覆盖
/// 所有即将滑出这个窗口的消息，否则上下文会出现空洞。
class MemoryPolicy {
  MemoryPolicy._();

  static const int rawWindowMultiplier = 2;
  static const int chunkSize = 20;
  static const int rebuildChunkSize = 60;
  static const int reserve = 20;

  /// 注入到 system prompt 的条数上限。
  static const int maxFacts = 30;
  static const int maxRejected = 30;

  static const int summaryMaxChars = 1200;
  static const int emotionalStateMaxChars = 300;
  static const int maxUpdateTokens = 2000;
  static const double updateTemperature = 0.2;

  static int rawWindow(int historyRounds) =>
      (historyRounds < 0 ? 0 : historyRounds) * rawWindowMultiplier;

  /// 必须由记忆接住的条数：所有比原文窗口更旧的消息。
  static int requiredCoverage({
    required int eligibleCount,
    required int historyRounds,
  }) {
    final required = eligibleCount - rawWindow(historyRounds);
    return required > 0 ? required : 0;
  }

  /// 后台更新希望达到的覆盖条数，额外留出 [reserve] 条缓冲，避免每轮都更新。
  static int targetCoverage({
    required int eligibleCount,
    required int historyRounds,
    int reserve = reserve,
  }) {
    final target = eligibleCount - rawWindow(historyRounds) + reserve;
    return target > 0 ? target : 0;
  }

  /// 只有确实存在窗口外消息、且攒够一个 chunk 时才值得后台更新。
  static bool shouldUpdateInBackground({
    required int coveredCount,
    required int requiredCoverage,
    int reserve = reserve,
    int chunkSize = chunkSize,
  }) {
    if (requiredCoverage <= 0) return false;
    final target = requiredCoverage + reserve;
    return target > coveredCount && target - coveredCount >= chunkSize;
  }
}
