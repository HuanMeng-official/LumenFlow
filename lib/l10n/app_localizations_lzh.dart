// ignore: unused_import
import 'package:intl/intl.dart' as intl;
import 'app_localizations.dart';

// ignore_for_file: type=lint

/// The translations for Literary Chinese (`lzh`).
class AppLocalizationsLzh extends AppLocalizations {
  AppLocalizationsLzh([String locale = 'lzh']) : super(locale);

  @override
  String get appTitle => '流光';

  @override
  String get appSubtitle => '與靈犀對談';

  @override
  String get chat => '對談';

  @override
  String get settings => '規度';

  @override
  String get about => '本末';

  @override
  String get conversations => '對談舊錄';

  @override
  String get newConversation => '新闢一局';

  @override
  String get noConversations => '尚無對談之錄';

  @override
  String get createNewConversation => '新闢一局對談';

  @override
  String get aiAssistant => '靈犀佐使';

  @override
  String get startChatting => '且與靈犀開言！';

  @override
  String get pleaseConfigureAPI => '祈先設樞機方可開言';

  @override
  String get settingsButton => '規度';

  @override
  String get needConfiguration => '尚待規度';

  @override
  String get configureAPIPrompt => '祈先於規度中設樞機渡口與符節';

  @override
  String get cancel => '罷休';

  @override
  String get confirm => '允定';

  @override
  String get save => '存錄';

  @override
  String get delete => '裁撤';

  @override
  String get edit => '修訂';

  @override
  String get ok => '善';

  @override
  String get goToSettings => '往赴規度';

  @override
  String get clearConversation => '滌除此談';

  @override
  String get clearConversationConfirm => '確欲滌除此局之悉數言語乎？';

  @override
  String get deleteConversation => '芟除此談';

  @override
  String deleteConversationConfirm(String title) {
    return '確欲芟除「$title」乎？覆水難收。';
  }

  @override
  String get editConversationTitle => '修訂談名';

  @override
  String get enterConversationTitle => '賜題談名';

  @override
  String get saveSuccess => '存錄已妥';

  @override
  String get settingsSaved => '規度已存';

  @override
  String get saveFailed => '存錄未果';

  @override
  String saveError(String error) {
    return '存錄生乖謬: $error';
  }

  @override
  String get resetSettings => '返本歸元';

  @override
  String get resetSettingsConfirm => '確欲返本歸元乎？諸般規度皆將消散。';

  @override
  String get exportSettings => '謄錄規度';

  @override
  String get exportSuccess => '謄錄已妥';

  @override
  String exportLocation(String location, String path) {
    return '規度已謄於$location之中：\n$path';
  }

  @override
  String get exportFailed => '謄錄未果';

  @override
  String exportError(String error) {
    return '謄錄生乖謬: $error\n\n祈察有否藏書之權，且觀庫房尚有隙地否。';
  }

  @override
  String get importSettings => '匯入規度';

  @override
  String get importSettingsConfirm => '此舉將覆故有之規度，確欲匯入乎？';

  @override
  String get importSuccess => '匯入已妥';

  @override
  String get settingsImported => '規度匯入無恙。';

  @override
  String get importFailed => '匯入未果';

  @override
  String importError(String error) {
    return '匯入生乖謬: $error';
  }

  @override
  String get error => '乖謬';

  @override
  String get responseInterrupted => '回話中絕，本器恐已星散';

  @override
  String get yesterday => '昨日';

  @override
  String daysAgo(int days) {
    return '$days日前';
  }

  @override
  String get editTitle => '修訂題名';

  @override
  String get deleteConversation2 => '芟除此談';

  @override
  String get userInfo => '閣下生平';

  @override
  String get userProfile => '容貌名諱';

  @override
  String get userProfileDesc => '設小像與尊號';

  @override
  String get basicSettings => '根本規度';

  @override
  String get apiType => '樞機法式';

  @override
  String get openaiApi => 'OpenAI 樞機';

  @override
  String get geminiApi => 'Gemini 樞機';

  @override
  String get deepseekApi => 'DeepSeek 樞機';

  @override
  String get claudeApi => 'Claude 樞機';

  @override
  String get siliconflowApi => 'SiliconFlow 樞機';

  @override
  String get minimaxApi => 'MiniMax 樞機';

  @override
  String get zhipuApi => '智譜 樞機';

  @override
  String get kimiApi => 'Kimi 樞機';

  @override
  String get lmsApi => 'LM-Studio 樞機';

  @override
  String get grokApi => 'Grok 樞機';

  @override
  String get openrouterApi => 'OpenRouter 樞機';

  @override
  String get otherApi => '他邦樞機';

  @override
  String get mimoApi => '小米 MiMo 樞機';

  @override
  String get apiTypeDesc => '擇靈犀之門戶';

  @override
  String get apiEndpoint => '樞機渡口';

  @override
  String get apiEndpointPlaceholder => '賜下樞機渡口之址';

  @override
  String get apiEndpointDesc => '如: https://api.openai.com/v1';

  @override
  String get apiKey => '樞機符節';

  @override
  String get apiKeyPlaceholder => '樞機符節';

  @override
  String get apiKeyDesc => '自靈犀門戶求得之勘合符節';

  @override
  String get modelSettings => '法象規度';

  @override
  String get model => '法象';

  @override
  String get modelPlaceholder => '賜下法象之名';

  @override
  String get modelDesc => '如: gpt-5, deepseek-chat';

  @override
  String get maxTokens => '至多言數';

  @override
  String get maxTokensPlaceholder => '賜下至多言數';

  @override
  String get maxTokensDesc => '限其單次回話之長，宜在六千至萬言之間';

  @override
  String get systemPrompt => '開宗明義';

  @override
  String get systemPromptPlaceholder => '賜下開宗明義之言';

  @override
  String get systemPromptDesc => '如：恆以文言對答';

  @override
  String get temperature => '性情之烈';

  @override
  String get temperatureDesc => '馭其變幻之度，自零至二，愈高則言辭愈奇';

  @override
  String get historyConversation => '前塵舊錄';

  @override
  String get enableHistory => '通曉前塵';

  @override
  String get enableHistoryDesc => '啓之則靈犀不忘前言，對答自能貫通';

  @override
  String get historyRounds => '追溯前塵之數';

  @override
  String get historyRoundsPlaceholder => '賜下追溯之回數';

  @override
  String get historyRoundsDesc => '靈犀所記前言之回數，宜五至二十回，過甚恐越言數之限';

  @override
  String get conversationTitle => '對談題名';

  @override
  String get autoGenerateTitle => '自擬題名';

  @override
  String get autoGenerateTitleDesc => '對談數回，靈犀自度其意以擬題';

  @override
  String get generateTiming => '擬題時機';

  @override
  String get generateTimingDesc => '定數回之後自擬題名';

  @override
  String get rounds => '回';

  @override
  String get appearance => '外觀容止';

  @override
  String get followSystem => '隨順天時';

  @override
  String get followSystemDesc => '自隨天時明暗之化';

  @override
  String get appColor => '本器設色';

  @override
  String get lightMode => '晝明之色';

  @override
  String get darkMode => '夜闇之色';

  @override
  String followSystemSetting(String mode) {
    return '依循中樞（$mode）';
  }

  @override
  String get selectColorMode => '擇本器之明暗';

  @override
  String get others => '雜項';

  @override
  String get resetToDefault => '返本歸元';

  @override
  String get commonApiEndpoints => '常見樞機渡口';

  @override
  String get commonApiEndpointsContent => 'OpenAI: https://api.openai.com/v1\n\nDeepSeek: https://api.deepseek.com\n\n阿里雲: https://dashscope.aliyuncs.com/api/v1\n\n祈察閣下所用之靈犀門戶，填其相應渡口。';

  @override
  String get commonModels => '常見法象';

  @override
  String get commonModelsContent => 'OpenAI:\n• gpt-5\n\nDeepSeek:\n• deepseek-chat\n• deepseek-reasoner\n\n祈察渡口以擇相應法象。';

  @override
  String get appInfo => '本器綱要';

  @override
  String get version => '修次';

  @override
  String get buildDate => '鳩工之日';

  @override
  String get developer => '營造匠人';

  @override
  String get features => '妙用諸端';

  @override
  String get intelligentConversation => '慧心清言';

  @override
  String get intelligentConversationDesc => '可與諸般法象作雅言之會';

  @override
  String get fileProcessing => '案牘披閱';

  @override
  String get fileProcessingDesc => '能納丹青、卷宗諸般文檔';

  @override
  String get historyRecords => '起居舊錄';

  @override
  String get historyRecordsDesc => '自存對語往來，通曉前言後語';

  @override
  String get customSettings => '隨心規度';

  @override
  String get customSettingsDesc => '樞機、設色、諸般巧思皆可自專';

  @override
  String get licenses => '開源文牒';

  @override
  String get sponsor => '賜金';

  @override
  String get sponsorDesc => '若覺此器堪用，幸掃符籙賜金以助營造';

  @override
  String get copyright => '© 2026 幻夢official';

  @override
  String get copyrightNotice => '此器徒供講學格物之用';

  @override
  String get copyrightTerms => '啟刃前祈遵諸門戶樞機之條陳';

  @override
  String get profileSaved => '閣下生平已存錄';

  @override
  String saveProfileError(String error) {
    return '存錄生平生乖謬: $error';
  }

  @override
  String get pickAvatarFailed => '擇小像未果';

  @override
  String get takePhotoFailed => '寫真未果';

  @override
  String get selectEmojiAvatar => '擇面譜作小像';

  @override
  String get selectAvatar => '擇小像';

  @override
  String get selectFromGallery => '自畫苑中擇取';

  @override
  String get takePhoto => '對鏡寫真';

  @override
  String get selectEmoji => '擇面譜';

  @override
  String get tapToChangeAvatar => '輕觸易貌';

  @override
  String get username => '尊號';

  @override
  String get usernameHint => '靈犀將以此名相稱';

  @override
  String get enterYourUsername => '賜下尊號';

  @override
  String get gender => '性別';

  @override
  String get genderHint => '定閣下之性別';

  @override
  String get male => '男';

  @override
  String get female => '女';

  @override
  String get selectGender => '定性別';

  @override
  String get aboutUserProfile => '生平敘略';

  @override
  String get aboutUserProfileContent => '• 小像：可擇畫像或面譜，示於對談之卷首\n• 尊號：靈犀對答時以此相稱\n• 諸般底細皆藏於本地，不登聞於雲端';

  @override
  String get selectPresetRole => '擇定先哲';

  @override
  String get selectPresetRoleMessage => '擇一預設身分，以定其開宗明義';

  @override
  String get closePresetMode => '罷免身分';

  @override
  String get continueAction => '賡續';

  @override
  String get deepThinking => '冥思苦索';

  @override
  String get rolePlay => '優孟衣冠';

  @override
  String get language => '雅言';

  @override
  String get interfaceLanguage => '器物之語';

  @override
  String get selectInterfaceLanguage => '擇此器所用之語';

  @override
  String get thinkChain => '推演之理';

  @override
  String get expandChain => '觀其推演之跡';

  @override
  String get downloadDirectory => '拓本之所';

  @override
  String get externalStorageDirectory => '外庫';

  @override
  String get appDocumentsDirectory => '本器書閣';

  @override
  String get imagePreview => '畫軸先觀';

  @override
  String get unableToLoadImage => '畫軸難舒';

  @override
  String get errorPrefix => '謬矣';

  @override
  String get fileTooLarge => '案牘過厚';

  @override
  String fileTooLargeMessage(String size, String limit) {
    return '所奉案牘厚計$size，已越$limit之制。祈以薄紙輕簡之。';
  }

  @override
  String get fileTooLargeWarning => '案牘過厚之誡';

  @override
  String fileTooLargeWarningMessage(String limit, String files) {
    return '下列案牘逾越$limit之制，恐難披閱：\n\n$files\n\n確欲強遞乎？';
  }

  @override
  String get noValidFiles => '無實文';

  @override
  String get noValidFilesMessage => '未得隻字片紙，祈再試之。';

  @override
  String get selectFileFailed => '擇案牘未果';

  @override
  String selectFileFailedMessage(String error) {
    return '乖謬：$error';
  }

  @override
  String get user => '閣下';

  @override
  String get ai => '靈犀';

  @override
  String get unknownError => '無名之謬';

  @override
  String attachmentInfo(String fileName, String fileSize, String mimeType) {
    return '隨附: $fileName ($fileSize, $mimeType)';
  }

  @override
  String get attachmentCannotRead => ' - 字跡莫辨';

  @override
  String get unknownMimeType => '無名之卷';

  @override
  String get multimediaNotSupported => '\n誡：DeepSeek 弗識丹青、幻影、聲樂諸般雅玩';

  @override
  String get responseBlocked => '言辭犯忌，為守關者所阻';

  @override
  String apiError(String message, int statusCode) {
    return '樞機之謬: $message (勘合碼: $statusCode)';
  }

  @override
  String get configureApiKeyFirst => '祈先於規度中賜下樞機符節';

  @override
  String get selectModelFirst => '祈先擇定一法象';

  @override
  String get messageInputPlaceholder => '落筆於此...';

  @override
  String get configureApiSettingsFirst => '祈先定樞機之規度';

  @override
  String baseSystemPrompt(String username) {
    return '爾當於對答間以「$username」呼之，並以中原雅言相復。';
  }

  @override
  String requestTimeout(String error) {
    return '晷漏已盡：門戶良久無音，祈察靈犀綱或少待再試。乖謬之詳: $error';
  }

  @override
  String networkConnectionFailed(String error) {
    return '千里傳音未遂：難通門戶，祈察靈犀綱。乖謬之詳: $error';
  }

  @override
  String securityConnectionFailed(String error) {
    return '勘合未遂：關防驗印未果，祈察曆法時辰。乖謬之詳: $error';
  }

  @override
  String connectionError(String error) {
    return '津渡之阻：靈犀綱有恙，祈察之。乖謬之詳: $error';
  }

  @override
  String httpProtocolError(String error) {
    return '禮節之謬：傳書被拒，祈少待再試。乖謬之詳: $error';
  }

  @override
  String networkCommunicationFailed(String error) {
    return '傳書未遂: $error';
  }

  @override
  String providerFileNotFound(String fileName) {
    return '案牘 $fileName 杳然無蹤或已焚毀';
  }

  @override
  String providerFileTooLarge(String fileName, String fileSize) {
    return '案牘 $fileName ($fileSize) 過厚，難以披閱';
  }

  @override
  String providerFileProcessError(String fileName, String error) {
    return '披閱 $fileName 時生乖謬: $error';
  }

  @override
  String providerFileContent(String fileName, String fileSize, String content) {
    return '案牘: $fileName ($fileSize)\n文理:\n$content';
  }

  @override
  String providerAttachmentCannotRead(String fileName, String fileSize, String mimeType) {
    return '隨附: $fileName ($fileSize, $mimeType) - 字跡莫辨';
  }

  @override
  String providerAttachmentInfo(String fileName, String fileSize, String mimeType) {
    return '隨附: $fileName ($fileSize, $mimeType)';
  }

  @override
  String providerTotalSizeExceeded(int limit) {
    return '隨附總計已逾${limit}MB之制';
  }

  @override
  String get providerInvalidResponseFormat => '門戶傳書，不合體式';

  @override
  String get providerMissingMessageField => '門戶傳書，缺失片言隻語（message）';

  @override
  String providerInvalidResponseFormatWithCode(int statusCode) {
    return '樞機之謬: 傳書不合體式 (勘合碼: $statusCode)';
  }

  @override
  String providerApiError(String message, int statusCode) {
    return '樞機之謬: $message (勘合碼: $statusCode)';
  }

  @override
  String providerStreamingTimeout(int seconds) {
    return '傳書逾時：過$seconds息未見新辭';
  }

  @override
  String get providerUnknownError => '無名之謬';

  @override
  String get providerUser => '閣下';

  @override
  String get providerAi => '靈犀';

  @override
  String get providerTitleGenSystemPrompt => '循閣下之言及對談之本末，擬一中原雅言之題，止於十五字。單賜題名，勿加匡廓雜飾。';

  @override
  String providerTitleGenUserPrompt(String conversationSummary) {
    return '祈觀此番對答而擬一短題：\n\n$conversationSummary';
  }

  @override
  String get providerMultimediaNotSupported => '\n誡：DeepSeek 弗識丹青、幻影、聲樂諸般雅玩';

  @override
  String get providerGeminiInvalidResponse => 'Gemini 門戶傳書，不合體式';

  @override
  String get providerGeminiMissingCandidates => 'Gemini 門戶傳書，缺 candidates 之目';

  @override
  String get providerGeminiInvalidFormat => 'Gemini 傳書，不合體式';

  @override
  String providerGeminiError(String message, int statusCode) {
    return 'Gemini 樞機之謬: $message (勘合碼: $statusCode)';
  }

  @override
  String providerGeminiStreamingTimeout(int seconds) {
    return 'Gemini 傳書逾時：過$seconds息未見新辭';
  }

  @override
  String providerGeminiInvalidFormatWithCode(int statusCode) {
    return 'Gemini 樞機之謬: 傳書不合體式 (勘合碼: $statusCode)';
  }

  @override
  String get providerResponseBlocked => '言辭犯忌，為守關者所阻';

  @override
  String get platformAndModel => '門戶與法象';

  @override
  String get platformAndModelDesc => '總理諸邦靈犀門戶與法象之規度';

  @override
  String get addPlatform => '廣開門戶';

  @override
  String get editPlatform => '修訂門戶';

  @override
  String get platformType => '門戶之屬';

  @override
  String get platformNamePlaceholder => '門戶之名';

  @override
  String get endpointPlaceholder => '樞機渡口之址';

  @override
  String get configured => '已設';

  @override
  String get notConfigured => '未設';

  @override
  String get models => '尊法象';

  @override
  String get available => '堪用';

  @override
  String get current => '當下';

  @override
  String get currentModel => '當下法象';

  @override
  String get manageModels => '總理法象';

  @override
  String get refreshModels => '點閱法象';

  @override
  String get noModelsAvailable => '尚無堪用之法象';

  @override
  String get noModelSelected => '未擇法象';

  @override
  String get modelsRefreshed => '法象之錄已點閱';

  @override
  String refreshModelsError(String error) {
    return '點閱未果: $error';
  }

  @override
  String get deletePlatform => '裁撤門戶';

  @override
  String deletePlatformConfirm(String name) {
    return '確欲裁撤門戶「$name」乎？';
  }

  @override
  String get switchToPlatform => '移步此門';

  @override
  String switchedToPlatform(String name) {
    return '已移步至 $name';
  }

  @override
  String get addModelTitle => '添置法象';

  @override
  String get modelNamePh => '法象之名';

  @override
  String get addModelBtn => '添置';

  @override
  String get deleteModelTitle => '裁撤法象';

  @override
  String deleteModelConfirm(String model) {
    return '確欲裁撤法象「$model」乎？';
  }

  @override
  String get deleteModelBtn => '裁撤所選';

  @override
  String get selectModelToDelete => '祈先擇定欲裁之法象';

  @override
  String get add => '添置';

  @override
  String get addNewModel => '新置法象';

  @override
  String get clickAddToCreate => '點擊上方「+」以添法象';

  @override
  String get noPlatformsConfigured => '尚未定立門戶之規度';

  @override
  String get addPlatformHint => '點擊右首「+」以開闢首個靈犀門戶';

  @override
  String get exportConversation => '謄錄對談';

  @override
  String get exportFormat => '謄錄之式';

  @override
  String get exportFormatTxt => '素書 (.txt)';

  @override
  String get exportFormatJson => '樞機文 (.json)';

  @override
  String get exportFormatLumenflow => '流光卷 (.lumenflow)';

  @override
  String get exportFormatPdf => '拓片 (.pdf)';

  @override
  String get exportConversationSuccess => '對談謄錄無恙';

  @override
  String get exportConversationFailed => '對談謄錄未果';

  @override
  String exportConversationError(String error) {
    return '謄錄生乖謬: $error';
  }

  @override
  String get exportConversationTitle => '談名: ';

  @override
  String get exportCreatedTime => '開局之時: ';

  @override
  String get exportUpdatedTime => '絕筆之時: ';

  @override
  String get exportMessageCount => '言辭之數: ';

  @override
  String get exportReasoningProcess => '[推演之跡]';

  @override
  String exportAttachments(int count) {
    return '[隨附: $count宗]';
  }

  @override
  String get exportBytes => '字節';

  @override
  String get exportConversationNotFound => '對談杳無蹤跡';

  @override
  String get exportThinkingProcess => '推演之跡';

  @override
  String get exportAttachmentsLabel => '隨附';

  @override
  String get notificationSettings => '飛報規度';

  @override
  String get enableNotification => '啓用飛報';

  @override
  String get enableNotificationDesc => '靈犀回覆已畢，即遣飛報相聞';

  @override
  String get dataManagement => '經籍總理';

  @override
  String get liveUpdateAIResponse => '回話';

  @override
  String get languageChanged => '雅言已易';

  @override
  String get restartAppToApplyLanguage => '雅言既易，須重啟本器方能踐行';

  @override
  String get loading => '正展卷...';

  @override
  String get copyMessage => '抄錄此言';

  @override
  String get copySuccess => '已抄入袖中';

  @override
  String get copyFailed => '抄錄未果';

  @override
  String copyError(String error) {
    return '抄錄生乖謬: $error';
  }

  @override
  String get copySuccessTitle => '抄錄妥當';

  @override
  String get copyFailedTitle => '抄錄未果';

  @override
  String get copyCode => '摹寫';

  @override
  String get copied => '已抄錄';

  @override
  String get aiResponseDisclaimer => '幻神之言，聊備一格，祈明察秋毫';

  @override
  String get advancedSettings => '玄妙';

  @override
  String get advancedSettingsSubtitle => '定本器之樞要';

  @override
  String get userProfileSubtitle => '點染閣下之儀容';

  @override
  String get platformAndModelSubtitle => '佈置門戶與法象';

  @override
  String get apiTypeSubtitle => '定樞機之度';

  @override
  String get modelSettingsSubtitle => '調法象之性情';

  @override
  String get historyConversationSubtitle => '總理前塵往事';

  @override
  String get toolsSettingsSubtitle => '置辦外邦奇巧';

  @override
  String get appearanceSubtitle => '裁本器之衣冠';

  @override
  String get credits => '芳名錄';

  @override
  String get creditsMainDeveloper => '首功匠人';

  @override
  String get creditsAppImprovementSuggestions => '建言獻策';

  @override
  String get creditsAppImprovementAndCode => '修繕與添磚加瓦';

  @override
  String get creditsBugTestingAndCode => '捉蟲與修葺';

  @override
  String get creditsDescription => '多賴下述高賢鼎力襄助：';

  @override
  String get contributors => '眾善知識';

  @override
  String get editMessage => '修訂前言';

  @override
  String get regenerateResponse => '重請靈犀';

  @override
  String get resubmit => '重遞';

  @override
  String get editMessageHint => '修訂言辭';

  @override
  String get confirmEdit => '允定修訂';

  @override
  String get editMessageDialogTitle => '點竄言辭';

  @override
  String get regenerateConfirm => '確欲重求靈犀之言乎？';

  @override
  String get messageOptions => '言辭之度';

  @override
  String get presetManagement => '錦囊總理';

  @override
  String get presetManagementSubtitle => '總理本器及閣下所納之錦囊';

  @override
  String get builtInPresets => '本器錦囊';

  @override
  String get userPresets => '閣下錦囊';

  @override
  String get noPresetsAvailable => '尚無錦囊';

  @override
  String get importXmlHint => '點擊右首「+」以納入XML卷宗';

  @override
  String get importPresetDialogTitle => '納入錦囊';

  @override
  String get presetNamePlaceholder => '錦囊之名';

  @override
  String get descriptionPlaceholder => '敘略';

  @override
  String get authorPlaceholder => '撰稿人';

  @override
  String get importButton => '納入';

  @override
  String get deletePresetDialogTitle => '焚毀錦囊';

  @override
  String deletePresetConfirm(String presetName) {
    return '確欲焚毀錦囊「$presetName」乎？';
  }

  @override
  String presetDeletedSuccess(String presetName) {
    return '已焚毀: $presetName';
  }

  @override
  String importFailedError(String error) {
    return '納入未果: $error';
  }

  @override
  String deleteFailedError(String error) {
    return '焚毀未果: $error';
  }

  @override
  String get filePathError => '無從尋覓卷宗之跡';

  @override
  String get authorLabel => '撰稿人:';

  @override
  String get versionLabel => '修次:';

  @override
  String get descriptionLabel => '敘略:';

  @override
  String get systemPromptLabel => '開宗明義之言:';

  @override
  String get closeButton => '合卷';

  @override
  String loadPresetsFailed(String error) {
    return '請出錦囊未果: $error';
  }

  @override
  String get roleCardGeneratorLink => '名帖坊';

  @override
  String get httpServerSwitchLabel => '名帖坊主事';

  @override
  String get httpServerStatusRunning => '當值';

  @override
  String get httpServerStatusStopped => '歇息';

  @override
  String get openGeneratorButton => '叩開作坊';

  @override
  String get httpServerDescription => '主事安札於五零五零之所，以奉名帖作坊。';

  @override
  String get httpServerNotRunningTitle => '主事未昇座';

  @override
  String get httpServerNotRunningMessage => '名帖坊主事未曾昇座。確欲請其當值乎？';

  @override
  String get startServerButton => '昇座';

  @override
  String get httpServerToggleTooltip => '易主事之行止';

  @override
  String openLinkFailed(String error) {
    return '叩關未果: $error';
  }

  @override
  String get currentTime => '此乃當下之辰光，苟無客官相詢，休要多口：';

  @override
  String httpServerOperationFailed(String error) {
    return '主事行止生乖謬: $error';
  }

  @override
  String get chatBackground => '畫屏';

  @override
  String get selectBackgroundImage => '擇丹青作屏';

  @override
  String get changeBackgroundImage => '易畫屏';

  @override
  String get selectBackgroundImageDesc => '擇一丹青以為對談之畫屏';

  @override
  String get currentBackgroundImage => '畫屏已設';

  @override
  String get clear => '滌除';

  @override
  String get backgroundOpacity => '畫屏明隱';

  @override
  String get backgroundOpacityDesc => '調畫屏之明暗隱現';

  @override
  String get selectImageFailed => '擇丹青未果';

  @override
  String get clearBackgroundImage => '撤去畫屏';

  @override
  String get clearBackgroundImageConfirm => '確欲撤去畫屏乎？';

  @override
  String get birthday => '生辰';

  @override
  String get birthdayHint => '定閣下之生辰八字';

  @override
  String get selectBirthday => '擇生辰';

  @override
  String get toolManagement => '奇巧總理';

  @override
  String get promptTools => '奇巧';

  @override
  String get addTimeToPrompt => '時辰';

  @override
  String get addTimeToPromptDesc => '觀天象知時辰';
}
