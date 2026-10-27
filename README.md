![LumenFlow](./README/img/cover.png)

> A local-first, cross-platform AI chat client built with Flutter. 13 AI platforms, streaming chat, tool calling, MCP, SQLite storage, and native CJK/PDF support.

[English](./README.md) | [中文版本](./README/README.zh_CN.md)

## Overview

LumenFlow (Chinese: 流光) is a Flutter-based AI chat application for Android, iOS, Windows, Linux, and macOS. It combines multi-platform model access, a tool-calling agent runtime, local SQLite storage, and a Cupertino-style interface.

- **Version**: 3.0.0+300
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
- **Auto title generation**: title new conversations from recent messages.
- **Retry and cancellation**: exponential backoff for transient HTTP failures and cancellation tokens for streaming/tool loops.

### Tool Calling and MCP

- **Built-in tools**: current time, calculator, text comparison, and text statistics.
- **MCP tools**: connect Streamable HTTP MCP servers, discover their tools, and expose them to the model.
- **Unified tool loop**: `AgentRunner` alternates model turns and tool executions with a bounded iteration budget.
- **Parallel tool calls**: multiple function calls in one model turn are executed and returned together.
- **Protocol-aware adapters**:
  - Chat Completions: DeepSeek, Kimi, MiniMax, Zhipu, SiliconFlow, Xiaomi MiMo, Other
  - Responses API: OpenAI, Grok, OpenRouter, LM Studio
  - Claude Messages: Claude
  - Gemini Interactions: Gemini
- **Error-aware tool results**: failed tools are reported back to the model with `is_error` where supported.

### Data and Export

- **SQLite storage** with foreign keys, indexes, transactions, and automatic migration from legacy SharedPreferences.
- **Conversation management**: history, search-friendly list, edit, regenerate, resubmit, delete, and per-conversation settings.
- **Attachments**: images, video, audio, PDF, and text extraction.
- **Export formats**: TXT, JSON, PDF, and LumenFlow archive.
  - [LumenFlow format specification](./LumenFlowFormatSpecification.md)
- **PDF export**: CJK-safe PDFs using embedded Noto Sans SC; fonts are subset per document.
- **Settings backup**: export/import JSON settings and restore defaults.

### Experience

- **Cupertino-style UI** with light/dark/system themes.
- **User profiles** with avatar, name, gender, and birthday.
- **Prompt presets and role-play**: multi-language XML character cards loaded from assets.
- **Character card generator**: bundled web generator served locally by the app.
- **Code blocks**: Markdown rendering with copy actions.
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
- **History context**: 30 messages by default
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
│   ├── tools/                        # Built-in time, calculator, and text tools
│   └── transport/
│       └── sse_decoder.dart          # Incremental SSE parser
├── controllers/
│   └── chat_send_controller.dart     # One streaming send lifecycle
├── l10n/                             # ARB files and generated localizations
├── models/                           # Conversation, message, attachment, platform, profile models
├── providers/                        # Per-platform chat/streaming providers
├── screens/                          # Chat, conversations, settings, tools, profiles, credits
├── services/
│   ├── ai_service.dart               # Provider selection and standard chat path
│   ├── tool_chat_service.dart        # Tool-capable provider turn
│   ├── conversation_database.dart    # SQLite and migration
│   ├── conversation_service.dart     # Conversation CRUD and export
│   ├── settings_service.dart         # Settings and active platform snapshot
│   └── ...                           # Files, prompts, notifications, live updates, HTTP server
├── utils/
│   ├── app_theme.dart                # Cupertino/Material theme and font setup
│   └── path_utils.dart               # Cross-platform data paths
└── widgets/                          # Chat input, message bubble, avatars, settings tiles
```

## Key Dependencies

| Package | Purpose |
| --- | --- |
| `material_ui` / `cupertino_ui` | Standalone Material and Cupertino design systems |
| `http` | Provider API and MCP HTTP transport |
| `sqlite3` | Conversation, message, attachment, and settings storage |
| `shared_preferences` | Lightweight settings and legacy migration |
| `file_picker` / `image_picker` | File and image selection |
| `pdf` / `archive` | PDF generation and LumenFlow archive export |
| `flutter_markdown_plus` | Markdown rendering |
| `flutter_svg` | Platform icons and vector UI assets |
| `flutter_local_notifications` | Local notifications |
| `window_manager` | Desktop window configuration |
| `auto_orientation_v2` | Mobile orientation control |
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
- **Data layer**: SQLite for conversations/messages/attachments; `SettingsService` for configuration and active-platform resolution.
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

- Enable or disable built-in tools (time, calculator, text tools).
- Add MCP servers with a Streamable HTTP JSON-RPC endpoint and optional custom headers.
- Review which platforms support tool calling.

MCP tools are exposed with a server-specific prefix so tools from different servers do not collide.

## Prompt Presets

The role-play system loads file-based prompt presets per locale:

- `assets/prompt/presets-*.json` contains preset metadata.
- `system_prompt` points to XML/TXT files under `assets/prompt/characters/<locale>/`.
- Supports `${userProfile.username}` substitution.
- Presets are available in Chinese, English, Japanese, Korean, and Spanish.

The character-card generator opens a local web page served by the app (`HttpServerService`, loopback port 5050).

## Data Storage

SQLite database location:

- **Android**: application documents directory (`conversations.db`).
- **Windows/Linux/macOS/iOS**: the platform home directory under `~/.lumenflow/conversations.db`.

Tables: `conversations`, `messages`, `attachments`, and application metadata/settings.

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

```bash
flutter pub get

# Android
flutter build apk --release
# or split by ABI
flutter build apk --split-per-abi

# Windows
flutter build windows --release

# Linux
flutter build linux --release

# macOS / iOS
flutter build macos --release
flutter build ios --release
```

Release Android signing is read from `android/key.properties`. Keep that file and your keystore out of source control.

### Notes

- The bundled CJK fonts add roughly 21 MB of source assets (compressed in the APK).
- The Android module is built with compileSdk 37 / targetSdk 37; `minSdk` is 29.

## Error Handling

- Network failures, timeouts, TLS/socket errors, and HTTP 429/5xx are retried with exponential backoff where safe.
- Tool-call failures are returned to the model as tool results instead of aborting the whole turn when possible.
- Provider errors are mapped to localized messages for supported locales.
- Cancellation is propagated to streaming reads and tool execution.

## License

The application source is licensed under the MIT License. See [LICENSE](./LICENSE).

Bundled Noto Sans SC font files are licensed under the SIL Open Font License 1.1; see [assets/fonts/OFL.txt](./assets/fonts/OFL.txt). The OFL applies to the font files, not to the rest of the application.

## Contributing

Issues and pull requests are welcome. Please keep changes focused, run `flutter analyze`, and describe any provider or protocol changes with links to the relevant API documentation.

## Acknowledgments

- [Flutter](https://flutter.dev/) and the `material_ui` / `cupertino_ui` packages
- AI providers: OpenAI, Anthropic, Google Gemini, DeepSeek, Kimi, MiniMax, Zhipu AI, SiliconFlow, Xiaomi MiMo, xAI, OpenRouter, LM Studio
- [Noto Sans SC](https://fonts.google.com/noto/specimen/Noto+Sans+SC) (OFL 1.1)
- [Cupertino Icons](https://pub.dev/packages/cupertino_icons)
- [MCP](https://modelcontextprotocol.io/) for the tool integration protocol

## Sponsor

![Sponsor Code](./assets/collection_code.png)

If you find this app helpful, please scan the code to support development.
