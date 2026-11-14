# LumenFlow Format Specification

> Version: **2.0**  
> Extension: `.lumenflow`  
> Container: **ZIP** (`application/zip`)  
> Status: v1 `.lumenflow` files are not supported.

## 1. Overview

A `.lumenflow` file is a ZIP container with a `manifest.json` at its root and one or more typed payload files. A single format serves three uses:

| `_type` | Purpose |
| --- | --- |
| `settings` | Application settings backup |
| `conversation` | Conversation, memory, notes, attachments, optional character card |
| `character_card` | Standalone character card |

Readers must reject unknown `_format` values, unsupported `_version` values, unknown `_type` values, missing files, size mismatches, SHA-256 mismatches, unsafe paths, and legacy v1 JSON.

## 2. Container layout

### 2.1 Settings

```text
settings.lumenflow
├── manifest.json
└── settings/
    └── settings.json
```

### 2.2 Conversation

```text
conversation.lumenflow
├── manifest.json
├── conversation/
│   ├── conversation.json
│   └── attachments/
│       └── 1_note.txt
└── character/                    # present when includes_character = true
    ├── meta.json
    ├── character.xml
    ├── world_info.json           # optional
    └── avatar.png                # optional
```

### 2.3 Standalone character card

```text
character.lumenflow
├── manifest.json
└── character/
    ├── meta.json
    ├── character.xml
    ├── world_info.json           # optional
    └── avatar.png                # optional
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
  "_title": "LuYao",
  "_language": "zh",
  "_contains_secrets": false,
  "includes_character": true,
  "files": [
    {
      "path": "character/character.xml",
      "role": "character",
      "size": 12345,
      "sha256": "…64 lowercase hex characters…"
    }
  ]
}
```

| Field | Type | Required | Description |
| --- | --- | --- | --- |
| `_format` | string | yes | Fixed value `lumenflow` |
| `_version` | string | yes | Container version, currently `2.0` |
| `_type` | string | yes | `settings`, `conversation`, or `character_card` |
| `_created` | string | yes | UTC ISO 8601 creation timestamp |
| `_app_version` | string | yes | Exporter application version |
| `_min_reader_version` | string | yes | Minimum reader version, currently `2.0` |
| `_title` | string | yes | Human-readable title |
| `_language` | string | yes | BCP-47-style language code, or `und` |
| `_contains_secrets` | boolean | no | `true` when the payload can contain API keys |
| `includes_character` | boolean | no | `true` when `character/` is present |
| `files` | array | yes | Payload files; **does not include `manifest.json` itself** |

Each `files` entry has `path`, `role`, `size`, and `sha256`. The reader exposes only files listed in the manifest; extra ZIP entries are ignored. Every listed file must exist, match its recorded size, and match its SHA-256.

### 3.1 Roles

| Role | Typical path |
| --- | --- |
| `settings` | `settings/settings.json` |
| `conversation` | `conversation/conversation.json` |
| `attachment` | `conversation/attachments/…` |
| `meta` | `character/meta.json` |
| `character` | `character/character.xml` |
| `world_info` | `character/world_info.json` |
| `avatar` | `character/avatar.png` |

## 4. Security and limits

- Reject empty, absolute, drive-qualified, backslash-containing, `.`/`..` segment, empty-segment, and case-insensitively duplicated paths.
- Normalize paths with `/`.
- Maximum total uncompressed payload: **512 MB**.
- Maximum single file: **256 MB**.
- Maximum archive entries: **5000**.
- Reject `manifest.json` as a payload path.
- Reject non-ZIP v1 JSON with `FormatException('Legacy lumenflow v1 is not supported')`.
- Settings archives set `_contains_secrets: true` because they include API keys and platform credentials.

## 5. Payload schemas

### 5.1 settings/settings.json

A flat JSON object of the application's setting keys and values, including platform configuration. It is the same object returned by `SettingsService.exportSettingsToJson()`.

### 5.2 conversation/conversation.json

The raw conversation document, without an additional v1 wrapper:

```json
{
  "id": "conversation-id",
  "title": "Conversation title",
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

`memory`, `memory_notes`, and `prompt_preset_snapshot` are optional. The manifest carries the v2 type and version; the conversation JSON does not repeat `_format`, `_version`, or `_type`.

Attachments are stored under `conversation/attachments/<n>_<sanitized-name>`, with a 1-based numeric prefix in message order. Importers pair files by the sanitized name and rebuild local paths.

### 5.3 character/character.xml

The role card XML. Its root element is `<system_instruction>`. The `<worldview_background>` section is no longer part of v2 character XML; world background lives in `world_info.json`. Readers that encounter an old XML during import may migrate that section once, producing a world info file and removing the section from the stored XML.

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

Limits and validation:

- `_format` must be `lumenflow_world_info`; `_version` must be `1`.
- Up to **500** entries.
- Entry `content` up to **4000** characters.
- Up to **20** primary keys and **20** secondary keys per entry.
- Regex keys up to **200** characters; invalid regexes are rejected.
- Entry IDs must be unique.
- Every entry must have at least one primary key.
- Unknown categories or match modes are rejected.

Categories: `character`, `location`, `item`, `rule`, `event`, `lore`, `other`.  
Match modes: `substring`, `word`, `regex`.

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

`name`, `description`, `author`, `version`, `language`, `tags`, and `icon` are optional. Missing or malformed metadata falls back to the XML `<role_name>` and import-dialog fields.

### 5.6 character/avatar.png

- PNG only; the signature is validated.
- `avatar.png` takes precedence over `meta.icon` when rendering.
- The longest side is resized to at most **1024**.
- If the encoded PNG exceeds **2 MB**, it is downsampled to **768**, then **512**.
- If it is still over 2 MB, the avatar is rejected.
- A corrupt avatar is ignored; the character card remains importable with its fallback icon.

## 6. World info activation

1. The caller supplies scan text. The app uses the current message plus the most recent `scan_depth` messages.
2. `background` is always injected and is not counted against the entry budget.
3. Entries activate when a primary key matches. If `secondary_keys` is non-empty, at least one secondary key must also match.
4. `substring` matches substrings; `word` uses word boundaries and falls back to substring for CJK; `regex` uses a regular expression.
5. Ordering: priority descending, then matched key length descending, then id.
6. Entries are admitted in that order while they fit `budget_tokens`. An entry that does not fit is skipped; smaller lower-priority entries may still be admitted.
7. Injected block:

```text
[世界书 · 浮生书店]
[世界背景]
……

[浮生书店]
……
```

8. System prompt order: base → custom → preset → note instruction → recall instruction → world info → memory.

## 7. Generator output

The bundled generator at `assets/gen/` exports a character card ZIP. It writes `manifest.json` first and computes SHA-256 for every payload with Web Crypto. A typical manifest:

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

The generator omits `character/world_info.json` when both background and entries are empty, and omits `character/avatar.png` when no avatar is selected.

## 8. Compatibility

- v2 is the only supported container version.
- Standalone raw `.json` conversation import remains available and carries no attachments or character files.
- The native world info format is **not** SillyTavern-compatible.
