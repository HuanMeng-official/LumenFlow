# LumenFlow

> 一个基于 Flutter 的 AI 聊天应用程序，集成了 OpenAI 的 API，提供对话式 AI 功能。

[English Version](../README.md) [中文版本](./README.zh_CN.md)

## 项目结构

```
lib/
├── main.dart                 # 应用程序入口点
├── models/                   # 数据模型
│   ├── conversation.dart     # 对话模型
│   ├── message.dart          # 消息模型
│   └── user_profile.dart     # 用户配置文件模型
├── screens/                  # UI 屏幕
│   ├── chat_screen.dart      # 主要聊天界面
│   ├── conversation_list_screen.dart
│   ├── settings_screen.dart
│   └── user_profile_screen.dart
├── services/                 # 业务逻辑和 API 集成
│   ├── ai_service.dart       # OpenAI API 集成
│   ├── conversation_service.dart
│   ├── settings_service.dart
│   └── user_service.dart
└── widgets/                  # 可重用的 UI 组件
    ├── avatar_widget.dart
    ├── chat_input.dart
    └── message_bubble.dart
```

## 主要功能

- 与 AI 模型实时聊天（默认使用 GPT-5）
- 管理对话历史记录
- 用户配置文件自定义
- 可配置的 AI 参数（temperature，max tokens 等）
- 使用 SharedPreferences 实现本地数据持久化
- 为 AI 响应渲染 Markdown

## 依赖项

- [Flutter](https://flutter.dev/) - UI 框架
- [http](https://pub.dev/packages/http) - 用于 API 请求的 HTTP 客户端
- [shared_preferences](https://pub.dev/packages/shared_preferences) - 持久化存储
- [intl](https://pub.dev/packages/intl) - 国际化和本地化
- [flutter_markdown](https://pub.dev/packages/flutter_markdown) - Markdown 渲染
- [image_picker](https://pub.dev/packages/image_picker) - 图片选择
- [path_provider](https://pub.dev/packages/path_provider) - 路径解析
- [path](https://pub.dev/packages/path) - 路径操作

## 架构

该应用程序遵循分层架构模式：

1. **Models（模型）**: 定义整个应用程序使用的数据结构
2. **Services（服务）**: 处理业务逻辑、API 集成和数据持久化
3. **Screens（屏幕）**: 表示整个屏幕的高阶 UI 组件
4. **Widgets（小部件）**: 可重用的 UI 组件

### 数据模型

- `Conversation`: 表示具有元数据和消息列表的聊天对话
- `Message`: 表示具有内容、发送者信息和状态的单个消息
- `UserProfile`: 存储用户特定的设置和偏好

### 服务

- `AIService`: 处理与 OpenAI API 的通信，包括请求格式化和响应解析
- `ConversationService`: 管理本地对话存储和检索
- `SettingsService`: 管理应用设置和配置
- `UserService`: 管理用户配置文件数据

## 配置

在使用应用程序之前，需要使用您的 OpenAI API 密钥进行配置：

1. 导航到设置屏幕
2. 输入您的 OpenAI API 密钥
3. 可选地调整模型参数（模型、temperature、max tokens）

应用程序使用以下默认值：
- API 端点：`https://api.openai.com/v1`
- 模型：`gpt-5`
- Temperature：`0.7`
- 最大 Tokens：`1000`

## 构建

要构建应用程序，请确保已安装并设置好 Flutter：

```bash
flutter pub get
flutter build apk        # 用于 Android
```

## 数据存储

该应用程序使用 `shared_preferences` 进行本地数据存储：
- 用户设置和 API 密钥
- 对话历史
- 用户配置信息

所有数据都存储在设备本地，不会在设备之间同步。

## 错误处理

该应用程序包含以下错误处理：
- 网络连接问题
- API 错误（无效密钥、速率限制等）
- 数据解析错误

错误信息会通过 UI 显示给用户，通常是在聊天界面或警报中显示。
