# LumenFlow

> 基于 Flutter 构建的跨平台 AI 聊天应用，支持 10+ 个 AI 平台，采用 SQLite 本地存储和全面的对话管理功能。

[English Version](../README.md) | [中文版本](./README.zh_CN.md)

## 概述

LumenFlow（中文名：流光）是一款使用 Flutter 构建的现代化 AI 聊天应用，在 Android 和 Windows 平台上提供无缝的对话体验。支持 10+ 个 AI 服务提供商，使用 SQLite 数据库进行本地数据持久化，具备丰富的多模态处理能力，提供多功能的 AI 助手体验。

- **许可证**: MIT
- **平台**: Android, Windows
- **语言**: Dart/Flutter

## 功能特性

### 核心 AI 能力
- **10+ AI 平台支持**: OpenAI、Claude、Google Gemini、DeepSeek、硅基流动、MiniMax、智谱 AI、Kimi、LM-Studio（本地部署）和其他（自定义 OpenAI 兼容 API）
- **多 AI 平台管理**: 同时配置和管理多个 AI 平台，支持独立的设置、模型列表和平台特定配置
- **流式响应**: 实时流式输出，提供响应式聊天体验
- **思考模式**: 支持的模型可视化 AI 思考过程
- **自动标题生成**: 根据对话内容自动生成对话标题

### 数据管理
- **SQLite 数据库**: 使用 sqlite3 实现高性能本地数据持久化
- **对话管理**: 完整的对话历史记录，支持本地存储和智能缓存
- **数据迁移**: 从 SharedPreferences 自动迁移到 SQLite
- **导出/导入**: 支持 TXT、JSON、PDF 和 LumenFlow 格式（[LumenFlow格式解析](./LumenFlow格式解析.md)）

### 用户体验
- **多模态支持**: 处理图像、视频和音频文件，支持视觉能力
- **文件附件**: 上传和提取各种文件类型的内容
- **用户资料**: 个性化设置，支持头像和用户名自定义
- **预设提示词系统**: 预配置的角色扮演提示词，包含丰富的角色设定
- **多语言预设**: 基于界面语言自动加载特定语言的预设
- **主题管理**: 支持亮色/暗色主题切换，支持跟随系统主题
- **国际化**: 完整的英文、中文、日文和韩文语言支持

### 技术特性
- **本地通知**: 重要事件的实时通知支持
- **Markdown 渲染**: 美观格式化的 AI 响应，支持代码块复制功能
- **代码块复制**: AI 响应中代码块的一键复制功能
- **消息复制**: 整个消息的一键复制功能
- **性能优化**: 减少重绘和优化聊天性能
- **重试机制**: 网络错误的自动重试，采用指数退避策略

## 项目结构

```
lib/
├── main.dart                 # 应用程序入口点
├── l10n/                     # 国际化文件
│   ├── app_en.arb           # 英文翻译
│   ├── app_zh.arb           # 中文翻译
│   ├── app_ja.arb           # 日文翻译
│   ├── app_ko.arb           # 韩文翻译
│   ├── app_localizations.dart # 本地化类
│   └── app_localizations_*.dart # 语言特定实现
├── models/                   # 数据模型
│   ├── conversation.dart     # 对话模型
│   ├── message.dart          # 消息模型
│   ├── user_profile.dart     # 用户资料模型
│   ├── attachment.dart       # 附件模型（文件、图像等）
│   ├── prompt_preset.dart    # 预设提示词模型
│   └── ai_platform.dart      # AI 平台配置模型
├── screens/                  # UI 界面
│   ├── chat_screen.dart      # 主聊天界面
│   ├── conversation_list_screen.dart  # 对话历史记录
│   ├── settings_screen.dart  # 应用设置
│   ├── user_profile_screen.dart  # 用户资料管理
│   ├── about_screen.dart     # 关于页面，显示应用信息
│   ├── image_preview_screen.dart  # 图片预览和查看
│   ├── platform_settings_screen.dart  # AI 平台与模型配置界面
│   ├── api_settings_screen.dart       # API 设置
│   ├── appearance_settings_screen.dart # 外观设置
│   ├── conversation_settings_screen.dart # 对话设置
│   └── model_settings_screen.dart    # 模型设置
├── services/                 # 业务逻辑和 API 集成
│   ├── ai_service.dart       # AI 服务集成
│   ├── conversation_service.dart  # 对话管理
│   ├── settings_service.dart # 设置管理
│   ├── conversation_database.dart   # SQLite 数据库服务
│   ├── user_service.dart     # 用户资料管理
│   ├── file_service.dart     # 文件处理和操作
│   ├── prompt_service.dart   # 预设提示词管理
│   ├── notification_service.dart # 通知服务
│   ├── version_service.dart  # 版本信息管理
│   └── live_update_service.dart # 实时更新服务
├── providers/                # AI 提供商实现
│   ├── ai_provider.dart     # 抽象基类
│   ├── openai_provider.dart # OpenAI 实现
│   ├── gemini_provider.dart # Gemini 实现
│   ├── deepseek_provider.dart # DeepSeek 实现
│   ├── claude_provider.dart   # Claude (Anthropic) 实现
│   ├── siliconflow_provider.dart # 硅基流动实现
│   ├── minimax_provider.dart  # MiniMax 实现
│   ├── zhipu_provider.dart    # 智谱AI 实现
│   ├── kimi_provider.dart     # Kimi 实现
│   ├── lmstudio_provider.dart # LM-Studio（本地）实现
│   └── other_provider.dart    # 其他（OpenAI 兼容）实现
├── utils/                    # 工具类
│   └── app_theme.dart        # 应用主题管理
└── widgets/                  # 可重用 UI 组件
    ├── avatar_widget.dart    # 用户头像显示
    ├── chat_input.dart       # 带文件附件的聊天输入框
    └── message_bubble.dart   # 消息显示气泡
```

## 依赖项

### 核心框架
- [Flutter](https://flutter.dev/) - UI 框架
- [cupertino_icons](https://pub.dev/packages/cupertino_icons) - iOS 风格图标

### 网络与数据
- [http](https://pub.dev/packages/http) - 用于 API 请求的 HTTP 客户端
- [sqlite3](https://pub.dev/packages/sqlite3) - SQLite 数据库用于本地存储
- [shared_preferences](https://pub.dev/packages/shared_preferences) - 传统持久化存储

### 文件处理
- [image_picker](https://pub.dev/packages/image_picker) - 图片选择
- [file_picker](https://pub.dev/packages/file_picker) - 文件选择和拾取
- [path_provider](https://pub.dev/packages/path_provider) - 路径解析
- [path](https://pub.dev/packages/path) - 路径操作
- [pdf](https://pub.dev/packages/pdf) - PDF 文件生成和处理
- [archive](https://pub.dev/packages/archive) - 压缩文件（ZIP）创建和解压

### UI 与国际化
- [flutter_markdown_plus](https://pub.dev/packages/flutter_markdown_plus) - 增强的 Markdown 渲染，支持代码块复制
- [flutter_localizations](https://api.flutter.dev/flutter/flutter_localizations/flutter_localizations-library.html) - Flutter 本地化支持
- [intl](https://pub.dev/packages/intl) - 国际化和本地化
- [flutter_svg](https://pub.dev/packages/flutter_svg) - SVG 图像渲染，用于平台图标显示

### 工具类
- [url_launcher](https://pub.dev/packages/url_launcher) - URL 启动支持
- [flutter_local_notifications](https://pub.dev/packages/flutter_local_notifications) - 本地通知

## 架构

该应用程序遵循分层架构模式：

1. **模型层**: 定义整个应用程序使用的数据结构
2. **服务层**: 处理业务逻辑、API 集成和数据持久化
3. **界面层**: 表示整个屏幕的高级 UI 组件
4. **组件层**: 可重用的 UI 组件
5. **提供商层**: AI 提供商实现，提供抽象接口
6. **本地化层**: 国际化支持，使用 ARB 文件

### 数据模型

- `Conversation`: 表示带有元数据和消息列表的聊天对话
- `Message`: 表示带有内容、发送者信息和状态的单个消息
- `UserProfile`: 存储用户特定的设置和偏好
- `Attachment`: 表示文件附件（图像、视频、音频、文档）及其元数据
- `PromptPreset`: 表示预配置的提示词预设，包含角色扮演角色设置
- `AIPlatform`: 表示 AI 平台配置，包含 API 端点、模型列表和平台特定设置

### 服务

- `AIService`: 处理与多个 AI 提供商的通信，包括请求格式化、响应解析和多模态支持
- `ConversationService`: 使用 SQLite 管理本地对话存储和检索
- `SettingsService`: 管理应用程序设置和配置，包括多 AI 平台管理
- `ConversationDatabase`: SQLite 数据库实现，支持从 SharedPreferences 自动迁移
- `UserService`: 管理用户资料数据
- `FileService`: 处理文件操作，包括读取、处理和从附件中提取内容
- `PromptService`: 管理提示词预设数据和配置
- `NotificationService`: 处理本地通知
- `VersionService`: 版本信息管理
- `LiveUpdateService`: 实时应用更新

### AI 提供商

该应用程序使用基于提供商的架构进行 AI 集成：

- `AIProvider`: 抽象基类，定义所有 AI 提供商的接口
- `OpenAIProvider`: OpenAI API 实现，支持多模态
- `GeminiProvider`: Google Gemini API 实现，支持多模态
- `DeepSeekProvider`: DeepSeek API 实现，支持流式传输
- `ClaudeProvider`: Claude (Anthropic) API 实现，支持多模态和思考模式
- `SiliconFlowProvider`: 硅基流动 API 实现
- `MiniMaxProvider`: MiniMax API 实现
- `ZhipuProvider`: 智谱AI API 实现
- `KimiProvider`: Kimi API 实现
- `LMStudioProvider`: LM-Studio（本地部署）实现，使用 OpenAI Responses API
- `OtherProvider`: OpenAI 兼容 API 实现（自定义端点）

这种架构允许轻松添加新的 AI 提供商，同时保持所有提供商之间的一致接口。

### SQLite 数据库架构

应用程序使用 SQLite 进行本地数据持久化，具有以下特性：

- **单例模式**: 全局数据库连接，支持同步写操作
- **外键约束**: 确保数据完整性，支持级联删除
- **自动迁移**: 从 SharedPreferences 无缝迁移到 SQLite
- **索引**: 对频繁访问的字段进行索引优化
- **事务支持**: ACID 兼容的操作，确保数据一致性

**数据库架构**：
- `conversations`: 存储对话元数据（id、标题、时间戳）
- `messages`: 存储消息内容及对话引用和状态
- `attachments`: 存储文件附件及消息引用
- `settings`: 存储应用程序设置和元数据

### 多 AI 平台管理

LumenFlow 支持同时管理多个 AI 平台。每个平台都可以有自己的配置、模型列表和设置。主要功能包括：

- **多平台支持**: 在单个应用程序中配置和管理 10+ 个 AI 平台
- **平台切换**: 在对话过程中轻松在已配置的平台之间切换
- **模型管理**: 每个平台维护自己的模型列表，支持从 API 自动获取模型列表
- **平台图标**: 通过平台特定的 SVG 图标进行视觉识别
- **配置迁移**: 自动从传统的单平台配置迁移到多平台配置
- **平台特定设置**: 每个平台可以拥有独立的 API 端点、身份验证方法和模型参数

平台管理界面可通过设置界面中的"平台与模型"部分访问。

## 配置

在使用应用程序之前，需要至少配置一个 AI 平台并输入 API 密钥：

1. 导航到设置界面
2. 选择"平台与模型"进入平台配置界面
3. 添加新平台或编辑现有平台
4. 输入平台名称、API 端点和 API 密钥
5. 配置模型参数（默认模型、温度、最大 tokens 数）
6. 保存平台配置
7. 将平台设置为活动状态以用于对话

您可以根据需要配置多个平台并在它们之间切换。

### 支持的 AI 提供商

1. **OpenAI**
   - API 端点：`https://api.openai.com/v1/responses`
   - 支持的模型：GPT-5.2, GPT-o3 和其他 OpenAI 模型
   - 图像、视频和音频的多模态支持

2. **Google Gemini**
   - API 端点：`https://generativelanguage.googleapis.com/v1beta/models/{model}:generateContent`
   - 支持的模型：Gemini 3.0 Flash、Gemini 3 Pro
   - 多模态能力

3. **DeepSeek**
   - API 端点：`https://api.deepseek.com/chat/completions`
   - 支持的模型：DeepSeek-V3.2
   - 文本流式传输支持

4. **Claude (Anthropic)**
   - API 端点：`https://api.anthropic.com/v1/messages`
   - 支持的模型：Claude Sonnet 4.5、Claude Opus 4.5
   - 图像多模态支持，具备思考模式能力

5. **硅基流动 (SiliconFlow)**
   - API 端点：`https://api.siliconflow.cn/v1/chat/completions`
   - 支持的模型：各种开源模型（Qwen、DeepSeek 等）
   - 文本支持

6. **MiniMax**
   - API 端点：`https://api.minimax.chat/v1/chat/completions`
   - 支持的模型：MiniMax 专有模型
   - 文本支持

7. **智谱AI (Zhipu AI)**
   - API 端点：`https://open.bigmodel.cn/api/paas/v4/chat/completions`
   - 支持的模型：GLM 系列模型
   - 文本支持

8. **Kimi**
   - API 端点：`https://api.moonshot.cn/v1/chat/completions`
   - 支持的模型：Kimi 模型
   - 文本支持，具备长上下文能力

9. **LM-Studio（本地）**
   - API 端点：自定义本地端点（默认：`http://localhost:1234/v1`）
   - 支持的模型：通过 LM-Studio 托管的本地 LLM
   - 使用 OpenAI Responses API 格式

10. **其他（自定义 API）**
    - API 端点：`https://URL/v1/chat/completions`
    - 支持的模型：用户定义的模型列表
    - OpenAI 聊天补全格式兼容性

### 默认值

配置新平台时，使用以下默认值：

- **默认平台类型**：OpenAI
- **默认模型**：
  - OpenAI：`gpt-5`
  - Gemini：`gemini-3-flash-preview`
  - DeepSeek：`deepseek-chat`
  - Claude：`claude-sonnet-4.5`
  - 硅基流动：`Qwen/Qwen2.5-32B-Instruct`
  - MiniMax：`MiniMax-M2.1`
  - 智谱AI：`glm-4.7`
  - Kimi：`moonshot-k2`
  - LM-Studio：`local-model`
- **温度**：`0.7`
- **最大 Tokens 数**：`4096`

注意：这些默认值在创建新平台配置时应用。您可以为每个平台独立自定义这些值。

### 预设提示词（角色扮演系统）

LumenFlow 包含一个先进的角色扮演系统，具有基于文件的提示预设，支持多种语言。系统会根据用户选择的界面语言自动加载相应的语言版本。

#### 工作原理
- **多语言支持**：预设提供英文、中文、日文和韩文版本
- **自动语言检测**：系统根据当前界面语言设置自动加载相应的预设版本
- **基于文件的预设**：`system_prompt` 字段指向 XML/TXT 文件（例如：`"characters/zh/NingXi.xml"`）
- **自动内容加载**：系统自动加载文件内容并将其用作系统提示词
- **变量替换**：支持 `\${userProfile.username}` 替换为实际用户名
- **XML 格式**：丰富的 XML 结构，用于详细的角色定义，包含元信息、个性逻辑、称呼协议和示例对话

#### 使用预设
1. 导航到聊天界面
2. 点击"角色扮演"按钮，从预设菜单中选择一个角色
3. 所选角色的完整个性系统将应用于对话
4. AI 回复将反映角色的特征、说话模式和行为，并使用所选语言进行响应

#### 自定义和添加预设
1. 在相应的语言目录中创建 XML/TXT 文件（`assets/prompt/characters/zh/` 对应中文，`assets/prompt/characters/en/` 对应英文，等）
2. 在对应的预设 JSON 文件中添加条目，`system_prompt` 指向正确的文件路径
3. 遵循 XML 格式结构以保持角色定义的一致性
4. 重启应用程序以加载新的预设

##### presets-*.json 结构示例
```json
{
  "id": "ningxi",
  "name": "宁汐",
  "description": "俏皮可爱的猫娘",
  "system_prompt": "characters/zh(or en)/NingXi.xml",
  "icon": "person.fill"
}
```
##### character.xml 结构示例
```xml
<system_instruction>
   <mate>
      <role_name>NAME</role_name>
      <identity>TEXT</identity>
      <core_philosophy>TEXT</core_philosophy>
   </mate>
   <personality_logic>TEXT</personality_logic>
   <addressing_protocol>TEXT</addressing_protocol>
   <linguistic_style>TEXT</linguistic_style>
   <behavior_narrative_rules>TEXT</behavior_narrative_rules>
   <interaction_strategy>TEXT</interaction_strategy>
   <user_info>TEXT</user_info>
   <example_dialogue>TEXT</example_dialogue>
</system_instruction>
```

## 数据存储

### SQLite 数据库

应用程序使用 SQLite 进行本地数据存储，提供高性能和可靠性：

- **位置**：应用程序文档目录（`conversations.db`）
- **表结构**：
  - `conversations`: 存储对话元数据
  - `messages`: 存储消息内容及元数据
  - `attachments`: 存储文件附件信息
  - `settings`: 存储应用程序设置
- **特性**：
  - 外键约束确保数据完整性
  - 从传统 SharedPreferences 自动迁移
  - 事务支持确保数据一致性
  - 索引查询实现最佳性能

**存储的数据**：
- 用户设置和 API 密钥
- 包含完整消息内容的对话历史
- 用户资料信息
- 附件元数据和文件引用

所有数据都存储在设备本地，不会在设备之间同步。

### 数据迁移

应用程序在首次启动时自动将数据从 SharedPreferences 迁移到 SQLite。这确保了：

- 从以前版本的平滑过渡
- 迁移过程中无数据丢失
- 基于事务的迁移，失败时自动回滚

## 设置管理

LumenFlow 提供设置导出和导入功能，用于备份和恢复应用配置。

### 导出设置
1. 导航到设置界面
2. 滚动到"数据管理"部分
3. 点击"导出设置"
4. 选择保存 JSON 文件的位置
5. 您的设置（包括 API 密钥、偏好设置和用户资料）将被保存

### 导入设置
1. 导航到设置界面
2. 滚动到"数据管理"部分
3. 点击"导入设置"
4. 选择之前导出的 JSON 文件
5. 确认从文件恢复设置

### 恢复默认设置
1. 导航到设置界面
2. 滚动到"数据管理"部分
3. 点击"恢复默认设置"
4. 确认将所有设置重置为默认值

**注意**：API 密钥和敏感信息包含在导出的文件中。请妥善保管这些文件。

## 国际化

LumenFlow 支持英文、中文、日文和韩文四种语言。应用程序会自动检测系统语言，也可以在设置中手动选择。所有界面元素、AI 响应和提示词预设都完全本地化。

### 语言支持
- **英文**: 所有界面元素和 AI 响应的完整英文本地化
- **中文**: 所有界面元素和 AI 响应的完整中文本地化
- **日文**: 所有界面元素和 AI 响应的完整日文本地化
- **韩文**: 所有界面元素和 AI 响应的完整韩文本地化

### 实现方式
- 使用 Flutter 内置的本地化系统，配合 ARB 文件
- AI 响应根据所选语言进行本地化
- 提示词预设自动加载适当的语言版本
- 角色定义提供多语言版本，使用单独的 XML 文件

## 构建

要构建应用程序，请确保已安装并设置好 Flutter：

```bash
# 安装依赖项
flutter pub get

# 为 Android 构建（带 ABI 分割的 APK）
flutter build apk --split-per-abi

# 为 Windows 构建（发布模式）
flutter build windows --release
```

### 使用构建脚本

或者，在 Windows 上使用提供的 PowerShell 构建脚本：

```powershell
.\build.ps1
```

此脚本将自动构建 Android APK 和 Windows EXE 包。

## 错误处理

该应用程序包含以下错误处理：

- 网络连接问题
- API 错误（无效密钥、速率限制等）
- 数据解析错误
- 文件处理错误
- 本地化错误

错误信息会通过本地化的 UI 消息显示给用户，通常在聊天界面或警报中显示。所有错误信息都支持所有支持的语言。

## 许可证

本项目基于 MIT 许可证。详见 [LICENSE](../LICENSE) 文件。

## 贡献

欢迎贡献！欢迎提交问题报告和拉取请求，以改进、修复错误或添加新功能。

## 致谢

- 基于 [Flutter](https://flutter.dev/) 构建
- AI 能力由 [OpenAI](https://openai.com/)、[Google Gemini](https://gemini.google.com/)、[Claude](https://www.anthropic.com/)、[DeepSeek](https://www.deepseek.com/)、[硅基流动](https://www.siliconflow.cn/)、[MiniMax](https://www.minimaxi.com/)、[智谱AI](https://www.zhipuai.cn/)、[Kimi](https://kimi.moonshot.cn/) 和 LM-Studio 提供支持
- 国际化支持使用 Flutter 的本地化系统
- 图标由 [Cupertino Icons](https://pub.dev/packages/cupertino_icons) 提供

## 赞助

![赞助码](../assets/collection_code.png)

如果觉得这个应用对你有帮助，欢迎扫码赞助支持开发。
