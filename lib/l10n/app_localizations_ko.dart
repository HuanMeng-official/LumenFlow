// ignore: unused_import
import 'package:intl/intl.dart' as intl;
import 'app_localizations.dart';

// ignore_for_file: type=lint

/// The translations for Korean (`ko`).
class AppLocalizationsKo extends AppLocalizations {
  AppLocalizationsKo([String locale = 'ko']) : super(locale);

  @override
  String get appTitle => 'LumenFlow';

  @override
  String get appSubtitle => 'AI와 대화하기';

  @override
  String get chat => '채팅';

  @override
  String get settings => '설정';

  @override
  String get about => '정보';

  @override
  String get conversations => '대화 목록';

  @override
  String get newConversation => '새 대화';

  @override
  String get noConversations => '아직 대화가 없습니다';

  @override
  String get createNewConversation => '새 대화 만들기';

  @override
  String get aiAssistant => 'AI 어시스턴트';

  @override
  String get startChatting => 'AI와 채팅을 시작하세요!';

  @override
  String get pleaseConfigureAPI => '채팅을 시작하려면 먼저 API 설정을 구성해주세요';

  @override
  String get settingsButton => '설정';

  @override
  String get needConfiguration => '구성이 필요합니다';

  @override
  String get configureAPIPrompt => '설정에서 API 엔드포인트 및 키를 구성해주세요';

  @override
  String get cancel => '취소';

  @override
  String get confirm => '확인';

  @override
  String get save => '저장';

  @override
  String get delete => '삭제';

  @override
  String get edit => '편집';

  @override
  String get ok => '확인';

  @override
  String get goToSettings => '설정으로 이동';

  @override
  String get clearConversation => '현재 대화 지우기';

  @override
  String get clearConversationConfirm => '현재 대화의 모든 메시지를 지우시겠습니까?';

  @override
  String get deleteConversation => '대화 삭제';

  @override
  String deleteConversationConfirm(String title) {
    return '「$title」 대화를 삭제하시겠습니까? 이 작업은 되돌릴 수 없습니다.';
  }

  @override
  String get editConversationTitle => '대화 제목 편집';

  @override
  String get enterConversationTitle => '대화 제목 입력';

  @override
  String get saveSuccess => '저장 성공';

  @override
  String get settingsSaved => '설정이 저장되었습니다';

  @override
  String get saveFailed => '저장 실패';

  @override
  String saveError(String error) {
    return '설정 저장 오류: $error';
  }

  @override
  String get resetSettings => '설정 초기화';

  @override
  String get resetSettingsConfirm => '기본 설정으로 복원하시겠습니까? 현재 모든 구성이 초기화됩니다.';

  @override
  String get exportSettings => '설정 내보내기';

  @override
  String get exportSuccess => '내보내기 성공';

  @override
  String exportLocation(String location, String path) {
    return '설정이 다음 위치에 성공적으로 내보내졌습니다: $location\n$path';
  }

  @override
  String get exportFailed => '내보내기 실패';

  @override
  String exportError(String error) {
    return '설정 내보내기 오류: $error\n\n앱에 저장소 권한이 있는지 확인하고 사용 가능한 저장 공간을 점검해주세요.';
  }

  @override
  String get importSettings => '설정 가져오기';

  @override
  String get importSettingsConfirm => '현재 설정을 덮어씁니다. 가져오시겠습니까?';

  @override
  String get importSuccess => '가져오기 성공';

  @override
  String get settingsImported => '설정이 성공적으로 가져와졌습니다.';

  @override
  String get importFailed => '가져오기 실패';

  @override
  String importError(String error) {
    return '설정 가져오기 오류: $error';
  }

  @override
  String get error => '오류';

  @override
  String get responseInterrupted => '응답이 중단되었습니다. 앱이 예기치 않게 종료되었을 수 있습니다';

  @override
  String get yesterday => '어제';

  @override
  String daysAgo(int days) {
    return '$days일 전';
  }

  @override
  String get editTitle => '제목 수정';

  @override
  String get deleteConversation2 => '대화 삭제';

  @override
  String get userInfo => '사용자 정보';

  @override
  String get userProfile => '사용자 프로필';

  @override
  String get userProfileDesc => '아바타 및 사용자 이름 설정';

  @override
  String get basicSettings => '기본 설정';

  @override
  String get apiType => 'API 유형';

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
  String get apiTypeDesc => 'AI 서비스 제공업체 선택';

  @override
  String get apiEndpoint => 'API 엔드포인트';

  @override
  String get apiEndpointPlaceholder => 'API 엔드포인트 URL 입력';

  @override
  String get apiEndpointDesc => '예: https://api.openai.com/v1';

  @override
  String get apiKey => 'API 키';

  @override
  String get apiKeyPlaceholder => 'API 키';

  @override
  String get apiKeyDesc => 'AI 서비스 제공업체에서 발급받은 인증 키';

  @override
  String get modelSettings => '모델 설정';

  @override
  String get model => '모델';

  @override
  String get modelPlaceholder => '모델 이름 입력';

  @override
  String get modelDesc => '예: gpt-5, deepseek-chat';

  @override
  String get maxTokens => '최대 토큰 수';

  @override
  String get maxTokensPlaceholder => '최대 토큰 수 입력';

  @override
  String get maxTokensDesc => '단일 응답 길이 제한, 권장값 500-8000';

  @override
  String get systemPrompt => '시스템 프롬프트';

  @override
  String get systemPromptPlaceholder => '시스템 프롬프트 입력';

  @override
  String get systemPromptDesc => '예: 항상 한국어로 답변하세요';

  @override
  String get temperature => '온도';

  @override
  String get temperatureDesc => '응답 무작위성 제어, 0.0-2.0, 값이 높을수록 창의적인 응답';

  @override
  String get historyConversation => '대화 기록';

  @override
  String get enableHistory => '히스토리 활성화';

  @override
  String get enableHistoryDesc => '활성화 시 AI는 이전 대화 맥락을 기억하여 더 일관된 응답 제공';

  @override
  String get historyRounds => '히스토리 라운드';

  @override
  String get historyRoundsPlaceholder => '히스토리 라운드 수 입력';

  @override
  String get historyRoundsDesc => 'AI가 기억하는 대화 라운드 수, 권장 5-20라운드. 너무 많으면 토큰 제한 초과 가능';

  @override
  String get conversationTitle => '대화 제목';

  @override
  String get autoGenerateTitle => '자동 제목 생성';

  @override
  String get autoGenerateTitleDesc => '여러 라운드 대화 후 AI가 내용 기반으로 자동 제목 생성';

  @override
  String get generateTiming => '생성 타이밍';

  @override
  String get generateTimingDesc => '자동 제목 생성 전 대화 라운드 수 설정';

  @override
  String get rounds => '라운드';

  @override
  String get appearance => '테마';

  @override
  String get followSystem => '시스템 설정 따르기';

  @override
  String get followSystemDesc => '자동으로 시스템 색상 모드 따름';

  @override
  String get appColor => '앱 색상';

  @override
  String get lightMode => '라이트 모드';

  @override
  String get darkMode => '다크 모드';

  @override
  String followSystemSetting(String mode) {
    return '시스템 따름 ($mode)';
  }

  @override
  String get selectColorMode => '앱 색상 모드 선택';

  @override
  String get others => '기타';

  @override
  String get resetToDefault => '기본 설정으로 재설정';

  @override
  String get usageInstructions => '사용법';

  @override
  String get usageInstructionsContent => '• API 유형: AI 서비스 제공업체(OpenAI, Gemini 또는 DeepSeek) 선택. 선택 후 엔드포인트 및 모델 자동 입력됨\n• API 엔드포인트: AI 서비스 제공업체의 API 주소. 도움말 버튼 클릭하여 일반적인 엔드포인트 보기\n• API 키: 서비스 제공업체에서 발급받은 인증 키. 안전하게 보관하세요\n• 모델: 사용할 AI 모델 이름. 다양한 엔드포인트는 서로 다른 모델 지원\n• 토큰 수: 단일 응답 길이 제한. 너무 작으면 불완전한 응답 발생 가능\n• 온도: 값이 높을수록 창의적인 응답. 권장 0.3-1.0\n• 과거 대화: 활성화 시 AI는 대화 맥락 기억하여 더 일관된 경험 제공';

  @override
  String get commonApiEndpoints => '일반적인 API 엔드포인트';

  @override
  String get commonApiEndpointsContent => 'OpenAI: https://api.openai.com/v1\n\nDeepSeek: https://api.deepseek.com\n\n알리바바 클라우드: https://dashscope.aliyuncs.com/api/v1\n\n사용하는 AI 서비스 제공업체에 따라 해당 엔드포인트 주소 입력.';

  @override
  String get commonModels => '일반적인 모델';

  @override
  String get commonModelsContent => 'OpenAI:\n• gpt-5\n\nDeepSeek:\n• deepseek-chat\n• deepseek-reasoner\n\nAPI 엔드포인트에 따라 해당 모델 선택.';

  @override
  String get appInfo => '앱 정보';

  @override
  String get version => '버전';

  @override
  String get buildDate => '빌드 날짜';

  @override
  String get developer => '개발자';

  @override
  String get features => '기능';

  @override
  String get intelligentConversation => '지능형 대화';

  @override
  String get intelligentConversationDesc => '다양한 AI 모델과 자연어 대화 지원';

  @override
  String get fileProcessing => '파일 처리';

  @override
  String get fileProcessingDesc => '이미지 및 문서 등 다양한 파일 형식 업로드 지원';

  @override
  String get historyRecords => '히스토리 기록';

  @override
  String get historyRecordsDesc => '맥락 기억 기능 포함 대화 기록 자동 저장';

  @override
  String get customSettings => '사용자 정의 설정';

  @override
  String get customSettingsDesc => 'API 파라미터, 테마 및 개인 설정 유연하게 구성';

  @override
  String get licenses => '라이선스';

  @override
  String get sponsor => '후원';

  @override
  String get sponsorDesc => '이 앱이 도움이 되었다면 코드를 스캔하여 후원하고 개발을 지원해주세요';

  @override
  String get copyright => '© 2026 幻梦official';

  @override
  String get copyrightNotice => '이 애플리케이션은 학습 및 연구 목적으로만 사용됩니다';

  @override
  String get copyrightTerms => '사용 전 관련 API 서비스 약관 준수 여부 확인하세요';

  @override
  String get profileSaved => '사용자 프로필이 저장되었습니다';

  @override
  String saveProfileError(String error) {
    return '사용자 프로필 저장 오류: $error';
  }

  @override
  String get pickAvatarFailed => '아바타 선택 실패';

  @override
  String get takePhotoFailed => '사진 촬영 실패';

  @override
  String get selectEmojiAvatar => '이모지 아바타 선택';

  @override
  String get selectAvatar => '아바타 선택';

  @override
  String get selectFromGallery => '갤러리에서 선택';

  @override
  String get takePhoto => '사진 촬영';

  @override
  String get selectEmoji => '이모지 선택';

  @override
  String get tapToChangeAvatar => '탭하여 아바타 변경';

  @override
  String get username => '사용자 이름';

  @override
  String get usernameHint => 'AI는 이 이름으로 사용자를 부릅니다';

  @override
  String get enterYourUsername => '사용자 이름 입력';

  @override
  String get gender => '성별';

  @override
  String get genderHint => '성별 선택';

  @override
  String get male => '남성';

  @override
  String get female => '여성';

  @override
  String get selectGender => '성별 선택';

  @override
  String get aboutUserProfile => '사용자 프로필 정보';

  @override
  String get aboutUserProfileContent => '• 아바타: 사진 또는 이모지를 아바타로 선택하여 채팅 인터페이스에 표시됨\n• 사용자 이름: AI는 대화 중 이 이름으로 사용자를 부름\n• 모든 정보는 로컬에만 저장되며 서버에 업로드되지 않음';

  @override
  String get selectPresetRole => '사전 설정 역할 선택';

  @override
  String get selectPresetRoleMessage => '사전 설정 역할을 선택하여 해당 시스템 프롬프트 적용';

  @override
  String get closePresetMode => '사전 설정 모드 닫기';

  @override
  String get continueAction => '계속';

  @override
  String get deepThinking => '심도 있는 사고';

  @override
  String get rolePlay => '역할 수행';

  @override
  String get language => '언어';

  @override
  String get interfaceLanguage => '인터페이스 언어';

  @override
  String get selectInterfaceLanguage => '앱 인터페이스 언어 선택';

  @override
  String get thinkChain => '사고 체인';

  @override
  String get expandChain => '추론 과정 보기';

  @override
  String get downloadDirectory => '다운로드 디렉터리';

  @override
  String get externalStorageDirectory => '외부 저장 디렉터리';

  @override
  String get appDocumentsDirectory => '앱 문서 디렉터리';

  @override
  String get imagePreview => '이미지 미리보기';

  @override
  String get unableToLoadImage => '이미지를 불러올 수 없음';

  @override
  String get errorPrefix => '오류';

  @override
  String get fileTooLarge => '파일이 너무 큼';

  @override
  String fileTooLargeMessage(String size, String limit) {
    return '선택한 파일 총 크기 $size가 $limit 제한을 초과합니다. 더 작은 파일을 선택하세요.';
  }

  @override
  String get fileTooLargeWarning => '파일 크기 경고';

  @override
  String fileTooLargeWarningMessage(String limit, String files) {
    return '다음 파일은 $limit 제한을 초과하여 올바르게 처리되지 않을 수 있습니다:\n\n$files\n\n업로드를 계속하시겠습니까?';
  }

  @override
  String get noValidFiles => '유효한 파일 없음';

  @override
  String get noValidFilesMessage => '파일이 성공적으로 처리되지 않았습니다. 다시 시도하세요.';

  @override
  String get selectFileFailed => '파일 선택 실패';

  @override
  String selectFileFailedMessage(String error) {
    return '오류: $error';
  }

  @override
  String get user => '사용자';

  @override
  String get ai => 'AI';

  @override
  String get unknownError => '알 수 없는 오류';

  @override
  String attachmentInfo(String fileName, String fileSize, String mimeType) {
    return '첨부파일: $fileName ($fileSize, $mimeType)';
  }

  @override
  String get attachmentCannotRead => ' - 콘텐츠를 읽을 수 없음';

  @override
  String get unknownMimeType => '알 수 없는 형식';

  @override
  String get multimediaNotSupported => '\n참고: DeepSeek는 이미지, 동영상, 오디오 등의 멀티미디어 파일 처리를 지원하지 않습니다';

  @override
  String get responseBlocked => '안전 필터에 의해 응답이 차단됨';

  @override
  String apiError(String message, int statusCode) {
    return 'API 오류: $message (상태 코드: $statusCode)';
  }

  @override
  String get configureApiKeyFirst => '먼저 설정에서 API 키를 구성해주세요';

  @override
  String get selectModelFirst => '먼저 모델을 선택해주세요';

  @override
  String get messageInputPlaceholder => '메시지를 입력하세요...';

  @override
  String get configureApiSettingsFirst => '먼저 API 설정을 구성해주세요';

  @override
  String baseSystemPrompt(String username) {
    return '「$username」은(는) 사용자 이름입니다. 대화 중 적절히 사용하고 한국어로 응답하세요';
  }

  @override
  String requestTimeout(String error) {
    return '요청 시간 초과: 서버 응답이 너무 오래 걸립니다. 네트워크 연결을 확인하거나 나중에 다시 시도하세요. 오류 세부 정보: $error';
  }

  @override
  String networkConnectionFailed(String error) {
    return '네트워크 연결 실패: 서버에 연결할 수 없습니다. 네트워크 연결을 확인하세요. 오류 세부 정보: $error';
  }

  @override
  String securityConnectionFailed(String error) {
    return '보안 연결 실패: SSL/TLS 핸드셰이크 실패, 시스템 시간 또는 네트워크 설정을 확인하세요. 오류 세부 정보: $error';
  }

  @override
  String connectionError(String error) {
    return '연결 오류: 네트워크 연결 문제 발생, 네트워크 설정을 확인하세요. 오류 세부 정보: $error';
  }

  @override
  String httpProtocolError(String error) {
    return 'HTTP 프로토콜 오류: 요청 처리 실패, 나중에 다시 시도하세요. 오류 세부 정보: $error';
  }

  @override
  String networkCommunicationFailed(String error) {
    return '네트워크 통신 실패: $error';
  }

  @override
  String providerFileNotFound(String fileName) {
    return '파일 $fileName이(가) 존재하지 않거나 삭제됨';
  }

  @override
  String providerFileTooLarge(String fileName, String fileSize) {
    return '파일 $fileName($fileSize)이(가) 너무 커서 처리할 수 없습니다';
  }

  @override
  String providerFileProcessError(String fileName, String error) {
    return '파일 $fileName 처리 오류: $error';
  }

  @override
  String providerFileContent(String fileName, String fileSize, String content) {
    return '파일: $fileName ($fileSize)\n내용:\n$content';
  }

  @override
  String providerAttachmentCannotRead(String fileName, String fileSize, String mimeType) {
    return '첨부파일: $fileName ($fileSize, $mimeType) - 콘텐츠를 읽을 수 없음';
  }

  @override
  String providerAttachmentInfo(String fileName, String fileSize, String mimeType) {
    return '첨부파일: $fileName ($fileSize, $mimeType)';
  }

  @override
  String providerTotalSizeExceeded(int limit) {
    return '총 첨부파일 크기가 ${limit}MB 제한을 초과했습니다';
  }

  @override
  String get providerInvalidResponseFormat => 'API가 잘못된 응답 형식을 반환했습니다';

  @override
  String get providerMissingMessageField => 'API 응답에 메시지 필드가 누락되었습니다';

  @override
  String providerInvalidResponseFormatWithCode(int statusCode) {
    return 'API 오류: 잘못된 응답 형식 (상태 코드: $statusCode)';
  }

  @override
  String providerApiError(String message, int statusCode) {
    return 'API 오류: $message (상태 코드: $statusCode)';
  }

  @override
  String providerStreamingTimeout(int seconds) {
    return '스트리밍 응답 시간 초과: $seconds초 동안 새로운 데이터 수신 없음';
  }

  @override
  String get providerUnknownError => '알 수 없는 오류';

  @override
  String get providerUser => '사용자';

  @override
  String get providerAi => 'AI';

  @override
  String get providerTitleGenSystemPrompt => '사용자의 언어 및 대화 내용을 기반으로 짧고 정확한 한글 제목 생성. 15단어 이내. 따옴표나 기타 형식 없이 제목만 반환.';

  @override
  String providerTitleGenUserPrompt(String conversationSummary) {
    return '대화 내용을 기반으로 짧은 한글 제목을 생성해주세요:\n\n$conversationSummary';
  }

  @override
  String get providerMultimediaNotSupported => '\n참고: DeepSeek는 이미지, 동영상, 오디오 등의 멀티미디어 파일 처리를 지원하지 않습니다';

  @override
  String get providerGeminiInvalidResponse => 'Gemini API가 잘못된 응답 형식을 반환했습니다';

  @override
  String get providerGeminiMissingCandidates => 'Gemini API 응답에 후보 필드가 누락되었습니다';

  @override
  String get providerGeminiInvalidFormat => '잘못된 Gemini API 응답 형식';

  @override
  String providerGeminiError(String message, int statusCode) {
    return 'Gemini API 오류: $message (상태 코드: $statusCode)';
  }

  @override
  String providerGeminiStreamingTimeout(int seconds) {
    return 'Gemini 스트리밍 응답 시간 초과: $seconds초 동안 새로운 데이터 수신 없음';
  }

  @override
  String providerGeminiInvalidFormatWithCode(int statusCode) {
    return 'Gemini API 오류: 잘못된 응답 형식 (상태 코드: $statusCode)';
  }

  @override
  String get providerResponseBlocked => '안전 필터에 의해 응답이 차단됨';

  @override
  String get platformAndModel => '플랫폼 및 모델';

  @override
  String get platformAndModelDesc => '다양한 AI 플랫폼 및 모델 구성 관리';

  @override
  String get addPlatform => '플랫폼 추가';

  @override
  String get editPlatform => '플랫폼 편집';

  @override
  String get platformType => '플랫폼 유형';

  @override
  String get platformNamePlaceholder => '플랫폼 이름';

  @override
  String get endpointPlaceholder => 'API 엔드포인트 URL';

  @override
  String get configured => '구성됨';

  @override
  String get notConfigured => '구성되지 않음';

  @override
  String get models => '모델';

  @override
  String get available => '사용 가능';

  @override
  String get current => '현재';

  @override
  String get currentModel => '현재 모델';

  @override
  String get manageModels => '모델 관리';

  @override
  String get refreshModels => '모델 새로 고침';

  @override
  String get noModelsAvailable => '사용 가능한 모델 없음';

  @override
  String get noModelSelected => '모델이 선택되지 않음';

  @override
  String get modelsRefreshed => '모델 목록이 새로 고쳐짐';

  @override
  String refreshModelsError(String error) {
    return '모델 새로 고침 실패: $error';
  }

  @override
  String get deletePlatform => '플랫폼 삭제';

  @override
  String deletePlatformConfirm(String name) {
    return '「$name」 플랫폼을 삭제하시겠습니까?';
  }

  @override
  String get switchToPlatform => '이 플랫폼으로 전환';

  @override
  String switchedToPlatform(String name) {
    return '$name(으)로 전환됨';
  }

  @override
  String get addModelTitle => '모델 추가';

  @override
  String get modelNamePh => '모델 이름';

  @override
  String get addModelBtn => '추가';

  @override
  String get deleteModelTitle => '모델 삭제';

  @override
  String deleteModelConfirm(String model) {
    return '「$model」 모델을 삭제하시겠습니까?';
  }

  @override
  String get deleteModelBtn => '선택 항목 삭제';

  @override
  String get selectModelToDelete => '먼저 삭제할 모델을 선택하세요';

  @override
  String get add => '추가';

  @override
  String get addNewModel => '새 모델 추가';

  @override
  String get clickAddToCreate => '위의 + 버튼을 눌러 모델을 추가하세요';

  @override
  String get noPlatformsConfigured => '구성된 플랫폼 없음';

  @override
  String get addPlatformHint => '오른쪽 상단의 + 버튼을 눌러 첫 번째 AI 플랫폼을 추가하세요';

  @override
  String get exportConversation => '대화 내보내기';

  @override
  String get exportFormat => '내보내기 형식';

  @override
  String get exportFormatTxt => '일반 텍스트 (.txt)';

  @override
  String get exportFormatJson => 'JSON (.json)';

  @override
  String get exportFormatLumenflow => 'Lumenflow (.lumenflow)';

  @override
  String get exportFormatPdf => 'PDF (.pdf)';

  @override
  String get exportConversationSuccess => '대화 내보내기 성공';

  @override
  String get exportConversationFailed => '대화 내보내기 실패';

  @override
  String exportConversationError(String error) {
    return '대화 내보내기 오류: $error';
  }

  @override
  String get exportConversationTitle => '대화 제목: ';

  @override
  String get exportCreatedTime => '생성 시간: ';

  @override
  String get exportUpdatedTime => '수정 시간: ';

  @override
  String get exportMessageCount => '메시지 수: ';

  @override
  String get exportReasoningProcess => '[추론 과정]';

  @override
  String exportAttachments(int count) {
    return '[첨부파일: $count]';
  }

  @override
  String get exportBytes => '바이트';

  @override
  String get exportConversationNotFound => '대화를 찾을 수 없음';

  @override
  String get exportThinkingProcess => '사고 과정';

  @override
  String get exportAttachmentsLabel => '첨부파일';

  @override
  String get notificationSettings => '알림 설정';

  @override
  String get enableNotification => '알림 사용';

  @override
  String get enableNotificationDesc => 'AI 응답 완료 시 알림 받기';

  @override
  String get dataManagement => '데이터 관리';

  @override
  String get liveUpdateAIResponse => '응답';

  @override
  String get languageChanged => '언어가 변경됨';

  @override
  String get restartAppToApplyLanguage => '언어 변경 사항을 적용하려면 앱을 다시 시작하세요';

  @override
  String get loading => '로드 중';
}
