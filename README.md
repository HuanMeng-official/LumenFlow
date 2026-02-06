# LumenFlow

> A cross-platform AI chat application built with Flutter, supporting 10+ AI platforms with SQLite-based local storage and comprehensive conversation management.

[English Version](./README.md) | [中文版本](./README/README.zh_CN.md)

## Overview

LumenFlow (Chinese: 流光) is a modern AI chat application built with Flutter that provides a seamless conversational experience across Android, Windows, and Linux platforms. With support for 10+ AI service providers, SQLite database for local data persistence, and rich multi-modal capabilities, it offers a versatile AI assistant experience.

- **License**: MIT
- **Platforms**: Android, Windows, Linux
- **Languages**: Dart/Flutter

## Features

### Core AI Capabilities
- **10+ AI Platform Support**: OpenAI, Claude, Google Gemini, DeepSeek, SiliconFlow, MiniMax, Zhipu AI, Kimi, LM-Studio (local deployment), and Other (custom OpenAI-compatible APIs)
- **Provider Pattern Architecture**: Clean abstraction layer for AI providers with unified interface
- **Multi-AI Platform Management**: Configure and manage multiple AI platforms simultaneously with independent settings, model lists, and platform-specific configurations
- **Streaming Responses**: Real-time streaming output for responsive chat experience
- **Thinking Mode**: AI thinking process visualization for supported models
- **Auto Title Generation**: Automatic conversation title generation based on content

### Data Management
- **SQLite Database**: High-performance local data persistence using sqlite3
- **Conversation Management**: Complete conversation history with local storage and intelligent caching
- **Data Migration**: Automatic migration from SharedPreferences to SQLite
- **Export/Import**: Multiple format support including TXT, JSON, PDF, and LumenFlow format ([LumenFlowFormatSpecification](./LumenFlowFormatSpecification.md))

### User Experience
- **Multi-Modal Support**: Process images, videos, and audio files with vision capabilities
- **File Attachments**: Upload and extract content from various file types
- **User Profiles**: Personalized settings with avatar and username customization
- **Prompt Preset System**: Pre-configured role-playing prompts with rich character settings
- **Multi-Language Presets**: Automatic language-specific preset loading based on interface language
- **Theme Management**: Support for light/dark theme switching with system theme following
- **Internationalization**: Full English, Chinese, Japanese, and Korean language support

### Technical Features
- **Local Notifications**: Real-time notification support for important events using `flutter_local_notifications`
- **Markdown Rendering**: Beautifully formatted AI responses with code block copy functionality using `flutter_markdown_plus`
- **Code Block Copy**: One-click copy functionality for code blocks in AI responses
- **Message Copy**: One-click copy functionality for entire messages
- **Performance Optimizations**: Reduced repaints and optimized chat performance with debouncing
- **Retry Mechanism**: Automatic retry with exponential backoff for network errors
- **Error Handling**: Comprehensive error handling with localized error messages in all supported languages
- **Database Transactions**: ACID-compliant SQLite operations with foreign key constraints

## Project Structure

```
lib/
├── main.dart                 # Application entry point
├── l10n/                     # Internationalization files
│   ├── app_en.arb           # English translations
│   ├── app_zh.arb           # Chinese translations
│   ├── app_ja.arb           # Japanese translations
│   ├── app_ko.arb           # Korean translations
│   ├── app_localizations.dart # Localization class
│   └── app_localizations_*.dart # Language-specific implementations
├── models/                   # Data models
│   ├── conversation.dart     # Conversation model
│   ├── message.dart          # Message model
│   ├── user_profile.dart     # User profile model
│   ├── attachment.dart       # Attachment model (files, images, etc.)
│   ├── prompt_preset.dart    # Prompt preset model
│   └── ai_platform.dart      # AI platform configuration model
├── screens/                  # UI screens
│   ├── chat_screen.dart      # Main chat interface
│   ├── conversation_list_screen.dart  # Conversation history
│   ├── settings_screen.dart  # Application settings
│   ├── user_profile_screen.dart  # User profile management
│   ├── about_screen.dart     # About page with app information
│   ├── image_preview_screen.dart  # Image preview and viewing
│   ├── platform_settings_screen.dart  # AI platform and model configuration
│   ├── api_settings_screen.dart       # API settings
│   ├── appearance_settings_screen.dart # Appearance settings
│   ├── conversation_settings_screen.dart # Conversation settings
│   ├── model_settings_screen.dart    # Model settings
│   └── advanced_settings_screen.dart # Advanced settings
├── services/                 # Business logic and API integration
│   ├── ai_service.dart       # AI service integration
│   ├── conversation_service.dart  # Conversation management
│   ├── settings_service.dart # Settings management
│   ├── conversation_database.dart   # SQLite database service
│   ├── user_service.dart     # User profile management
│   ├── file_service.dart     # File handling and processing
│   ├── prompt_service.dart   # Prompt preset management
│   ├── notification_service.dart # Notification service
│   ├── version_service.dart  # Version information management
│   └── live_update_service.dart # Live update service
├── providers/                # AI provider implementations
│   ├── ai_provider.dart     # Abstract base class
│   ├── openai_provider.dart # OpenAI implementation
│   ├── gemini_provider.dart # Gemini implementation
│   ├── deepseek_provider.dart # DeepSeek implementation
│   ├── claude_provider.dart   # Claude (Anthropic) implementation
│   ├── siliconflow_provider.dart # SiliconFlow implementation
│   ├── minimax_provider.dart  # MiniMax implementation
│   ├── zhipu_provider.dart    # Zhipu AI implementation
│   ├── kimi_provider.dart     # Kimi implementation
│   ├── lmstudio_provider.dart # LM-Studio (local) implementation
│   └── other_provider.dart    # Other (OpenAI-compatible) implementation
├── utils/                    # Utility classes
│   └── app_theme.dart        # Application theme management
└── widgets/                  # Reusable UI components
    ├── avatar_widget.dart    # User avatar display
    ├── chat_input.dart       # Chat input with file attachment
    ├── message_bubble.dart   # Message display bubble
    └── settings/             # Settings UI components
        ├── settings_action_tile.dart
        ├── settings_dropdown_tile.dart
        ├── settings_input_tile.dart
        ├── settings_navigation_tile.dart
        ├── settings_section.dart
        ├── settings_slider_tile.dart
        └── settings_switch_tile.dart
```

## Dependencies

### Core Framework
- [Flutter](https://flutter.dev/) - UI framework
- [cupertino_icons](https://pub.dev/packages/cupertino_icons) - iOS-style icons

### Networking & Data
- [http](https://pub.dev/packages/http) ^1.6.0 - HTTP client for API requests
- [sqlite3](https://pub.dev/packages/sqlite3) ^3.1.4 - SQLite database for local storage with foreign key support
- [shared_preferences](https://pub.dev/packages/shared_preferences) ^2.5.4 - Legacy persistent storage (for migration)

### File Handling
- [image_picker](https://pub.dev/packages/image_picker) ^1.2.1 - Image selection from gallery/camera
- [file_picker](https://pub.dev/packages/file_picker) ^10.3.8 - File selection and picking with multiple file support
- [path_provider](https://pub.dev/packages/path_provider) ^2.1.5 - Platform-specific path resolution
- [path](https://pub.dev/packages/path) ^1.9.1 - Cross-platform path manipulation
- [pdf](https://pub.dev/packages/pdf) ^3.11.3 - PDF file generation and processing for export
- [archive](https://pub.dev/packages/archive) ^4.0.7 - Archive file (ZIP) creation and extraction for data export

### UI & Internationalization
- [flutter_markdown_plus](https://pub.dev/packages/flutter_markdown_plus) ^1.0.7 - Enhanced Markdown rendering with code block copy support
- [flutter_localizations](https://api.flutter.dev/flutter/flutter_localizations/flutter_localizations-library.html) - Flutter built-in localization support
- [intl](https://pub.dev/packages/intl) any - Internationalization and localization with ARB files
- [flutter_svg](https://pub.dev/packages/flutter_svg) ^2.2.3 - SVG image rendering for platform icons and UI elements

### Utilities
- [url_launcher](https://pub.dev/packages/url_launcher) ^6.3.2 - URL launching support for external links
- [flutter_local_notifications](https://pub.dev/packages/flutter_local_notifications) ^19.5.0 - Local notifications for important events

## Architecture

The application follows a layered architecture pattern:

1. **Models**: Define the data structures used throughout the application
2. **Services**: Handle business logic, API integrations, and data persistence
3. **Screens**: High-level UI components that represent entire screens
4. **Widgets**: Reusable UI components
5. **Providers**: AI provider implementations with abstract interface
6. **Localization**: Internationalization support with ARB files

### Data Models

- `Conversation`: Represents a chat conversation with metadata and a list of messages
- `Message`: Represents a single message with content, sender information, and status
- `UserProfile`: Stores user-specific settings and preferences
- `Attachment`: Represents file attachments (images, videos, audio, documents) with metadata
- `PromptPreset`: Represents pre-configured prompt presets with role-playing character settings
- `AIPlatform`: Represents AI platform configuration with API endpoints, models, and platform-specific settings

### Services

- `AIService`: Handles communication with multiple AI providers, including request formatting, response parsing, and multi-modal support
- `ConversationService`: Manages local conversation storage and retrieval using SQLite
- `SettingsService`: Manages application settings and configuration, including multi-AI platform management
- `ConversationDatabase`: SQLite database implementation with automatic migration from SharedPreferences
- `UserService`: Manages user profile data
- `FileService`: Handles file operations, including reading, processing, and extracting content from attachments
- `PromptService`: Manages prompt preset data and configuration
- `NotificationService`: Handles local notifications
- `VersionService`: Version information management
- `LiveUpdateService`: Real-time application updates

### AI Providers

The application uses a provider-based architecture for AI integration:

- `AIProvider`: Abstract base class defining the interface for all AI providers
- `OpenAIProvider`: Implementation for OpenAI API with multi-modal support
- `GeminiProvider`: Implementation for Google Gemini API with multi-modal support
- `DeepSeekProvider`: Implementation for DeepSeek API with streaming capabilities
- `ClaudeProvider`: Implementation for Claude (Anthropic) API with multi-modal and thinking mode
- `SiliconFlowProvider`: Implementation for SiliconFlow API
- `MiniMaxProvider`: Implementation for MiniMax API
- `ZhipuProvider`: Implementation for Zhipu AI API
- `KimiProvider`: Implementation for Kimi API
- `LMStudioProvider`: Implementation for LM-Studio (local deployment) with OpenAI Responses API
- `OtherProvider`: Implementation for OpenAI-compatible APIs (custom endpoints)

This architecture allows for easy addition of new AI providers while maintaining a consistent interface across all providers.

### SQLite Database Architecture

The application uses SQLite for local data persistence with the following features:

- **Single Instance**: Global database connection with synchronized write operations
- **Foreign Key Constraints**: Ensures data integrity with cascade delete
- **Automatic Migration**: Seamless data migration from SharedPreferences to SQLite
- **Indexing**: Optimized queries with indexes on frequently accessed fields
- **Transaction Support**: ACID-compliant operations for data consistency

**Database Schema**:
- `conversations`: Stores conversation metadata (id, title, timestamps)
- `messages`: Stores messages with conversation reference and status
- `attachments`: Stores file attachments with message reference
- `settings`: Stores application settings and metadata

### Multi-AI Platform Management

LumenFlow supports managing multiple AI platforms simultaneously. Each platform can have its own configuration, model lists, and settings. Key features include:

- **Multiple Platform Support**: Configure and manage 10+ AI platforms in a single application
- **Platform Switching**: Easily switch between configured platforms during conversations
- **Model Management**: Each platform maintains its own model list, with support for automatic model list fetching
- **Platform Icons**: Visual identification with platform-specific SVG icons
- **Configuration Migration**: Automatic migration from legacy single-platform configuration to multi-platform configuration
- **Platform-Specific Settings**: Each platform can have independent API endpoints, authentication methods, and model parameters

The platform management interface is accessible through the "Platform & Models" section in the settings screen.

## Configuration

Before using the application, you need to configure at least one AI platform with your API keys:

1. Navigate to the Settings screen
2. Select "Platform & Models" to access platform configuration
3. Add a new platform or edit an existing one
4. Enter the platform name, API endpoint, and API key
5. Configure model parameters (default model, temperature, max tokens)
6. Save the platform configuration
7. Set the platform as active for use in conversations

You can configure multiple platforms and switch between them as needed.

### Supported AI Providers

1. **OpenAI**
   - API Endpoint: `https://api.openai.com/v1/responses`
   - Supported models: GPT-5.2, GPT-o3, and other OpenAI models
   - Multi-modal support for images, videos, and audio

2. **Google Gemini**
   - API Endpoint: `https://generativelanguage.googleapis.com/v1beta/models/{model}:generateContent`
   - Supported models: Gemini 3 Flash, Gemini 3 Pro
   - Multi-modal capabilities

3. **DeepSeek**
   - API Endpoint: `https://api.deepseek.com/chat/completions`
   - Supported models: DeepSeek-V3.2
   - Text-only support with streaming capabilities

4. **Claude (Anthropic)**
   - API Endpoint: `https://api.anthropic.com/v1/messages`
   - Supported models: Claude Sonnet 4.5, Claude Opus 4.5
   - Multi-modal support for images with thinking mode capability

5. **SiliconFlow**
   - API Endpoint: `https://api.siliconflow.cn/v1/chat/completions`
   - Supported models: Various open-source models (Qwen, DeepSeek, etc.)
   - Text-only support

6. **MiniMax**
   - API Endpoint: `https://api.minimax.chat/v1/chat/completions`
   - Supported models: MiniMax proprietary models
   - Text-only support

7. **Zhipu AI**
   - API Endpoint: `https://open.bigmodel.cn/api/paas/v4/chat/completions`
   - Supported models: GLM series models
   - Text-only support

8. **Kimi**
   - API Endpoint: `https://api.moonshot.cn/v1/chat/completions`
   - Supported models: Kimi models
   - Text-only support with long context capabilities

9. **LM-Studio (Local)**
   - API Endpoint: Custom local endpoint (default: `http://localhost:1234/v1`)
   - Supported models: Local LLMs hosted via LM-Studio
   - Uses OpenAI Responses API format

10. **Other (Custom API)**
    - API Endpoint: `https://URL/v1/chat/completions`
    - Supported models: User-defined model list
    - OpenAI chat completions format compatibility

### Default Values

When configuring a new platform, the following default values are used:

- **Default Platform Type**: OpenAI
- **Default Models**:
  - OpenAI：`gpt-5`
  - Gemini：`gemini-3-flash-preview`
  - DeepSeek：`deepseek-chat`
  - Claude：`claude-sonnet-4.5`
  - SiliconFlow：`Qwen/Qwen2.5-32B-Instruct`
  - MiniMax：`MiniMax-M2.1`
  - 智谱AI：`glm-4.7`
  - Kimi：`moonshot-k2`
  - LM-Studio：`local-model`
- **Temperature**: `0.7`
- **Max Tokens**: `4096`

Note: These defaults apply when creating a new platform configuration. You can customize these values for each platform independently.

### Prompt Presets

LumenFlow includes an advanced role-playing system with file-based prompt presets that support multiple languages. The system automatically loads the appropriate language version based on the user's selected interface language.

#### How It Works
- **Multi-Language Support**: Presets are available in English, Chinese, Japanese, and Korean versions
- **Automatic Language Detection**: The system automatically loads presets based on the current interface language setting
- **File-Based Presets**: The `system_prompt` field in preset files points to XML/TXT files (e.g., `"characters/zh/NingXi.xml"`)
- **Automatic Content Loading**: The system automatically loads the file content and uses it as the system prompt
- **Variable Substitution**: Supports `\${userProfile.username}` replacement with actual user names
- **XML Format**: Rich XML structure for detailed character definitions with meta information, personality logic, addressing protocols, and example dialogues

#### Using Presets
1. Navigate to the chat interface
2. Click the "Role-Play" button and select a character from the preset menu
3. The selected character's complete personality system will be applied to the conversation
4. AI responses will reflect the character's traits, speech patterns, and behaviors in the selected language

#### Customizing & Adding Presets
1. Create XML/TXT files in the appropriate language directory (`assets/prompt/characters/zh/` for Chinese, `assets/prompt/characters/en/` for English, etc.)
2. Add entries to the corresponding presets JSON file with `system_prompt` pointing to the correct file path
3. Follow the XML format structure for consistent character definitions
4. Restart the application to load new presets

##### Example presets-*.json Structure
```json
{
  "id": "ningxi",
  "name": "NingXi",
  "description": "A playful, adorable cat-girl",
  "system_prompt": "characters/zh(or en)/NingXi.xml",
  "icon": "person.fill"
}
```
##### Example character.xml Structure
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

## Data Storage

### SQLite Database

The application uses SQLite for local data storage, providing high performance and reliability:

- **Location**: Platform-specific data directory
  - Android: Application documents directory (`conversations.db`)
  - Windows/Linux: User home directory (`.lumenflow/conversations.db`)
- **Tables**:
  - `conversations`: Stores conversation metadata
  - `messages`: Stores message content and metadata
  - `attachments`: Stores file attachment information
  - `settings`: Stores application settings
- **Features**:
  - Foreign key constraints for data integrity
  - Automatic migration from legacy SharedPreferences
  - Transaction support for data consistency
  - Indexed queries for optimal performance

**Stored Data**:
- User settings and API keys
- Conversation history with full message content
- User profile information
- Attachment metadata and file references

All data is stored locally on the device and is not synchronized across devices.

### Data Migration

The application automatically migrates data from SharedPreferences to SQLite on first launch. This ensures:

- Seamless transition from previous versions
- No data loss during migration
- Transaction-based migration with rollback on failure

## Settings Management

LumenFlow provides settings export and import functionality to backup and restore your application configuration.

### Exporting Settings
1. Navigate to the Settings screen
2. Scroll to the "Data Management" section
3. Tap "Export Settings"
4. Choose a location to save the JSON file
5. Your settings (including API keys, preferences, and user profile) will be saved

### Importing Settings
1. Navigate to the Settings screen
2. Scroll to the "Data Management" section
3. Tap "Import Settings"
4. Select a previously exported JSON file
5. Confirm to restore settings from the file

### Resetting to Default
1. Navigate to the Settings screen
2. Scroll to the "Data Management" section
3. Tap "Restore Default Settings"
4. Confirm to reset all settings to default values

**Note**: API keys and sensitive information are included in exported files. Keep these files secure.

## Internationalization

LumenFlow supports English, Chinese, Japanese, and Korean languages. The application automatically detects the system language or allows manual selection in settings. All interface elements, AI responses, and prompt presets are fully localized.

### Language Support
- **English**: Complete English localization for all interface elements and AI responses
- **Chinese**: Complete Chinese localization for all interface elements and AI responses
- **Japanese**: Complete Japanese localization for all interface elements and AI responses
- **Korean**: Complete Korean localization for all interface elements and AI responses

### Implementation
- Uses Flutter's built-in localization system with ARB files
- AI responses are localized based on selected language
- Prompt presets automatically load the appropriate language version
- Character definitions are available in multiple languages with separate XML files

## Building

To build the application, ensure you have Flutter installed and set up:

```bash
# Install dependencies
flutter pub get

# Build for Android (APK with ABI splitting)
flutter build apk --split-per-abi

# Build for Windows (Release mode)
flutter build windows --release

# Build for Linux (Release mode)
flutter build linux --release
```

### Using Build Scripts

The project includes platform-specific build scripts:

**Windows (PowerShell)**:
```powershell
# Build Android APK
.\build_apk.ps1

# Build Windows EXE
.\build_exe.ps1
```

**Linux (Bash)**:
```bash
# Build Linux ELF
./build_elf.sh
```

These scripts handle the specific build configurations for each platform.

## Error Handling

The application includes comprehensive error handling implemented in `AIService._handleError()`:

- **Network Errors**: Timeouts, connection failures, socket errors, TLS/SSL handshake failures
- **API Errors**: Invalid API keys, rate limits, quota exceeded, model not found
- **Data Errors**: JSON parsing errors, invalid response formats
- **File Errors**: File size limits, unsupported file types, extraction failures
- **Database Errors**: SQLite constraints, transaction failures, migration errors
- **Localization Errors**: Missing translations, format errors

**Error Handling Features**:
- Localized error messages in all supported languages (English, Chinese, Japanese, Korean)
- User-friendly error messages that hide technical details
- Automatic retry with exponential backoff for network errors
- Graceful degradation when features are unavailable
- Comprehensive logging for debugging purposes

Errors are displayed to users through localized UI messages in the chat interface or as system alerts.

## License

This project is licensed under the MIT License. See the [LICENSE](LICENSE) file for details.

## Contributing

Contributions are welcome! Please feel free to submit issues and pull requests for improvements, bug fixes, or new features.

## Acknowledgments

- Built with [Flutter](https://flutter.dev/)
- AI capabilities powered by [OpenAI](https://openai.com/), [Google Gemini](https://gemini.google.com/), [Claude](https://www.anthropic.com/), [DeepSeek](https://www.deepseek.com/), [SiliconFlow](https://www.siliconflow.cn/), [MiniMax](https://www.minimaxi.com/), [Zhipu AI](https://www.zhipuai.cn/), [Kimi](https://kimi.moonshot.cn/), and LM-Studio
- Internationalization support using Flutter's localization system
- Icons provided by [Cupertino Icons](https://pub.dev/packages/cupertino_icons)

## Sponsor

![Sponsor Code](./assets/collection_code.png)

If you find this app helpful, please scan the code to sponsor and support development.
