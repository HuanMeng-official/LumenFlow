![LumenFlow](./img/cover.png)

> 基于 Flutter 构建的本地优先跨平台 AI 聊天客户端：13 个 AI 平台、流式对话、工具调用、MCP、SQLite 本地存储，以及完整的中文 PDF 支持。

[English Version](../README.md) | [中文版本](./README.zh_CN.md)

## 概述

LumenFlow（中文名：流光）是一款使用 Flutter 构建的 AI 聊天应用，支持 Android、iOS、Windows、Linux 和 macOS。它把多平台模型接入、工具调用 Agent、本地 SQLite 存储和 Cupertino 风格界面整合在一起。

- **版本**：3.0.0+300
- **许可证**：MIT（内置 Noto Sans SC 字体为 OFL-1.1）
- **UI 技术栈**：Flutter 3.47.8 / Dart 3.13.7，`material_ui`、`cupertino_ui`
- **Android 基线**：compileSdk 37.2、targetSdk 37、minSdk 29（Android 10+）

## 功能特性

### AI 与平台

- **13 种平台类型**：OpenAI、Claude、Google Gemini、DeepSeek、Kimi、MiniMax、智谱 AI、硅基流动、小米 MiMo、Grok、OpenRouter、LM Studio、其他（OpenAI 兼容）。
- **多平台管理**：每个平台独立保存端点、API Key、模型列表、默认模型和启用状态。
- **模型列表刷新**：从支持的平台 API 拉取模型并选择默认模型。
- **流式响应**：逐步输出正文和思考内容。
- **思考模式**：在模型支持时展示推理摘要。
- **自动标题**：根据最近消息自动生成对话标题。
- **重试与取消**：网络错误指数退避重试；流式请求和工具循环支持取消。

### 工具调用与 MCP

- **内置工具**：当前时间、计算器、文本对比、文本统计。
- **MCP 工具**：连接 Streamable HTTP MCP 服务器，发现并暴露其工具。
- **统一工具循环**：`AgentRunner` 在模型回合和工具执行之间交替，并限制最大迭代次数。
- **并行工具调用**：同一轮模型返回多个工具调用时统一执行并回传。
- **按协议适配**：
  - Chat Completions：DeepSeek、Kimi、MiniMax、智谱、硅基流动、小米 MiMo、其他
  - Responses API：OpenAI、Grok、OpenRouter、LM Studio
  - Claude Messages：Claude
  - Gemini Interactions：Gemini
- **工具错误回传**：工具执行失败会作为错误结果返回给模型，而不是直接中断整个回合。

### 数据与导出

- **SQLite 存储**：外键、索引、事务和 SharedPreferences 自动迁移。
- **对话管理**：历史列表、编辑、重新生成、重新提交、删除和对话级设置。
- **附件处理**：图片、视频、音频、PDF 和文本内容提取。
- **导出格式**：TXT、JSON、PDF、LumenFlow 压缩包。
  - [LumenFlow 格式说明](./LumenFlow格式解析.md)
- **PDF 导出**：嵌入 Noto Sans SC，按实际使用字符做字体子集，中文不再乱码。
- **设置备份**：导出/导入 JSON 设置，恢复默认设置。

### 使用体验

- **Cupertino 风格界面**：支持亮色、暗色和跟随系统主题。
- **用户资料**：头像、用户名、性别、生日。
- **预设提示词与角色扮演**：多语言 XML 角色卡从 assets 加载。
- **角色卡生成器**：内置网页生成器，由本地 HTTP 服务提供。
- **Markdown 与代码块**：Markdown 渲染和代码块复制。
- **本地通知与实时更新**：重要事件通知和 Live Update 支持。
- **本地优先**：对话内容和 API Key 保存在设备本地。

## AI 平台

| 平台 | API 类型 | 默认端点 | 默认模型 | 工具协议 |
| --- | --- | --- | --- | --- |
| OpenAI | Responses | `https://api.openai.com/v1` | `gpt-6.1-sol` | Responses |
| Claude | Messages | `https://api.anthropic.com/v1` | `claude-opus-5-5` | Messages |
| Google Gemini | Interactions | `https://generativelanguage.googleapis.com/v1beta` | `gemini-3.8-flash` | Interactions |
| DeepSeek | Chat Completions | `https://api.deepseek.com` | `deepseek-flash` | Chat Completions |
| Kimi | Chat Completions | `https://api.moonshot.cn/v1` | `kimi-k3.1-pro` | Chat Completions |
| MiniMax | Chat Completions | `https://api.minimax.cn/v1` | `MiniMax-M3.1-Flash` | Chat Completions |
| 智谱 AI | Chat Completions | `https://open.bigmodel.cn/api/paas/v4` | `glm-5.3` | Chat Completions |
| 硅基流动 | Chat Completions | `https://api.siliconflow.cn/v1` | 模型列表 / 用户选择 | Chat Completions |
| 小米 MiMo | Chat Completions | `https://api.xiaomimimo.com/v1` | `mimo-v2.6-pro` | Chat Completions |
| Grok | Responses | `https://api.x.ai/v1` | `grok-4.7` | Responses |
| OpenRouter | Responses | `https://openrouter.ai/api/v1` | 模型列表 / 用户选择 | Responses |
| LM Studio | Responses | `http://YOUR_LM-STUDIO_ADDRESS:PORT/v1` | 模型列表 / 用户选择 | Responses |
| 其他 | Chat Completions | `https://YOUR_LLM_ADDRESS/v1` | 模型列表 / 用户选择 | Chat Completions |

> 端点和模型 ID 只是默认值。各平台 API 和模型目录变化较快，请使用模型刷新功能或直接编辑平台配置。

### 其他默认值

- **温度**：`0.7`
- **最大 Tokens**：`8192`（Gemini 同步请求上限为 65,536）
- **历史上下文**：默认 30 条消息
- **默认平台**：OpenAI

## 项目结构

```text
lib/
├── main.dart                         # 应用入口
├── ai/
│   ├── agent/
│   │   └── agent_runner.dart         # 模型 ↔ 工具执行循环
│   ├── contracts/                    # 与平台无关的请求/消息/工具/事件类型
│   ├── mcp/                          # MCP 客户端、模型和工具管理
│   ├── providers/
│   │   ├── chat_completions_profile.dart
│   │   ├── chat_completions_tool_provider.dart
│   │   ├── responses_tool_provider.dart
│   │   ├── claude_tool_provider.dart
│   │   └── gemini_tool_provider.dart
│   ├── tools/                        # 内置时间、计算器、文本工具
│   └── transport/
│       └── sse_decoder.dart          # 增量 SSE 解析
├── controllers/
│   └── chat_send_controller.dart     # 单次流式发送生命周期
├── l10n/                             # ARB 文件和生成的本地化代码
├── models/                           # 对话、消息、附件、平台、用户资料模型
├── providers/                        # 各平台普通聊天/流式 Provider
├── screens/                          # 聊天、对话、设置、工具、资料、赞助页面
├── services/
│   ├── ai_service.dart               # Provider 选择和普通聊天路径
│   ├── tool_chat_service.dart        # 带工具的平台回合
│   ├── conversation_database.dart    # SQLite 与数据迁移
│   ├── conversation_service.dart     # 对话 CRUD 与导出
│   ├── settings_service.dart         # 设置与当前平台快照
│   └── ...                           # 文件、提示词、通知、实时更新、HTTP 服务
├── utils/
│   ├── app_theme.dart                # Cupertino/Material 主题和字体
│   └── path_utils.dart               # 跨平台数据目录
└── widgets/                          # 聊天输入、消息气泡、头像、设置组件
```

## 关键依赖

| 包 | 用途 |
| --- | --- |
| `material_ui` / `cupertino_ui` | 独立发布的 Material 和 Cupertino 设计系统 |
| `http` | 平台 API 和 MCP HTTP 传输 |
| `sqlite3` | 对话、消息、附件和设置存储 |
| `shared_preferences` | 轻量设置和旧数据迁移 |
| `file_picker` / `image_picker` | 文件和图片选择 |
| `pdf` / `archive` | PDF 生成和 LumenFlow 压缩包导出 |
| `flutter_markdown_plus` | Markdown 渲染 |
| `flutter_svg` | 平台图标和矢量 UI 资源 |
| `flutter_local_notifications` | 本地通知 |
| `window_manager` | 桌面窗口配置 |
| `auto_orientation_v2` | 移动端屏幕方向控制 |
| `flutter_localizations` / `intl` | 基于 ARB 的本地化 |

## 架构

LumenFlow 采用分层、本地优先的架构：

```text
UI（screens/widgets）
        │
        ├── ChatSendController ──► AIService ──► lib/providers/* ──► HTTP
        │
        └── ToolChatService ──► AgentRunner ──► 协议工具 Provider
                                      │                │
                                      └── AIToolExecutor（内置工具 + MCP）
```

- **UI 层**：Cupertino 风格页面和可复用组件。
- **应用层**：`AIService` 根据当前平台选择 Provider；`ChatSendController` 管理一次发送/流式生命周期。
- **工具层**：`ToolChatService` 和 `AgentRunner` 执行模型/工具循环；`CompositeToolExecutor` 合并内置工具和已启用的 MCP 工具。
- **协议层**：每类平台有独立的流式和工具适配器，负责请求构造和事件映射。
- **数据层**：SQLite 保存对话、消息、附件；`SettingsService` 管理配置和当前平台解析。
- **本地化层**：由 ARB 文件生成 `AppLocalizations`。

### Provider 协议适配

- **Chat Completions**：兼容 OpenAI 的 `chat/completions` 流式响应、`tool_calls` 和 `tool` 消息。
- **Responses API**：类型化输出项、`function_call` / `function_call_output`、item ID 和完成事件去重。
- **Claude Messages**：`tool_use` / `tool_result`、思考/签名的原始内容块回放、流式 JSON 参数增量。
- **Gemini Interactions**：`/v1beta/interactions`、step 事件、思考摘要、函数调用，以及 `previous_interaction_id` + `function_result` 的服务端状态续轮。

## 配置

1. 打开 **设置 → 平台与模型**。
2. 添加平台或编辑已有平台。
3. 填写端点和 API Key。
4. 刷新模型列表，或手动输入模型 ID。
5. 选择默认模型。
6. 保存后点击平台卡片，将其设为当前平台。

每个平台独立保存端点、凭据、模型列表和参数。旧版的单平台 API 设置页面仍然保留。

### 工具管理

打开 **设置 → 工具管理**：

- 启用/禁用内置工具（时间、计算器、文本工具）。
- 添加 MCP 服务器，填写 Streamable HTTP JSON-RPC 端点和可选自定义请求头。
- 查看哪些平台支持工具调用。

MCP 工具会带上服务器前缀，避免不同服务器的同名工具冲突。

## 预设提示词

角色扮演系统按语言加载基于文件的预设：

- `assets/prompt/presets-*.json` 保存预设元数据。
- `system_prompt` 指向 `assets/prompt/characters/<locale>/` 下的 XML/TXT 文件。
- 支持 `${userProfile.username}` 变量替换。
- 提供中文、英文、日文、韩文和西班牙文预设。

角色卡生成器由应用内置的本地 HTTP 服务提供（`HttpServerService`，回环地址端口 5050）。

## 数据存储

SQLite 数据库位置：

- **Android**：应用文档目录（`conversations.db`）。
- **Windows/Linux/macOS/iOS**：平台主目录下的 `~/.lumenflow/conversations.db`。

表：`conversations`、`messages`、`attachments` 以及应用元数据/设置。

所有对话、API Key 和用户资料都保存在设备本地。需要备份时使用设置导出功能。

## 字体与本地化

- UI 和 PDF 导出统一使用内置的 **Noto Sans SC** Regular/Bold。
- 同时注册了 `CupertinoSystemText` / `CupertinoSystemDisplay` 字体别名，让 Cupertino 弹层和对话框也使用内置字体。
- 日文、韩文界面仍回退到系统本地字体，保留日文汉字字形差异和韩文 Hangul 覆盖。
- 界面语言：英文（`en`）、简体中文（`zh`）、日文（`ja`）、韩文（`ko`）、西班牙文（`es`）、文言中文（`lzh`）。
- Noto Sans SC 使用 SIL Open Font License 1.1，详见 [assets/fonts/OFL.txt](../assets/fonts/OFL.txt)。

## 构建

### 环境要求

- Flutter 3.47.8+ / Dart 3.13.7+
- Android：Android SDK 37（compileSdk 37.2）、JDK 17、Gradle 9.3.1、AGP 9.1.0、Kotlin 2.4.0
- Windows：Visual Studio 2022，安装“使用 C++ 的桌面开发”
- Linux：GTK 3、clang、cmake、ninja、pkg-config

```bash
flutter pub get

# Android
flutter build apk --release
# 或按 ABI 拆分
flutter build apk --split-per-abi

# Windows
flutter build windows --release

# Linux
flutter build linux --release

# macOS / iOS
flutter build macos --release
flutter build ios --release
```

Android release 签名从 `android/key.properties` 读取；该文件和 keystore 不要提交到仓库。

### 说明

- 内置中文字体使源码资源增加约 21MB（APK 内会压缩）。
- Android 模块使用 compileSdk 37 / targetSdk 37，minSdk 29。

## 错误处理

- 网络失败、超时、TLS/Socket 错误以及 HTTP 429/5xx 会在安全范围内按指数退避重试。
- 工具调用失败会尽量作为工具结果返回给模型，而不是直接中断整个回合。
- 各平台错误会映射为对应语言的本地化消息。
- 取消操作会传递到流式读取和工具执行。

## 许可证

应用源码使用 MIT 许可证，详见 [LICENSE](../LICENSE)。

内置 Noto Sans SC 字体文件使用 SIL Open Font License 1.1，详见 [assets/fonts/OFL.txt](../assets/fonts/OFL.txt)。OFL 仅适用于字体文件，不适用于应用其余部分。

## 贡献

欢迎提交 Issue 和 Pull Request。请保持改动聚焦，运行 `flutter analyze`，并在修改 Provider 或协议实现时附上对应官方 API 文档链接。

## 致谢

- [Flutter](https://flutter.dev/) 以及 `material_ui` / `cupertino_ui` 包
- AI 平台：OpenAI、Anthropic、Google Gemini、DeepSeek、Kimi、MiniMax、智谱 AI、硅基流动、小米 MiMo、xAI、OpenRouter、LM Studio
- [Noto Sans SC](https://fonts.google.com/noto/specimen/Noto+Sans+SC)（OFL 1.1）
- [Cupertino Icons](https://pub.dev/packages/cupertino_icons)
- [MCP](https://modelcontextprotocol.io/) 工具集成协议

## 赞助

![赞助码](../assets/collection_code.png)

如果觉得这个应用对你有帮助，欢迎扫码赞助支持开发。
