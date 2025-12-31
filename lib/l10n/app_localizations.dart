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

  /// No description provided for @claudeApi.
  ///
  /// In en, this message translates to:
  /// **'Claude API'**
  String get claudeApi;

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
  /// **'API key'**
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

  /// No description provided for @gender.
  ///
  /// In en, this message translates to:
  /// **'Gender'**
  String get gender;

  /// No description provided for @genderHint.
  ///
  /// In en, this message translates to:
  /// **'Select your gender'**
  String get genderHint;

  /// No description provided for @male.
  ///
  /// In en, this message translates to:
  /// **'Male'**
  String get male;

  /// No description provided for @female.
  ///
  /// In en, this message translates to:
  /// **'Female'**
  String get female;

  /// No description provided for @selectGender.
  ///
  /// In en, this message translates to:
  /// **'Select gender'**
  String get selectGender;

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

  /// No description provided for @downloadDirectory.
  ///
  /// In en, this message translates to:
  /// **'Download Directory'**
  String get downloadDirectory;

  /// No description provided for @externalStorageDirectory.
  ///
  /// In en, this message translates to:
  /// **'External Storage Directory'**
  String get externalStorageDirectory;

  /// No description provided for @appDocumentsDirectory.
  ///
  /// In en, this message translates to:
  /// **'App Documents Directory'**
  String get appDocumentsDirectory;

  /// No description provided for @imagePreview.
  ///
  /// In en, this message translates to:
  /// **'Image Preview'**
  String get imagePreview;

  /// No description provided for @unableToLoadImage.
  ///
  /// In en, this message translates to:
  /// **'Unable to load image'**
  String get unableToLoadImage;

  /// No description provided for @errorPrefix.
  ///
  /// In en, this message translates to:
  /// **'Error'**
  String get errorPrefix;

  /// No description provided for @fileTooLarge.
  ///
  /// In en, this message translates to:
  /// **'File Too Large'**
  String get fileTooLarge;

  /// No description provided for @fileTooLargeMessage.
  ///
  /// In en, this message translates to:
  /// **'Total size of selected files {size} exceeds {limit} limit. Please select smaller files.'**
  String fileTooLargeMessage(String size, String limit);

  /// No description provided for @fileTooLargeWarning.
  ///
  /// In en, this message translates to:
  /// **'File Too Large Warning'**
  String get fileTooLargeWarning;

  /// No description provided for @fileTooLargeWarningMessage.
  ///
  /// In en, this message translates to:
  /// **'The following files exceed {limit} limit and may not be processed correctly:\n\n{files}\n\nContinue uploading?'**
  String fileTooLargeWarningMessage(String limit, String files);

  /// No description provided for @noValidFiles.
  ///
  /// In en, this message translates to:
  /// **'No Valid Files'**
  String get noValidFiles;

  /// No description provided for @noValidFilesMessage.
  ///
  /// In en, this message translates to:
  /// **'No files were successfully processed. Please try again.'**
  String get noValidFilesMessage;

  /// No description provided for @selectFileFailed.
  ///
  /// In en, this message translates to:
  /// **'Select File Failed'**
  String get selectFileFailed;

  /// No description provided for @selectFileFailedMessage.
  ///
  /// In en, this message translates to:
  /// **'Error: {error}'**
  String selectFileFailedMessage(String error);

  /// No description provided for @user.
  ///
  /// In en, this message translates to:
  /// **'User'**
  String get user;

  /// No description provided for @ai.
  ///
  /// In en, this message translates to:
  /// **'AI'**
  String get ai;

  /// No description provided for @unknownError.
  ///
  /// In en, this message translates to:
  /// **'Unknown error'**
  String get unknownError;

  /// No description provided for @attachmentInfo.
  ///
  /// In en, this message translates to:
  /// **'Attachment: {fileName} ({fileSize}, {mimeType})'**
  String attachmentInfo(String fileName, String fileSize, String mimeType);

  /// No description provided for @attachmentCannotRead.
  ///
  /// In en, this message translates to:
  /// **' - Cannot read content'**
  String get attachmentCannotRead;

  /// No description provided for @unknownMimeType.
  ///
  /// In en, this message translates to:
  /// **'Unknown type'**
  String get unknownMimeType;

  /// No description provided for @multimediaNotSupported.
  ///
  /// In en, this message translates to:
  /// **'\nNote: DeepSeek does not support processing multimedia files such as images, videos, and audio'**
  String get multimediaNotSupported;

  /// No description provided for @responseBlocked.
  ///
  /// In en, this message translates to:
  /// **'Response blocked by safety filter'**
  String get responseBlocked;

  /// No description provided for @apiError.
  ///
  /// In en, this message translates to:
  /// **'API Error: {message} (Status code: {statusCode})'**
  String apiError(String message, int statusCode);

  /// No description provided for @configureApiKeyFirst.
  ///
  /// In en, this message translates to:
  /// **'Please configure API key in settings first'**
  String get configureApiKeyFirst;

  /// No description provided for @selectModelFirst.
  ///
  /// In en, this message translates to:
  /// **'Please select a model first'**
  String get selectModelFirst;

  /// No description provided for @messageInputPlaceholder.
  ///
  /// In en, this message translates to:
  /// **'Type a message...'**
  String get messageInputPlaceholder;

  /// No description provided for @configureApiSettingsFirst.
  ///
  /// In en, this message translates to:
  /// **'Please configure API settings first'**
  String get configureApiSettingsFirst;

  /// No description provided for @baseSystemPrompt.
  ///
  /// In en, this message translates to:
  /// **'\"{username}\" is user\'s name, please use this name appropriately in the conversation and respond in English'**
  String baseSystemPrompt(String username);

  /// No description provided for @requestTimeout.
  ///
  /// In en, this message translates to:
  /// **'Request timeout: Server response took too long, please check network connection or try again later. Error details: {error}'**
  String requestTimeout(String error);

  /// No description provided for @networkConnectionFailed.
  ///
  /// In en, this message translates to:
  /// **'Network connection failed: Unable to connect to server, please check network connection. Error details: {error}'**
  String networkConnectionFailed(String error);

  /// No description provided for @securityConnectionFailed.
  ///
  /// In en, this message translates to:
  /// **'Security connection failed: SSL/TLS handshake failed, please check system time or network settings. Error details: {error}'**
  String securityConnectionFailed(String error);

  /// No description provided for @connectionError.
  ///
  /// In en, this message translates to:
  /// **'Connection error: Network connection problem occurred, please check network settings. Error details: {error}'**
  String connectionError(String error);

  /// No description provided for @httpProtocolError.
  ///
  /// In en, this message translates to:
  /// **'HTTP protocol error: Request processing failed, please try again later. Error details: {error}'**
  String httpProtocolError(String error);

  /// No description provided for @networkCommunicationFailed.
  ///
  /// In en, this message translates to:
  /// **'Network communication failed: {error}'**
  String networkCommunicationFailed(String error);

  /// No description provided for @providerFileNotFound.
  ///
  /// In en, this message translates to:
  /// **'File {fileName} does not exist or has been deleted'**
  String providerFileNotFound(String fileName);

  /// No description provided for @providerFileTooLarge.
  ///
  /// In en, this message translates to:
  /// **'File {fileName} ({fileSize}) is too large to process'**
  String providerFileTooLarge(String fileName, String fileSize);

  /// No description provided for @providerFileProcessError.
  ///
  /// In en, this message translates to:
  /// **'Error processing file {fileName}: {error}'**
  String providerFileProcessError(String fileName, String error);

  /// No description provided for @providerFileContent.
  ///
  /// In en, this message translates to:
  /// **'File: {fileName} ({fileSize})\nContent:\n{content}'**
  String providerFileContent(String fileName, String fileSize, String content);

  /// No description provided for @providerAttachmentCannotRead.
  ///
  /// In en, this message translates to:
  /// **'Attachment: {fileName} ({fileSize}, {mimeType}) - Cannot read content'**
  String providerAttachmentCannotRead(String fileName, String fileSize, String mimeType);

  /// No description provided for @providerAttachmentInfo.
  ///
  /// In en, this message translates to:
  /// **'Attachment: {fileName} ({fileSize}, {mimeType})'**
  String providerAttachmentInfo(String fileName, String fileSize, String mimeType);

  /// No description provided for @providerTotalSizeExceeded.
  ///
  /// In en, this message translates to:
  /// **'Total attachment size exceeds {limit}MB limit'**
  String providerTotalSizeExceeded(int limit);

  /// No description provided for @providerInvalidResponseFormat.
  ///
  /// In en, this message translates to:
  /// **'API returned invalid response format'**
  String get providerInvalidResponseFormat;

  /// No description provided for @providerMissingMessageField.
  ///
  /// In en, this message translates to:
  /// **'API response is missing message field'**
  String get providerMissingMessageField;

  /// No description provided for @providerInvalidResponseFormatWithCode.
  ///
  /// In en, this message translates to:
  /// **'API Error: Invalid response format (Status code: {statusCode})'**
  String providerInvalidResponseFormatWithCode(int statusCode);

  /// No description provided for @providerApiError.
  ///
  /// In en, this message translates to:
  /// **'API Error: {message} (Status code: {statusCode})'**
  String providerApiError(String message, int statusCode);

  /// No description provided for @providerStreamingTimeout.
  ///
  /// In en, this message translates to:
  /// **'Streaming response timeout: No new data received for {seconds} seconds'**
  String providerStreamingTimeout(int seconds);

  /// No description provided for @providerUnknownError.
  ///
  /// In en, this message translates to:
  /// **'Unknown error'**
  String get providerUnknownError;

  /// No description provided for @providerUser.
  ///
  /// In en, this message translates to:
  /// **'User'**
  String get providerUser;

  /// No description provided for @providerAi.
  ///
  /// In en, this message translates to:
  /// **'AI'**
  String get providerAi;

  /// No description provided for @providerTitleGenSystemPrompt.
  ///
  /// In en, this message translates to:
  /// **'Generate a short, accurate English title based on the user’s language and conversation content. No more than 15 words. Only return the title, without quotes or other formatting.'**
  String get providerTitleGenSystemPrompt;

  /// No description provided for @providerTitleGenUserPrompt.
  ///
  /// In en, this message translates to:
  /// **'Please generate a short English title based on the conversation content.:\n\n{conversationSummary}'**
  String providerTitleGenUserPrompt(String conversationSummary);

  /// No description provided for @providerMultimediaNotSupported.
  ///
  /// In en, this message translates to:
  /// **'\nNote: DeepSeek does not support processing multimedia files such as images, videos, and audio'**
  String get providerMultimediaNotSupported;

  /// No description provided for @providerGeminiInvalidResponse.
  ///
  /// In en, this message translates to:
  /// **'Gemini API returned invalid response format'**
  String get providerGeminiInvalidResponse;

  /// No description provided for @providerGeminiMissingCandidates.
  ///
  /// In en, this message translates to:
  /// **'Gemini API response is missing candidates field'**
  String get providerGeminiMissingCandidates;

  /// No description provided for @providerGeminiInvalidFormat.
  ///
  /// In en, this message translates to:
  /// **'Invalid Gemini API response format'**
  String get providerGeminiInvalidFormat;

  /// No description provided for @providerGeminiError.
  ///
  /// In en, this message translates to:
  /// **'Gemini API Error: {message} (Status code: {statusCode})'**
  String providerGeminiError(String message, int statusCode);

  /// No description provided for @providerGeminiStreamingTimeout.
  ///
  /// In en, this message translates to:
  /// **'Gemini streaming response timeout: No new data received for {seconds} seconds'**
  String providerGeminiStreamingTimeout(int seconds);

  /// No description provided for @providerGeminiInvalidFormatWithCode.
  ///
  /// In en, this message translates to:
  /// **'Gemini API Error: Invalid response format (Status code: {statusCode})'**
  String providerGeminiInvalidFormatWithCode(int statusCode);

  /// No description provided for @providerResponseBlocked.
  ///
  /// In en, this message translates to:
  /// **'Response blocked by safety filter'**
  String get providerResponseBlocked;

  /// No description provided for @platformAndModel.
  ///
  /// In en, this message translates to:
  /// **'Platforms & Models'**
  String get platformAndModel;

  /// No description provided for @platformAndModelDesc.
  ///
  /// In en, this message translates to:
  /// **'Manage multiple AI platforms and model configurations'**
  String get platformAndModelDesc;

  /// No description provided for @addPlatform.
  ///
  /// In en, this message translates to:
  /// **'Add Platform'**
  String get addPlatform;

  /// No description provided for @editPlatform.
  ///
  /// In en, this message translates to:
  /// **'Edit Platform'**
  String get editPlatform;

  /// No description provided for @platformType.
  ///
  /// In en, this message translates to:
  /// **'Platform Type'**
  String get platformType;

  /// No description provided for @platformNamePlaceholder.
  ///
  /// In en, this message translates to:
  /// **'Platform name'**
  String get platformNamePlaceholder;

  /// No description provided for @endpointPlaceholder.
  ///
  /// In en, this message translates to:
  /// **'API endpoint URL'**
  String get endpointPlaceholder;

  /// No description provided for @configured.
  ///
  /// In en, this message translates to:
  /// **'Configured'**
  String get configured;

  /// No description provided for @notConfigured.
  ///
  /// In en, this message translates to:
  /// **'Not Configured'**
  String get notConfigured;

  /// No description provided for @models.
  ///
  /// In en, this message translates to:
  /// **'models'**
  String get models;

  /// No description provided for @available.
  ///
  /// In en, this message translates to:
  /// **'Available'**
  String get available;

  /// No description provided for @current.
  ///
  /// In en, this message translates to:
  /// **'Current'**
  String get current;

  /// No description provided for @currentModel.
  ///
  /// In en, this message translates to:
  /// **'Current Model'**
  String get currentModel;

  /// No description provided for @manageModels.
  ///
  /// In en, this message translates to:
  /// **'Manage Models'**
  String get manageModels;

  /// No description provided for @refreshModels.
  ///
  /// In en, this message translates to:
  /// **'Refresh Models'**
  String get refreshModels;

  /// No description provided for @noModelsAvailable.
  ///
  /// In en, this message translates to:
  /// **'No available models'**
  String get noModelsAvailable;

  /// No description provided for @noModelSelected.
  ///
  /// In en, this message translates to:
  /// **'No model selected'**
  String get noModelSelected;

  /// No description provided for @modelsRefreshed.
  ///
  /// In en, this message translates to:
  /// **'Model list refreshed'**
  String get modelsRefreshed;

  /// No description provided for @refreshModelsError.
  ///
  /// In en, this message translates to:
  /// **'Failed to refresh models: {error}'**
  String refreshModelsError(String error);

  /// No description provided for @deletePlatform.
  ///
  /// In en, this message translates to:
  /// **'Delete Platform'**
  String get deletePlatform;

  /// No description provided for @deletePlatformConfirm.
  ///
  /// In en, this message translates to:
  /// **'Are you sure you want to delete platform \"{name}\"?'**
  String deletePlatformConfirm(String name);

  /// No description provided for @switchToPlatform.
  ///
  /// In en, this message translates to:
  /// **'Switch to this platform'**
  String get switchToPlatform;

  /// No description provided for @switchedToPlatform.
  ///
  /// In en, this message translates to:
  /// **'Switched to {name}'**
  String switchedToPlatform(String name);

  /// No description provided for @addModelTitle.
  ///
  /// In en, this message translates to:
  /// **'Add Model'**
  String get addModelTitle;

  /// No description provided for @modelNamePh.
  ///
  /// In en, this message translates to:
  /// **'Model name'**
  String get modelNamePh;

  /// No description provided for @addModelBtn.
  ///
  /// In en, this message translates to:
  /// **'Add'**
  String get addModelBtn;

  /// No description provided for @deleteModelTitle.
  ///
  /// In en, this message translates to:
  /// **'Delete Model'**
  String get deleteModelTitle;

  /// No description provided for @deleteModelConfirm.
  ///
  /// In en, this message translates to:
  /// **'Are you sure you want to delete model \"{model}\"?'**
  String deleteModelConfirm(String model);

  /// No description provided for @deleteModelBtn.
  ///
  /// In en, this message translates to:
  /// **'Delete Selected'**
  String get deleteModelBtn;

  /// No description provided for @selectModelToDelete.
  ///
  /// In en, this message translates to:
  /// **'Please select a model to delete first'**
  String get selectModelToDelete;

  /// No description provided for @add.
  ///
  /// In en, this message translates to:
  /// **'Add'**
  String get add;

  /// No description provided for @addNewModel.
  ///
  /// In en, this message translates to:
  /// **'Add new model'**
  String get addNewModel;

  /// No description provided for @clickAddToCreate.
  ///
  /// In en, this message translates to:
  /// **'Tap the + button above to add a model'**
  String get clickAddToCreate;

  /// No description provided for @noPlatformsConfigured.
  ///
  /// In en, this message translates to:
  /// **'No platforms configured'**
  String get noPlatformsConfigured;

  /// No description provided for @addPlatformHint.
  ///
  /// In en, this message translates to:
  /// **'Tap the + button in the top right to add your first AI platform'**
  String get addPlatformHint;

  /// No description provided for @exportConversation.
  ///
  /// In en, this message translates to:
  /// **'Export Conversation'**
  String get exportConversation;

  /// No description provided for @exportFormat.
  ///
  /// In en, this message translates to:
  /// **'Export Format'**
  String get exportFormat;

  /// No description provided for @exportFormatTxt.
  ///
  /// In en, this message translates to:
  /// **'Plain Text (.txt)'**
  String get exportFormatTxt;

  /// No description provided for @exportFormatJson.
  ///
  /// In en, this message translates to:
  /// **'JSON (.json)'**
  String get exportFormatJson;

  /// No description provided for @exportFormatLumenflow.
  ///
  /// In en, this message translates to:
  /// **'Lumenflow (.lumenflow)'**
  String get exportFormatLumenflow;

  /// No description provided for @exportFormatPdf.
  ///
  /// In en, this message translates to:
  /// **'PDF (.pdf)'**
  String get exportFormatPdf;

  /// No description provided for @exportConversationSuccess.
  ///
  /// In en, this message translates to:
  /// **'Conversation exported successfully'**
  String get exportConversationSuccess;

  /// No description provided for @exportConversationFailed.
  ///
  /// In en, this message translates to:
  /// **'Conversation export failed'**
  String get exportConversationFailed;

  /// No description provided for @exportConversationError.
  ///
  /// In en, this message translates to:
  /// **'Error exporting conversation: {error}'**
  String exportConversationError(String error);
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
