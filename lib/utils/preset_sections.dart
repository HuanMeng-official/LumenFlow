import 'package:xml/xml.dart';

import '../l10n/app_localizations.dart';

/// 预设正文中的一个可展示段落。
class PresetSection {
  const PresetSection({this.tag, required this.text});

  /// XML 标签名；纯文本回退时为 null。
  final String? tag;

  final String text;
}

/// 把角色卡正文拆成按标签分组的只读段落。
///
/// `<meta>` / `<mate>` 保存的是角色名、身份和核心哲学，已在预设摘要中展示，
/// 这里不再重复。解析失败或非 `<system_instruction>` 内容按纯文本回退。
List<PresetSection> parsePresetSections(String content) {
  final trimmed = content.trim();
  if (trimmed.isEmpty) return const [];
  if (!trimmed.startsWith('<')) {
    return [PresetSection(text: trimmed)];
  }

  try {
    final document = XmlDocument.parse(trimmed);
    final root = document.rootElement;
    if (root.name.local != 'system_instruction') {
      return [PresetSection(text: trimmed)];
    }

    final sections = <PresetSection>[];
    for (final element in root.childElements) {
      final tag = element.name.local;
      if (tag == 'meta' || tag == 'mate') continue;
      final text = _dedent(element.innerText);
      if (text.isEmpty) continue;
      sections.add(PresetSection(tag: tag, text: text));
    }
    return sections;
  } catch (_) {
    return [PresetSection(text: trimmed)];
  }
}

/// 把 XML 标签换成与生成器一致的可读标题。
String? presetSectionLabel(String? tag, AppLocalizations l10n) {
  return switch (tag) {
    null => null,
    'worldview_background' => l10n.presetSectionWorldviewBackground,
    'appearance_traits' => l10n.presetSectionAppearance,
    'personality_logic' => l10n.presetSectionPersonality,
    'addressing_protocol' => l10n.presetSectionAddressing,
    'linguistic_style' => l10n.presetSectionLinguistic,
    'behavior_narrative_rules' => l10n.presetSectionBehavior,
    'interaction_strategy' => l10n.presetSectionInteraction,
    'internal_monologue' => l10n.presetSectionInternalMonologue,
    'emotional_depth' => l10n.presetSectionEmotionalDepth,
    'knowledge_filter' => l10n.presetSectionKnowledgeFilter,
    'negative_constraints' => l10n.presetSectionNegativeConstraints,
    'example_dialogue' => l10n.presetSectionExampleDialogue,
    'user_info' => l10n.presetSectionUserProfile,
    _ => tag.replaceAll('_', ' '),
  };
}

String _dedent(String text) {
  final lines = text
      .replaceAll('\r\n', '\n')
      .replaceAll('\r', '\n')
      .split('\n');
  while (lines.isNotEmpty && lines.first.trim().isEmpty) {
    lines.removeAt(0);
  }
  while (lines.isNotEmpty && lines.last.trim().isEmpty) {
    lines.removeLast();
  }
  if (lines.isEmpty) return '';

  var commonIndent = 1 << 30;
  for (final line in lines) {
    if (line.trim().isEmpty) continue;
    final indent = line.length - line.trimLeft().length;
    if (indent < commonIndent) commonIndent = indent;
  }
  if (commonIndent == 1 << 30) commonIndent = 0;

  return lines
      .map((line) {
        final rightTrimmed = line.replaceFirst(RegExp(r'[ \t]+$'), '');
        if (rightTrimmed.isEmpty) return '';
        if (rightTrimmed.length <= commonIndent) {
          return rightTrimmed.trimLeft();
        }
        return rightTrimmed.substring(commonIndent);
      })
      .join('\n')
      .trim();
}
