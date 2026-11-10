/// 解析用户输入的标签列表。
///
/// 中英文逗号、顿号、分号和换行都视为分隔符，避免用户反复尝试
/// 半角 `,` 还是全角 `，`。标签内部的空格会保留，仅去掉首尾空白。
List<String> parsePresetTags(String input) {
  return input
      .split(RegExp(r'[,，、;；\n]'))
      .map((tag) => tag.trim())
      .where((tag) => tag.isNotEmpty)
      .toList(growable: false);
}
