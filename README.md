![LumenFlow](./README/img/cover.png)

> A local-first, cross-platform AI chat client built with Flutter. 13 AI platforms, streaming chat, tool calling, MCP, long-conversation memory, role presets, syntax-highlighted Markdown with math, SQLite storage, and native CJK/PDF support.

[English](./README.md) | [中文版本](./README/README.zh_CN.md)

## Overview

LumenFlow (Chinese: 流光) is a Flutter-based AI chat application for Android, iOS, Windows, Linux, and macOS. It combines multi-platform model access, a tool-calling agent runtime, local SQLite storage, and a Cupertino-style interface.

- **License**: MIT (bundled Noto Sans SC fonts are OFL-1.1)
- **UI stack**: Flutter 3.47.8 / Dart 3.13.7, `material_ui`, `cupertino_ui`
- **Android baseline**: compileSdk 37.2, targetSdk 37, minSdk 29 (Android 10+)

## Features

### AI and Providers

- **13 platform types**: OpenAI, Claude, Google Gemini, DeepSeek, Kimi, MiniMax, Zhipu AI, SiliconFlow, Xiaomi MiMo, Grok, OpenRouter, LM Studio, and Other (OpenAI-compatible).
- **Multi-platform management**: independent endpoint, API key, model list, default model, and enabled state for each platform.
- **Model refresh**: fetch available models from supported provider APIs and select a default.
- **Streaming responses**: incremental answer and reasoning output.
- **Thinking mode**: expose reasoning summaries where the provider supports them.
- **Reply language**: follow the UI, follow the user, or pin a supported language. Character cards can override this setting.
- **Claude prompt caching**: stable system prompts are sent as content blocks with `cache_control: ephemeral`.
- **Auto title generation**: title new conversations from recent messages.
- **Retry and cancellation**: exponential backoff for transient HTTP failures and cancellation tokens for streaming/tool loops.

### Tool Calling and MCP

- **Built-in tools**: current time, date math, Chinese lunar calendar conversion, calculator, text comparison, text statistics, and unit conversion.
- **MCP tools**: connect Streamable HTTP MCP servers, discover their tools, and expose them to the model.
- **Unified tool loop**: `AgentRunner` alternates model turns and tool executions with a bounded iteration budget.
- **Attachment-aware tool mode**: text attachments are listed in a compact manifest with request-scoped ids, and `builtin__read_attachment` reads their content on demand with paging. Tool-enabled chats no longer fall back to a text-only provider request when text files are attached.
- **Parallel tool calls**: multiple function calls in one model turn are executed and returned together.
- **Protocol-aware adapters**:
  - Chat Completions: DeepSeek, Kimi, MiniMax, Zhipu, SiliconFlow, Xiaomi MiMo, Other
  - Responses API: OpenAI, Grok, OpenRouter, LM Studio
  - Claude Messages: Claude
  - Gemini Interactions: Gemini
- **Error-aware tool results**: failed tools are reported back to the model with `is_error` where supported.

### Memory and Long Conversations

- **Rolling memory**: conversations that exceed the raw history window are compressed into a story summary, current relationship/emotional state, and a ledger of agreements, facts, and decisions.
- **Hard memory**: agreements, rules, and decisions keep their original wording; superseded entries are retained but not injected. Rejected proposals and their reasons are remembered separately to avoid re-proposing them.
- **Automatic maintenance**: memory is updated in the background after a reply. Before sending, the app briefly waits if older messages are about to leave the window.
- **Active notes**: the conversation model can call `remember_note` to record a new agreement, fact, emotional turn, or rejected proposal immediately; the next maintenance pass merges the note into the ledger instead of waiting for the background window.
- **On-demand recall**: once older messages fall outside the raw window, the model can call `recall` with short keywords to search old messages and the full memory ledger, including superseded and rejected entries. The tool is only exposed when there is older content to search.
- **Automatic invalidation**: editing, regenerating, or deleting covered messages invalidates the memory and triggers a rebuild.
- **Read-only viewer**: chat ⋯ menu → **View Memory** shows the stored summary, emotional state, agreements, superseded entries, rejected proposals, and notes waiting to be merged. It does not modify anything.
- **Roleplay memory page**: conversations using a role card get a dedicated view with the character profile, mood, relationship stage, scene, story time, intimacy change, newly learned memories, and unresolved threads, so the story state stays easy to check.
- **Travels with the conversation**: JSON, LumenFlow archive, and ZIP exports include memory and pending active notes; import remaps message IDs and restores them.

### Data and Export

- **SQLite storage** with foreign keys, indexes, transactions, and automatic migration from legacy SharedPreferences.
- **Conversation management**: history, message search, edit, regenerate, resubmit, delete, and per-conversation settings.
- **Attachments**: images, video, audio, PDF, and text extraction.
- **Export formats**: TXT, JSON, PDF, and LumenFlow archive. JSON, LumenFlow, and ZIP exports include rolling memory and pending active notes, and can optionally embed the active user role card.
- **Conversation import**: LumenFlow archives (including ZIP) and raw conversation JSON; missing user presets can be recreated from the embedded snapshot after confirmation. Imported memory is restored with remapped message IDs.
  - [LumenFlow format specification](./LumenFlowFormatSpecification.md)
- **PDF export**: CJK-safe PDFs using embedded Noto Sans SC; fonts are subset per document.
- **Settings backup**: export/import JSON settings and restore defaults.

### Experience

- **Cupertino-style UI** with light/dark/system themes.
- **User profiles** with avatar, name, gender, and birthday.
- **Prompt presets and role-play**: localized built-in cards plus user-imported XML/TXT presets, editable metadata, language/tag filters, token estimates, duplicate detection, and conversation snapshots.
- **Character card generator**: bundled web generator served locally by the app.
- **Markdown extras**: fenced code with Night Owl syntax highlighting, copy/download actions, inline-code styling, and inline/block math rendering.
- **Adaptive layout**: two-column desktop workspace that falls back to a single column when the window is narrow.
- **Local notifications** and live-update support.
- **Local-first**: conversations and credentials are stored on the device.

## AI Platforms

| Platform | API family | Default endpoint | Default model | Tool protocol |
| --- | --- | --- | --- | --- |
| OpenAI | Responses | `https://api.openai.com/v1` | `gpt-6.1-sol` | Responses |
| Claude | Messages | `https://api.anthropic.com/v1` | `claude-opus-5-5` | Messages |
| Google Gemini | Interactions | `https://generativelanguage.googleapis.com/v1beta` | `gemini-3.8-flash` | Interactions |
| DeepSeek | Chat Completions | `https://api.deepseek.com` | `deepseek-flash` | Chat Completions |
| Kimi | Chat Completions | `https://api.moonshot.cn/v1` | `kimi-k3.1-pro` | Chat Completions |
| MiniMax | Chat Completions | `https://api.minimax.cn/v1` | `MiniMax-M3.1-Flash` | Chat Completions |
| Zhipu AI | Chat Completions | `https://open.bigmodel.cn/api/paas/v4` | `glm-5.3` | Chat Completions |
| SiliconFlow | Chat Completions | `https://api.siliconflow.cn/v1` | model list / user-selected | Chat Completions |
| Xiaomi MiMo | Chat Completions | `https://api.xiaomimimo.com/v1` | `mimo-v2.6-pro` | Chat Completions |
| Grok | Responses | `https://api.x.ai/v1` | `grok-4.7` | Responses |
| OpenRouter | Responses | `https://openrouter.ai/api/v1` | model list / user-selected | Responses |
| LM Studio | Responses | `http://YOUR_LM-STUDIO_ADDRESS:PORT/v1` | model list / user-selected | Responses |
| Other | Chat Completions | `https://YOUR_LLM_ADDRESS/v1` | model list / user-selected | Chat Completions |

> Endpoints and model IDs are defaults only. Providers change their APIs and model catalogs frequently; use the model refresh action or edit the platform configuration when needed.

### Other Defaults

- **Temperature**: `0.7`
- **Max tokens**: `8192` (Gemini requests are capped at the synchronous 65,536-token limit)
- **History context**: 30 rounds (up to 60 messages) by default
- **Memory compression**: enabled by default; requires history to be enabled
- **Default platform**: OpenAI

## Project Structure

```text
lib/
├── main.dart                         # Application entry point
├── ai/
│   ├── agent/
│   │   └── agent_runner.dart         # Model ↔ tool execution loop
│   ├── contracts/                    # Provider-neutral request/message/tool/event types
│   ├── mcp/                          # MCP client, models, and tool manager
│   ├── providers/
│   │   ├── chat_completions_profile.dart
│   │   ├── chat_completions_tool_provider.dart
│   │   ├── responses_tool_provider.dart
│   │   ├── claude_tool_provider.dart
│   │   └── gemini_tool_provider.dart
│   ├── tools/                        # Built-in time, calculator, text, memory-note, and recall tools
│   └── transport/
│       └── sse_decoder.dart          # Incremental SSE parser
├── controllers/
│   ├── chat_screen_controller.dart   # Interface between desktop shell and embedded chat
│   └── chat_send_controller.dart     # One streaming send lifecycle
├── l10n/                             # ARB files and generated localizations
├── models/                           # Conversation, message, attachment, memory, memory-note, platform, profile, preset models
├── providers/                        # Per-platform chat/streaming providers
├── screens/                          # Chat, conversations, settings, tools, profiles, preset management, memory viewer
├── services/
│   ├── ai_service.dart               # Provider selection and standard chat path
│   ├── tool_chat_service.dart        # Tool-capable provider turn
│   ├── conversation_database.dart    # SQLite and migration
│   ├── conversation_service.dart     # Conversation CRUD, export/import, snapshots
│   ├── memory_service.dart           # Rolling memory coverage, updates, and injection
│   ├── memory_recall.dart            # Local search over old messages and memory ledger
│   ├── memory_policy.dart            # Window/coverage/chunk policy
│   ├── memory_prompt.dart            # <memory> block and update prompts
│   ├── memory_update.dart            # Model output parsing and ledger merge
│   ├── memory_transfer.dart          # Import-time message ID/fingerprint remap
│   ├── conversation_memory_store.dart # SQLite-backed memory store
│   ├── system_prompt_builder.dart    # Base/custom/preset/memory composition
│   ├── prompt_service.dart           # Preset loading, schema migration, card validation
│   ├── preset_repository.dart        # Shared preset state between chat and settings
│   ├── settings_service.dart         # Settings and active platform snapshot
│   └── ...                           # Files, notifications, live updates, HTTP server
├── utils/
│   ├── app_theme.dart                # Cupertino/Material theme and font setup
│   ├── code_highlight_theme.dart     # Night Owl syntax highlighting themes
│   ├── markdown_math.dart            # Inline/block math preprocessing and builders
│   ├── memory_fingerprint.dart       # Covered-message content fingerprint
│   ├── preset_*.dart                 # Preset filtering, icons, tags, token estimation
│   └── path_utils.dart               # Cross-platform data paths
└── widgets/                          # Chat input, message bubble, preset editors, avatars, settings tiles
```

## Key Dependencies

| Package | Purpose |
| --- | --- |
| `material_ui` / `cupertino_ui` | Standalone Material and Cupertino design systems |
| `http` | Provider API and MCP HTTP transport |
| `sqlite3` | Conversation, message, attachment, memory, and settings storage |
| `shared_preferences` | Lightweight settings and legacy migration |
| `file_picker` / `image_picker` | File and image selection |
| `pdf` / `archive` | PDF generation and LumenFlow archive export |
| `flutter_markdown_plus` | Markdown rendering |
| `flutter_highlight` | Fenced-code syntax highlighting |
| `flutter_math_fork` | Inline and block math typesetting |
| `crypto` / `xml` | Preset content hashing, memory fingerprints, and XML card validation |
| `flutter_svg` | Platform icons and vector UI assets |
| `flutter_local_notifications` | Local notifications |
| `window_manager` | Desktop window configuration |
| `flutter_localizations` / `intl` | ARB-based localization |

## Architecture

LumenFlow uses a layered, local-first architecture:

```text
UI (screens/widgets)
        │
        ├── ChatSendController ──► AIService ──► lib/providers/* ──► HTTP
        │
        └── ToolChatService ──► AgentRunner ──► protocol tool provider
                                      │                │
                                      └── AIToolExecutor (built-in + MCP)
```

- **UI layer**: Cupertino-style screens and reusable widgets.
- **Application layer**: `AIService` selects a provider from the active platform; `ChatSendController` owns a single send/stream lifecycle.
- **Tool layer**: `ToolChatService` and `AgentRunner` run the model/tool loop. `CompositeToolExecutor` merges built-in tools and enabled MCP tools.
- **Protocol layer**: each provider family has a dedicated streaming/tool adapter with its own request and event mapping.
- **Data layer**: SQLite for conversations/messages/attachments/memory; `SettingsService` for configuration and active-platform resolution.
- **Memory layer**: `MemoryService` validates coverage/fingerprints, rolls old messages into `ConversationMemory`, merges active `remember_note` notes, and appends a `<memory>` block to the end of the system prompt. `MemoryRecallService` provides local, on-demand search over older messages and the full ledger. The ledger lives in SQLite and travels with conversation exports.
- **Preset layer**: `PromptService` loads localized built-in cards and schema-v2 user presets; `PresetRepository` shares one loading state between chat and settings.
- **Localization layer**: generated `AppLocalizations` from ARB files.

### Provider Protocol Adapters

- **Chat Completions**: OpenAI-compatible `chat/completions` streaming plus `tool_calls` / `tool` messages.
- **Responses API**: typed output items, `function_call` / `function_call_output`, item IDs, and completion deduplication.
- **Claude Messages**: `tool_use` / `tool_result`, content-block replay for thinking/signatures, and streaming input JSON deltas.
- **Gemini Interactions**: `/v1beta/interactions`, step events, thought summaries, function calls, and stateful continuation via `previous_interaction_id` + `function_result`.

## Configuration

1. Open **Settings → Platform & Models**.
2. Add a platform or edit an existing one.
3. Enter the endpoint and API key.
4. Refresh the model list or enter a model ID manually.
5. Select the default model.
6. Save, then tap the platform card to make it active.

Each platform keeps its own endpoint, credentials, model list, and parameters. The API settings screen remains available for the single-platform configuration flow.

### Tool Management

Open **Settings → Tool Management** to:

- Enable or disable built-in tools.
- Add MCP servers with a Streamable HTTP JSON-RPC endpoint and optional custom headers.
- Review which platforms support tool calling.
- Memory Tools (`remember_note` and `recall`) are shown at the top as automatic, read-only tools. They have no separate switch and follow the Memory Compression setting.

MCP tools are exposed with a server-specific prefix so tools from different servers do not collide.

### Memory Compression

Open **Settings → History Conversation**:

- **Enable History** must be on for memory to work.
- **Memory Compression** is on by default. Long conversations are summarized into story/emotional state, agreements/facts, and rejected proposals.
- The conversation model can call `remember_note` to record durable agreements, facts, emotional turns, or rejected proposals immediately; the next maintenance pass merges them into the ledger.
- Once older messages fall outside the raw window, the model can call `recall` with short keywords to search old messages and the full ledger.
- In a chat, open the ⋯ menu → **View Memory** to inspect the current memory. The view is read-only.

Memory is stored only on the device and is included in conversation JSON/LumenFlow/ZIP exports.

## Prompt Presets

Role-play presets pair a small metadata record with an optional character-card body.

### [Built-in presets](./README/presets.md)

- `assets/prompt/presets-<locale>.json` contains metadata; `prompt_file` points to XML cards under `assets/prompt/characters/<locale>/`.
- Locale fallback is `lzh → zh → en`; other locales fall back to `en → zh`. Missing cards are shown as unavailable instead of disappearing silently.
- Built-in metadata is available in Chinese, English, Japanese, Korean, and Spanish.

### User presets

- Import XML or TXT cards from **Settings → Preset Management**. Files are limited to 200 KB and validated for UTF-8, XML structure/root, and an optional `<role_name>`.
- Editable metadata covers name, description, author, version, icon, language, and tags. The import dialog shows a token estimate and warns above 4,000/8,000 tokens.
- Duplicate detection uses a SHA-256 hash of normalized card content; importing a duplicate requires confirmation.
- Presets can be duplicated, exported, deleted, and filtered by language or tag.
- User data lives in `user_prompts/`: `user_presets.json` (schema v2) plus card files. Legacy v1 files are backed up and migrated automatically.
- Schema v2 separates inline `system_prompt` from `prompt_file`, persists language/tags/timestamps/content hash, isolates malformed entries, and surfaces load problems in the preset manager.

### Prompt assembly

- The final system prompt is composed of localized base rules (including the reply-language rule) → custom prompt → selected preset → memory block.
- Presets support `${userProfile.username}`, `${userProfile.gender}`, and `${userProfile.birthday}` substitution.
- The AI reply language can follow the UI, follow the user, or be pinned; a character card's own language and tone take priority.

The character-card generator opens a local web page served by the app (`HttpServerService`, loopback port 5050).

## Data Storage

SQLite database location:

- **Android**: application documents directory (`conversations.db`).
- **Windows/Linux**: `~/.lumenflow/conversations.db` (`%USERPROFILE%\.lumenflow\conversations.db` on Windows).
- **macOS**: inside the App Sandbox container at `~/Library/Containers/me.huanmeng.lumenFlow/Data/.lumenflow/conversations.db`.
- **iOS**: `Library/Application Support/conversations.db` inside the app data container.

Tables: `conversations`, `messages`, `attachments`, `conversation_memory`, `conversation_memory_notes`, and application metadata/settings.

User presets live next to the database in `user_prompts/`:

- `user_presets.json` — schema-v2 metadata.
- `<preset-id>.xml` / `.txt` — character-card bodies.

All conversation data, API keys, and profiles stay on the device. Use the settings export feature if you want a backup.

## Fonts and Localization

- UI and PDF export use bundled **Noto Sans SC** Regular/Bold.
- `CupertinoSystemText` / `CupertinoSystemDisplay` aliases are registered so Cupertino sheets/dialogs also use the bundled font.
- Japanese and Korean UI fall back to system fonts to preserve locale-specific Han glyphs and Hangul coverage.
- UI locales: English (`en`), Simplified Chinese (`zh`), Japanese (`ja`), Korean (`ko`), Spanish (`es`), and Literary Chinese (`lzh`).
- Noto Sans SC is licensed under the SIL Open Font License 1.1; see [assets/fonts/OFL.txt](./assets/fonts/OFL.txt).

## Building

### Requirements

- Flutter 3.47.8+ / Dart 3.13.7+
- Android: Android SDK 37 (compileSdk 37.2), JDK 17, Gradle 9.3.1, AGP 9.1.0, Kotlin 2.4.0
- Windows: Visual Studio 2022 with Desktop development with C++
- Linux: GTK 3, clang, cmake, ninja, pkg-config

Linux / macOS:  
```bash
flutter pub get

sudo chmod +x ./build.sh
```

Windows:  
```bash
flutter pub get

./build.ps1
```

Release Android signing is read from `android/key.properties`.

### macOS and iOS signing

This repository does not include any distribution certificates. macOS and iOS artifacts are signed as described below.

**macOS**

- `flutter build macos --release` produces an ad-hoc signed `.app` that runs on the build machine.
- `./build.sh` packages the app into `app-universal-release.dmg` and writes a `app-universal-release.dmg.sha1` checksum.
- The DMG is **not notarized**. On other Macs, Gatekeeper may block the first launch. Remove the quarantine flag with:

  ```bash
  xattr -cr /Applications/LumenFlow.app
  ```

  or open it from System Settings → Privacy & Security → Open Anyway.

**iOS**

- Simulator builds run without signing.
- Device builds (`flutter build ios` / `flutter build ipa`) require a signing identity and provisioning profile. Configure an Apple Developer Team in Xcode before using the `iOS (Signed .ipa)` option in `build.sh`.
- `flutter build ios --no-codesign` (the `iOS (Unsigned .ipa)` option) produces `app-arm64-release.ipa`, which **cannot be installed on stock devices**. It is intended for TrollStore, jailbroken devices with AppSync Unified, or re-signing with tools such as Sideloadly or AltStore.
- Installing on a regular device requires either a free Apple ID personal team (expires after 7 days) or a paid Apple Developer account.
- App Store / TestFlight distribution requires a paid Apple Developer account, a configured signing team, and `flutter build ipa` (or Xcode Organizer).

### Notes

- The bundled CJK fonts add roughly 21 MB of source assets (compressed in the APK).
- The Android module is built with compileSdk 37 / targetSdk 37; `minSdk` is 29.

## Error Handling

- Network failures, timeouts, TLS/socket errors, and HTTP 429/5xx are retried with exponential backoff where safe.
- Tool-call failures are returned to the model as tool results instead of aborting the whole turn when possible.
- Provider errors are mapped to localized messages for supported locales.
- Preset load problems (corrupt JSON, invalid entries, missing or unreadable cards) are collected and shown in the preset manager instead of aborting startup.
- Cancellation is propagated to streaming reads and tool execution.

## License

The application source is licensed under the MIT License. See [LICENSE](./LICENSE).

Bundled Noto Sans SC font files are licensed under the SIL Open Font License 1.1; see [assets/fonts/OFL.txt](./assets/fonts/OFL.txt). The OFL applies to the font files, not to the rest of the application.

## Contributing

Issues and pull requests are welcome. Please keep changes focused, run `flutter analyze` and `flutter test`, and describe any provider or protocol changes with links to the relevant API documentation.

## Acknowledgments

- [Flutter](https://flutter.dev/) and the `material_ui` / `cupertino_ui` packages
- AI providers: OpenAI, Anthropic, Google Gemini, DeepSeek, Kimi, MiniMax, Zhipu AI, SiliconFlow, Xiaomi MiMo, xAI, OpenRouter, LM Studio
- [Noto Sans SC](https://fonts.google.com/noto/specimen/Noto+Sans+SC) (OFL 1.1)
- [Cupertino Icons](https://pub.dev/packages/cupertino_icons)
- [MCP](https://modelcontextprotocol.io/) for the tool integration protocol

## Sponsor

![Sponsor Code](./assets/collection_code.png)

If you find this app helpful, please scan the code to support development.
