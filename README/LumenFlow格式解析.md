# LumenFlow 格式说明

> 版本：**2.0**  
> 扩展名：`.lumenflow`  
> 容器：**ZIP**（`application/zip`）  
> 状态：v1 `.lumenflow` 不再支持。

## 1. 概述

`.lumenflow` 是一个 ZIP 容器，根目录必须有 `manifest.json`，并按类型携带一种或多种 payload。同一格式服务三类用途：

| `_type` | 用途 |
| --- | --- |
| `settings` | 应用设置备份 |
| `conversation` | 对话、记忆、便签、附件，可选内置角色卡 |
| `character_card` | 独立角色卡 |

读取方必须拒绝未知 `_format`、不支持的 `_version`、未知 `_type`、缺失文件、大小或 SHA-256 不匹配、危险路径，以及旧版 v1 JSON。

## 2. 容器结构

### 2.1 设置

```text
settings.lumenflow
├── manifest.json
└── settings/
    └── settings.json
```

### 2.2 对话

```text
conversation.lumenflow
├── manifest.json
├── conversation/
│   ├── conversation.json
│   └── attachments/
│       └── 1_note.txt
└── character/                    # includes_character = true 时存在
    ├── meta.json
    ├── character.xml
    ├── world_info.json           # 可选
    └── avatar.png                # 可选
```

### 2.3 独立角色卡

```text
character.lumenflow
├── manifest.json
└── character/
    ├── meta.json
    ├── character.xml
    ├── world_info.json           # 可选
    └── avatar.png                # 可选
```

## 3. manifest.json

```json
{
  "_format": "lumenflow",
  "_version": "2.0",
  "_type": "character_card",
  "_created": "2026-11-14T10:30:00.000Z",
  "_app_version": "3.1.0",
  "_min_reader_version": "2.0",
  "_title": "陆瑶",
  "_language": "zh",
  "_contains_secrets": false,
  "includes_character": true,
  "files": [
    {
      "path": "character/character.xml",
      "role": "character",
      "size": 12345,
      "sha256": "……64 位小写十六进制……"
    }
  ]
}
```

| 字段 | 类型 | 必需 | 说明 |
| --- | --- | --- | --- |
| `_format` | string | 是 | 固定为 `lumenflow` |
| `_version` | string | 是 | 容器版本，当前为 `2.0` |
| `_type` | string | 是 | `settings`、`conversation` 或 `character_card` |
| `_created` | string | 是 | UTC ISO 8601 创建时间 |
| `_app_version` | string | 是 | 导出方应用版本 |
| `_min_reader_version` | string | 是 | 最低读取版本，当前为 `2.0` |
| `_title` | string | 是 | 人类可读标题 |
| `_language` | string | 是 | 语言代码，或 `und` |
| `_contains_secrets` | boolean | 否 | payload 可能包含 API Key 时为 `true` |
| `includes_character` | boolean | 否 | 存在 `character/` 时为 `true` |
| `files` | array | 是 | payload 文件；**不包含 `manifest.json` 自身** |

每个 `files` 条目包含 `path`、`role`、`size`、`sha256`。读取方只暴露 manifest 列出的文件，ZIP 中多余条目忽略。列出的文件必须存在、大小一致、SHA-256 一致。

### 3.1 角色

| role | 常见路径 |
| --- | --- |
| `settings` | `settings/settings.json` |
| `conversation` | `conversation/conversation.json` |
| `attachment` | `conversation/attachments/…` |
| `meta` | `character/meta.json` |
| `character` | `character/character.xml` |
| `world_info` | `character/world_info.json` |
| `avatar` | `character/avatar.png` |

## 4. 安全与上限

- 拒绝空路径、绝对路径、盘符、反斜杠、`.`/`..` 段、空段、大小写冲突路径。
- 路径统一使用 `/`。
- 解压后总 payload 上限：**512 MB**。
- 单文件上限：**256 MB**。
- 条目数上限：**5000**。
- payload 路径不得为 `manifest.json`。
- 非 ZIP 的 v1 JSON 直接抛出 `FormatException('Legacy lumenflow v1 is not supported')`。
- 设置归档的 `_contains_secrets` 为 `true`，因为其中包含 API Key 与平台凭据。

## 5. payload 结构

### 5.1 settings/settings.json

应用设置键值对组成的扁平 JSON 对象，与 `SettingsService.exportSettingsToJson()` 的返回一致，包含平台配置。

### 5.2 conversation/conversation.json

原始对话文档，不再套一层 v1 包装：

```json
{
  "id": "conversation-id",
  "title": "对话标题",
  "createdAt": "2026-11-14T10:00:00.000Z",
  "updatedAt": "2026-11-14T10:30:00.000Z",
  "messages": [],
  "thinkingMode": false,
  "promptPresetEnabled": true,
  "promptPresetId": "luyao",
  "isPinned": false,
  "memory": {},
  "memory_notes": [],
  "prompt_preset_snapshot": {}
}
```

`memory`、`memory_notes`、`prompt_preset_snapshot` 可选。类型与版本由 manifest 承载，对话 JSON 不重复 `_format`、`_version`、`_type`。

附件位于 `conversation/attachments/<n>_<安全文件名>`，`n` 从 1 开始，按消息顺序编号。导入时按安全文件名配对，并重建本地路径。

### 5.3 character/character.xml

角色卡 XML，根元素为 `<system_instruction>`。v2 的角色 XML 不再包含 `<worldview_background>`；世界背景位于 `world_info.json`。导入旧 XML 时，如果发现该节且没有 world info，会一次性迁移：生成世界书文件并从存储的 XML 中删除该节。

### 5.4 character/world_info.json

```json
{
  "_format": "lumenflow_world_info",
  "_version": 1,
  "name": "浮生书店",
  "description": "陆瑶的旧书店、邻里与千年过往。",
  "background": "……世界背景全文……",
  "scan_depth": 4,
  "budget_tokens": 1000,
  "entries": [
    {
      "id": "fushang-bookshop",
      "title": "浮生书店",
      "category": "location",
      "tags": ["书店", "老宅"],
      "keys": ["浮生", "旧书店", "书店"],
      "secondary_keys": [],
      "match": "substring",
      "case_sensitive": false,
      "content": "……",
      "priority": 100,
      "enabled": true,
      "position": "system",
      "depth": 0
    }
  ]
}
```

限制与校验：

- `_format` 必须为 `lumenflow_world_info`；`_version` 必须为 `1`。
- 最多 **500** 条条目。
- 单条 `content` 最多 **4000** 字符。
- 每条最多 **20** 个主关键词、**20** 个次关键词。
- 正则关键词最多 **200** 字符；非法正则拒绝。
- 条目 ID 必须唯一。
- 每条至少一个主关键词。
- 未知 category 或 match 拒绝。

category：`character` / `location` / `item` / `rule` / `event` / `lore` / `other`。  
match：`substring` / `word` / `regex`。

### 5.5 character/meta.json

```json
{
  "_format": "lumenflow_character_meta",
  "_version": 1,
  "name": "陆瑶",
  "description": "……",
  "author": "……",
  "version": "v3",
  "language": "zh",
  "tags": ["狐妖", "现代都市", "同居"],
  "icon": "person.fill"
}
```

`name`、`description`、`author`、`version`、`language`、`tags`、`icon` 均可选。缺失或损坏时回退到 XML `<role_name>` 与导入对话框字段。

### 5.6 character/avatar.png

- 仅 PNG；校验文件签名。
- 存在 `avatar.png` 时优先于 `meta.icon`。
- 最长边缩到不超过 **1024**。
- 编码后超过 **2 MB** 时，依次降到 **768**、**512**。
- 仍然超过 2 MB 则拒绝。
- 头像损坏时忽略，角色卡仍可导入并使用备用图标。

## 6. 世界书激活

1. 调用方传入扫描文本。应用使用当前消息 + 最近 `scan_depth` 条消息。
2. `background` 永远注入，不占用条目预算。
3. 主关键词命中时条目可激活；若 `secondary_keys` 非空，还必须至少命中一个次关键词。
4. `substring` 做子串匹配；`word` 使用单词边界，CJK 回退子串；`regex` 使用正则。
5. 排序：priority 降序 → 命中关键词长度降序 → id。
6. 按该顺序放入能装进 `budget_tokens` 的条目；装不下的条目跳过，后续更小、优先级更低的条目仍可能被放入。
7. 注入格式：

```text
[世界书 · 浮生书店]
[世界背景]
……

[浮生书店]
……
```

8. system prompt 顺序：基础 → 自定义 → 角色预设 → note 指令 → recall 指令 → 世界书 → 记忆。

## 7. 生成器输出

内置生成器位于 `assets/gen/`，导出的角色卡 ZIP 先写 `manifest.json`，再用 Web Crypto 为每个 payload 计算 SHA-256。典型 manifest：

```json
{
  "_format": "lumenflow",
  "_version": "2.0",
  "_type": "character_card",
  "_created": "2026-11-14T10:30:00.000Z",
  "_app_version": "web-generator",
  "_min_reader_version": "2.0",
  "_title": "陆瑶",
  "_language": "zh",
  "_contains_secrets": false,
  "includes_character": true,
  "files": [
    { "path": "character/meta.json", "role": "meta", "size": 236, "sha256": "…" },
    { "path": "character/character.xml", "role": "character", "size": 535, "sha256": "…" },
    { "path": "character/world_info.json", "role": "world_info", "size": 578, "sha256": "…" },
    { "path": "character/avatar.png", "role": "avatar", "size": 29728, "sha256": "…" }
  ]
}
```

背景与条目都为空时不写 `character/world_info.json`；未选择头像时不写 `character/avatar.png`。

## 8. 兼容性

- 只支持 v2 容器。
- 裸 `.json` 对话导入仍保留，但不带附件与角色卡。
- 原生世界书格式**不兼容** SillyTavern。
