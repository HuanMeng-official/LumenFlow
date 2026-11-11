import 'package:flutter/material.dart';
import 'package:flutter_highlight/themes/night-owl.dart';

/// 代码块语法高亮主题。
///
/// 暗色使用 Night Owl，亮色使用同风格的 Night Owl Light，
/// 两者都把背景设为透明，由代码块容器统一提供背景色。
Map<String, TextStyle> codeHighlightTheme(Brightness brightness) {
  final theme = Map<String, TextStyle>.from(
    brightness == Brightness.dark ? nightOwlTheme : nightOwlLightTheme,
  );
  theme['root'] = (theme['root'] ?? const TextStyle()).copyWith(
    backgroundColor: Colors.transparent,
  );
  // 代码块统一不使用斜体，保留配色即可。
  return theme.map(
    (key, style) => MapEntry(
      key,
      style.fontStyle == FontStyle.italic
          ? style.copyWith(fontStyle: FontStyle.normal)
          : style,
    ),
  );
}

/// Night Owl Light 的 highlight.js 配色。
///
/// 基于官方 Light Owl 主题，并将注释色稍微加深，保证在浅灰背景上可读。
const nightOwlLightTheme = <String, TextStyle>{
  'root': TextStyle(color: Color(0xFF403F53)),
  'keyword': TextStyle(color: Color(0xFF994CC3), fontStyle: FontStyle.italic),
  'built_in': TextStyle(color: Color(0xFF0C969B)),
  'type': TextStyle(color: Color(0xFF4876D6)),
  'literal': TextStyle(color: Color(0xFFBC5454)),
  'number': TextStyle(color: Color(0xFFAA0982)),
  'regexp': TextStyle(color: Color(0xFF5CA7E4)),
  'string': TextStyle(color: Color(0xFF4876D6)),
  'subst': TextStyle(color: Color(0xFFC96765)),
  'symbol': TextStyle(color: Color(0xFF4876D6)),
  'class': TextStyle(color: Color(0xFF111111)),
  'function': TextStyle(
    color: Color(0xFF4876D6),
    fontStyle: FontStyle.italic,
  ),
  'title': TextStyle(
    color: Color(0xFF4876D6),
    fontStyle: FontStyle.italic,
  ),
  'params': TextStyle(color: Color(0xFF0C969B)),
  'comment': TextStyle(
    color: Color(0xFF7A8499),
    fontStyle: FontStyle.italic,
  ),
  'doctag': TextStyle(color: Color(0xFF0C969B)),
  'meta': TextStyle(color: Color(0xFF4876D6)),
  'meta-keyword': TextStyle(color: Color(0xFF4876D6)),
  'meta-string': TextStyle(color: Color(0xFF4876D6)),
  'section': TextStyle(color: Color(0xFF994CC3)),
  'tag': TextStyle(color: Color(0xFF994CC3)),
  'name': TextStyle(color: Color(0xFF994CC3)),
  'builtin-name': TextStyle(color: Color(0xFF0C969B)),
  'attr': TextStyle(
    color: Color(0xFF4876D6),
    fontStyle: FontStyle.italic,
  ),
  'attribute': TextStyle(
    color: Color(0xFF4876D6),
    fontStyle: FontStyle.italic,
  ),
  'variable': TextStyle(color: Color(0xFF4876D6)),
  'bullet': TextStyle(color: Color(0xFF994CC3)),
  'code': TextStyle(color: Color(0xFF0C969B)),
  'emphasis': TextStyle(color: Color(0xFF994CC3), fontStyle: FontStyle.italic),
  'strong': TextStyle(color: Color(0xFF4876D6), fontWeight: FontWeight.bold),
  'formula': TextStyle(color: Color(0xFF994CC3)),
  'link': TextStyle(color: Color(0xFF994CC3)),
  'quote': TextStyle(
    color: Color(0xFF7A8499),
    fontStyle: FontStyle.italic,
  ),
  'selector-tag': TextStyle(color: Color(0xFF994CC3)),
  'selector-id': TextStyle(color: Color(0xFFAA0982)),
  'selector-class': TextStyle(color: Color(0xFF4876D6)),
  'selector-attr': TextStyle(color: Color(0xFF4876D6)),
  'selector-pseudo': TextStyle(color: Color(0xFF994CC3)),
  'template-tag': TextStyle(color: Color(0xFF994CC3)),
  'template-variable': TextStyle(color: Color(0xFF4876D6)),
  'addition': TextStyle(
    color: Color(0xFF4876D6),
    fontStyle: FontStyle.italic,
  ),
  'deletion': TextStyle(
    color: Color(0xFFD3423E),
    fontStyle: FontStyle.italic,
  ),
};
