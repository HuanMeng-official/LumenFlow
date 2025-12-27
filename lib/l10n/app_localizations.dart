import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:intl/intl.dart' as intl;

import 'app_localizations_en.dart';
import 'app_localizations_zh.dart';

// ignore_for_file: type=lint

/// Callers can lookup localized strings with an instance of AppLocalizations
/// returned by `AppLocalizations.of(context)`.
///
/// Applications need to include `AppLocalizations.delegate()` in their app's
/// `localizationDelegates` list, and the locales they support in the app's
/// `supportedLocales` list. For example:
///
/// ```dart
/// import 'l10n/app_localizations.dart';
///
/// return MaterialApp(
///   localizationsDelegates: AppLocalizations.localizationsDelegates,
///   supportedLocales: AppLocalizations.supportedLocales,
///   home: MyApplicationHome(),
/// );
/// ```
///
/// ## Update pubspec.yaml
///
/// Please make sure to update your pubspec.yaml to include the following
/// packages:
///
/// ```yaml
/// dependencies:
///   # Internationalization support.
///   flutter_localizations:
///     sdk: flutter
///   intl: any # Use the pinned version from flutter_localizations
///
///   # Rest of dependencies
/// ```
///
/// ## iOS Applications
///
/// iOS applications define key application metadata, including supported
/// locales, in an Info.plist file that is built into the application bundle.
/// To configure the locales supported by your app, you’ll need to edit this
/// file.
///
/// First, open your project’s ios/Runner.xcworkspace Xcode workspace file.
/// Then, in the Project Navigator, open the Info.plist file under the Runner
/// project’s Runner folder.
///
/// Next, select the Information Property List item, select Add Item from the
/// Editor menu, then select Localizations from the pop-up menu.
///
/// Select and expand the newly-created Localizations item then, for each
/// locale your application supports, add a new item and select the locale
/// you wish to add from the pop-up menu in the Value field. This list should
/// be consistent with the languages listed in the AppLocalizations.supportedLocales
/// property.
abstract class AppLocalizations {
  AppLocalizations(String locale) : localeName = intl.Intl.canonicalizedLocale(locale.toString());

  final String localeName;

  static AppLocalizations? of(BuildContext context) {
    return Localizations.of<AppLocalizations>(context, AppLocalizations);
  }

  static const LocalizationsDelegate<AppLocalizations> delegate = _AppLocalizationsDelegate();

  /// A list of this localizations delegate along with the default localizations
  /// delegates.
  ///
  /// Returns a list of localizations delegates containing this delegate along with
  /// GlobalMaterialLocalizations.delegate, GlobalCupertinoLocalizations.delegate,
  /// and GlobalWidgetsLocalizations.delegate.
  ///
  /// Additional delegates can be added by appending to this list in
  /// MaterialApp. This list does not have to be used at all if a custom list
  /// of delegates is preferred or required.
  static const List<LocalizationsDelegate<dynamic>> localizationsDelegates = <LocalizationsDelegate<dynamic>>[
    delegate,
    GlobalMaterialLocalizations.delegate,
    GlobalCupertinoLocalizations.delegate,
    GlobalWidgetsLocalizations.delegate,
  ];

  /// A list of this localizations delegate's supported locales.
  static const List<Locale> supportedLocales = <Locale>[
    Locale('en'),
    Locale('zh')
  ];

  /// No description provided for @appTitle.
  ///
  /// In en, this message translates to:
  /// **'LumenFlow'**
  String get appTitle;

  /// No description provided for @appSubtitle.
  ///
  /// In en, this message translates to:
  /// **'Chat With Your AI'**
  String get appSubtitle;

  /// No description provided for @chat.
  ///
  /// In en, this message translates to:
  /// **'Chat'**
  String get chat;

  /// No description provided for @settings.
  ///
  /// In en, this message translates to:
  /// **'Settings'**
  String get settings;

  /// No description provided for @about.
  ///
  /// In en, this message translates to:
  /// **'About'**
  String get about;

  /// No description provided for @conversations.
  ///
  /// In en, this message translates to:
  /// **'Conversations'**
  String get conversations;

  /// No description provided for @newConversation.
  ///
  /// In en, this message translates to:
  /// **'New Conversation'**
  String get newConversation;

  /// No description provided for @noConversations.
  ///
  /// In en, this message translates to:
  /// **'No conversations yet'**
  String get noConversations;

  /// No description provided for @createNewConversation.
  ///
  /// In en, this message translates to:
  /// **'Create new conversation'**
  String get createNewConversation;

  /// No description provided for @aiAssistant.
  ///
  /// In en, this message translates to:
  /// **'AI Assistant'**
  String get aiAssistant;

  /// No description provided for @startChatting.
  ///
  /// In en, this message translates to:
  /// **'Start chatting with AI!'**
  String get startChatting;

  /// No description provided for @pleaseConfigureAPI.
  ///
  /// In en, this message translates to:
  /// **'Please configure API settings to start chatting'**
  String get pleaseConfigureAPI;

  /// No description provided for @settingsButton.
  ///
  /// In en, this message translates to:
  /// **'Settings'**
  String get settingsButton;

  /// No description provided for @needConfiguration.
  ///
  /// In en, this message translates to:
  /// **'Configuration Required'**
  String get needConfiguration;

  /// No description provided for @configureAPIPrompt.
  ///
  /// In en, this message translates to:
  /// **'Please configure API endpoint and key in settings'**
  String get configureAPIPrompt;

  /// No description provided for @cancel.
  ///
  /// In en, this message translates to:
  /// **'Cancel'**
  String get cancel;

  /// No description provided for @confirm.
  ///
  /// In en, this message translates to:
  /// **'Confirm'**
  String get confirm;

  /// No description provided for @save.
  ///
  /// In en, this message translates to:
  /// **'Save'**
  String get save;

  /// No description provided for @delete.
  ///
  /// In en, this message translates to:
  /// **'Delete'**
  String get delete;

  /// No description provided for @edit.
  ///
  /// In en, this message translates to:
  /// **'Edit'**
  String get edit;

  /// No description provided for @ok.
  ///
  /// In en, this message translates to:
  /// **'OK'**
  String get ok;

  /// No description provided for @goToSettings.
  ///
  /// In en, this message translates to:
  /// **'Go to Settings'**
  String get goToSettings;

  /// No description provided for @clearConversation.
  ///
  /// In en, this message translates to:
  /// **'Clear Current Conversation'**
  String get clearConversation;

  /// No description provided for @clearConversationConfirm.
  ///
  /// In en, this message translates to:
  /// **'Are you sure you want to clear all messages in the current conversation?'**
  String get clearConversationConfirm;

  /// No description provided for @deleteConversation.
  ///
  /// In en, this message translates to:
  /// **'Delete Conversation'**
  String get deleteConversation;

  /// No description provided for @deleteConversationConfirm.
  ///
  /// In en, this message translates to:
  /// **'Are you sure you want to delete conversation \"{title}\"? This action cannot be undone.'**
  String deleteConversationConfirm(String title);

  /// No description provided for @editConversationTitle.
  ///
  /// In en, this message translates to:
  /// **'Edit Conversation Title'**
  String get editConversationTitle;

  /// No description provided for @enterConversationTitle.
  ///
  /// In en, this message translates to:
  /// **'Enter conversation title'**
  String get enterConversationTitle;

  /// No description provided for @saveSuccess.
  ///
  /// In en, this message translates to:
  /// **'Saved Successfully'**
  String get saveSuccess;

  /// No description provided for @settingsSaved.
  ///
  /// In en, this message translates to:
  /// **'Settings have been saved'**
  String get settingsSaved;

  /// No description provided for @saveFailed.
  ///
  /// In en, this message translates to:
  /// **'Save Failed'**
  String get saveFailed;

  /// No description provided for @saveError.
  ///
  /// In en, this message translates to:
  /// **'Error saving settings: {error}'**
  String saveError(String error);

  /// No description provided for @resetSettings.
  ///
  /// In en, this message translates to:
  /// **'Reset Settings'**
  String get resetSettings;

  /// No description provided for @resetSettingsConfirm.
  ///
  /// In en, this message translates to:
  /// **'Are you sure you want to restore default settings? This will clear all current configurations.'**
  String get resetSettingsConfirm;

  /// No description provided for @exportSettings.
  ///
  /// In en, this message translates to:
  /// **'Export Settings'**
  String get exportSettings;

  /// No description provided for @exportSuccess.
  ///
  /// In en, this message translates to:
  /// **'Export Successful'**
  String get exportSuccess;

  /// No description provided for @exportLocation.
  ///
  /// In en, this message translates to:
  /// **'Settings have been successfully exported to {location}:\n{path}'**
  String exportLocation(String location, String path);

  /// No description provided for @exportFailed.
  ///
  /// In en, this message translates to:
  /// **'Export Failed'**
  String get exportFailed;

  /// No description provided for @exportError.
  ///
  /// In en, this message translates to:
  /// **'Error exporting settings: {error}\n\nPlease ensure the app has storage permission and check available storage space.'**
  String exportError(String error);

  /// No description provided for @importSettings.
  ///
  /// In en, this message translates to:
  /// **'Import Settings'**
  String get importSettings;

  /// No description provided for @importSettingsConfirm.
  ///
  /// In en, this message translates to:
  /// **'This will overwrite current settings. Are you sure you want to import?'**
  String get importSettingsConfirm;

  /// No description provided for @importSuccess.
  ///
  /// In en, this message translates to:
  /// **'Import Successful'**
  String get importSuccess;

  /// No description provided for @settingsImported.
  ///
  /// In en, this message translates to:
  /// **'Settings have been successfully imported.'**
  String get settingsImported;

  /// No description provided for @importFailed.
  ///
  /// In en, this message translates to:
  /// **'Import Failed'**
  String get importFailed;

  /// No description provided for @importError.
  ///
  /// In en, this message translates to:
  /// **'Error importing settings: {error}'**
  String importError(String error);

  /// No description provided for @error.
  ///
  /// In en, this message translates to:
  /// **'Error'**
  String get error;

  /// No description provided for @responseInterrupted.
  ///
  /// In en, this message translates to:
  /// **'Response interrupted, app may have exited unexpectedly'**
  String get responseInterrupted;

  /// No description provided for @yesterday.
  ///
  /// In en, this message translates to:
  /// **'Yesterday'**
  String get yesterday;

  /// No description provided for @daysAgo.
  ///
  /// In en, this message translates to:
  /// **'{days} days ago'**
  String daysAgo(int days);

  /// No description provided for @editTitle.
  ///
  /// In en, this message translates to:
  /// **'Edit Title'**
  String get editTitle;

  /// No description provided for @deleteConversation2.
  ///
  /// In en, this message translates to:
  /// **'Delete Conversation'**
  String get deleteConversation2;

  /// No description provided for @userInfo.
  ///
  /// In en, this message translates to:
  /// **'User Information'**
  String get userInfo;

  /// No description provided for @userProfile.
  ///
  /// In en, this message translates to:
  /// **'User Profile'**
  String get userProfile;

  /// No description provided for @userProfileDesc.
  ///
  /// In en, this message translates to:
  /// **'Set avatar and username'**
  String get userProfileDesc;

  /// No description provided for @basicSettings.
  ///
  /// In en, this message translates to:
  /// **'Basic Settings'**
  String get basicSettings;

  /// No description provided for @apiType.
  ///
  /// In en, this message translates to:
  /// **'API Type'**
  String get apiType;

  /// No description provided for @openaiApi.
  ///
  /// In en, this message translates to:
  /// **'OpenAI API'**
  String get openaiApi;

  /// No description provided for @geminiApi.
  ///
  /// In en, this message translates to:
  /// **'Gemini API'**
  String get geminiApi;

  /// No description provided for @deepseekApi.
  ///
  /// In en, this message translates to:
  /// **'DeepSeek API'**
  String get deepseekApi;

  /// No description provided for @apiTypeDesc.
  ///
  /// In en, this message translates to:
  /// **'Select AI service provider'**
  String get apiTypeDesc;

  /// No description provided for @apiEndpoint.
  ///
  /// In en, this message translates to:
  /// **'API Endpoint'**
  String get apiEndpoint;

  /// No description provided for @apiEndpointPlaceholder.
  ///
  /// In en, this message translates to:
  /// **'Enter API endpoint URL'**
  String get apiEndpointPlaceholder;

  /// No description provided for @apiEndpointDesc.
  ///
  /// In en, this message translates to:
  /// **'e.g.: https://api.openai.com/v1'**
  String get apiEndpointDesc;

  /// No description provided for @apiKey.
  ///
  /// In en, this message translates to:
  /// **'API Key'**
  String get apiKey;

  /// No description provided for @apiKeyPlaceholder.
  ///
  /// In en, this message translates to:
  /// **'Enter API key'**
  String get apiKeyPlaceholder;

  /// No description provided for @apiKeyDesc.
  ///
  /// In en, this message translates to:
  /// **'Authentication key obtained from AI service provider'**
  String get apiKeyDesc;

  /// No description provided for @modelSettings.
  ///
  /// In en, this message translates to:
  /// **'Model Settings'**
  String get modelSettings;

  /// No description provided for @model.
  ///
  /// In en, this message translates to:
  /// **'Model'**
  String get model;

  /// No description provided for @modelPlaceholder.
  ///
  /// In en, this message translates to:
  /// **'Enter model name'**
  String get modelPlaceholder;

  /// No description provided for @modelDesc.
  ///
  /// In en, this message translates to:
  /// **'e.g.: gpt-5, deepseek-chat'**
  String get modelDesc;

  /// No description provided for @maxTokens.
  ///
  /// In en, this message translates to:
  /// **'Max Tokens'**
  String get maxTokens;

  /// No description provided for @maxTokensPlaceholder.
  ///
  /// In en, this message translates to:
  /// **'Enter max tokens'**
  String get maxTokensPlaceholder;

  /// No description provided for @maxTokensDesc.
  ///
  /// In en, this message translates to:
  /// **'Limit the length of single response, recommended 500-8000'**
  String get maxTokensDesc;

  /// No description provided for @systemPrompt.
  ///
  /// In en, this message translates to:
  /// **'System Prompt'**
  String get systemPrompt;

  /// No description provided for @systemPromptPlaceholder.
  ///
  /// In en, this message translates to:
  /// **'Enter System Prompt'**
  String get systemPromptPlaceholder;

  /// No description provided for @systemPromptDesc.
  ///
  /// In en, this message translates to:
  /// **'e.g.: Always answer in Chinese'**
  String get systemPromptDesc;

  /// No description provided for @temperature.
  ///
  /// In en, this message translates to:
  /// **'Temperature'**
  String get temperature;

  /// No description provided for @temperatureDesc.
  ///
  /// In en, this message translates to:
  /// **'Control response randomness, 0.0-2.0, higher value means more creative responses'**
  String get temperatureDesc;

  /// No description provided for @historyConversation.
  ///
  /// In en, this message translates to:
  /// **'History Conversation'**
  String get historyConversation;

  /// No description provided for @enableHistory.
  ///
  /// In en, this message translates to:
  /// **'Enable History'**
  String get enableHistory;

  /// No description provided for @enableHistoryDesc.
  ///
  /// In en, this message translates to:
  /// **'When enabled, AI will remember previous conversation context and provide more coherent responses'**
  String get enableHistoryDesc;

  /// No description provided for @historyRounds.
  ///
  /// In en, this message translates to:
  /// **'History Rounds'**
  String get historyRounds;

  /// No description provided for @historyRoundsPlaceholder.
  ///
  /// In en, this message translates to:
  /// **'Enter number of history rounds'**
  String get historyRoundsPlaceholder;

  /// No description provided for @historyRoundsDesc.
  ///
  /// In en, this message translates to:
  /// **'Number of conversation rounds AI remembers, recommended 5-20 rounds. Too many may exceed token limit'**
  String get historyRoundsDesc;

  /// No description provided for @conversationTitle.
  ///
  /// In en, this message translates to:
  /// **'Conversation Title'**
  String get conversationTitle;

  /// No description provided for @autoGenerateTitle.
  ///
  /// In en, this message translates to:
  /// **'Auto Generate Title'**
  String get autoGenerateTitle;

  /// No description provided for @autoGenerateTitleDesc.
  ///
  /// In en, this message translates to:
  /// **'After several rounds of conversation, AI will automatically generate title based on content'**
  String get autoGenerateTitleDesc;

  /// No description provided for @generateTiming.
  ///
  /// In en, this message translates to:
  /// **'Generate Timing'**
  String get generateTiming;

  /// No description provided for @generateTimingDesc.
  ///
  /// In en, this message translates to:
  /// **'Set how many rounds of conversation before auto-generating title'**
  String get generateTimingDesc;

  /// No description provided for @rounds.
  ///
  /// In en, this message translates to:
  /// **'rounds'**
  String get rounds;

  /// No description provided for @appearance.
  ///
  /// In en, this message translates to:
  /// **'Appearance'**
  String get appearance;

  /// No description provided for @followSystem.
  ///
  /// In en, this message translates to:
  /// **'Follow System Settings'**
  String get followSystem;

  /// No description provided for @followSystemDesc.
  ///
  /// In en, this message translates to:
  /// **'Automatically follow system color mode'**
  String get followSystemDesc;

  /// No description provided for @appColor.
  ///
  /// In en, this message translates to:
  /// **'App Color'**
  String get appColor;

  /// No description provided for @lightMode.
  ///
  /// In en, this message translates to:
  /// **'Light Mode'**
  String get lightMode;

  /// No description provided for @darkMode.
  ///
  /// In en, this message translates to:
  /// **'Dark Mode'**
  String get darkMode;

  /// No description provided for @followSystemSetting.
  ///
  /// In en, this message translates to:
  /// **'Following system ({mode})'**
  String followSystemSetting(String mode);

  /// No description provided for @selectColorMode.
  ///
  /// In en, this message translates to:
  /// **'Select app color mode'**
  String get selectColorMode;

  /// No description provided for @others.
  ///
  /// In en, this message translates to:
  /// **'Others'**
  String get others;

  /// No description provided for @resetToDefault.
  ///
  /// In en, this message translates to:
  /// **'Reset to Default Settings'**
  String get resetToDefault;

  /// No description provided for @usageInstructions.
  ///
  /// In en, this message translates to:
  /// **'Usage Instructions'**
  String get usageInstructions;

  /// No description provided for @usageInstructionsContent.
  ///
  /// In en, this message translates to:
  /// **'• API Type: Select AI service provider (OpenAI, Gemini or DeepSeek). Endpoint and model will be auto-filled after selection\n• API Endpoint: API address of AI service provider. Click help button to view common endpoints\n• API Key: Authentication key obtained from service provider. Please keep it safe\n• Model: AI model name to use. Different endpoints support different models\n• Token Count: Limit the length of single response. Too small may result in incomplete responses\n• Temperature: Higher value means more creative responses. Recommended 0.3-1.0\n• History Conversation: When enabled, AI can remember conversation context for more coherent experience'**
  String get usageInstructionsContent;

  /// No description provided for @commonApiEndpoints.
  ///
  /// In en, this message translates to:
  /// **'Common API Endpoints'**
  String get commonApiEndpoints;

  /// No description provided for @commonApiEndpointsContent.
  ///
  /// In en, this message translates to:
  /// **'OpenAI: https://api.openai.com/v1\n\nDeepSeek: https://api.deepseek.com\n\nAlibaba Cloud: https://dashscope.aliyuncs.com/api/v1\n\nPlease fill in the corresponding endpoint address based on the AI service provider you use.'**
  String get commonApiEndpointsContent;

  /// No description provided for @commonModels.
  ///
  /// In en, this message translates to:
  /// **'Common Models'**
  String get commonModels;

  /// No description provided for @commonModelsContent.
  ///
  /// In en, this message translates to:
  /// **'OpenAI:\n• gpt-5\n\nDeepSeek:\n• deepseek-chat\n• deepseek-reasoner\n\nPlease select the corresponding model based on your API endpoint.'**
  String get commonModelsContent;

  /// No description provided for @appInfo.
  ///
  /// In en, this message translates to:
  /// **'App Information'**
  String get appInfo;

  /// No description provided for @version.
  ///
  /// In en, this message translates to:
  /// **'Version'**
  String get version;

  /// No description provided for @buildDate.
  ///
  /// In en, this message translates to:
  /// **'Build Date'**
  String get buildDate;

  /// No description provided for @developer.
  ///
  /// In en, this message translates to:
  /// **'Developer'**
  String get developer;

  /// No description provided for @features.
  ///
  /// In en, this message translates to:
  /// **'Features'**
  String get features;

  /// No description provided for @intelligentConversation.
  ///
  /// In en, this message translates to:
  /// **'Intelligent Conversation'**
  String get intelligentConversation;

  /// No description provided for @intelligentConversationDesc.
  ///
  /// In en, this message translates to:
  /// **'Support natural language conversations with various AI models'**
  String get intelligentConversationDesc;

  /// No description provided for @fileProcessing.
  ///
  /// In en, this message translates to:
  /// **'File Processing'**
  String get fileProcessing;

  /// No description provided for @fileProcessingDesc.
  ///
  /// In en, this message translates to:
  /// **'Support uploading multiple file formats such as images and documents'**
  String get fileProcessingDesc;

  /// No description provided for @historyRecords.
  ///
  /// In en, this message translates to:
  /// **'History Records'**
  String get historyRecords;

  /// No description provided for @historyRecordsDesc.
  ///
  /// In en, this message translates to:
  /// **'Automatically save conversation history with context memory'**
  String get historyRecordsDesc;

  /// No description provided for @customSettings.
  ///
  /// In en, this message translates to:
  /// **'Custom Settings'**
  String get customSettings;

  /// No description provided for @customSettingsDesc.
  ///
  /// In en, this message translates to:
  /// **'Flexibly configure API parameters, themes and personalized options'**
  String get customSettingsDesc;

  /// No description provided for @licenses.
  ///
  /// In en, this message translates to:
  /// **'Licenses'**
  String get licenses;

  /// No description provided for @copyright.
  ///
  /// In en, this message translates to:
  /// **'© 2025 幻梦official'**
  String get copyright;

  /// No description provided for @copyrightNotice.
  ///
  /// In en, this message translates to:
  /// **'This application is for learning and research purposes only'**
  String get copyrightNotice;

  /// No description provided for @copyrightTerms.
  ///
  /// In en, this message translates to:
  /// **'Please ensure compliance with relevant API service terms before use'**
  String get copyrightTerms;

  /// No description provided for @profileSaved.
  ///
  /// In en, this message translates to:
  /// **'User profile has been saved'**
  String get profileSaved;

  /// No description provided for @saveProfileError.
  ///
  /// In en, this message translates to:
  /// **'Error saving user profile: {error}'**
  String saveProfileError(String error);

  /// No description provided for @pickAvatarFailed.
  ///
  /// In en, this message translates to:
  /// **'Failed to pick avatar'**
  String get pickAvatarFailed;

  /// No description provided for @takePhotoFailed.
  ///
  /// In en, this message translates to:
  /// **'Failed to take photo'**
  String get takePhotoFailed;

  /// No description provided for @selectEmojiAvatar.
  ///
  /// In en, this message translates to:
  /// **'Select Emoji Avatar'**
  String get selectEmojiAvatar;

  /// No description provided for @selectAvatar.
  ///
  /// In en, this message translates to:
  /// **'Select Avatar'**
  String get selectAvatar;

  /// No description provided for @selectFromGallery.
  ///
  /// In en, this message translates to:
  /// **'Select from Gallery'**
  String get selectFromGallery;

  /// No description provided for @takePhoto.
  ///
  /// In en, this message translates to:
  /// **'Take Photo'**
  String get takePhoto;

  /// No description provided for @selectEmoji.
  ///
  /// In en, this message translates to:
  /// **'Select Emoji'**
  String get selectEmoji;

  /// No description provided for @tapToChangeAvatar.
  ///
  /// In en, this message translates to:
  /// **'Tap to change avatar'**
  String get tapToChangeAvatar;

  /// No description provided for @username.
  ///
  /// In en, this message translates to:
  /// **'Username'**
  String get username;

  /// No description provided for @usernameHint.
  ///
  /// In en, this message translates to:
  /// **'AI will use this name to address you'**
  String get usernameHint;

  /// No description provided for @enterYourUsername.
  ///
  /// In en, this message translates to:
  /// **'Enter your username'**
  String get enterYourUsername;

  /// No description provided for @aboutUserProfile.
  ///
  /// In en, this message translates to:
  /// **'About User Profile'**
  String get aboutUserProfile;

  /// No description provided for @aboutUserProfileContent.
  ///
  /// In en, this message translates to:
  /// **'• Avatar: Choose a photo or emoji as your avatar, displayed in chat interface\n• Username: AI will use this name to address you in conversations\n• All information is stored locally only, never uploaded to server'**
  String get aboutUserProfileContent;

  /// No description provided for @selectPresetRole.
  ///
  /// In en, this message translates to:
  /// **'Select Preset Role'**
  String get selectPresetRole;

  /// No description provided for @selectPresetRoleMessage.
  ///
  /// In en, this message translates to:
  /// **'Select a preset role to apply the corresponding system prompt'**
  String get selectPresetRoleMessage;

  /// No description provided for @closePresetMode.
  ///
  /// In en, this message translates to:
  /// **'Close Preset Mode'**
  String get closePresetMode;

  /// No description provided for @continueAction.
  ///
  /// In en, this message translates to:
  /// **'Continue'**
  String get continueAction;

  /// No description provided for @deepThinking.
  ///
  /// In en, this message translates to:
  /// **'Deep Thinking'**
  String get deepThinking;

  /// No description provided for @rolePlay.
  ///
  /// In en, this message translates to:
  /// **'Role Play'**
  String get rolePlay;

  /// No description provided for @language.
  ///
  /// In en, this message translates to:
  /// **'Language'**
  String get language;

  /// No description provided for @interfaceLanguage.
  ///
  /// In en, this message translates to:
  /// **'Interface Language'**
  String get interfaceLanguage;

  /// No description provided for @selectInterfaceLanguage.
  ///
  /// In en, this message translates to:
  /// **'Select app interface language'**
  String get selectInterfaceLanguage;

  /// No description provided for @thinkChain.
  ///
  /// In en, this message translates to:
  /// **'Chain of Thinking'**
  String get thinkChain;

  /// No description provided for @expandChain.
  ///
  /// In en, this message translates to:
  /// **'View reasoning process'**
  String get expandChain;
}

class _AppLocalizationsDelegate extends LocalizationsDelegate<AppLocalizations> {
  const _AppLocalizationsDelegate();

  @override
  Future<AppLocalizations> load(Locale locale) {
    return SynchronousFuture<AppLocalizations>(lookupAppLocalizations(locale));
  }

  @override
  bool isSupported(Locale locale) => <String>['en', 'zh'].contains(locale.languageCode);

  @override
  bool shouldReload(_AppLocalizationsDelegate old) => false;
}

AppLocalizations lookupAppLocalizations(Locale locale) {


  // Lookup logic when only language code is specified.
  switch (locale.languageCode) {
    case 'en': return AppLocalizationsEn();
    case 'zh': return AppLocalizationsZh();
  }

  throw FlutterError(
    'AppLocalizations.delegate failed to load unsupported locale "$locale". This is likely '
    'an issue with the localizations generation tool. Please file an issue '
    'on GitHub with a reproducible sample app and the gen-l10n configuration '
    'that was used.'
  );
}
