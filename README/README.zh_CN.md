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
- **主题管理**: 支持亮色/暗色主题切换
- **跨平台**: 支持 Android 和 Windows 平台
- **本地存储**: 使用 SharedPreferences 实现数据持久化
- **Markdown渲染**: 美观格式化的 AI 响应
- **PowerShell构建脚本**: 自动构建 Android 和 Windows 应用的脚本

## 项目结构

```
lib/
├── main.dart                 # 应用程序入口点
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
│   └── user_profile_screen.dart  # 用户配置管理
├── services/                 # 业务逻辑和 API 集成
│   ├── ai_service.dart       # AI 服务（OpenAI 和 Gemini 集成）
│   ├── conversation_service.dart  # 对话管理
│   ├── settings_service.dart # 设置管理
│   ├── user_service.dart     # 用户配置管理
│   ├── file_service.dart     # 文件处理和操作
│   └── prompt_service.dart   # 预设提示词管理
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

## 架构

该应用程序遵循分层架构模式：

1. **模型层**: 定义整个应用程序使用的数据结构
2. **服务层**: 处理业务逻辑、API 集成和数据持久化
3. **界面层**: 表示整个屏幕的高级 UI 组件
4. **组件层**: 可重用的 UI 组件

### 数据模型

- `Conversation`: 表示带有元数据和消息列表的聊天对话
- `Message`: 表示带有内容、发送者信息和状态的单个消息
- `UserProfile`: 存储用户特定的设置和偏好
- `Attachment`: 表示文件附件（图像、视频、音频、文档）及其元数据
- `PromptPreset`: 表示预配置的提示词预设，包含角色扮演角色设置

### 服务

- `AIService`: 处理与 OpenAI 和 Google Gemini API 的通信，包括请求格式化、响应解析和多模态支持
- `ConversationService`: 管理本地对话存储和检索
- `SettingsService`: 管理应用程序设置和配置
- `UserService`: 管理用户配置数据
- `FileService`: 处理文件操作，包括读取、处理和从附件中提取内容
- `PromptService`: 管理提示词预设数据和配置

## 配置

在使用应用程序之前，需要配置您的 AI API 密钥：

1. 导航到设置界面
2. 输入您的 OpenAI API 密钥和/或 Google Gemini API 密钥
3. 选择您偏好的 AI 提供商（OpenAI 或 Gemini）
4. 可选地调整模型参数（模型、温度、最大 tokens 数）

### 支持的 AI 提供商

1. **OpenAI**
   - API 端点：`https://api.openai.com/v1`
   - 支持的模型：GPT-5.1、GPT-4o 和其他 OpenAI 模型
   - 图像、视频和音频的多模态支持

2. **Google Gemini**
   - API 端点：`https://generativelanguage.googleapis.com/v1`
   - 支持的模型：Gemini Pro、Gemini Ultra
   - 多模态能力

### 默认值

- 默认提供商：OpenAI
- 默认模型：`gpt-5`（OpenAI）或 `gemini-2.5-flash`（Gemini）
- 温度：`0.7`
- 最大 Tokens 数：`1000`

### 预设提示词（角色扮演系统）

LumenFlow 包含一个基于文件的高级角色扮演系统。预设配置在 `assets/prompt/presets.json` 中，其中 `system_prompt` 字段包含指向 XML/TXT 文件的路径，这些文件包含详细的角色定义。

#### 工作原理
- **基于文件的预设**：`presets.json` 中的 `system_prompt` 字段指向 XML/TXT 文件（例如：`"characters/NingXi.xml"`）
- **自动内容加载**：系统自动加载文件内容并将其用作系统提示词
- **变量替换**：支持 `\${userProfile.username}` 替换为实际用户名
- **XML 格式**：丰富的 XML 结构，用于详细的角色定义，包含元信息、个性逻辑、称呼协议和示例对话

#### 使用预设
1. 导航到聊天界面
2. 点击"角色扮演"按钮，从预设菜单中选择一个角色
3. 所选角色的完整个性系统将应用于对话
4. AI 回复将反映角色的特征、说话模式和行为

#### 自定义和添加预设
1. 在 `assets/prompt/characters/` 目录中创建包含角色定义的 XML/TXT 文件
2. 在 `presets.json` 中添加条目，`system_prompt` 指向文件路径
3. 遵循 XML 格式结构以保持角色定义的一致性
4. 重启应用程序以加载新的预设

##### presets.json 结构示例
```json
{
  "id": "ningxi",
  "name": "宁汐",
  "description": "俏皮可爱的猫娘",
  "system_prompt": "characters/NingXi.xml",
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
   <example_dialogue>TEXT</example_dialogue>
</system_instruction>
```

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

错误信息会通过 UI 显示给用户，通常在聊天界面或警报中显示。

## 许可证

本项目基于 MIT 许可证。详见 [LICENSE](../LICENSE) 文件。

## 贡献

欢迎贡献！欢迎提交问题报告和拉取请求，以改进、修复错误或添加新功能。

## 致谢

- 基于 [Flutter](https://flutter.dev/) 构建
- AI 能力由 [OpenAI](https://openai.com/) 和 [Google Gemini](https://gemini.google.com/) 提供支持
- 图标由 [Cupertino Icons](https://pub.dev/packages/cupertino_icons) 提供