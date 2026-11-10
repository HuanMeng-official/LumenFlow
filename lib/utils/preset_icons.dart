import 'package:cupertino_ui/cupertino_ui.dart';

/// 角色预设可选的图标名（与 JSON 中持久化的字符串一致）。
const List<String> presetIconNames = [
  'person.fill',
  'person.crop.circle',
  'sparkles',
  'wand.and.stars',
  'heart.fill',
  'flame.fill',
  'moon.stars',
  'sun.max',
  'star.fill',
  'bolt.fill',
  'globe',
  'pencil',
];

/// 根据持久化的图标名返回 Cupertino 图标；未知名称回退到人物图标。
IconData presetIconForName(String name) {
  return switch (name) {
    'person.crop.circle' => CupertinoIcons.person_crop_circle,
    'sparkles' => CupertinoIcons.sparkles,
    'wand.and.stars' => CupertinoIcons.wand_stars,
    'heart.fill' => CupertinoIcons.heart_fill,
    'flame.fill' => CupertinoIcons.flame_fill,
    'moon.stars' => CupertinoIcons.moon_stars,
    'sun.max' => CupertinoIcons.sun_max,
    'star.fill' => CupertinoIcons.star_fill,
    'bolt.fill' => CupertinoIcons.bolt_fill,
    'globe' => CupertinoIcons.globe,
    'pencil' => CupertinoIcons.pencil,
    _ => CupertinoIcons.person_fill,
  };
}
