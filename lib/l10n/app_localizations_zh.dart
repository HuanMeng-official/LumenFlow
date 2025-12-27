// ignore: unused_import
import 'package:intl/intl.dart' as intl;
import 'app_localizations.dart';

// ignore_for_file: type=lint

/// The translations for Chinese (`zh`).
class AppLocalizationsZh extends AppLocalizations {
  AppLocalizationsZh([String locale = 'zh']) : super(locale);

  @override
  String get appTitle => '流光';

  @override
  String get appSubtitle => 'Chat With Your AI';

  @override
  String get chat => '对话';

  @override
  String get settings => '设置';

  @override
  String get about => '关于';

  @override
  String get conversations => '对话记录';

  @override
  String get newConversation => '新对话';

  @override
  String get noConversations => '暂无对话记录';

  @override
  String get createNewConversation => '创建新对话';

  @override
  String get aiAssistant => 'AI 助手';

  @override
  String get startChatting => '开始与AI对话吧！';

  @override
  String get pleaseConfigureAPI => '请先配置API设置才能开始对话';

  @override
  String get settingsButton => '设置';

  @override
  String get needConfiguration => '需要配置';

  @override
  String get configureAPIPrompt => '请先在设置中配置API端点和密钥';

  @override
  String get cancel => '取消';

  @override
  String get confirm => '确定';

  @override
  String get save => '保存';

  @override
  String get delete => '删除';

  @override
  String get edit => '编辑';

  @override
  String get ok => '确定';

  @override
  String get goToSettings => '去设置';

  @override
  String get clearConversation => '清除当前对话';

  @override
  String get clearConversationConfirm => '确定要清除当前对话的所有消息吗？';

  @override
  String get deleteConversation => '删除对话';

  @override
  String deleteConversationConfirm(String title) {
    return '确定要删除对话\"$title\"吗？此操作无法撤销。';
  }

  @override
  String get editConversationTitle => '编辑对话标题';

  @override
  String get enterConversationTitle => '输入对话标题';

  @override
  String get saveSuccess => '保存成功';

  @override
  String get settingsSaved => '设置已保存';

  @override
  String get saveFailed => '保存失败';

  @override
  String saveError(String error) {
    return '保存设置时出错: $error';
  }

  @override
  String get resetSettings => '重置设置';

  @override
  String get resetSettingsConfirm => '确定要恢复默认设置吗？这将清除所有当前配置。';

  @override
  String get exportSettings => '导出设置';

  @override
  String get exportSuccess => '导出成功';

  @override
  String exportLocation(String location, String path) {
    return '设置已成功导出到$location：\n$path';
  }

  @override
  String get exportFailed => '导出失败';

  @override
  String exportError(String error) {
    return '导出设置时出错: $error\n\n请确保应用有存储权限，并检查存储空间是否充足。';
  }

  @override
  String get importSettings => '导入设置';

  @override
  String get importSettingsConfirm => '这将覆盖当前设置，确定要导入吗？';

  @override
  String get importSuccess => '导入成功';

  @override
  String get settingsImported => '设置已成功导入。';

  @override
  String get importFailed => '导入失败';

  @override
  String importError(String error) {
    return '导入设置时出错: $error';
  }

  @override
  String get error => '错误';

  @override
  String get responseInterrupted => '响应中断，应用可能意外退出';

  @override
  String get yesterday => '昨天';

  @override
  String daysAgo(int days) {
    return '$days天前';
  }

  @override
  String get editTitle => '编辑标题';

  @override
  String get deleteConversation2 => '删除对话';

  @override
  String get userInfo => '用户信息';

  @override
  String get userProfile => '个人资料';

  @override
  String get userProfileDesc => '设置头像和用户名';

  @override
  String get basicSettings => '基础设置';

  @override
  String get apiType => 'API格式';

  @override
  String get openaiApi => 'OpenAI API';

  @override
  String get geminiApi => 'Gemini API';

  @override
  String get deepseekApi => 'DeepSeek API';

  @override
  String get apiTypeDesc => '选择AI服务提供商';

  @override
  String get apiEndpoint => 'API端点';

  @override
  String get apiEndpointPlaceholder => '输入API端点URL';

  @override
  String get apiEndpointDesc => '例如: https://api.openai.com/v1';

  @override
  String get apiKey => 'API密钥';

  @override
  String get apiKeyPlaceholder => '输入API密钥';

  @override
  String get apiKeyDesc => '从AI服务提供商获取的认证密钥';

  @override
  String get modelSettings => '模型设置';

  @override
  String get model => '模型';

  @override
  String get modelPlaceholder => '输入模型名称';

  @override
  String get modelDesc => '例如: gpt-5, deepseek-chat';

  @override
  String get maxTokens => '最大Token数';

  @override
  String get maxTokensPlaceholder => '输入最大Token数';

  @override
  String get maxTokensDesc => '限制单次回复的长度，建议500-8000';

  @override
  String get systemPrompt => 'System Prompt';

  @override
  String get systemPromptPlaceholder => '输入 System Prompt';

  @override
  String get systemPromptDesc => '例如：始终使用中文回答';

  @override
  String get temperature => '温度';

  @override
  String get temperatureDesc => '控制回复的随机性，0.0-2.0，数值越高回复越有创意';

  @override
  String get historyConversation => '历史对话';

  @override
  String get enableHistory => '启用历史对话';

  @override
  String get enableHistoryDesc => '开启后AI会记住之前的对话内容，提供更连贯的回复';

  @override
  String get historyRounds => '历史对话轮数';

  @override
  String get historyRoundsPlaceholder => '输入历史对话轮数';

  @override
  String get historyRoundsDesc => 'AI记住的历史对话轮数，建议5-20轮，过多可能超出Token限制';

  @override
  String get conversationTitle => '对话标题';

  @override
  String get autoGenerateTitle => '自动生成标题';

  @override
  String get autoGenerateTitleDesc => '对话进行若干轮后，AI会根据内容自动生成标题';

  @override
  String get generateTiming => '生成时机';

  @override
  String get generateTimingDesc => '设置多少轮对话后自动生成标题';

  @override
  String get rounds => '轮';

  @override
  String get appearance => '外观';

  @override
  String get followSystem => '跟随系统设置';

  @override
  String get followSystemDesc => '自动跟随系统颜色模式';

  @override
  String get appColor => '应用颜色';

  @override
  String get lightMode => '浅色模式';

  @override
  String get darkMode => '暗色模式';

  @override
  String followSystemSetting(String mode) {
    return '跟随系统设置中（$mode）';
  }

  @override
  String get selectColorMode => '选择应用颜色模式';

  @override
  String get others => '其他';

  @override
  String get resetToDefault => '重置为默认设置';

  @override
  String get usageInstructions => '使用说明';

  @override
  String get usageInstructionsContent => '• API格式：选择AI服务提供商（OpenAI、Gemini或DeepSeek），选择后将自动填充端点和模型\n• API端点：AI服务提供商的API地址，点击帮助按钮查看常用端点\n• API密钥：从服务提供商获取的认证密钥，请妥善保管\n• 模型：要使用的AI模型名称，不同端点支持不同模型\n• Token数：限制单次回复的长度，过小可能导致回复不完整\n• 温度：数值越高回复越有创意，建议0.3-1.0\n• 历史对话：开启后AI能记住对话上下文，提供更连贯的体验';

  @override
  String get commonApiEndpoints => '常用API端点';

  @override
  String get commonApiEndpointsContent => 'OpenAI: https://api.openai.com/v1\n\nDeepSeek: https://api.deepseek.com\n\n阿里云: https://dashscope.aliyuncs.com/api/v1\n\n请根据您使用的AI服务提供商填写相应的端点地址。';

  @override
  String get commonModels => '常用模型';

  @override
  String get commonModelsContent => 'OpenAI:\n• gpt-5\n\nDeepSeek:\n• deepseek-chat\n• deepseek-reasoner\n\n请根据您的API端点选择对应的模型。';

  @override
  String get appInfo => '应用信息';

  @override
  String get version => '版本';

  @override
  String get buildDate => '构建日期';

  @override
  String get developer => '开发者';

  @override
  String get features => '功能特性';

  @override
  String get intelligentConversation => '智能对话';

  @override
  String get intelligentConversationDesc => '支持与多种AI模型进行自然语言对话';

  @override
  String get fileProcessing => '文件处理';

  @override
  String get fileProcessingDesc => '支持上传图片、文档等多种文件格式';

  @override
  String get historyRecords => '历史记录';

  @override
  String get historyRecordsDesc => '自动保存对话历史，支持上下文记忆';

  @override
  String get customSettings => '自定义设置';

  @override
  String get customSettingsDesc => '灵活配置API参数、主题和个性化选项';

  @override
  String get licenses => '开源许可';

  @override
  String get copyright => '© 2025 幻梦official';

  @override
  String get copyrightNotice => '本应用仅供学习和研究使用';

  @override
  String get copyrightTerms => '使用前请确保遵守相关API服务条款';

  @override
  String get profileSaved => '用户信息已保存';

  @override
  String saveProfileError(String error) {
    return '保存用户信息时出错: $error';
  }

  @override
  String get pickAvatarFailed => '选择头像失败';

  @override
  String get takePhotoFailed => '拍照失败';

  @override
  String get selectEmojiAvatar => '选择表情头像';

  @override
  String get selectAvatar => '选择头像';

  @override
  String get selectFromGallery => '从相册选择';

  @override
  String get takePhoto => '拍照';

  @override
  String get selectEmoji => '选择表情';

  @override
  String get tapToChangeAvatar => '点击更换头像';

  @override
  String get username => '用户名';

  @override
  String get usernameHint => 'AI会使用这个名字来称呼你';

  @override
  String get enterYourUsername => '输入你的用户名';

  @override
  String get aboutUserProfile => '关于用户信息';

  @override
  String get aboutUserProfileContent => '• 头像：可以选择照片或表情作为头像，会在聊天界面显示\n• 用户名：AI会在对话中使用这个名字称呼你\n• 所有信息仅存储在本地，不会上传到服务器';

  @override
  String get selectPresetRole => '选择预设角色';

  @override
  String get selectPresetRoleMessage => '选择一个预设角色来应用相应的系统提示词';

  @override
  String get closePresetMode => '关闭预设模式';

  @override
  String get continueAction => '继续';

  @override
  String get deepThinking => '深度思考';

  @override
  String get rolePlay => '角色扮演';

  @override
  String get language => '语言';

  @override
  String get interfaceLanguage => '界面语言';

  @override
  String get selectInterfaceLanguage => '选择应用界面语言';

  @override
  String get thinkChain => '思考链';

  @override
  String get expandChain => '查看推理过程';

  @override
  String get downloadDirectory => '下载目录';

  @override
  String get externalStorageDirectory => '外部存储目录';

  @override
  String get appDocumentsDirectory => '应用文档目录';

  @override
  String get imagePreview => '图片预览';

  @override
  String get unableToLoadImage => '无法加载图片';

  @override
  String get errorPrefix => '错误';

  @override
  String get fileTooLarge => '文件过大';

  @override
  String fileTooLargeMessage(String size, String limit) {
    return '选择的文件总大小$size超过$limit限制。请选择较小的文件。';
  }

  @override
  String get fileTooLargeWarning => '文件过大警告';

  @override
  String fileTooLargeWarningMessage(String limit, String files) {
    return '以下文件超过$limit限制，可能无法正确处理：\n\n$files\n\n是否继续上传？';
  }

  @override
  String get noValidFiles => '无有效文件';

  @override
  String get noValidFilesMessage => '没有成功处理任何文件，请重试。';

  @override
  String get selectFileFailed => '选择文件失败';

  @override
  String selectFileFailedMessage(String error) {
    return '错误：$error';
  }

  @override
  String get user => '用户';

  @override
  String get ai => 'AI';

  @override
  String get unknownError => '未知错误';

  @override
  String attachmentInfo(String fileName, String fileSize, String mimeType) {
    return '附件: $fileName ($fileSize, $mimeType)';
  }

  @override
  String get attachmentCannotRead => ' - 无法读取内容';

  @override
  String get unknownMimeType => '未知类型';

  @override
  String get multimediaNotSupported => '\n提示: DeepSeek 不支持处理图片、视频、音频等多媒体文件';

  @override
  String get responseBlocked => '响应被安全过滤器阻止';

  @override
  String apiError(String message, int statusCode) {
    return 'API错误: $message (状态码: $statusCode)';
  }
}
