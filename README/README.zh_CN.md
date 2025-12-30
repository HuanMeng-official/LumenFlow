# LumenFlow

> 基于 Flutter 构建的跨平台 AI 聊天应用，支持 OpenAI 和 Google Gemini API，具备多模态处理能力。

[English Version](../README.md) | [中文版本](./README.zh_CN.md)

## 概述

LumenFlow（中文名：流光）是一款使用 Flutter 构建的现代化 AI 聊天应用，在 Android 和 Windows 平台上提供无缝的对话体验。支持 OpenAI 和 Google Gemini API，并具备多模态文件处理能力，提供多功能的 AI 助手体验。

- **许可证**: MIT
- **平台**: Android, Windows
- **语言**: Dart/Flutter

## 功能特性

- **多AI模型支持**: 支持 OpenAI 和 Google Gemini API，可无缝切换
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
│   └── prompt_preset.dart    # 预设提示词模型
├── screens/                  # UI 界面
│   ├── chat_screen.dart      # 主聊天界面
│   ├── conversation_list_screen.dart  # 对话历史记录
│   ├── settings_screen.dart  # 应用设置
│   ├── user_profile_screen.dart  # 用户配置管理
│   ├── about_screen.dart     # 关于页面，显示应用信息
│   └── image_preview_screen.dart  # 图片预览和查看
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
│   └── deepseek_provider.dart # DeepSeek 实现
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

### 服务

- `AIService`: 处理与 OpenAI、Google Gemini 和 DeepSeek API 的通信，包括请求格式化、响应解析和多模态支持
- `ConversationService`: 管理本地对话存储和检索
- `SettingsService`: 管理应用程序设置和配置
- `UserService`: 管理用户配置数据
- `FileService`: 处理文件操作，包括读取、处理和从附件中提取内容
- `PromptService`: 管理提示词预设数据和配置

### AI 提供商

该应用程序使用基于提供商的架构进行 AI 集成：

- `AIProvider`: 抽象基类，定义所有 AI 提供商的接口
- `OpenAIProvider`: OpenAI API 实现，支持多模态
- `GeminiProvider`: Google Gemini API 实现，支持多模态
- `DeepSeekProvider`: DeepSeek API 实现，支持文本流式传输

这种架构允许轻松添加新的 AI 提供商，同时保持所有提供商之间的一致接口。

## 配置

在使用应用程序之前，需要配置您的 AI API 密钥：

1. 导航到设置界面
2. 输入您的密钥
3. 选择您偏好的 AI 提供商（OpenAI、Gemini 或 DeepSeek）
4. 可选地调整模型参数（模型、温度、最大 tokens 数）

### 支持的 AI 提供商

1. **OpenAI**
   - API 端点：`https://api.openai.com/v1`
   - 支持的模型：GPT-5.1、GPT-4o 和其他 OpenAI 模型
   - 图像、视频和音频的多模态支持

2. **Google Gemini**
   - API 端点：`https://generativelanguage.googleapis.com/v1beta/models/{model}:generateContent`
   - 支持的模型：Gemini 3 Pro Preview、Gemini 3 Flash Preview
   - 多模态能力

3. **DeepSeek**
   - API 端点：`https://api.deepseek.com`
   - 支持的模型：DeepSeek Chat、DeepSeek Coder
   - 文本流式传输支持

### 默认值

- 默认提供商：OpenAI
- 默认模型：`gpt-5`（OpenAI）、`gemini-2.5-flash`（Gemini）或 `deepseek-chat`（DeepSeek）
- 温度：`0.7`
- 最大 Tokens 数：`1000`

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

LumenFlow 提供设置导出和导入功能，用于备份和恢复应用配置。

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