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
  String get claudeApi => 'Claude API';

  @override
  String get siliconflowApi => 'SiliconFlow API';

  @override
  String get minimaxApi => 'MiniMax API';

  @override
  String get zhipuApi => 'ZhipuAI API';

  @override
  String get kimiApi => 'Kimi API';

  @override
  String get lmsApi => 'LM-Studio API';

  @override
  String get otherApi => 'Other API';

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
  String get apiKeyPlaceholder => 'API key';

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
  String get sponsor => 'Sponsor';

  @override
  String get sponsorDesc => 'If you find this app helpful, please scan the code to sponsor and support development';

  @override
  String get copyright => '© 2026 幻梦official';

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
  String get gender => 'Gender';

  @override
  String get genderHint => 'Select your gender';

  @override
  String get male => 'Male';

  @override
  String get female => 'Female';

  @override
  String get selectGender => 'Select gender';

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

  @override
  String get thinkChain => 'Chain of Thinking';

  @override
  String get expandChain => 'View reasoning process';

  @override
  String get downloadDirectory => 'Download Directory';

  @override
  String get externalStorageDirectory => 'External Storage Directory';

  @override
  String get appDocumentsDirectory => 'App Documents Directory';

  @override
  String get imagePreview => 'Image Preview';

  @override
  String get unableToLoadImage => 'Unable to load image';

  @override
  String get errorPrefix => 'Error';

  @override
  String get fileTooLarge => 'File Too Large';

  @override
  String fileTooLargeMessage(String size, String limit) {
    return 'Total size of selected files $size exceeds $limit limit. Please select smaller files.';
  }

  @override
  String get fileTooLargeWarning => 'File Too Large Warning';

  @override
  String fileTooLargeWarningMessage(String limit, String files) {
    return 'The following files exceed $limit limit and may not be processed correctly:\n\n$files\n\nContinue uploading?';
  }

  @override
  String get noValidFiles => 'No Valid Files';

  @override
  String get noValidFilesMessage => 'No files were successfully processed. Please try again.';

  @override
  String get selectFileFailed => 'Select File Failed';

  @override
  String selectFileFailedMessage(String error) {
    return 'Error: $error';
  }

  @override
  String get user => 'User';

  @override
  String get ai => 'AI';

  @override
  String get unknownError => 'Unknown error';

  @override
  String attachmentInfo(String fileName, String fileSize, String mimeType) {
    return 'Attachment: $fileName ($fileSize, $mimeType)';
  }

  @override
  String get attachmentCannotRead => ' - Cannot read content';

  @override
  String get unknownMimeType => 'Unknown type';

  @override
  String get multimediaNotSupported => '\nNote: DeepSeek does not support processing multimedia files such as images, videos, and audio';

  @override
  String get responseBlocked => 'Response blocked by safety filter';

  @override
  String apiError(String message, int statusCode) {
    return 'API Error: $message (Status code: $statusCode)';
  }

  @override
  String get configureApiKeyFirst => 'Please configure API key in settings first';

  @override
  String get selectModelFirst => 'Please select a model first';

  @override
  String get messageInputPlaceholder => 'Type a message...';

  @override
  String get configureApiSettingsFirst => 'Please configure API settings first';

  @override
  String baseSystemPrompt(String username) {
    return '\"$username\" is user\'s name, please use this name appropriately in the conversation and respond in English';
  }

  @override
  String requestTimeout(String error) {
    return 'Request timeout: Server response took too long, please check network connection or try again later. Error details: $error';
  }

  @override
  String networkConnectionFailed(String error) {
    return 'Network connection failed: Unable to connect to server, please check network connection. Error details: $error';
  }

  @override
  String securityConnectionFailed(String error) {
    return 'Security connection failed: SSL/TLS handshake failed, please check system time or network settings. Error details: $error';
  }

  @override
  String connectionError(String error) {
    return 'Connection error: Network connection problem occurred, please check network settings. Error details: $error';
  }

  @override
  String httpProtocolError(String error) {
    return 'HTTP protocol error: Request processing failed, please try again later. Error details: $error';
  }

  @override
  String networkCommunicationFailed(String error) {
    return 'Network communication failed: $error';
  }

  @override
  String providerFileNotFound(String fileName) {
    return 'File $fileName does not exist or has been deleted';
  }

  @override
  String providerFileTooLarge(String fileName, String fileSize) {
    return 'File $fileName ($fileSize) is too large to process';
  }

  @override
  String providerFileProcessError(String fileName, String error) {
    return 'Error processing file $fileName: $error';
  }

  @override
  String providerFileContent(String fileName, String fileSize, String content) {
    return 'File: $fileName ($fileSize)\nContent:\n$content';
  }

  @override
  String providerAttachmentCannotRead(String fileName, String fileSize, String mimeType) {
    return 'Attachment: $fileName ($fileSize, $mimeType) - Cannot read content';
  }

  @override
  String providerAttachmentInfo(String fileName, String fileSize, String mimeType) {
    return 'Attachment: $fileName ($fileSize, $mimeType)';
  }

  @override
  String providerTotalSizeExceeded(int limit) {
    return 'Total attachment size exceeds ${limit}MB limit';
  }

  @override
  String get providerInvalidResponseFormat => 'API returned invalid response format';

  @override
  String get providerMissingMessageField => 'API response is missing message field';

  @override
  String providerInvalidResponseFormatWithCode(int statusCode) {
    return 'API Error: Invalid response format (Status code: $statusCode)';
  }

  @override
  String providerApiError(String message, int statusCode) {
    return 'API Error: $message (Status code: $statusCode)';
  }

  @override
  String providerStreamingTimeout(int seconds) {
    return 'Streaming response timeout: No new data received for $seconds seconds';
  }

  @override
  String get providerUnknownError => 'Unknown error';

  @override
  String get providerUser => 'User';

  @override
  String get providerAi => 'AI';

  @override
  String get providerTitleGenSystemPrompt => 'Generate a short, accurate English title based on the user’s language and conversation content. No more than 15 words. Only return the title, without quotes or other formatting.';

  @override
  String providerTitleGenUserPrompt(String conversationSummary) {
    return 'Please generate a short English title based on the conversation content.:\n\n$conversationSummary';
  }

  @override
  String get providerMultimediaNotSupported => '\nNote: DeepSeek does not support processing multimedia files such as images, videos, and audio';

  @override
  String get providerGeminiInvalidResponse => 'Gemini API returned invalid response format';

  @override
  String get providerGeminiMissingCandidates => 'Gemini API response is missing candidates field';

  @override
  String get providerGeminiInvalidFormat => 'Invalid Gemini API response format';

  @override
  String providerGeminiError(String message, int statusCode) {
    return 'Gemini API Error: $message (Status code: $statusCode)';
  }

  @override
  String providerGeminiStreamingTimeout(int seconds) {
    return 'Gemini streaming response timeout: No new data received for $seconds seconds';
  }

  @override
  String providerGeminiInvalidFormatWithCode(int statusCode) {
    return 'Gemini API Error: Invalid response format (Status code: $statusCode)';
  }

  @override
  String get providerResponseBlocked => 'Response blocked by safety filter';

  @override
  String get platformAndModel => 'Platforms & Models';

  @override
  String get platformAndModelDesc => 'Manage multiple AI platforms and model configurations';

  @override
  String get addPlatform => 'Add Platform';

  @override
  String get editPlatform => 'Edit Platform';

  @override
  String get platformType => 'Platform Type';

  @override
  String get platformNamePlaceholder => 'Platform name';

  @override
  String get endpointPlaceholder => 'API endpoint URL';

  @override
  String get configured => 'Configured';

  @override
  String get notConfigured => 'Not Configured';

  @override
  String get models => 'models';

  @override
  String get available => 'Available';

  @override
  String get current => 'Current';

  @override
  String get currentModel => 'Current Model';

  @override
  String get manageModels => 'Manage Models';

  @override
  String get refreshModels => 'Refresh Models';

  @override
  String get noModelsAvailable => 'No available models';

  @override
  String get noModelSelected => 'No model selected';

  @override
  String get modelsRefreshed => 'Model list refreshed';

  @override
  String refreshModelsError(String error) {
    return 'Failed to refresh models: $error';
  }

  @override
  String get deletePlatform => 'Delete Platform';

  @override
  String deletePlatformConfirm(String name) {
    return 'Are you sure you want to delete platform \"$name\"?';
  }

  @override
  String get switchToPlatform => 'Switch to this platform';

  @override
  String switchedToPlatform(String name) {
    return 'Switched to $name';
  }

  @override
  String get addModelTitle => 'Add Model';

  @override
  String get modelNamePh => 'Model name';

  @override
  String get addModelBtn => 'Add';

  @override
  String get deleteModelTitle => 'Delete Model';

  @override
  String deleteModelConfirm(String model) {
    return 'Are you sure you want to delete model \"$model\"?';
  }

  @override
  String get deleteModelBtn => 'Delete Selected';

  @override
  String get selectModelToDelete => 'Please select a model to delete first';

  @override
  String get add => 'Add';

  @override
  String get addNewModel => 'Add new model';

  @override
  String get clickAddToCreate => 'Tap the + button above to add a model';

  @override
  String get noPlatformsConfigured => 'No platforms configured';

  @override
  String get addPlatformHint => 'Tap the + button in the top right to add your first AI platform';

  @override
  String get exportConversation => 'Export Conversation';

  @override
  String get exportFormat => 'Export Format';

  @override
  String get exportFormatTxt => 'Plain Text (.txt)';

  @override
  String get exportFormatJson => 'JSON (.json)';

  @override
  String get exportFormatLumenflow => 'Lumenflow (.lumenflow)';

  @override
  String get exportFormatPdf => 'PDF (.pdf)';

  @override
  String get exportConversationSuccess => 'Conversation exported successfully';

  @override
  String get exportConversationFailed => 'Conversation export failed';

  @override
  String exportConversationError(String error) {
    return 'Error exporting conversation: $error';
  }

  @override
  String get exportConversationTitle => 'Conversation Title: ';

  @override
  String get exportCreatedTime => 'Created Time: ';

  @override
  String get exportUpdatedTime => 'Updated Time: ';

  @override
  String get exportMessageCount => 'Message Count: ';

  @override
  String get exportReasoningProcess => '[Reasoning Process]';

  @override
  String exportAttachments(int count) {
    return '[Attachments: $count]';
  }

  @override
  String get exportBytes => 'bytes';

  @override
  String get exportConversationNotFound => 'Conversation not found';

  @override
  String get exportThinkingProcess => 'Thinking Process';

  @override
  String get exportAttachmentsLabel => 'Attachments';

  @override
  String get notificationSettings => 'Notification Settings';

  @override
  String get enableNotification => 'Enable Notifications';

  @override
  String get enableNotificationDesc => 'Receive notification when AI response is completed';

  @override
  String get dataManagement => 'Data Management';

  @override
  String get liveUpdateAIResponse => 'Response';

  @override
  String get languageChanged => 'Language Changed';

  @override
  String get restartAppToApplyLanguage => 'Please restart the app to apply the language change';

  @override
  String get loading => 'Loading';

  @override
  String get copyMessage => 'Copy message';

  @override
  String get copySuccess => 'Copied to clipboard';

  @override
  String get copyFailed => 'Copy failed';

  @override
  String copyError(String error) {
    return 'Copy error: $error';
  }

  @override
  String get copySuccessTitle => 'Copy Success';

  @override
  String get copyFailedTitle => 'Copy Failed';

  @override
  String get copyCode => 'Copy';

  @override
  String get copied => 'Copied';

  @override
  String get aiResponseDisclaimer => 'Content is for reference only, please verify carefully';

  @override
  String get advancedSettings => 'Advanced';

  @override
  String get advancedSettingsSubtitle => 'Configure app behavior';

  @override
  String get userProfileSubtitle => 'Personalize your account';

  @override
  String get platformAndModelSubtitle => 'Configure AI platforms and models';

  @override
  String get apiTypeSubtitle => 'Set up API connection parameters';

  @override
  String get modelSettingsSubtitle => 'Adjust model response behavior';

  @override
  String get historyConversationSubtitle => 'Manage conversation history';

  @override
  String get toolsSettingsSubtitle => 'Configure external tools';

  @override
  String get appearanceSubtitle => 'Customize app appearance';
}
