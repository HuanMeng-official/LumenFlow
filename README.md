# LumenFlow

> A cross-platform AI chat application built with Flutter, supporting OpenAI and Google Gemini APIs with multi-modal capabilities.

[English Version](./README.md) | [中文版本](./README/README.zh_CN.md)

## Overview

LumenFlow (Chinese: 流光) is a modern AI chat application built with Flutter that provides a seamless conversational experience across Android and Windows platforms. With support for both OpenAI and Google Gemini APIs, along with multi-modal file processing capabilities, it offers a versatile AI assistant experience.

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
- **Prompt Preset System**: Pre-configured role-playing prompts with rich character settings
- **Theme Management**: Support for light/dark theme switching
- **Cross-Platform**: Supports Android and Windows platforms
- **Local Storage**: Data persistence using SharedPreferences
- **Markdown Rendering**: Beautifully formatted AI responses
- **About Page**: Displays application information, version, and copyright details
- **Settings Export/Import**: Backup and restore application settings via JSON files
- **Role-Play System**: File-based prompt preset system with automatic content loading
- **PowerShell Build Script**: Automated build process for both Android and Windows

## Project Structure

```
lib/
├── main.dart                 # Application entry point
├── models/                   # Data models
│   ├── conversation.dart     # Conversation model
│   ├── message.dart          # Message model
│   ├── user_profile.dart     # User profile model
│   ├── attachment.dart       # Attachment model (files, images, etc.)
│   └── prompt_preset.dart    # Prompt preset model
├── screens/                  # UI screens
│   ├── chat_screen.dart      # Main chat interface
│   ├── conversation_list_screen.dart  # Conversation history
│   ├── settings_screen.dart  # Application settings
│   ├── user_profile_screen.dart  # User profile management
│   ├── about_screen.dart     # About page with app information
│   └── image_preview_screen.dart  # Image preview and viewing
├── services/                 # Business logic and API integration
│   ├── ai_service.dart       # AI service (OpenAI & Gemini integration)
│   ├── conversation_service.dart  # Conversation management
│   ├── settings_service.dart # Settings management
│   ├── user_service.dart     # User profile management
│   ├── file_service.dart     # File handling and processing
│   ├── prompt_service.dart   # Prompt preset management
│   └── version_service.dart  # Version information management
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
- `PromptPreset`: Represents pre-configured prompt presets with role-playing character settings

### Services

- `AIService`: Handles communication with OpenAI and Google Gemini APIs, including request formatting, response parsing, and multi-modal support
- `ConversationService`: Manages local conversation storage and retrieval
- `SettingsService`: Manages application settings and configuration
- `UserService`: Manages user profile data
- `FileService`: Handles file operations, including reading, processing, and extracting content from attachments
- `PromptService`: Manages prompt preset data and configuration

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

### Prompt Presets

LumenFlow includes an advanced role-playing system with file-based prompt presets. These presets are configured in `assets/prompt/presets.json` where the `system_prompt` field contains a file path to XML/TXT files containing detailed character definitions.

#### How It Works
- **File-Based Presets**: The `system_prompt` field in `presets.json` points to XML/TXT files (e.g., `"characters/NingXi.xml"`)
- **Automatic Content Loading**: The system automatically loads the file content and uses it as the system prompt
- **Variable Substitution**: Supports `\${userProfile.username}` replacement with actual user names
- **XML Format**: Rich XML structure for detailed character definitions with meta information, personality logic, addressing protocols, and example dialogues

#### Using Presets
1. Navigate to the chat interface
2. Click the "Role-Play" button and select a character from the preset menu
3. The selected character's complete personality system will be applied to the conversation
4. AI responses will reflect the character's traits, speech patterns, and behaviors

#### Customizing & Adding Presets
1. Create XML/TXT files in `assets/prompt/characters/` directory with character definitions
2. Add entries to `presets.json` with `system_prompt` pointing to the file path
3. Follow the XML format structure for consistent character definitions
4. Restart the application to load new presets

##### Example presets.json Structure
```json
{
  "id": "ningxi",
  "name": "宁汐",
  "description": "俏皮可爱的猫娘",
  "system_prompt": "characters/NingXi.xml",
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
   <example_dialogue>TEXT</example_dialogue>
</system_instruction>
```

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
