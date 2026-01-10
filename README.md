# LumenFlow

> A cross-platform AI chat application built with Flutter, supporting OpenAI and Google Gemini APIs with multi-modal capabilities.

[English Version](./README.md) | [中文版本](./README/README.zh_CN.md)

## Overview

LumenFlow (Chinese: 流光) is a modern AI chat application built with Flutter that provides a seamless conversational experience across Android and Windows platforms. With support for both OpenAI and Google Gemini APIs, along with multi-modal file processing capabilities, it offers a versatile AI assistant experience.

- **License**: MIT
- **Platforms**: Android, Windows
- **Languages**: Dart/Flutter

## Features

- **Multi-AI Model Support**: Seamlessly switch between OpenAI, Google Gemini and Claude APIs
- **Multi-AI Platform Management**: Configure and manage multiple AI platforms with independent settings, model lists, and platform-specific configurations
- **Multi-Modal Support**: Process images, videos, and audio files with vision capabilities
- **Streaming Responses**: Real-time streaming output for responsive chat experience
- **File Attachments**: Upload and extract content from various file types
- **Conversation Management**: Complete conversation history with local persistence
- **User Profiles**: Personalized settings and preferences
- **Prompt Preset System**: Pre-configured role-playing prompts with rich character settings
- **Multi-Language Presets**: Automatic language-specific preset loading based on interface language
- **Theme Management**: Support for light/dark theme switching with system theme following
- **Cross-Platform**: Supports Android and Windows platforms
- **Local Storage**: Data persistence using SharedPreferences
- **Markdown Rendering**: Beautifully formatted AI responses
- **About Page**: Displays application information and copyright details
- **Settings Export/Import**: Backup and restore application settings via JSON files
- **Custom .lumenflow Format**: Enhanced settings export/import with metadata and version control (see [LumenFlow Format Specification](./LumenFlowFormatSpecification.md))
- **Role-Play System**: File-based prompt preset system with automatic content loading
- **PowerShell Build Script**: Automated build process for both Android and Windows
- **Internationalization**: Full English and Chinese language support
- **Thinking Mode**: AI thinking process visualization
- **Auto Title Generation**: Automatic conversation title generation

## Project Structure

```
lib/
├── main.dart                 # Application entry point
├── l10n/                     # Internationalization files
│   ├── app_en.arb           # English translations
│   ├── app_zh.arb           # Chinese translations
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
│   └── platform_settings_screen.dart  # AI platform and model configuration screen
├── services/                 # Business logic and API integration
│   ├── ai_service.dart       # AI service (OpenAI, Gemini & DeepSeek integration)
│   ├── conversation_service.dart  # Conversation management
│   ├── settings_service.dart # Settings management
│   ├── user_service.dart     # User profile management
│   ├── file_service.dart     # File handling and processing
│   ├── prompt_service.dart   # Prompt preset management
│   └── version_service.dart  # Version information management
├── providers/                # AI provider implementations
│   ├── ai_provider.dart     # Abstract base class
│   ├── openai_provider.dart # OpenAI implementation
│   ├── gemini_provider.dart # Gemini implementation
│   ├── deepseek_provider.dart # DeepSeek implementation
│   └── claude_provider.dart   # Claude (Anthropic) implementation
├── utils/                    # Utility classes
│   └── app_theme.dart        # Application theme management
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
- [flutter_localizations](https://api.flutter.dev/flutter/flutter_localizations/flutter_localizations-library.html) - Flutter localization support
- [flutter_svg](https://pub.dev/packages/flutter_svg) - SVG image rendering for platform icons
- [pdf](https://pub.dev/packages/pdf) - PDF file generation and processing
- [archive](https://pub.dev/packages/archive) - Archive file (ZIP) creation and extraction

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

- `AIService`: Handles communication with OpenAI, Google Gemini, and DeepSeek APIs, including request formatting, response parsing, and multi-modal support
- `ConversationService`: Manages local conversation storage and retrieval
- `SettingsService`: Manages application settings and configuration, including multi-AI platform management, configuration migration, and platform-specific settings
- `UserService`: Manages user profile data
- `FileService`: Handles file operations, including reading, processing, and extracting content from attachments
- `PromptService`: Manages prompt preset data and configuration

### AI Providers

The application uses a provider-based architecture for AI integration:

- `AIProvider`: Abstract base class defining the interface for all AI providers
- `OpenAIProvider`: Implementation for OpenAI API with multi-modal support
- `GeminiProvider`: Implementation for Google Gemini API with multi-modal support
- `DeepSeekProvider`: Implementation for DeepSeek API with text-only support
- `ClaudeProvider`: Implementation for Claude (Anthropic) API with multi-modal support

This architecture allows for easy addition of new AI providers while maintaining a consistent interface across all providers.

### Multi-AI Platform Management

LumenFlow now supports managing multiple AI platforms simultaneously. Each platform can have its own configuration, model lists, and settings. Key features include:

- **Multiple Platform Support**: Configure and manage multiple AI platforms (OpenAI, Claude, DeepSeek, Gemini) in a single application
- **Platform Switching**: Easily switch between configured platforms during conversations
- **Model Management**: Each platform maintains its own model list, with support for automatic model list fetching from APIs
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
   - API Endpoint: `https://api.openai.com/v1/chat/completions` or `https://api.openai.com/v1/responses`
   - Supported models: GPT-5.2, GPT-4o, and other OpenAI models
   - Multi-modal support for images, videos, and audio

2. **Google Gemini**
   - API Endpoint: `https://generativelanguage.googleapis.com/v1beta/models/{model}:generateContent`
   - Supported models: Gemini 3 Pro Preview, Gemini 3 Flash Preview
   - Multi-modal capabilities

3. **DeepSeek**
   - API Endpoint: `https://api.deepseek.com`
   - Supported models: DeepSeek Chat, DeepSeek Coder
   - Text-only support with streaming capabilities

4. **Claude (Anthropic)**
   - API Endpoint: `https://api.anthropic.com/v1/messages`
   - Supported models: Claude Opus 4.5, Claude Sonnet 4.5
   - Multi-modal support for images with thinking mode capability

### Default Values

When configuring a new platform, the following default values are used:

- **Default Platform Type**: OpenAI
- **Default Models**:
  - OpenAI: `gpt-5.2`
  - Gemini: `gemini-3-flash-preview`
  - DeepSeek: `deepseek-chat`
  - Claude: `claude-sonnet-4-5`
- **Temperature**: `0.7`
- **Max Tokens**: `1000`

Note: These defaults apply when creating a new platform configuration. You can customize these values for each platform independently.

### Prompt Presets

LumenFlow includes an advanced role-playing system with file-based prompt presets that support multiple languages. The system automatically loads the appropriate language version based on the user's selected interface language.

#### How It Works
- **Multi-Language Support**: Presets are available in both Chinese (`presets-zh.json`) and English (`presets-en.json`) versions
- **Automatic Language Detection**: The system automatically loads presets based on the current interface language setting
- **File-Based Presets**: The `system_prompt` field in preset files points to XML/TXT files (e.g., `"characters/zh/NingXi.xml"` for Chinese, `"characters/en/NingXi.xml"` for English)
- **Automatic Content Loading**: The system automatically loads the file content and uses it as the system prompt
- **Variable Substitution**: Supports `\${userProfile.username}` replacement with actual user names
- **XML Format**: Rich XML structure for detailed character definitions with meta information, personality logic, addressing protocols, and example dialogues

#### Using Presets
1. Navigate to the chat interface
2. Click the "Role-Play" button and select a character from the preset menu
3. The selected character's complete personality system will be applied to the conversation
4. AI responses will reflect the character's traits, speech patterns, and behaviors in the selected language

#### Customizing & Adding Presets
1. Create XML/TXT files in the appropriate language directory (`assets/prompt/characters/zh/` for Chinese, `assets/prompt/characters/en/` for English)
2. Add entries to both `presets-zh.json` and `presets-en.json` with `system_prompt` pointing to the correct file path
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
   <user_info>TEXT<user_info>
   <example_dialogue>TEXT</example_dialogue>
</system_instruction>
```

## Settings Management

LumenFlow provides settings export and import functionality to backup and restore your application configuration. The application supports both standard JSON format and the enhanced `.lumenflow` format, which includes metadata for better version control and compatibility management. For detailed format specifications, see [LumenFlow Format Specification](./LumenFlowFormatSpecification.md).

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

LumenFlow supports both English and Chinese languages. The application automatically detects the system language or allows manual selection in settings. All interface elements, AI responses, and prompt presets are fully localized.

### Language Support
- **English**: Complete English localization for all interface elements and AI responses
- **Chinese**: Complete Chinese localization for all interface elements and AI responses

### Implementation
- Uses Flutter's built-in localization system with ARB files
- AI responses are localized based on selected language
- Prompt presets automatically load the appropriate language version
- Character definitions are available in both languages with separate XML files

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

The application includes comprehensive error handling for:
- Network connectivity issues
- API errors (invalid keys, rate limits, etc.)
- Data parsing errors
- File processing errors
- Localization errors

Errors are displayed to the user through localized UI messages, typically in the chat interface or as alerts. All error messages are available in both English and Chinese.

## License

This project is licensed under the MIT License. See the [LICENSE](LICENSE) file for details.

## Contributing

Contributions are welcome! Please feel free to submit issues and pull requests for improvements, bug fixes, or new features.

## Acknowledgments

- Built with [Flutter](https://flutter.dev/)
- AI capabilities powered by [OpenAI](https://openai.com/), [Google Gemini](https://gemini.google.com/), and [DeepSeek](https://www.deepseek.com/)
- Internationalization support using Flutter's localization system
- Icons provided by [Cupertino Icons](https://pub.dev/packages/cupertino_icons)
