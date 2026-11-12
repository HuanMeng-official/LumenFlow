import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:intl/intl.dart' as intl;

import 'app_localizations_en.dart';
import 'app_localizations_es.dart';
import 'app_localizations_ja.dart';
import 'app_localizations_ko.dart';
import 'app_localizations_lzh.dart';
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
    Locale('es'),
    Locale('ja'),
    Locale('ko'),
    Locale('lzh'),
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

  /// No description provided for @searchConversations.
  ///
  /// In en, this message translates to:
  /// **'Search conversations'**
  String get searchConversations;

  /// No description provided for @searchNoResults.
  ///
  /// In en, this message translates to:
  /// **'No matching conversations'**
  String get searchNoResults;

  /// No description provided for @searchMessages.
  ///
  /// In en, this message translates to:
  /// **'Search messages'**
  String get searchMessages;

  /// No description provided for @messageSearchHint.
  ///
  /// In en, this message translates to:
  /// **'Type to search this conversation'**
  String get messageSearchHint;

  /// No description provided for @messageSearchNoResults.
  ///
  /// In en, this message translates to:
  /// **'No matching messages'**
  String get messageSearchNoResults;

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

  /// Shown after the user saves an exported file through the system save panel.
  ///
  /// In en, this message translates to:
  /// **'Saved to the selected location'**
  String get exportSaved;

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

  /// No description provided for @importConversation.
  ///
  /// In en, this message translates to:
  /// **'Import Conversation'**
  String get importConversation;

  /// No description provided for @conversationImportSuccess.
  ///
  /// In en, this message translates to:
  /// **'Conversation imported.'**
  String get conversationImportSuccess;

  /// No description provided for @conversationImportFailed.
  ///
  /// In en, this message translates to:
  /// **'Import Conversation Failed'**
  String get conversationImportFailed;

  /// No description provided for @conversationImportInvalid.
  ///
  /// In en, this message translates to:
  /// **'Not a valid LumenFlow conversation package.'**
  String get conversationImportInvalid;

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

  /// No description provided for @pinConversation.
  ///
  /// In en, this message translates to:
  /// **'Pin'**
  String get pinConversation;

  /// No description provided for @unpinConversation.
  ///
  /// In en, this message translates to:
  /// **'Unpin'**
  String get unpinConversation;

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

  /// No description provided for @siliconflowApi.
  ///
  /// In en, this message translates to:
  /// **'SiliconFlow API'**
  String get siliconflowApi;

  /// No description provided for @minimaxApi.
  ///
  /// In en, this message translates to:
  /// **'MiniMax API'**
  String get minimaxApi;

  /// No description provided for @zhipuApi.
  ///
  /// In en, this message translates to:
  /// **'ZhipuAI API'**
  String get zhipuApi;

  /// No description provided for @kimiApi.
  ///
  /// In en, this message translates to:
  /// **'Kimi API'**
  String get kimiApi;

  /// No description provided for @lmsApi.
  ///
  /// In en, this message translates to:
  /// **'LM-Studio API'**
  String get lmsApi;

  /// No description provided for @grokApi.
  ///
  /// In en, this message translates to:
  /// **'Grok API'**
  String get grokApi;

  /// No description provided for @openrouterApi.
  ///
  /// In en, this message translates to:
  /// **'OpenRouter API'**
  String get openrouterApi;

  /// No description provided for @otherApi.
  ///
  /// In en, this message translates to:
  /// **'Other API'**
  String get otherApi;

  /// No description provided for @mimoApi.
  ///
  /// In en, this message translates to:
  /// **'XiaoMi MiMo API'**
  String get mimoApi;

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
  /// **'e.g.: gpt-6.1-sol, deepseek-flash'**
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
  /// **'Limit the length of single response, recommended 6000-10000'**
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

  /// No description provided for @memoryCompression.
  ///
  /// In en, this message translates to:
  /// **'Memory Compression'**
  String get memoryCompression;

  /// No description provided for @memoryCompressionDesc.
  ///
  /// In en, this message translates to:
  /// **'Automatically organizes the story, agreements, and rejected proposals in long conversations; stored only on this device'**
  String get memoryCompressionDesc;

  /// No description provided for @memoryCompressing.
  ///
  /// In en, this message translates to:
  /// **'Organizing memory…'**
  String get memoryCompressing;

  /// No description provided for @memoryCompressingProgress.
  ///
  /// In en, this message translates to:
  /// **'Organizing memory {current}/{total}…'**
  String memoryCompressingProgress(int current, int total);

  /// No description provided for @memoryCompressionFailed.
  ///
  /// In en, this message translates to:
  /// **'Memory update failed. Using the existing memory this time'**
  String get memoryCompressionFailed;

  /// No description provided for @viewMemory.
  ///
  /// In en, this message translates to:
  /// **'View Memory'**
  String get viewMemory;

  /// No description provided for @memoryViewerTitle.
  ///
  /// In en, this message translates to:
  /// **'Conversation Memory'**
  String get memoryViewerTitle;

  /// No description provided for @memoryViewerEmptyTitle.
  ///
  /// In en, this message translates to:
  /// **'No memory yet'**
  String get memoryViewerEmptyTitle;

  /// No description provided for @memoryViewerEmptyDesc.
  ///
  /// In en, this message translates to:
  /// **'Once a long conversation exceeds the raw context window, the AI automatically organizes the story, agreements, and rejected proposals.'**
  String get memoryViewerEmptyDesc;

  /// No description provided for @memoryViewerSummary.
  ///
  /// In en, this message translates to:
  /// **'Story so far'**
  String get memoryViewerSummary;

  /// No description provided for @memoryViewerEmotionalState.
  ///
  /// In en, this message translates to:
  /// **'Current relationship & mood'**
  String get memoryViewerEmotionalState;

  /// No description provided for @memoryViewerFacts.
  ///
  /// In en, this message translates to:
  /// **'Agreements & facts to remember'**
  String get memoryViewerFacts;

  /// No description provided for @memoryViewerSupersededFacts.
  ///
  /// In en, this message translates to:
  /// **'Superseded agreements'**
  String get memoryViewerSupersededFacts;

  /// No description provided for @memoryViewerRejected.
  ///
  /// In en, this message translates to:
  /// **'Rejected proposals'**
  String get memoryViewerRejected;

  /// No description provided for @memoryViewerReopened.
  ///
  /// In en, this message translates to:
  /// **'Under discussion again'**
  String get memoryViewerReopened;

  /// No description provided for @memoryViewerUpdatedAt.
  ///
  /// In en, this message translates to:
  /// **'Updated {time}'**
  String memoryViewerUpdatedAt(String time);

  /// No description provided for @memoryViewerLocalOnly.
  ///
  /// In en, this message translates to:
  /// **'Memory is stored only on this device and updates automatically with the conversation.'**
  String get memoryViewerLocalOnly;

  /// No description provided for @memoryTools.
  ///
  /// In en, this message translates to:
  /// **'Memory Tools'**
  String get memoryTools;

  /// No description provided for @memoryToolsAvailability.
  ///
  /// In en, this message translates to:
  /// **'Enabled automatically with Memory Compression; no separate switch.'**
  String get memoryToolsAvailability;

  /// No description provided for @memoryToolsAuto.
  ///
  /// In en, this message translates to:
  /// **'Auto'**
  String get memoryToolsAuto;

  /// No description provided for @memoryNoteToolName.
  ///
  /// In en, this message translates to:
  /// **'Remember Note'**
  String get memoryNoteToolName;

  /// No description provided for @memoryNoteToolDesc.
  ///
  /// In en, this message translates to:
  /// **'Records agreements, facts, emotional turns, or rejected proposals during the conversation; merged into memory on the next maintenance pass.'**
  String get memoryNoteToolDesc;

  /// No description provided for @memoryRecallToolName.
  ///
  /// In en, this message translates to:
  /// **'Recall'**
  String get memoryRecallToolName;

  /// No description provided for @memoryRecallToolDesc.
  ///
  /// In en, this message translates to:
  /// **'Searches older messages and the full memory ledger by keyword; available once messages fall outside the raw window.'**
  String get memoryRecallToolDesc;

  /// No description provided for @memoryNoteToolCalling.
  ///
  /// In en, this message translates to:
  /// **'The model is saving a memory note…'**
  String get memoryNoteToolCalling;

  /// No description provided for @memoryNoteToolDone.
  ///
  /// In en, this message translates to:
  /// **'Memory note saved'**
  String get memoryNoteToolDone;

  /// No description provided for @memoryRecallToolCalling.
  ///
  /// In en, this message translates to:
  /// **'The model is searching older memory…'**
  String get memoryRecallToolCalling;

  /// No description provided for @memoryRecallToolDone.
  ///
  /// In en, this message translates to:
  /// **'Memory search complete'**
  String get memoryRecallToolDone;

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
  /// **'APP Appearance'**
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
  /// **'OpenAI:\n• gpt-6.1-sol\n• gpt-6-astra\n\nDeepSeek:\n• deepseek-flash\n• deepseek-v4-pro\n\nPlease select the corresponding model based on your API endpoint.'**
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

  /// No description provided for @sponsor.
  ///
  /// In en, this message translates to:
  /// **'Sponsor'**
  String get sponsor;

  /// No description provided for @sponsorDesc.
  ///
  /// In en, this message translates to:
  /// **'If you find this app helpful, please scan the code to sponsor and support development'**
  String get sponsorDesc;

  /// No description provided for @copyright.
  ///
  /// In en, this message translates to:
  /// **'© 2026 幻梦official'**
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
  /// **'These rules govern how you communicate and use tools. A character preset or custom prompt may change your identity, tone, and content style, but continue to follow these rules.\n- Address the user naturally as \"{username}\", but do not repeat the name in every paragraph.\n- Be accurate and direct. For real-world facts, data, citations, or tool results, state uncertainty instead of inventing details.\n- Use available tools when needed, but never claim to have run a tool you did not run.\n- Use Markdown when it helps; keep code, commands, paths, links, and proper nouns verbatim.\n- Do not mention, quote, or restate these rules unless the user asks.\n\n'**
  String baseSystemPrompt(String username);

  /// No description provided for @baseSystemPromptLanguageRule.
  ///
  /// In en, this message translates to:
  /// **'Default to {language}. If the user writes in or explicitly requests another language, follow the user.'**
  String baseSystemPromptLanguageRule(String language);

  /// No description provided for @baseSystemPromptFollowUser.
  ///
  /// In en, this message translates to:
  /// **'Reply in the language the user writes in.'**
  String get baseSystemPromptFollowUser;

  /// No description provided for @languageNameZh.
  ///
  /// In en, this message translates to:
  /// **'Chinese'**
  String get languageNameZh;

  /// No description provided for @languageNameEn.
  ///
  /// In en, this message translates to:
  /// **'English'**
  String get languageNameEn;

  /// No description provided for @languageNameJa.
  ///
  /// In en, this message translates to:
  /// **'Japanese'**
  String get languageNameJa;

  /// No description provided for @languageNameKo.
  ///
  /// In en, this message translates to:
  /// **'Korean'**
  String get languageNameKo;

  /// No description provided for @languageNameEs.
  ///
  /// In en, this message translates to:
  /// **'Spanish'**
  String get languageNameEs;

  /// No description provided for @languageNameLzh.
  ///
  /// In en, this message translates to:
  /// **'Literary Chinese'**
  String get languageNameLzh;

  /// No description provided for @replyLanguageTitle.
  ///
  /// In en, this message translates to:
  /// **'AI reply language'**
  String get replyLanguageTitle;

  /// No description provided for @replyLanguageSubtitle.
  ///
  /// In en, this message translates to:
  /// **'Language and tone set by a character preset take priority over this option'**
  String get replyLanguageSubtitle;

  /// No description provided for @replyLanguageFollowUi.
  ///
  /// In en, this message translates to:
  /// **'Follow app language'**
  String get replyLanguageFollowUi;

  /// No description provided for @replyLanguageOptionFollowUser.
  ///
  /// In en, this message translates to:
  /// **'Follow user input'**
  String get replyLanguageOptionFollowUser;

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
  /// **'\nNote: DeepSeek does not support processing multimedia files such as videos and audio'**
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

  /// No description provided for @exportConversationTitle.
  ///
  /// In en, this message translates to:
  /// **'Conversation Title: '**
  String get exportConversationTitle;

  /// No description provided for @exportCreatedTime.
  ///
  /// In en, this message translates to:
  /// **'Created Time: '**
  String get exportCreatedTime;

  /// No description provided for @exportUpdatedTime.
  ///
  /// In en, this message translates to:
  /// **'Updated Time: '**
  String get exportUpdatedTime;

  /// No description provided for @exportMessageCount.
  ///
  /// In en, this message translates to:
  /// **'Message Count: '**
  String get exportMessageCount;

  /// No description provided for @exportReasoningProcess.
  ///
  /// In en, this message translates to:
  /// **'[Reasoning Process]'**
  String get exportReasoningProcess;

  /// No description provided for @exportAttachments.
  ///
  /// In en, this message translates to:
  /// **'[Attachments: {count}]'**
  String exportAttachments(int count);

  /// No description provided for @exportBytes.
  ///
  /// In en, this message translates to:
  /// **'bytes'**
  String get exportBytes;

  /// No description provided for @exportConversationNotFound.
  ///
  /// In en, this message translates to:
  /// **'Conversation not found'**
  String get exportConversationNotFound;

  /// No description provided for @exportThinkingProcess.
  ///
  /// In en, this message translates to:
  /// **'Thinking Process'**
  String get exportThinkingProcess;

  /// No description provided for @exportAttachmentsLabel.
  ///
  /// In en, this message translates to:
  /// **'Attachments'**
  String get exportAttachmentsLabel;

  /// No description provided for @notificationSettings.
  ///
  /// In en, this message translates to:
  /// **'Notification Settings'**
  String get notificationSettings;

  /// No description provided for @enableNotification.
  ///
  /// In en, this message translates to:
  /// **'Enable Notifications'**
  String get enableNotification;

  /// No description provided for @enableNotificationDesc.
  ///
  /// In en, this message translates to:
  /// **'Receive notification when AI response is completed'**
  String get enableNotificationDesc;

  /// No description provided for @dataManagement.
  ///
  /// In en, this message translates to:
  /// **'Data Management'**
  String get dataManagement;

  /// No description provided for @liveUpdateAIResponse.
  ///
  /// In en, this message translates to:
  /// **'Response'**
  String get liveUpdateAIResponse;

  /// No description provided for @enableLiveUpdate.
  ///
  /// In en, this message translates to:
  /// **'Live Update'**
  String get enableLiveUpdate;

  /// No description provided for @enableLiveUpdateDesc.
  ///
  /// In en, this message translates to:
  /// **'Show Android 16 live update notification during AI response'**
  String get enableLiveUpdateDesc;

  /// No description provided for @languageChanged.
  ///
  /// In en, this message translates to:
  /// **'Language Changed'**
  String get languageChanged;

  /// No description provided for @restartAppToApplyLanguage.
  ///
  /// In en, this message translates to:
  /// **'Please restart the app to apply the language change'**
  String get restartAppToApplyLanguage;

  /// No description provided for @loading.
  ///
  /// In en, this message translates to:
  /// **'Loading'**
  String get loading;

  /// No description provided for @copyMessage.
  ///
  /// In en, this message translates to:
  /// **'Copy message'**
  String get copyMessage;

  /// No description provided for @copySuccess.
  ///
  /// In en, this message translates to:
  /// **'Copied to clipboard'**
  String get copySuccess;

  /// No description provided for @copyFailed.
  ///
  /// In en, this message translates to:
  /// **'Copy failed'**
  String get copyFailed;

  /// No description provided for @copyError.
  ///
  /// In en, this message translates to:
  /// **'Copy error: {error}'**
  String copyError(String error);

  /// No description provided for @copySuccessTitle.
  ///
  /// In en, this message translates to:
  /// **'Copy Success'**
  String get copySuccessTitle;

  /// No description provided for @copyFailedTitle.
  ///
  /// In en, this message translates to:
  /// **'Copy Failed'**
  String get copyFailedTitle;

  /// No description provided for @copyCode.
  ///
  /// In en, this message translates to:
  /// **'Copy'**
  String get copyCode;

  /// No description provided for @copied.
  ///
  /// In en, this message translates to:
  /// **'Copied'**
  String get copied;

  /// No description provided for @downloadCode.
  ///
  /// In en, this message translates to:
  /// **'Download'**
  String get downloadCode;

  /// No description provided for @downloadCodeSuccess.
  ///
  /// In en, this message translates to:
  /// **'Code downloaded'**
  String get downloadCodeSuccess;

  /// No description provided for @downloadCodeFailed.
  ///
  /// In en, this message translates to:
  /// **'Failed to download code'**
  String get downloadCodeFailed;

  /// No description provided for @aiResponseDisclaimer.
  ///
  /// In en, this message translates to:
  /// **'Content is for reference only, please verify carefully'**
  String get aiResponseDisclaimer;

  /// No description provided for @advancedSettings.
  ///
  /// In en, this message translates to:
  /// **'Advanced'**
  String get advancedSettings;

  /// No description provided for @advancedSettingsSubtitle.
  ///
  /// In en, this message translates to:
  /// **'Configure app behavior'**
  String get advancedSettingsSubtitle;

  /// No description provided for @userProfileSubtitle.
  ///
  /// In en, this message translates to:
  /// **'Personalize your account'**
  String get userProfileSubtitle;

  /// No description provided for @platformAndModelSubtitle.
  ///
  /// In en, this message translates to:
  /// **'Configure AI platforms and models'**
  String get platformAndModelSubtitle;

  /// No description provided for @apiTypeSubtitle.
  ///
  /// In en, this message translates to:
  /// **'Set up API connection parameters'**
  String get apiTypeSubtitle;

  /// No description provided for @modelSettingsSubtitle.
  ///
  /// In en, this message translates to:
  /// **'Adjust model response behavior'**
  String get modelSettingsSubtitle;

  /// No description provided for @historyConversationSubtitle.
  ///
  /// In en, this message translates to:
  /// **'Manage conversation history'**
  String get historyConversationSubtitle;

  /// No description provided for @toolsSettingsSubtitle.
  ///
  /// In en, this message translates to:
  /// **'Configure external tools'**
  String get toolsSettingsSubtitle;

  /// No description provided for @appearanceSubtitle.
  ///
  /// In en, this message translates to:
  /// **'Customize app appearance'**
  String get appearanceSubtitle;

  /// No description provided for @credits.
  ///
  /// In en, this message translates to:
  /// **'Credits'**
  String get credits;

  /// No description provided for @creditsMainDeveloper.
  ///
  /// In en, this message translates to:
  /// **'Main Developer'**
  String get creditsMainDeveloper;

  /// No description provided for @creditsAppImprovementSuggestions.
  ///
  /// In en, this message translates to:
  /// **'App Improvement Suggestions'**
  String get creditsAppImprovementSuggestions;

  /// No description provided for @creditsAppImprovementAndCode.
  ///
  /// In en, this message translates to:
  /// **'App Improvement and Partial Code'**
  String get creditsAppImprovementAndCode;

  /// No description provided for @creditsBugTestingAndCode.
  ///
  /// In en, this message translates to:
  /// **'Bug Testing and Partial Code'**
  String get creditsBugTestingAndCode;

  /// No description provided for @creditsDescription.
  ///
  /// In en, this message translates to:
  /// **'Special thanks to the following contributors for their invaluable support:'**
  String get creditsDescription;

  /// No description provided for @contributors.
  ///
  /// In en, this message translates to:
  /// **'Contributors'**
  String get contributors;

  /// No description provided for @editMessage.
  ///
  /// In en, this message translates to:
  /// **'Edit message'**
  String get editMessage;

  /// No description provided for @regenerateResponse.
  ///
  /// In en, this message translates to:
  /// **'Regenerate response'**
  String get regenerateResponse;

  /// No description provided for @resubmit.
  ///
  /// In en, this message translates to:
  /// **'Resubmit'**
  String get resubmit;

  /// No description provided for @editMessageHint.
  ///
  /// In en, this message translates to:
  /// **'Edit message content'**
  String get editMessageHint;

  /// No description provided for @confirmEdit.
  ///
  /// In en, this message translates to:
  /// **'Confirm edit'**
  String get confirmEdit;

  /// No description provided for @editMessageDialogTitle.
  ///
  /// In en, this message translates to:
  /// **'Edit message'**
  String get editMessageDialogTitle;

  /// No description provided for @regenerateConfirm.
  ///
  /// In en, this message translates to:
  /// **'Regenerate this AI response?'**
  String get regenerateConfirm;

  /// No description provided for @continueGeneration.
  ///
  /// In en, this message translates to:
  /// **'Continue generating'**
  String get continueGeneration;

  /// No description provided for @continueGenerationPrompt.
  ///
  /// In en, this message translates to:
  /// **'Continue the previous assistant response from where it stopped. Do not repeat content that has already been written.'**
  String get continueGenerationPrompt;

  /// No description provided for @forkConversation.
  ///
  /// In en, this message translates to:
  /// **'Fork from here'**
  String get forkConversation;

  /// No description provided for @deleteMessage.
  ///
  /// In en, this message translates to:
  /// **'Delete message'**
  String get deleteMessage;

  /// No description provided for @deleteMessageConfirm.
  ///
  /// In en, this message translates to:
  /// **'Delete this message?'**
  String get deleteMessageConfirm;

  /// No description provided for @messageOptions.
  ///
  /// In en, this message translates to:
  /// **'Message options'**
  String get messageOptions;

  /// No description provided for @presetManagement.
  ///
  /// In en, this message translates to:
  /// **'Preset Management'**
  String get presetManagement;

  /// No description provided for @presetManagementSubtitle.
  ///
  /// In en, this message translates to:
  /// **'Manage built-in and user-imported prompts'**
  String get presetManagementSubtitle;

  /// No description provided for @presetIssuesTitle.
  ///
  /// In en, this message translates to:
  /// **'Preset load issues'**
  String get presetIssuesTitle;

  /// No description provided for @presetIssuesCount.
  ///
  /// In en, this message translates to:
  /// **'{count} issues, tap to view'**
  String presetIssuesCount(int count);

  /// No description provided for @presetIssueBuiltInMetaMissing.
  ///
  /// In en, this message translates to:
  /// **'Built-in preset file not found (tried: {locales})'**
  String presetIssueBuiltInMetaMissing(String locales);

  /// No description provided for @presetIssueUserJsonCorrupt.
  ///
  /// In en, this message translates to:
  /// **'User preset JSON is corrupt; backed up to {backup}'**
  String presetIssueUserJsonCorrupt(String backup);

  /// No description provided for @presetIssueCardFileMissing.
  ///
  /// In en, this message translates to:
  /// **'Character card file missing: {name}'**
  String presetIssueCardFileMissing(String name);

  /// No description provided for @presetIssueCardFileUnreadable.
  ///
  /// In en, this message translates to:
  /// **'Character card file unreadable: {name}'**
  String presetIssueCardFileUnreadable(String name);

  /// No description provided for @presetIssueUserEntryInvalid.
  ///
  /// In en, this message translates to:
  /// **'One user preset entry could not be read: {detail}'**
  String presetIssueUserEntryInvalid(String detail);

  /// No description provided for @presetIssueUserJsonWriteFailed.
  ///
  /// In en, this message translates to:
  /// **'Failed to save user presets: {detail}'**
  String presetIssueUserJsonWriteFailed(String detail);

  /// No description provided for @presetIssueUserMigrationBackupFailed.
  ///
  /// In en, this message translates to:
  /// **'Could not back up legacy presets; migration skipped: {detail}'**
  String presetIssueUserMigrationBackupFailed(String detail);

  /// No description provided for @presetIssueUserJsonCorruptNoBackup.
  ///
  /// In en, this message translates to:
  /// **'User preset JSON is corrupt and the backup failed: {detail}'**
  String presetIssueUserJsonCorruptNoBackup(String detail);

  /// No description provided for @presetBrokenLabel.
  ///
  /// In en, this message translates to:
  /// **'File missing'**
  String get presetBrokenLabel;

  /// No description provided for @presetBrokenReason.
  ///
  /// In en, this message translates to:
  /// **'Reason: {reason}'**
  String presetBrokenReason(String reason);

  /// No description provided for @presetUnavailableTitle.
  ///
  /// In en, this message translates to:
  /// **'Character unavailable'**
  String get presetUnavailableTitle;

  /// No description provided for @presetUnavailableMessage.
  ///
  /// In en, this message translates to:
  /// **'The character preset used by this conversation is missing or was deleted.'**
  String get presetUnavailableMessage;

  /// No description provided for @presetDisableAndSend.
  ///
  /// In en, this message translates to:
  /// **'Turn off role mode and send'**
  String get presetDisableAndSend;

  /// No description provided for @presetUnavailableBadge.
  ///
  /// In en, this message translates to:
  /// **'Character unavailable'**
  String get presetUnavailableBadge;

  /// No description provided for @builtInPresets.
  ///
  /// In en, this message translates to:
  /// **'Built-in Presets'**
  String get builtInPresets;

  /// No description provided for @userPresets.
  ///
  /// In en, this message translates to:
  /// **'User Presets'**
  String get userPresets;

  /// No description provided for @noPresetsAvailable.
  ///
  /// In en, this message translates to:
  /// **'No presets available'**
  String get noPresetsAvailable;

  /// No description provided for @importXmlHint.
  ///
  /// In en, this message translates to:
  /// **'Tap the + button in the top right to import XML files'**
  String get importXmlHint;

  /// No description provided for @importPresetDialogTitle.
  ///
  /// In en, this message translates to:
  /// **'Import Preset'**
  String get importPresetDialogTitle;

  /// No description provided for @presetNamePlaceholder.
  ///
  /// In en, this message translates to:
  /// **'Preset Name'**
  String get presetNamePlaceholder;

  /// No description provided for @descriptionPlaceholder.
  ///
  /// In en, this message translates to:
  /// **'Description'**
  String get descriptionPlaceholder;

  /// No description provided for @authorPlaceholder.
  ///
  /// In en, this message translates to:
  /// **'Author'**
  String get authorPlaceholder;

  /// No description provided for @importButton.
  ///
  /// In en, this message translates to:
  /// **'Import'**
  String get importButton;

  /// No description provided for @presetImportErrorTitle.
  ///
  /// In en, this message translates to:
  /// **'Cannot import character card'**
  String get presetImportErrorTitle;

  /// No description provided for @presetImportErrorEmpty.
  ///
  /// In en, this message translates to:
  /// **'The file is empty.'**
  String get presetImportErrorEmpty;

  /// No description provided for @presetImportErrorTooLarge.
  ///
  /// In en, this message translates to:
  /// **'The file exceeds the 200 KB limit.'**
  String get presetImportErrorTooLarge;

  /// No description provided for @presetImportErrorInvalidUtf8.
  ///
  /// In en, this message translates to:
  /// **'The file is not valid UTF-8 text.'**
  String get presetImportErrorInvalidUtf8;

  /// No description provided for @presetImportErrorInvalidXml.
  ///
  /// In en, this message translates to:
  /// **'The XML is malformed.'**
  String get presetImportErrorInvalidXml;

  /// No description provided for @presetImportErrorInvalidRoot.
  ///
  /// In en, this message translates to:
  /// **'The root element must be <system_instruction>.'**
  String get presetImportErrorInvalidRoot;

  /// No description provided for @presetImportWarningNameMissing.
  ///
  /// In en, this message translates to:
  /// **'No <role_name> found; the file name will be used.'**
  String get presetImportWarningNameMissing;

  /// No description provided for @presetImportDuplicateTitle.
  ///
  /// In en, this message translates to:
  /// **'Character card already exists'**
  String get presetImportDuplicateTitle;

  /// No description provided for @presetImportDuplicateMessage.
  ///
  /// In en, this message translates to:
  /// **'\"{name}\" already exists. Import anyway?'**
  String presetImportDuplicateMessage(String name);

  /// No description provided for @presetImportAnyway.
  ///
  /// In en, this message translates to:
  /// **'Import anyway'**
  String get presetImportAnyway;

  /// No description provided for @presetIconLabel.
  ///
  /// In en, this message translates to:
  /// **'Icon'**
  String get presetIconLabel;

  /// No description provided for @presetVersionPlaceholder.
  ///
  /// In en, this message translates to:
  /// **'Version'**
  String get presetVersionPlaceholder;

  /// No description provided for @presetLanguageLabel.
  ///
  /// In en, this message translates to:
  /// **'Language'**
  String get presetLanguageLabel;

  /// No description provided for @presetLanguageAny.
  ///
  /// In en, this message translates to:
  /// **'Any'**
  String get presetLanguageAny;

  /// No description provided for @presetTagsPlaceholder.
  ///
  /// In en, this message translates to:
  /// **'Tags (comma separated)'**
  String get presetTagsPlaceholder;

  /// No description provided for @presetFilterAll.
  ///
  /// In en, this message translates to:
  /// **'All'**
  String get presetFilterAll;

  /// No description provided for @presetFilterNoResults.
  ///
  /// In en, this message translates to:
  /// **'No presets match this filter'**
  String get presetFilterNoResults;

  /// No description provided for @presetEditTitle.
  ///
  /// In en, this message translates to:
  /// **'Edit Preset'**
  String get presetEditTitle;

  /// No description provided for @presetSave.
  ///
  /// In en, this message translates to:
  /// **'Save'**
  String get presetSave;

  /// No description provided for @presetDuplicate.
  ///
  /// In en, this message translates to:
  /// **'Duplicate as my copy'**
  String get presetDuplicate;

  /// No description provided for @presetDuplicateSuffix.
  ///
  /// In en, this message translates to:
  /// **' (copy)'**
  String get presetDuplicateSuffix;

  /// No description provided for @presetExport.
  ///
  /// In en, this message translates to:
  /// **'Export XML'**
  String get presetExport;

  /// No description provided for @presetExportSuccess.
  ///
  /// In en, this message translates to:
  /// **'Exported'**
  String get presetExportSuccess;

  /// No description provided for @presetExportFailed.
  ///
  /// In en, this message translates to:
  /// **'Export failed'**
  String get presetExportFailed;

  /// No description provided for @includePresetCard.
  ///
  /// In en, this message translates to:
  /// **'Include character card content'**
  String get includePresetCard;

  /// No description provided for @includePresetCardHint.
  ///
  /// In en, this message translates to:
  /// **'May contain private content; only applies to JSON / LumenFlow'**
  String get includePresetCardHint;

  /// No description provided for @importPresetSnapshotTitle.
  ///
  /// In en, this message translates to:
  /// **'Import character card'**
  String get importPresetSnapshotTitle;

  /// No description provided for @importPresetSnapshotMessage.
  ///
  /// In en, this message translates to:
  /// **'Import character card \"{name}\"?'**
  String importPresetSnapshotMessage(String name);

  /// No description provided for @presetTokenEstimate.
  ///
  /// In en, this message translates to:
  /// **'About {count} tokens'**
  String presetTokenEstimate(int count);

  /// No description provided for @presetTokenWarning.
  ///
  /// In en, this message translates to:
  /// **'Over 4000 tokens: this content is resent on every turn.'**
  String get presetTokenWarning;

  /// No description provided for @presetTokenStrongWarning.
  ///
  /// In en, this message translates to:
  /// **'Over 8000 tokens: consider trimming the character card.'**
  String get presetTokenStrongWarning;

  /// No description provided for @presetFullContent.
  ///
  /// In en, this message translates to:
  /// **'Full content'**
  String get presetFullContent;

  /// No description provided for @deletePresetDialogTitle.
  ///
  /// In en, this message translates to:
  /// **'Delete Preset'**
  String get deletePresetDialogTitle;

  /// No description provided for @deletePresetConfirm.
  ///
  /// In en, this message translates to:
  /// **'Are you sure you want to delete preset \"{presetName}\"?'**
  String deletePresetConfirm(String presetName);

  /// No description provided for @presetDeletedSuccess.
  ///
  /// In en, this message translates to:
  /// **'Deleted: {presetName}'**
  String presetDeletedSuccess(String presetName);

  /// No description provided for @importFailedError.
  ///
  /// In en, this message translates to:
  /// **'Import failed: {error}'**
  String importFailedError(String error);

  /// No description provided for @deleteFailedError.
  ///
  /// In en, this message translates to:
  /// **'Delete failed: {error}'**
  String deleteFailedError(String error);

  /// No description provided for @filePathError.
  ///
  /// In en, this message translates to:
  /// **'Unable to get file path'**
  String get filePathError;

  /// No description provided for @authorLabel.
  ///
  /// In en, this message translates to:
  /// **'Author:'**
  String get authorLabel;

  /// No description provided for @versionLabel.
  ///
  /// In en, this message translates to:
  /// **'Version:'**
  String get versionLabel;

  /// No description provided for @descriptionLabel.
  ///
  /// In en, this message translates to:
  /// **'Description:'**
  String get descriptionLabel;

  /// No description provided for @systemPromptLabel.
  ///
  /// In en, this message translates to:
  /// **'System Prompt:'**
  String get systemPromptLabel;

  /// No description provided for @closeButton.
  ///
  /// In en, this message translates to:
  /// **'Close'**
  String get closeButton;

  /// No description provided for @loadPresetsFailed.
  ///
  /// In en, this message translates to:
  /// **'Failed to load presets: {error}'**
  String loadPresetsFailed(String error);

  /// No description provided for @roleCardGeneratorLink.
  ///
  /// In en, this message translates to:
  /// **'Role Card Generator'**
  String get roleCardGeneratorLink;

  /// No description provided for @httpServerSwitchLabel.
  ///
  /// In en, this message translates to:
  /// **'Role Card Generator Server'**
  String get httpServerSwitchLabel;

  /// No description provided for @httpServerStatusRunning.
  ///
  /// In en, this message translates to:
  /// **'Running'**
  String get httpServerStatusRunning;

  /// No description provided for @httpServerStatusStopped.
  ///
  /// In en, this message translates to:
  /// **'Stopped'**
  String get httpServerStatusStopped;

  /// No description provided for @openGeneratorButton.
  ///
  /// In en, this message translates to:
  /// **'Open Generator'**
  String get openGeneratorButton;

  /// No description provided for @httpServerDescription.
  ///
  /// In en, this message translates to:
  /// **'Server running on port 5050, serving the role card generator page.'**
  String get httpServerDescription;

  /// No description provided for @httpServerNotRunningTitle.
  ///
  /// In en, this message translates to:
  /// **'Server Not Running'**
  String get httpServerNotRunningTitle;

  /// No description provided for @httpServerNotRunningMessage.
  ///
  /// In en, this message translates to:
  /// **'The role card generator server is not running. Do you want to start the server?'**
  String get httpServerNotRunningMessage;

  /// No description provided for @startServerButton.
  ///
  /// In en, this message translates to:
  /// **'Start'**
  String get startServerButton;

  /// No description provided for @httpServerToggleTooltip.
  ///
  /// In en, this message translates to:
  /// **'Toggle HTTP server status'**
  String get httpServerToggleTooltip;

  /// No description provided for @openLinkFailed.
  ///
  /// In en, this message translates to:
  /// **'Failed to open link: {error}'**
  String openLinkFailed(String error);

  /// No description provided for @currentTime.
  ///
  /// In en, this message translates to:
  /// **'The following is the current time; do not proactively state the time unless the user asks:'**
  String get currentTime;

  /// No description provided for @httpServerOperationFailed.
  ///
  /// In en, this message translates to:
  /// **'HTTP server operation failed: {error}'**
  String httpServerOperationFailed(String error);

  /// No description provided for @chatBackground.
  ///
  /// In en, this message translates to:
  /// **'Chat Background'**
  String get chatBackground;

  /// No description provided for @selectBackgroundImage.
  ///
  /// In en, this message translates to:
  /// **'Select Background Image'**
  String get selectBackgroundImage;

  /// No description provided for @changeBackgroundImage.
  ///
  /// In en, this message translates to:
  /// **'Change Background Image'**
  String get changeBackgroundImage;

  /// No description provided for @selectBackgroundImageDesc.
  ///
  /// In en, this message translates to:
  /// **'Select an image as chat background'**
  String get selectBackgroundImageDesc;

  /// No description provided for @currentBackgroundImage.
  ///
  /// In en, this message translates to:
  /// **'Background image set'**
  String get currentBackgroundImage;

  /// No description provided for @clear.
  ///
  /// In en, this message translates to:
  /// **'Clear'**
  String get clear;

  /// No description provided for @backgroundOpacity.
  ///
  /// In en, this message translates to:
  /// **'Background Opacity'**
  String get backgroundOpacity;

  /// No description provided for @backgroundOpacityDesc.
  ///
  /// In en, this message translates to:
  /// **'Adjust background image transparency'**
  String get backgroundOpacityDesc;

  /// No description provided for @selectImageFailed.
  ///
  /// In en, this message translates to:
  /// **'Failed to select image'**
  String get selectImageFailed;

  /// No description provided for @clearBackgroundImage.
  ///
  /// In en, this message translates to:
  /// **'Clear Background Image'**
  String get clearBackgroundImage;

  /// No description provided for @clearBackgroundImageConfirm.
  ///
  /// In en, this message translates to:
  /// **'Are you sure you want to clear the background image?'**
  String get clearBackgroundImageConfirm;

  /// No description provided for @birthday.
  ///
  /// In en, this message translates to:
  /// **'Birthday'**
  String get birthday;

  /// No description provided for @birthdayHint.
  ///
  /// In en, this message translates to:
  /// **'Select your birthday date'**
  String get birthdayHint;

  /// No description provided for @selectBirthday.
  ///
  /// In en, this message translates to:
  /// **'Select Birthday'**
  String get selectBirthday;

  /// No description provided for @toolManagement.
  ///
  /// In en, this message translates to:
  /// **'Tool Management'**
  String get toolManagement;

  /// No description provided for @promptTools.
  ///
  /// In en, this message translates to:
  /// **'Tools'**
  String get promptTools;

  /// No description provided for @addTimeToPrompt.
  ///
  /// In en, this message translates to:
  /// **'Time'**
  String get addTimeToPrompt;

  /// No description provided for @addTimeToPromptDesc.
  ///
  /// In en, this message translates to:
  /// **'Get time'**
  String get addTimeToPromptDesc;

  /// No description provided for @builtinCalculator.
  ///
  /// In en, this message translates to:
  /// **'Calculator'**
  String get builtinCalculator;

  /// No description provided for @builtinCalculatorDesc.
  ///
  /// In en, this message translates to:
  /// **'Evaluate arithmetic'**
  String get builtinCalculatorDesc;

  /// No description provided for @builtinTextTools.
  ///
  /// In en, this message translates to:
  /// **'Text tools'**
  String get builtinTextTools;

  /// No description provided for @builtinTextToolsDesc.
  ///
  /// In en, this message translates to:
  /// **'Compare and count text'**
  String get builtinTextToolsDesc;

  /// No description provided for @builtinDateMath.
  ///
  /// In en, this message translates to:
  /// **'Date math'**
  String get builtinDateMath;

  /// No description provided for @builtinDateMathDesc.
  ///
  /// In en, this message translates to:
  /// **'Date differences, adding dates, and weekday info'**
  String get builtinDateMathDesc;

  /// No description provided for @builtinLunarCalendar.
  ///
  /// In en, this message translates to:
  /// **'Lunar calendar'**
  String get builtinLunarCalendar;

  /// No description provided for @builtinLunarCalendarDesc.
  ///
  /// In en, this message translates to:
  /// **'Convert solar and Chinese lunar dates'**
  String get builtinLunarCalendarDesc;

  /// No description provided for @builtinUnitConvert.
  ///
  /// In en, this message translates to:
  /// **'Unit converter'**
  String get builtinUnitConvert;

  /// No description provided for @builtinUnitConvertDesc.
  ///
  /// In en, this message translates to:
  /// **'Convert length, mass, temperature, and more'**
  String get builtinUnitConvertDesc;
}

class _AppLocalizationsDelegate extends LocalizationsDelegate<AppLocalizations> {
  const _AppLocalizationsDelegate();

  @override
  Future<AppLocalizations> load(Locale locale) {
    return SynchronousFuture<AppLocalizations>(lookupAppLocalizations(locale));
  }

  @override
  bool isSupported(Locale locale) => <String>['en', 'es', 'ja', 'ko', 'lzh', 'zh'].contains(locale.languageCode);

  @override
  bool shouldReload(_AppLocalizationsDelegate old) => false;
}

AppLocalizations lookupAppLocalizations(Locale locale) {


  // Lookup logic when only language code is specified.
  switch (locale.languageCode) {
    case 'en': return AppLocalizationsEn();
    case 'es': return AppLocalizationsEs();
    case 'ja': return AppLocalizationsJa();
    case 'ko': return AppLocalizationsKo();
    case 'lzh': return AppLocalizationsLzh();
    case 'zh': return AppLocalizationsZh();
  }

  throw FlutterError(
    'AppLocalizations.delegate failed to load unsupported locale "$locale". This is likely '
    'an issue with the localizations generation tool. Please file an issue '
    'on GitHub with a reproducible sample app and the gen-l10n configuration '
    'that was used.'
  );
}
