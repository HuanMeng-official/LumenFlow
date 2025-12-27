// ignore: unused_import
import 'package:intl/intl.dart' as intl;
import 'app_localizations.dart';

// ignore_for_file: type=lint

/// The translations for English (`en`).
class AppLocalizationsEn extends AppLocalizations {
  AppLocalizationsEn([String locale = 'en']) : super(locale);

  @override
  String get appTitle => 'LumenFlow';

  @override
  String get appSubtitle => 'Chat With Your AI';

  @override
  String get chat => 'Chat';

  @override
  String get settings => 'Settings';

  @override
  String get about => 'About';

  @override
  String get conversations => 'Conversations';

  @override
  String get newConversation => 'New Conversation';

  @override
  String get noConversations => 'No conversations yet';

  @override
  String get createNewConversation => 'Create new conversation';

  @override
  String get aiAssistant => 'AI Assistant';

  @override
  String get startChatting => 'Start chatting with AI!';

  @override
  String get pleaseConfigureAPI => 'Please configure API settings to start chatting';

  @override
  String get settingsButton => 'Settings';

  @override
  String get needConfiguration => 'Configuration Required';

  @override
  String get configureAPIPrompt => 'Please configure API endpoint and key in settings';

  @override
  String get cancel => 'Cancel';

  @override
  String get confirm => 'Confirm';

  @override
  String get save => 'Save';

  @override
  String get delete => 'Delete';

  @override
  String get edit => 'Edit';

  @override
  String get ok => 'OK';

  @override
  String get goToSettings => 'Go to Settings';

  @override
  String get clearConversation => 'Clear Current Conversation';

  @override
  String get clearConversationConfirm => 'Are you sure you want to clear all messages in the current conversation?';

  @override
  String get deleteConversation => 'Delete Conversation';

  @override
  String deleteConversationConfirm(String title) {
    return 'Are you sure you want to delete conversation \"$title\"? This action cannot be undone.';
  }

  @override
  String get editConversationTitle => 'Edit Conversation Title';

  @override
  String get enterConversationTitle => 'Enter conversation title';

  @override
  String get saveSuccess => 'Saved Successfully';

  @override
  String get settingsSaved => 'Settings have been saved';

  @override
  String get saveFailed => 'Save Failed';

  @override
  String saveError(String error) {
    return 'Error saving settings: $error';
  }

  @override
  String get resetSettings => 'Reset Settings';

  @override
  String get resetSettingsConfirm => 'Are you sure you want to restore default settings? This will clear all current configurations.';

  @override
  String get exportSettings => 'Export Settings';

  @override
  String get exportSuccess => 'Export Successful';

  @override
  String exportLocation(String location, String path) {
    return 'Settings have been successfully exported to $location:\n$path';
  }

  @override
  String get exportFailed => 'Export Failed';

  @override
  String exportError(String error) {
    return 'Error exporting settings: $error\n\nPlease ensure the app has storage permission and check available storage space.';
  }

  @override
  String get importSettings => 'Import Settings';

  @override
  String get importSettingsConfirm => 'This will overwrite current settings. Are you sure you want to import?';

  @override
  String get importSuccess => 'Import Successful';

  @override
  String get settingsImported => 'Settings have been successfully imported.';

  @override
  String get importFailed => 'Import Failed';

  @override
  String importError(String error) {
    return 'Error importing settings: $error';
  }

  @override
  String get error => 'Error';

  @override
  String get responseInterrupted => 'Response interrupted, app may have exited unexpectedly';

  @override
  String get yesterday => 'Yesterday';

  @override
  String daysAgo(int days) {
    return '$days days ago';
  }

  @override
  String get editTitle => 'Edit Title';

  @override
  String get deleteConversation2 => 'Delete Conversation';

  @override
  String get userInfo => 'User Information';

  @override
  String get userProfile => 'User Profile';

  @override
  String get userProfileDesc => 'Set avatar and username';

  @override
  String get basicSettings => 'Basic Settings';

  @override
  String get apiType => 'API Type';

  @override
  String get openaiApi => 'OpenAI API';

  @override
  String get geminiApi => 'Gemini API';

  @override
  String get deepseekApi => 'DeepSeek API';

  @override
  String get apiTypeDesc => 'Select AI service provider';

  @override
  String get apiEndpoint => 'API Endpoint';

  @override
  String get apiEndpointPlaceholder => 'Enter API endpoint URL';

  @override
  String get apiEndpointDesc => 'e.g.: https://api.openai.com/v1';

  @override
  String get apiKey => 'API Key';

  @override
  String get apiKeyPlaceholder => 'Enter API key';

  @override
  String get apiKeyDesc => 'Authentication key obtained from AI service provider';

  @override
  String get modelSettings => 'Model Settings';

  @override
  String get model => 'Model';

  @override
  String get modelPlaceholder => 'Enter model name';

  @override
  String get modelDesc => 'e.g.: gpt-5, deepseek-chat';

  @override
  String get maxTokens => 'Max Tokens';

  @override
  String get maxTokensPlaceholder => 'Enter max tokens';

  @override
  String get maxTokensDesc => 'Limit the length of single response, recommended 500-8000';

  @override
  String get systemPrompt => 'System Prompt';

  @override
  String get systemPromptPlaceholder => 'Enter System Prompt';

  @override
  String get systemPromptDesc => 'e.g.: Always answer in Chinese';

  @override
  String get temperature => 'Temperature';

  @override
  String get temperatureDesc => 'Control response randomness, 0.0-2.0, higher value means more creative responses';

  @override
  String get historyConversation => 'History Conversation';

  @override
  String get enableHistory => 'Enable History';

  @override
  String get enableHistoryDesc => 'When enabled, AI will remember previous conversation context and provide more coherent responses';

  @override
  String get historyRounds => 'History Rounds';

  @override
  String get historyRoundsPlaceholder => 'Enter number of history rounds';

  @override
  String get historyRoundsDesc => 'Number of conversation rounds AI remembers, recommended 5-20 rounds. Too many may exceed token limit';

  @override
  String get conversationTitle => 'Conversation Title';

  @override
  String get autoGenerateTitle => 'Auto Generate Title';

  @override
  String get autoGenerateTitleDesc => 'After several rounds of conversation, AI will automatically generate title based on content';

  @override
  String get generateTiming => 'Generate Timing';

  @override
  String get generateTimingDesc => 'Set how many rounds of conversation before auto-generating title';

  @override
  String get rounds => 'rounds';

  @override
  String get appearance => 'Appearance';

  @override
  String get followSystem => 'Follow System Settings';

  @override
  String get followSystemDesc => 'Automatically follow system color mode';

  @override
  String get appColor => 'App Color';

  @override
  String get lightMode => 'Light Mode';

  @override
  String get darkMode => 'Dark Mode';

  @override
  String followSystemSetting(String mode) {
    return 'Following system ($mode)';
  }

  @override
  String get selectColorMode => 'Select app color mode';

  @override
  String get others => 'Others';

  @override
  String get resetToDefault => 'Reset to Default Settings';

  @override
  String get usageInstructions => 'Usage Instructions';

  @override
  String get usageInstructionsContent => '• API Type: Select AI service provider (OpenAI, Gemini or DeepSeek). Endpoint and model will be auto-filled after selection\n• API Endpoint: API address of AI service provider. Click help button to view common endpoints\n• API Key: Authentication key obtained from service provider. Please keep it safe\n• Model: AI model name to use. Different endpoints support different models\n• Token Count: Limit the length of single response. Too small may result in incomplete responses\n• Temperature: Higher value means more creative responses. Recommended 0.3-1.0\n• History Conversation: When enabled, AI can remember conversation context for more coherent experience';

  @override
  String get commonApiEndpoints => 'Common API Endpoints';

  @override
  String get commonApiEndpointsContent => 'OpenAI: https://api.openai.com/v1\n\nDeepSeek: https://api.deepseek.com\n\nAlibaba Cloud: https://dashscope.aliyuncs.com/api/v1\n\nPlease fill in the corresponding endpoint address based on the AI service provider you use.';

  @override
  String get commonModels => 'Common Models';

  @override
  String get commonModelsContent => 'OpenAI:\n• gpt-5\n\nDeepSeek:\n• deepseek-chat\n• deepseek-reasoner\n\nPlease select the corresponding model based on your API endpoint.';

  @override
  String get appInfo => 'App Information';

  @override
  String get version => 'Version';

  @override
  String get buildDate => 'Build Date';

  @override
  String get developer => 'Developer';

  @override
  String get features => 'Features';

  @override
  String get intelligentConversation => 'Intelligent Conversation';

  @override
  String get intelligentConversationDesc => 'Support natural language conversations with various AI models';

  @override
  String get fileProcessing => 'File Processing';

  @override
  String get fileProcessingDesc => 'Support uploading multiple file formats such as images and documents';

  @override
  String get historyRecords => 'History Records';

  @override
  String get historyRecordsDesc => 'Automatically save conversation history with context memory';

  @override
  String get customSettings => 'Custom Settings';

  @override
  String get customSettingsDesc => 'Flexibly configure API parameters, themes and personalized options';

  @override
  String get licenses => 'Licenses';

  @override
  String get copyright => '© 2025 幻梦official';

  @override
  String get copyrightNotice => 'This application is for learning and research purposes only';

  @override
  String get copyrightTerms => 'Please ensure compliance with relevant API service terms before use';

  @override
  String get profileSaved => 'User profile has been saved';

  @override
  String saveProfileError(String error) {
    return 'Error saving user profile: $error';
  }

  @override
  String get pickAvatarFailed => 'Failed to pick avatar';

  @override
  String get takePhotoFailed => 'Failed to take photo';

  @override
  String get selectEmojiAvatar => 'Select Emoji Avatar';

  @override
  String get selectAvatar => 'Select Avatar';

  @override
  String get selectFromGallery => 'Select from Gallery';

  @override
  String get takePhoto => 'Take Photo';

  @override
  String get selectEmoji => 'Select Emoji';

  @override
  String get tapToChangeAvatar => 'Tap to change avatar';

  @override
  String get username => 'Username';

  @override
  String get usernameHint => 'AI will use this name to address you';

  @override
  String get enterYourUsername => 'Enter your username';

  @override
  String get aboutUserProfile => 'About User Profile';

  @override
  String get aboutUserProfileContent => '• Avatar: Choose a photo or emoji as your avatar, displayed in chat interface\n• Username: AI will use this name to address you in conversations\n• All information is stored locally only, never uploaded to server';

  @override
  String get selectPresetRole => 'Select Preset Role';

  @override
  String get selectPresetRoleMessage => 'Select a preset role to apply the corresponding system prompt';

  @override
  String get closePresetMode => 'Close Preset Mode';

  @override
  String get continueAction => 'Continue';

  @override
  String get deepThinking => 'Deep Thinking';

  @override
  String get rolePlay => 'Role Play';

  @override
  String get language => 'Language';

  @override
  String get interfaceLanguage => 'Interface Language';

  @override
  String get selectInterfaceLanguage => 'Select app interface language';
}
