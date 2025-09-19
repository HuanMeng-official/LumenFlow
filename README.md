# LumenFlow

> A Flutter-based AI chat application that integrates with OpenAI's API to provide conversational AI capabilities.

[English Version](./README.md) [中文版本](./README/README.zh_CN.md)

## Project Structure

```
lib/
├── main.dart                 # Application entry point
├── models/                   # Data models
│   ├── conversation.dart     # Conversation model
│   ├── message.dart          # Message model
│   └── user_profile.dart     # User profile model
├── screens/                  # UI screens
│   ├── chat_screen.dart      # Main chat interface
│   ├── conversation_list_screen.dart
│   ├── settings_screen.dart
│   └── user_profile_screen.dart
├── services/                 # Business logic and API integration
│   ├── ai_service.dart       # OpenAI API integration
│   ├── conversation_service.dart
│   ├── settings_service.dart
│   └── user_service.dart
└── widgets/                  # Reusable UI components
    ├── avatar_widget.dart
    ├── chat_input.dart
    └── message_bubble.dart
```

## Key Features

- Real-time chat with AI models (GPT-5 by default)
- Conversation history management
- User profile customization
- Configurable AI parameters (temperature, max tokens, etc.)
- Local data persistence using SharedPreferences
- Markdown rendering for AI responses

## Dependencies

- [Flutter](https://flutter.dev/) - UI framework
- [http](https://pub.dev/packages/http) - HTTP client for API requests
- [shared_preferences](https://pub.dev/packages/shared_preferences) - Persistent storage
- [intl](https://pub.dev/packages/intl) - Internationalization and localization
- [flutter_markdown](https://pub.dev/packages/flutter_markdown) - Markdown rendering
- [image_picker](https://pub.dev/packages/image_picker) - Image selection
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

### Services

- `AIService`: Handles communication with the OpenAI API, including request formatting and response parsing
- `ConversationService`: Manages local conversation storage and retrieval
- `SettingsService`: Manages application settings and configuration
- `UserService`: Manages user profile data

## Configuration

Before using the application, you need to configure it with your OpenAI API key:

1. Navigate to the Settings screen
2. Enter your OpenAI API key
3. Optionally adjust model parameters (model, temperature, max tokens)

The application uses the following default values:
- API Endpoint: `https://api.openai.com/v1`
- Model: `gpt-5`
- Temperature: `0.7`
- Max Tokens: `1000`

## Building

To build the application, ensure you have Flutter installed and set up:

```bash
flutter pub get
flutter build apk        # For Android
```

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
