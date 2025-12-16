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
- **跨平台**: 支持 Android 和 Windows 平台
- **本地存储**: 使用 SharedPreferences 实现数据持久化
- **Markdown渲染**: 美观格式化的 AI 响应

## 项目结构

```
lib/
├── main.dart                 # 应用程序入口点
├── models/                   # 数据模型
│   ├── conversation.dart     # 对话模型
│   ├── message.dart          # 消息模型
│   ├── user_profile.dart     # 用户配置模型
│   └── attachment.dart       # 附件模型（文件、图像等）
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
│   └── file_service.dart     # 文件处理和操作
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

### 服务

- `AIService`: 处理与 OpenAI 和 Google Gemini API 的通信，包括请求格式化、响应解析和多模态支持
- `ConversationService`: 管理本地对话存储和检索
- `SettingsService`: 管理应用程序设置和配置
- `UserService`: 管理用户配置数据
- `FileService`: 处理文件操作，包括读取、处理和从附件中提取内容

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