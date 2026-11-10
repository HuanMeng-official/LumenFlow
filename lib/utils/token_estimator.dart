/// 粗略的 token 估算。CJK 字符按约 1 token/字，其他文本按约 4 字符/token。
///
/// 只用于向用户提示成本量级，不宣称精确，也不依赖具体服务商的分词器。
class TokenEstimator {
  const TokenEstimator._();

  static int estimate(String text) {
    if (text.isEmpty) return 0;

    var cjkCount = 0;
    var otherCount = 0;
    for (final rune in text.runes) {
      if (_isCjk(rune)) {
        cjkCount++;
      } else {
        otherCount++;
      }
    }
    return cjkCount + (otherCount / 4).ceil();
  }

  static bool _isCjk(int rune) {
    return (rune >= 0x3000 && rune <= 0x303F) || // CJK punctuation
        (rune >= 0x3040 && rune <= 0x30FF) || // Hiragana / Katakana
        (rune >= 0x3400 && rune <= 0x4DBF) || // CJK Extension A
        (rune >= 0x4E00 && rune <= 0x9FFF) || // CJK Unified Ideographs
        (rune >= 0xAC00 && rune <= 0xD7AF) || // Hangul
        (rune >= 0xF900 && rune <= 0xFAFF); // CJK Compatibility Ideographs
  }
}
