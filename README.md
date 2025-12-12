# LumenFlow

> A cross-platform AI chat application built with Flutter, supporting OpenAI and Google Gemini APIs with multi-modal capabilities.

[English Version](./README.md) | [中文版本](./README/README.zh_CN.md)

## Overview

LumenFlow (Chinese: 流光) is a modern AI chat application built with Flutter that provides a seamless conversational experience across Android and Windows platforms. With support for both OpenAI and Google Gemini APIs, along with multi-modal file processing capabilities, it offers a versatile AI assistant experience.

- **Version**: 1.0.3+1
- **License**: MIT
- **Platforms**: Android, Windows
- **Languages**: Dart/Flutter

## Features

- **Multi-AI Model Support**: Seamlessly switch between OpenAI and Google Gemini APIs
- **Multi-Modal Support**: Process images, videos, and audio files with vision capabilities
- **Streaming Responses**: Real-time streaming output for responsive chat experience
- **File Attachments**: Upload and extract content from various file types
- **Conversation Management**: Complete conversation history with local persistence
- **User Profiles**: Personalized settings and preferences
- **Cross-Platform**: Supports Android and Windows platforms
- **Local Storage**: Data persistence using SharedPreferences
- **Markdown Rendering**: Beautifully formatted AI responses

## Project Structure

```
lib/
├── main.dart                 # Application entry point
├── models/                   # Data models
│   ├── conversation.dart     # Conversation model
│   ├── message.dart          # Message model
│   ├── user_profile.dart     # User profile model
│   └── attachment.dart       # Attachment model (files, images, etc.)
├── screens/                  # UI screens
│   ├── chat_screen.dart      # Main chat interface
│   ├── conversation_list_screen.dart  # Conversation history
│   ├── settings_screen.dart  # Application settings
│   └── user_profile_screen.dart  # User profile management
├── services/                 # Business logic and API integration
│   ├── ai_service.dart       # AI service (OpenAI & Gemini integration)
│   ├── conversation_service.dart  # Conversation management
│   ├── settings_service.dart # Settings management
│   ├── user_service.dart     # User profile management
│   └── file_service.dart     # File handling and processing
└── widgets/                  # Reusable UI components
    ├── avatar_widget.dart    # User avatar display
    ├── chat_input.dart       # Chat input with file attachment
    └── message_bubble.dart   # Message display bubble
```


## Dependencies

- [Flutter](https://flutter.dev/) - UI framework
- [cupertino_icons](https://pub.dev/packages/cupertino_icons) - iOS-style icons
- [http](https://pub.dev/packages/http) - HTTP client for API requests
- [shared_preferences](https://pub.dev/packages/shared_preferences) - Persistent storage
- [intl](https://pub.dev/packages/intl) - Internationalization and localization
- [flutter_markdown](https://pub.dev/packages/flutter_markdown) - Markdown rendering
- [image_picker](https://pub.dev/packages/image_picker) - Image selection
- [file_picker](https://pub.dev/packages/file_picker) - File selection and picking
- [path_provider](https://pub.dev/packages/path_provider) - Path resolution
- [path](https://pub.dev/packages/path) - Path manipulation

## Architecture

The application follows a layered architecture pattern:

1. **Models**: Define the data structures used throughout the application
2. **Services**: Handle business logic, API integrations, and data persistence
3. **Screens**: High-level UI components that represent entire screens
4. **Widgets**: Reusable UI components

### Data Models

- `Conversation`: Represents a chat conversation with metadata and a list of messages
- `Message`: Represents a single message with content, sender information, and status
- `UserProfile`: Stores user-specific settings and preferences
- `Attachment`: Represents file attachments (images, videos, audio, documents) with metadata

### Services

- `AIService`: Handles communication with OpenAI and Google Gemini APIs, including request formatting, response parsing, and multi-modal support
- `ConversationService`: Manages local conversation storage and retrieval
- `SettingsService`: Manages application settings and configuration
- `UserService`: Manages user profile data
- `FileService`: Handles file operations, including reading, processing, and extracting content from attachments

## Configuration

Before using the application, you need to configure it with your AI API keys:

1. Navigate to the Settings screen
2. Enter your OpenAI API key and/or Google Gemini API key
3. Select your preferred AI provider (OpenAI or Gemini)
4. Optionally adjust model parameters (model, temperature, max tokens)

### Supported AI Providers

1. **OpenAI**
   - API Endpoint: `https://api.openai.com/v1`
   - Supported models: GPT-5.1, GPT-4o, and other OpenAI models
   - Multi-modal support for images, videos, and audio

2. **Google Gemini**
   - API Endpoint: `https://generativelanguage.googleapis.com/v1`
   - Supported models: Gemini Pro, Gemini Ultra
   - Multi-modal capabilities

### Default Values

- Default Provider: OpenAI
- Default Model: `gpt-5` (OpenAI) or `gemini-2.5-flash` (Gemini)
- Temperature: `0.7`
- Max Tokens: `1000`

## Building

To build the application, ensure you have Flutter installed and set up:

```bash
# Install dependencies
flutter pub get

# Build for Android (APK with ABI splitting)
flutter build apk --split-per-abi

# Build for Windows (Release mode)
flutter build windows --release
```

### Using Build Script

Alternatively, use the provided PowerShell build script for Windows:

```powershell
.\build.ps1
```

This script will build both Android APK and Windows EXE packages automatically.

## Data Storage

The application uses `shared_preferences` for local data storage:
- User settings and API keys
- Conversation history
- User profile information

All data is stored locally on the device and is not synchronized across devices.

## Error Handling

The application includes error handling for:
- Network connectivity issues
- API errors (invalid keys, rate limits, etc.)
- Data parsing errors

Errors are displayed to the user through the UI, typically in the chat interface or as alerts.

## License

This project is licensed under the MIT License. See the [LICENSE](LICENSE) file for details.

## Contributing

Contributions are welcome! Please feel free to submit issues and pull requests for improvements, bug fixes, or new features.

## Acknowledgments

- Built with [Flutter](https://flutter.dev/)
- AI capabilities powered by [OpenAI](https://openai.com/) and [Google Gemini](https://gemini.google.com/)
- Icons provided by [Cupertino Icons](https://pub.dev/packages/cupertino_icons)
