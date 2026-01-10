# LumenFlow

> 基于 Flutter 构建的跨平台 AI 聊天应用，支持 OpenAI 和 Google Gemini API，具备多模态处理能力。

[English Version](../README.md) | [中文版本](./README.zh_CN.md)

## 概述

LumenFlow（中文名：流光）是一款使用 Flutter 构建的现代化 AI 聊天应用，在 Android 和 Windows 平台上提供无缝的对话体验。支持 OpenAI 和 Google Gemini API，并具备多模态文件处理能力，提供多功能的 AI 助手体验。

- **许可证**: MIT
- **平台**: Android, Windows
- **语言**: Dart/Flutter

## 功能特性

- **多AI模型支持**: 支持 OpenAI、Google Gemini 和 Claude API，可无缝切换
- **多AI平台管理**: 配置和管理多个AI平台，支持独立的设置、模型列表和平台特定配置
- **多模态支持**: 处理图像、视频和音频文件，支持视觉能力
- **流式响应**: 实时流式输出，提供响应式聊天体验
- **文件附件**: 上传和提取各种文件类型的内容
- **对话管理**: 完整的对话历史记录，支持本地持久化
- **用户配置**: 个性化设置和偏好
- **预设提示词系统**: 预配置的角色扮演提示词，包含丰富的角色设定
- **多语言预设**: 基于界面语言自动加载特定语言的预设
- **主题管理**: 支持亮色/暗色主题切换，支持跟随系统主题
- **跨平台**: 支持 Android 和 Windows 平台
- **本地存储**: 使用 SharedPreferences 实现数据持久化
- **Markdown渲染**: 美观格式化的 AI 响应
- **关于页面**: 显示应用信息、版本和版权详情
- **设置导出/导入**: 通过 JSON 文件备份和恢复应用设置
- **自定义 .lumenflow 格式**: 增强的设置导出/导入功能，包含元数据和版本控制（参见 [LumenFlow 格式规范](./LumenFlow格式解析.md)）
- **角色扮演系统**: 基于文件的预设提示词系统，支持自动内容加载
- **PowerShell构建脚本**: 自动构建 Android 和 Windows 应用的脚本
- **国际化**: 完整的英文和中文语言支持
- **思考模式**: AI思考过程可视化
- **自动标题生成**: 自动对话标题生成

## 项目结构

```
lib/
├── main.dart                 # 应用程序入口点
├── l10n/                     # 国际化文件
│   ├── app_en.arb           # 英文翻译
│   ├── app_zh.arb           # 中文翻译
│   ├── app_localizations.dart # 本地化类
│   └── app_localizations_*.dart # 语言特定实现
├── models/                   # 数据模型
│   ├── conversation.dart     # 对话模型
│   ├── message.dart          # 消息模型
│   ├── user_profile.dart     # 用户配置模型
│   ├── attachment.dart       # 附件模型（文件、图像等）
│   ├── prompt_preset.dart    # 预设提示词模型
│   └── ai_platform.dart      # AI平台配置模型
├── screens/                  # UI 界面
│   ├── chat_screen.dart      # 主聊天界面
│   ├── conversation_list_screen.dart  # 对话历史记录
│   ├── settings_screen.dart  # 应用设置
│   ├── user_profile_screen.dart  # 用户配置管理
│   ├── about_screen.dart     # 关于页面，显示应用信息
│   ├── image_preview_screen.dart  # 图片预览和查看
│   └── platform_settings_screen.dart  # AI平台与模型配置界面
├── services/                 # 业务逻辑和 API 集成
│   ├── ai_service.dart       # AI 服务（OpenAI、Gemini 和 DeepSeek 集成）
│   ├── conversation_service.dart  # 对话管理
│   ├── settings_service.dart # 设置管理
│   ├── user_service.dart     # 用户配置管理
│   ├── file_service.dart     # 文件处理和操作
│   ├── prompt_service.dart   # 预设提示词管理
│   └── version_service.dart  # 版本信息管理
├── providers/                # AI 提供商实现
│   ├── ai_provider.dart     # 抽象基类
│   ├── openai_provider.dart # OpenAI 实现
│   ├── gemini_provider.dart # Gemini 实现
│   ├── deepseek_provider.dart # DeepSeek 实现
│   └── claude_provider.dart   # Claude (Anthropic) 实现
├── utils/                    # 工具类
│   └── app_theme.dart        # 应用主题管理
└── widgets/                  # 可重用 UI 组件
    ├── avatar_widget.dart    # 用户头像显示
    ├── chat_input.dart       # 带文件附件的聊天输入框
    └── message_bubble.dart   # 消息显示气泡
```

## 依赖项

- [Flutter](https://flutter.dev/) - UI 框架
- [cupertino_icons](https://pub.dev/packages/cupertino_icons) - iOS 风格图标
- [http](https://pub.dev/packages/http) - 用于 API 请求的 HTTP 客户端
- [shared_preferences](https://pub.dev/packages/shared_preferences) - 持久化存储
- [intl](https://pub.dev/packages/intl) - 国际化和本地化
- [flutter_markdown](https://pub.dev/packages/flutter_markdown) - Markdown 渲染
- [image_picker](https://pub.dev/packages/image_picker) - 图片选择
- [file_picker](https://pub.dev/packages/file_picker) - 文件选择和拾取
- [path_provider](https://pub.dev/packages/path_provider) - 路径解析
- [path](https://pub.dev/packages/path) - 路径操作
- [flutter_localizations](https://api.flutter.dev/flutter/flutter_localizations/flutter_localizations-library.html) - Flutter 本地化支持
- [flutter_svg](https://pub.dev/packages/flutter_svg) - SVG图像渲染，用于平台图标显示
- [pdf](https://pub.dev/packages/pdf) - PDF文件生成和处理
- [archive](https://pub.dev/packages/archive) - 压缩文件（ZIP）创建和解压

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
- `AIPlatform`: 表示AI平台配置，包含API端点、模型列表和平台特定设置

### 服务

- `AIService`: 处理与 OpenAI、Google Gemini 和 DeepSeek API 的通信，包括请求格式化、响应解析和多模态支持
- `ConversationService`: 管理本地对话存储和检索
- `SettingsService`: 管理应用程序设置和配置，包括多AI平台管理、配置迁移和平台特定设置
- `UserService`: 管理用户配置数据
- `FileService`: 处理文件操作，包括读取、处理和从附件中提取内容
- `PromptService`: 管理提示词预设数据和配置

### AI 提供商

该应用程序使用基于提供商的架构进行 AI 集成：

- `AIProvider`: 抽象基类，定义所有 AI 提供商的接口
- `OpenAIProvider`: OpenAI API 实现，支持多模态
- `GeminiProvider`: Google Gemini API 实现，支持多模态
- `DeepSeekProvider`: DeepSeek API 实现，支持文本流式传输
- `ClaudeProvider`: Claude (Anthropic) API 实现，支持多模态和思考模式

这种架构允许轻松添加新的 AI 提供商，同时保持所有提供商之间的一致接口。

### 多AI平台管理

LumenFlow 现在支持同时管理多个 AI 平台。每个平台都可以有自己的配置、模型列表和设置。主要功能包括：

- **多平台支持**：在单个应用程序中配置和管理多个 AI 平台（OpenAI、Claude、DeepSeek、Gemini）
- **平台切换**：在对话过程中轻松在已配置的平台之间切换
- **模型管理**：每个平台维护自己的模型列表，支持从 API 自动获取模型列表
- **平台图标**：通过平台特定的 SVG 图标进行视觉识别
- **配置迁移**：自动从传统的单平台配置迁移到多平台配置
- **平台特定设置**：每个平台可以拥有独立的 API 端点、身份验证方法和模型参数

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
   - API 端点：`https://api.openai.com/v1/chat/completions` 或 `https://api.openai.com/v1/responses`
   - 支持的模型：GPT-5.2、GPT-4o 和其他 OpenAI 模型
   - 图像、视频和音频的多模态支持

2. **Google Gemini**
   - API 端点：`https://generativelanguage.googleapis.com/v1beta/models/{model}:generateContent`
   - 支持的模型：Gemini 3 Pro Preview、Gemini 3 Flash Preview
   - 多模态能力

3. **DeepSeek**
   - API 端点：`https://api.deepseek.com`
   - 支持的模型：DeepSeek Chat、DeepSeek Coder
   - 文本流式传输支持

4. **Claude (Anthropic)**
   - API 端点：`https://api.anthropic.com/v1/messages`
   - 支持的模型：Claude Opus 4.5、Claude Sonnet 4.5
   - 图像多模态支持，具备思考模式能力

### 默认值

配置新平台时，使用以下默认值：

- **默认平台类型**：OpenAI
- **默认模型**：
  - OpenAI：`gpt-5.2`
  - Gemini：`gemini-3-flash-preview`
  - DeepSeek：`deepseek-chat`
  - Claude：`claude-sonnet-4.5`
- **温度**：`0.7`
- **最大 Tokens 数**：`1000`

注意：这些默认值在创建新平台配置时应用。您可以为每个平台独立自定义这些值。

### 预设提示词（角色扮演系统）

LumenFlow 包含一个先进的角色扮演系统，具有基于文件的提示预设，支持多种语言。系统会根据用户选择的界面语言自动加载相应的语言版本。

#### 工作原理
- **多语言支持**：预设提供中文（`presets-zh.json`）和英文（`presets-en.json`）版本
- **自动语言检测**：系统根据当前界面语言设置自动加载相应的预设版本
- **基于文件的预设**：`system_prompt` 字段指向 XML/TXT 文件（例如：`"characters/zh/NingXi.xml"` 对应中文，`"characters/en/NingXi.xml"` 对应英文）
- **自动内容加载**：系统自动加载文件内容并将其用作系统提示词
- **变量替换**：支持 `\${userProfile.username}` 替换为实际用户名
- **XML 格式**：丰富的 XML 结构，用于详细的角色定义，包含元信息、个性逻辑、称呼协议和示例对话

#### 使用预设
1. 导航到聊天界面
2. 点击"角色扮演"按钮，从预设菜单中选择一个角色
3. 所选角色的完整个性系统将应用于对话
4. AI 回复将反映角色的特征、说话模式和行为，并使用所选语言进行响应

#### 自定义和添加预设
1. 在相应的语言目录中创建 XML/TXT 文件（`assets/prompt/characters/zh/` 对应中文，`assets/prompt/characters/en/` 对应英文）
2. 在 `presets-zh.json` 和 `presets-en.json` 中添加条目，`system_prompt` 指向正确的文件路径
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

## 设置管理

LumenFlow 提供设置导出和导入功能，用于备份和恢复应用配置。应用程序支持标准 JSON 格式和增强的 `.lumenflow` 格式，后者包含元数据，提供更好的版本控制和兼容性管理。有关详细格式规范，请参见 [LumenFlow 格式规范](../LumenFlowFormatSpecification.md)。

### 导出设置
1. 导航到设置界面
2. 滚动到"数据管理"部分
3. 点击"导出设置"
4. 选择保存 JSON 文件的位置
5. 您的设置（包括 API 密钥、偏好设置和用户配置）将被保存

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

LumenFlow 支持英文和中文两种语言。应用程序会自动检测系统语言，也可以在设置中手动选择。所有界面元素、AI 响应和提示词预设都完全本地化。

### 语言支持
- **英文**: 所有界面元素和 AI 响应的完整英文本地化
- **中文**: 所有界面元素和 AI 响应的完整中文本地化

### 实现方式
- 使用 Flutter 内置的本地化系统，配合 ARB 文件
- AI 响应根据所选语言进行本地化
- 提示词预设自动加载适当的语言版本

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

## 数据存储

该应用程序使用 `shared_preferences` 进行本地数据存储：

- 用户设置和 API 密钥
- 对话历史记录
- 用户配置信息

所有数据都存储在设备本地，不会在设备之间同步。

## 错误处理

该应用程序包含以下错误处理：

- 网络连接问题
- API 错误（无效密钥、速率限制等）
- 数据解析错误
- 文件处理错误
- 本地化错误

错误信息会通过本地化的 UI 消息显示给用户，通常在聊天界面或警报中显示。所有错误信息都支持英文和中文两种语言。

## 许可证

本项目基于 MIT 许可证。详见 [LICENSE](../LICENSE) 文件。

## 贡献

欢迎贡献！欢迎提交问题报告和拉取请求，以改进、修复错误或添加新功能。

## 致谢

- 基于 [Flutter](https://flutter.dev/) 构建
- AI 能力由 [OpenAI](https://openai.com/)、[Google Gemini](https://gemini.google.com/) 和 [DeepSeek](https://www.deepseek.com/) 提供支持
- 国际化支持使用 Flutter 的本地化系统
- 图标由 [Cupertino Icons](https://pub.dev/packages/cupertino_icons) 提供