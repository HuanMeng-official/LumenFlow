// ignore: unused_import
import 'package:intl/intl.dart' as intl;
import 'app_localizations.dart';

// ignore_for_file: type=lint

/// The translations for Japanese (`ja`).
class AppLocalizationsJa extends AppLocalizations {
  AppLocalizationsJa([String locale = 'ja']) : super(locale);

  @override
  String get appTitle => 'LumenFlow';

  @override
  String get appSubtitle => 'AIとチャット';

  @override
  String get chat => 'チャット';

  @override
  String get settings => '設定';

  @override
  String get about => 'アプリについて';

  @override
  String get conversations => '会話履歴';

  @override
  String get newConversation => '新しい会話';

  @override
  String get noConversations => 'まだ会話がありません';

  @override
  String get createNewConversation => '新しい会話を開始';

  @override
  String get aiAssistant => 'AIアシスタント';

  @override
  String get startChatting => 'AIとのチャットを開始しましょう！';

  @override
  String get pleaseConfigureAPI => 'チャットを始めるには、まずAPI設定を行ってください';

  @override
  String get settingsButton => '設定';

  @override
  String get needConfiguration => '設定が必要です';

  @override
  String get configureAPIPrompt => '設定画面でAPIエンドポイントとキーを構成してください';

  @override
  String get cancel => 'キャンセル';

  @override
  String get confirm => '確認';

  @override
  String get save => '保存';

  @override
  String get delete => '削除';

  @override
  String get edit => '編集';

  @override
  String get ok => 'OK';

  @override
  String get goToSettings => '設定へ移動';

  @override
  String get clearConversation => '現在の会話をクリア';

  @override
  String get clearConversationConfirm => '現在の会話のすべてのメッセージをクリアしてもよろしいですか？';

  @override
  String get deleteConversation => '会話を削除';

  @override
  String deleteConversationConfirm(String title) {
    return '「$title」の会話を削除してもよろしいですか？この操作は元に戻せません。';
  }

  @override
  String get editConversationTitle => '会話タイトルを編集';

  @override
  String get enterConversationTitle => '会話タイトルを入力';

  @override
  String get saveSuccess => '保存に成功しました';

  @override
  String get settingsSaved => '設定が保存されました';

  @override
  String get saveFailed => '保存に失敗しました';

  @override
  String saveError(String error) {
    return '設定の保存中にエラーが発生しました: $error';
  }

  @override
  String get resetSettings => '設定をリセット';

  @override
  String get resetSettingsConfirm => 'デフォルト設定を復元してもよろしいですか？現在のすべての構成がクリアされます。';

  @override
  String get exportSettings => '設定をエクスポート';

  @override
  String get exportSuccess => 'エクスポートに成功しました';

  @override
  String exportLocation(String location, String path) {
    return '設定は $location に正常にエクスポートされました:\n$path';
  }

  @override
  String get exportFailed => 'エクスポートに失敗しました';

  @override
  String exportError(String error) {
    return '設定のエクスポート中にエラーが発生しました: $error\n\nアプリがストレージへのアクセス許可を持っていること、および利用可能なストレージ容量を確認してください。';
  }

  @override
  String get importSettings => '設定をインポート';

  @override
  String get importSettingsConfirm => 'これにより現在の設定が上書きされます。本当にインポートしますか？';

  @override
  String get importSuccess => 'インポートに成功しました';

  @override
  String get settingsImported => '設定が正常にインポートされました。';

  @override
  String get importFailed => 'インポートに失敗しました';

  @override
  String importError(String error) {
    return '設定のインポート中にエラーが発生しました: $error';
  }

  @override
  String get error => 'エラー';

  @override
  String get responseInterrupted => '応答が中断されました。アプリが予期せず終了した可能性があります';

  @override
  String get yesterday => '昨日';

  @override
  String daysAgo(int days) {
    return '$days日前';
  }

  @override
  String get editTitle => 'タイトルを編集';

  @override
  String get deleteConversation2 => '会話を削除';

  @override
  String get userInfo => 'ユーザー情報';

  @override
  String get userProfile => 'ユーザープロファイル';

  @override
  String get userProfileDesc => 'アバターとユーザー名を設定';

  @override
  String get basicSettings => '基本設定';

  @override
  String get apiType => 'APIタイプ';

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
  String get apiTypeDesc => 'AIサービスプロバイダーを選択';

  @override
  String get apiEndpoint => 'APIエンドポイント';

  @override
  String get apiEndpointPlaceholder => 'APIエンドポイントURLを入力';

  @override
  String get apiEndpointDesc => '例: https://api.openai.com/v1';

  @override
  String get apiKey => 'APIキー';

  @override
  String get apiKeyPlaceholder => 'APIキー';

  @override
  String get apiKeyDesc => 'AIサービスプロバイダーから取得した認証キー';

  @override
  String get modelSettings => 'モデル設定';

  @override
  String get model => 'モデル';

  @override
  String get modelPlaceholder => 'モデル名を入力';

  @override
  String get modelDesc => '例: gpt-5, deepseek-chat';

  @override
  String get maxTokens => '最大トークン数';

  @override
  String get maxTokensPlaceholder => '最大トークン数を入力';

  @override
  String get maxTokensDesc => '単一応答の長さを制限します。推奨値: 500-8000';

  @override
  String get systemPrompt => 'システムプロンプト';

  @override
  String get systemPromptPlaceholder => 'システムプロンプトを入力';

  @override
  String get systemPromptDesc => '例: 必ず日本語で回答してください';

  @override
  String get temperature => '温度';

  @override
  String get temperatureDesc => '応答のランダム性を制御します（0.0-2.0）。値が高いほど創造的な応答になります';

  @override
  String get historyConversation => '履歴会話';

  @override
  String get enableHistory => '履歴を有効化';

  @override
  String get enableHistoryDesc => '有効にすると、AIは以前の会話コンテキストを記憶し、より連続性のある応答を提供します';

  @override
  String get historyRounds => '履歴ラウンド数';

  @override
  String get historyRoundsPlaceholder => '履歴ラウンド数を入力';

  @override
  String get historyRoundsDesc => 'AIが記憶する会話ラウンド数。推奨値: 5-20ラウンド。多すぎるとトークン制限を超える可能性があります';

  @override
  String get conversationTitle => '会話タイトル';

  @override
  String get autoGenerateTitle => 'タイトル自動生成';

  @override
  String get autoGenerateTitleDesc => '数回の会話後に、AIが内容に基づいてタイトルを自動生成します';

  @override
  String get generateTiming => '生成タイミング';

  @override
  String get generateTimingDesc => 'タイトルを自動生成するまでの会話ラウンド数を設定';

  @override
  String get rounds => 'ラウンド';

  @override
  String get appearance => '外観';

  @override
  String get followSystem => 'システム設定に従う';

  @override
  String get followSystemDesc => 'システムのカラーモードに自動的に従います';

  @override
  String get appColor => 'アプリカラー';

  @override
  String get lightMode => 'ライトモード';

  @override
  String get darkMode => 'ダークモード';

  @override
  String followSystemSetting(String mode) {
    return 'システムに従っています ($mode)';
  }

  @override
  String get selectColorMode => 'アプリのカラーモードを選択';

  @override
  String get others => 'その他';

  @override
  String get resetToDefault => 'デフォルト設定に戻す';

  @override
  String get usageInstructions => '使用方法';

  @override
  String get usageInstructionsContent => '• APIタイプ: AIサービスプロバイダー (OpenAI, Gemini, または DeepSeek) を選択します。選択後、エンドポイントとモデルが自動入力されます。\n• APIエンドポイント: AIサービスプロバイダーのAPIアドレスです。ヘルプボタンをクリックして一般的なエンドポイントを表示できます。\n• APIキー: サービスプロバイダーから取得した認証キーです。安全に保管してください。\n• モデル: 使用するAIモデル名です。異なるエンドポイントは異なるモデルをサポートしています。\n• トークン数: 単一応答の長さを制限します。小さすぎると応答が不完全になる可能性があります。\n• 温度: 値が高いほど創造的な応答になります。推奨値: 0.3-1.0\n• 履歴会話: 有効にすると、AIは会話のコンテキストを記憶し、より連続性のある体験を提供します。';

  @override
  String get commonApiEndpoints => 'よく使われるAPIエンドポイント';

  @override
  String get commonApiEndpointsContent => 'OpenAI: https://api.openai.com/v1\n\nDeepSeek: https://api.deepseek.com\n\nAlibaba Cloud: https://dashscope.aliyuncs.com/api/v1\n\n使用するAIサービスプロバイダーに応じて、対応するエンドポイントアドレスを入力してください。';

  @override
  String get commonModels => 'よく使われるモデル';

  @override
  String get commonModelsContent => 'OpenAI:\n• gpt-5\n\nDeepSeek:\n• deepseek-chat\n• deepseek-reasoner\n\nAPIエンドポイントに応じて対応するモデルを選択してください。';

  @override
  String get appInfo => 'アプリ情報';

  @override
  String get version => 'バージョン';

  @override
  String get buildDate => 'ビルド日';

  @override
  String get developer => '開発者';

  @override
  String get features => '機能';

  @override
  String get intelligentConversation => 'インテリジェント会話';

  @override
  String get intelligentConversationDesc => 'さまざまなAIモデルとの自然言語による会話をサポート';

  @override
  String get fileProcessing => 'ファイル処理';

  @override
  String get fileProcessingDesc => '画像やドキュメントなど、複数のファイル形式のアップロードをサポート';

  @override
  String get historyRecords => '履歴記録';

  @override
  String get historyRecordsDesc => '会話履歴を自動保存し、コンテキストメモリを備える';

  @override
  String get customSettings => 'カスタム設定';

  @override
  String get customSettingsDesc => 'APIパラメータ、テーマ、個人設定などを柔軟に構成可能';

  @override
  String get licenses => 'ライセンス';

  @override
  String get sponsor => 'スポンサー';

  @override
  String get sponsorDesc => 'このアプリが役立った場合は、コードをスキャンしてスポンサーし、開発を支援してください';

  @override
  String get copyright => '© 2026 幻夢official';

  @override
  String get copyrightNotice => 'このアプリケーションは学習と研究目的のみを想定しています';

  @override
  String get copyrightTerms => '使用前に関連するAPIサービス規約を遵守していることを確認してください';

  @override
  String get profileSaved => 'ユーザープロファイルが保存されました';

  @override
  String saveProfileError(String error) {
    return 'ユーザープロファイルの保存中にエラーが発生しました: $error';
  }

  @override
  String get pickAvatarFailed => 'アバターの選択に失敗しました';

  @override
  String get takePhotoFailed => '写真撮影に失敗しました';

  @override
  String get selectEmojiAvatar => '絵文字アバターを選択';

  @override
  String get selectAvatar => 'アバターを選択';

  @override
  String get selectFromGallery => 'ギャラリーから選択';

  @override
  String get takePhoto => '写真を撮る';

  @override
  String get selectEmoji => '絵文字を選択';

  @override
  String get tapToChangeAvatar => 'タップしてアバターを変更';

  @override
  String get username => 'ユーザー名';

  @override
  String get usernameHint => 'AIはこの名前でユーザーを呼びかけます';

  @override
  String get enterYourUsername => 'ユーザー名を入力';

  @override
  String get gender => '性別';

  @override
  String get genderHint => 'ご自身の性別を選択してください';

  @override
  String get male => '男性';

  @override
  String get female => '女性';

  @override
  String get selectGender => '性別を選択';

  @override
  String get aboutUserProfile => 'ユーザープロファイルについて';

  @override
  String get aboutUserProfileContent => '• アバター: 画像または絵文字をアバターとして選択し、チャットインターフェースに表示されます\n• ユーザー名: AIは会話中、この名前でユーザーを呼びかけます\n• すべての情報はローカルにのみ保存され、サーバーにはアップロードされません';

  @override
  String get selectPresetRole => 'プリセットロールを選択';

  @override
  String get selectPresetRoleMessage => 'プリセットロールを選択して、対応するシステムプロンプトを適用します';

  @override
  String get closePresetMode => 'プリセットモードを閉じる';

  @override
  String get continueAction => '続ける';

  @override
  String get deepThinking => '深く考え中';

  @override
  String get rolePlay => 'ロールプレイ';

  @override
  String get language => '言語';

  @override
  String get interfaceLanguage => 'インターフェース言語';

  @override
  String get selectInterfaceLanguage => 'アプリのインターフェース言語を選択';

  @override
  String get thinkChain => '思考の連鎖';

  @override
  String get expandChain => '推論プロセスを表示';

  @override
  String get downloadDirectory => 'ダウンロードディレクトリ';

  @override
  String get externalStorageDirectory => '外部ストレージディレクトリ';

  @override
  String get appDocumentsDirectory => 'アプリ文書ディレクトリ';

  @override
  String get imagePreview => '画像プレビュー';

  @override
  String get unableToLoadImage => '画像を読み込めません';

  @override
  String get errorPrefix => 'エラー';

  @override
  String get fileTooLarge => 'ファイルが大きすぎます';

  @override
  String fileTooLargeMessage(String size, String limit) {
    return '選択されたファイルの合計サイズ $size が $limit の制限を超えています。小さなファイルを選択してください。';
  }

  @override
  String get fileTooLargeWarning => 'ファイルサイズ超過警告';

  @override
  String fileTooLargeWarningMessage(String limit, String files) {
    return '以下のファイルは $limit の制限を超えているため、正しく処理できない可能性があります:\n\n$files\n\nアップロードを続けますか？';
  }

  @override
  String get noValidFiles => '有効なファイルがありません';

  @override
  String get noValidFilesMessage => 'ファイルが正常に処理されませんでした。もう一度お試しください。';

  @override
  String get selectFileFailed => 'ファイル選択に失敗しました';

  @override
  String selectFileFailedMessage(String error) {
    return 'エラー: $error';
  }

  @override
  String get user => 'ユーザー';

  @override
  String get ai => 'AI';

  @override
  String get unknownError => '不明なエラー';

  @override
  String attachmentInfo(String fileName, String fileSize, String mimeType) {
    return '添付ファイル: $fileName ($fileSize, $mimeType)';
  }

  @override
  String get attachmentCannotRead => ' - コンテンツを読み取れません';

  @override
  String get unknownMimeType => '不明なタイプ';

  @override
  String get multimediaNotSupported => '\n注意: DeepSeekは画像、動画、音声などのマルチメディアファイルの処理をサポートしていません';

  @override
  String get responseBlocked => '安全性フィルターによって応答がブロックされました';

  @override
  String apiError(String message, int statusCode) {
    return 'APIエラー: $message (ステータスコード: $statusCode)';
  }

  @override
  String get configureApiKeyFirst => 'まず設定でAPIキーを構成してください';

  @override
  String get selectModelFirst => 'まずモデルを選択してください';

  @override
  String get messageInputPlaceholder => 'メッセージを入力...';

  @override
  String get configureApiSettingsFirst => 'まずAPI設定を行ってください';

  @override
  String baseSystemPrompt(String username) {
    return '「$username」はユーザー名です。会話の中で適切に使用し、日本語で返答してください';
  }

  @override
  String requestTimeout(String error) {
    return 'リクエストタイムアウト: サーバー応答が遅すぎます。ネットワーク接続を確認するか、後でもう一度お試しください。エラー詳細: $error';
  }

  @override
  String networkConnectionFailed(String error) {
    return 'ネットワーク接続に失敗しました: サーバーに接続できません。ネットワーク接続を確認してください。エラー詳細: $error';
  }

  @override
  String securityConnectionFailed(String error) {
    return 'セキュリティ接続に失敗しました: SSL/TLSハンドシェイクに失敗しました。システム時刻またはネットワーク設定を確認してください。エラー詳細: $error';
  }

  @override
  String connectionError(String error) {
    return '接続エラー: ネットワーク接続の問題が発生しました。ネットワーク設定を確認してください。エラー詳細: $error';
  }

  @override
  String httpProtocolError(String error) {
    return 'HTTPプロトコルエラー: リクエスト処理に失敗しました。後でもう一度お試しください。エラー詳細: $error';
  }

  @override
  String networkCommunicationFailed(String error) {
    return 'ネットワーク通信に失敗しました: $error';
  }

  @override
  String providerFileNotFound(String fileName) {
    return 'ファイル $fileName が存在しないか削除されています';
  }

  @override
  String providerFileTooLarge(String fileName, String fileSize) {
    return 'ファイル $fileName ($fileSize) が大きすぎて処理できません';
  }

  @override
  String providerFileProcessError(String fileName, String error) {
    return 'ファイル $fileName の処理中にエラーが発生しました: $error';
  }

  @override
  String providerFileContent(String fileName, String fileSize, String content) {
    return 'ファイル: $fileName ($fileSize)\nコンテンツ:\n$content';
  }

  @override
  String providerAttachmentCannotRead(String fileName, String fileSize, String mimeType) {
    return '添付ファイル: $fileName ($fileSize, $mimeType) - コンテンツを読み取れません';
  }

  @override
  String providerAttachmentInfo(String fileName, String fileSize, String mimeType) {
    return '添付ファイル: $fileName ($fileSize, $mimeType)';
  }

  @override
  String providerTotalSizeExceeded(int limit) {
    return '添付ファイルの合計サイズが ${limit}MB の制限を超えています';
  }

  @override
  String get providerInvalidResponseFormat => 'APIが無効な応答形式を返しました';

  @override
  String get providerMissingMessageField => 'API応答にメッセージフィールドがありません';

  @override
  String providerInvalidResponseFormatWithCode(int statusCode) {
    return 'APIエラー: 無効な応答形式 (ステータスコード: $statusCode)';
  }

  @override
  String providerApiError(String message, int statusCode) {
    return 'APIエラー: $message (ステータスコード: $statusCode)';
  }

  @override
  String providerStreamingTimeout(int seconds) {
    return 'ストリーミング応答タイムアウト: $seconds 秒間新しいデータが受信されませんでした';
  }

  @override
  String get providerUnknownError => '不明なエラー';

  @override
  String get providerUser => 'ユーザー';

  @override
  String get providerAi => 'AI';

  @override
  String get providerTitleGenSystemPrompt => 'ユーザーの言語と会話内容に基づいて、短くて正確な日本語のタイトルを生成してください。15語以内。タイトルのみを返し、引用符やその他の書式は不要です。';

  @override
  String providerTitleGenUserPrompt(String conversationSummary) {
    return '会話内容に基づいて短い日本語のタイトルを生成してください:\n\n$conversationSummary';
  }

  @override
  String get providerMultimediaNotSupported => '\n注意: DeepSeekは画像、動画、音声などのマルチメディアファイルの処理をサポートしていません';

  @override
  String get providerGeminiInvalidResponse => 'Gemini APIが無効な応答形式を返しました';

  @override
  String get providerGeminiMissingCandidates => 'Gemini API応答に候補フィールドがありません';

  @override
  String get providerGeminiInvalidFormat => '無効なGemini API応答形式';

  @override
  String providerGeminiError(String message, int statusCode) {
    return 'Gemini APIエラー: $message (ステータスコード: $statusCode)';
  }

  @override
  String providerGeminiStreamingTimeout(int seconds) {
    return 'Geminiストリーミング応答タイムアウト: $seconds 秒間新しいデータが受信されませんでした';
  }

  @override
  String providerGeminiInvalidFormatWithCode(int statusCode) {
    return 'Gemini APIエラー: 無効な応答形式 (ステータスコード: $statusCode)';
  }

  @override
  String get providerResponseBlocked => '安全性フィルターによって応答がブロックされました';

  @override
  String get platformAndModel => 'プラットフォームとモデル';

  @override
  String get platformAndModelDesc => '複数のAIプラットフォームとモデル構成を管理';

  @override
  String get addPlatform => 'プラットフォームを追加';

  @override
  String get editPlatform => 'プラットフォームを編集';

  @override
  String get platformType => 'プラットフォームタイプ';

  @override
  String get platformNamePlaceholder => 'プラットフォーム名';

  @override
  String get endpointPlaceholder => 'APIエンドポイントURL';

  @override
  String get configured => '構成済み';

  @override
  String get notConfigured => '未構成';

  @override
  String get models => 'モデル';

  @override
  String get available => '利用可能';

  @override
  String get current => '現在';

  @override
  String get currentModel => '現在のモデル';

  @override
  String get manageModels => 'モデルを管理';

  @override
  String get refreshModels => 'モデルを更新';

  @override
  String get noModelsAvailable => '利用可能なモデルがありません';

  @override
  String get noModelSelected => 'モデルが選択されていません';

  @override
  String get modelsRefreshed => 'モデルリストが更新されました';

  @override
  String refreshModelsError(String error) {
    return 'モデルの更新に失敗しました: $error';
  }

  @override
  String get deletePlatform => 'プラットフォームを削除';

  @override
  String deletePlatformConfirm(String name) {
    return 'プラットフォーム「$name」を削除してもよろしいですか？';
  }

  @override
  String get switchToPlatform => 'このプラットフォームに切り替える';

  @override
  String switchedToPlatform(String name) {
    return '$name に切り替えました';
  }

  @override
  String get addModelTitle => 'モデルを追加';

  @override
  String get modelNamePh => 'モデル名';

  @override
  String get addModelBtn => '追加';

  @override
  String get deleteModelTitle => 'モデルを削除';

  @override
  String deleteModelConfirm(String model) {
    return 'モデル「$model」を削除してもよろしいですか？';
  }

  @override
  String get deleteModelBtn => '選択したものを削除';

  @override
  String get selectModelToDelete => 'まず削除するモデルを選択してください';

  @override
  String get add => '追加';

  @override
  String get addNewModel => '新しいモデルを追加';

  @override
  String get clickAddToCreate => '上記の+ボタンをタップしてモデルを追加してください';

  @override
  String get noPlatformsConfigured => 'プラットフォームが構成されていません';

  @override
  String get addPlatformHint => '右上の+ボタンをタップして、最初のAIプラットフォームを追加してください';

  @override
  String get exportConversation => '会話をエクスポート';

  @override
  String get exportFormat => 'エクスポート形式';

  @override
  String get exportFormatTxt => 'プレーンテキスト (.txt)';

  @override
  String get exportFormatJson => 'JSON (.json)';

  @override
  String get exportFormatLumenflow => 'Lumenflow (.lumenflow)';

  @override
  String get exportFormatPdf => 'PDF (.pdf)';

  @override
  String get exportConversationSuccess => '会話のエクスポートに成功しました';

  @override
  String get exportConversationFailed => '会話のエクスポートに失敗しました';

  @override
  String exportConversationError(String error) {
    return '会話のエクスポート中にエラーが発生しました: $error';
  }

  @override
  String get exportConversationTitle => '会話タイトル: ';

  @override
  String get exportCreatedTime => '作成日時: ';

  @override
  String get exportUpdatedTime => '更新日時: ';

  @override
  String get exportMessageCount => 'メッセージ数: ';

  @override
  String get exportReasoningProcess => '[推論プロセス]';

  @override
  String exportAttachments(int count) {
    return '[添付ファイル: $count]';
  }

  @override
  String get exportBytes => 'バイト';

  @override
  String get exportConversationNotFound => '会話が見つかりません';

  @override
  String get exportThinkingProcess => '思考プロセス';

  @override
  String get exportAttachmentsLabel => '添付ファイル';
}
