import 'dart:convert';
import 'dart:async';
import 'dart:io';
import 'package:http/http.dart' as http;
import 'settings_service.dart';
import 'user_service.dart';
import 'file_service.dart';
import '../models/message.dart';
import '../models/attachment.dart';
import '../models/user_profile.dart';

/// AI服务类，负责处理与AI模型（OpenAI和Google Gemini）的通信
/// 支持文本对话、文件附件处理、流式输出等功能
/// 提供统一的接口供聊天界面调用，隐藏不同API的差异
class AIService {
  final SettingsService _settingsService = SettingsService();
  final UserService _userService = UserService();
  final FileService _fileService = FileService();

  /// Base64编码的最大文件大小（25MB）
  /// 超过此大小的文件无法通过Base64方式上传到AI API
  static const int maxFileSizeForBase64 = 25 * 1024 * 1024;

  /// 文本提取的最大文件大小（10MB）
  /// 超过此大小的文本文件将不尝试提取内容，只发送文件名和元数据
  static const int maxFileSizeForTextExtraction = 10 * 1024 * 1024;

  /// 所有附件的总大小限制（50MB）
  /// 单次请求中所有附件大小之和不能超过此限制
  static const int maxTotalAttachmentsSize = 50 * 1024 * 1024;

  /// 替换系统提示词中的变量占位符
  ///
  /// 参数:
  ///   systemPrompt - 原始系统提示词
  ///   userProfile - 用户配置对象
  /// 返回值:
  ///   替换变量后的系统提示词
  /// 说明:
  ///   目前支持的变量:
  ///   - ${userProfile.username}: 替换为用户名
  String _replaceSystemPromptVariables(String systemPrompt, UserProfile userProfile) {
    return systemPrompt.replaceAll('\${userProfile.username}', userProfile.username);
  }

  /// 格式化文件大小为人类可读的字符串
  ///
  /// 参数:
  ///   bytes - 文件大小（字节）
  /// 返回值:
  ///   格式化后的字符串，如 "10.5 MB"、"256 KB"
  String _formatFileSize(int bytes) {
    if (bytes < 1024) {
      return '$bytes B';
    } else if (bytes < 1024 * 1024) {
      return '${(bytes / 1024).toStringAsFixed(1)} KB';
    } else if (bytes < 1024 * 1024 * 1024) {
      return '${(bytes / (1024 * 1024)).toStringAsFixed(1)} MB';
    } else {
      return '${(bytes / (1024 * 1024 * 1024)).toStringAsFixed(1)} GB';
    }
  }

  /// 检查附件是否支持视觉API（图片、视频、音频）
  ///
  /// 参数:
  ///   attachment - 附件对象
  /// 返回值:
  ///   true表示支持视觉API，false表示不支持
  /// 说明:
  ///   支持的文件类型：image/*, video/*, audio/*
  bool _isVisionSupportedFile(Attachment attachment) {
    final mimeType = attachment.mimeType?.toLowerCase() ?? '';
    return mimeType.startsWith('image/') ||
        mimeType.startsWith('video/') ||
        mimeType.startsWith('audio/');
  }

  /// 构建OpenAI API的消息内容结构
  ///
  /// 参数:
  ///   message - 用户输入的文本消息
  ///   attachments - 附件列表（可选）
  /// 返回值:
  ///   如果是纯文本消息，返回字符串
  ///   如果包含附件或多模态内容，返回包含内容部件的列表
  /// 说明:
  ///   1. 检查附件总大小限制
  ///   2. 支持视觉文件（图片/视频/音频）的Base64编码
  ///   3. 支持文本文件的提取和发送
  ///   4. 处理文件不存在或过大的情况
  ///   5. 返回格式符合OpenAI API的消息内容规范
  Future<dynamic> _buildOpenAIMessageContent(
      String message, List<Attachment> attachments) async {
    if (attachments.isEmpty) {
      return message;
    }

    final totalSize = attachments.fold<int>(
        0, (sum, attachment) => sum + (attachment.fileSize ?? 0));
    if (totalSize > maxTotalAttachmentsSize) {
      throw Exception('附件总大小超过${maxTotalAttachmentsSize ~/ (1024 * 1024)}MB限制');
    }

    final contentParts = <Map<String, dynamic>>[];

    if (message.isNotEmpty) {
      contentParts.add({'type': 'text', 'text': message});
    }

    for (final attachment in attachments) {
      try {
        if (attachment.filePath == null ||
            !await _fileService.fileExists(attachment.filePath!)) {
          contentParts.add(
              {'type': 'text', 'text': '文件 ${attachment.fileName} 不存在或已删除'});
          continue;
        }

        final file = File(attachment.filePath!);
        final fileSize = attachment.fileSize ??
            await _fileService.getFileSize(attachment.filePath!);

        if (fileSize > maxFileSizeForBase64) {
          contentParts.add({
            'type': 'text',
            'text':
                '文件 ${attachment.fileName} (${_formatFileSize(fileSize)}) 过大，无法处理'
          });
          continue;
        }

        if (_isVisionSupportedFile(attachment)) {
          try {
            final dataUrl =
                await _fileService.getFileDataUrl(file, attachment.mimeType);
            contentParts.add({
              'type': 'image_url',
              'image_url': {'url': dataUrl}
            });
          } catch (e) {
            contentParts.add({
              'type': 'text',
              'text': '处理文件 ${attachment.fileName} 时出错: $e'
            });
          }
        } else {
          if (fileSize <= maxFileSizeForTextExtraction) {
            try {
              final content = await _fileService.readTextFile(file);
              contentParts.add({
                'type': 'text',
                'text':
                    '文件: ${attachment.fileName} (${_formatFileSize(fileSize)})\n内容:\n$content'
              });
            } catch (e) {
              contentParts.add({
                'type': 'text',
                'text':
                    '附件: ${attachment.fileName} (${_formatFileSize(fileSize)}, ${attachment.mimeType ?? '未知类型'}) - 无法读取内容'
              });
            }
          } else {
            contentParts.add({
              'type': 'text',
              'text':
                  '附件: ${attachment.fileName} (${_formatFileSize(fileSize)}, ${attachment.mimeType ?? '未知类型'})'
            });
          }
        }
      } catch (e) {
        contentParts.add(
            {'type': 'text', 'text': '处理文件 ${attachment.fileName} 时出错: $e'});
      }
    }

    if (contentParts.length == 1 && contentParts[0]['type'] == 'text') {
      return contentParts[0]['text'] as String;
    }

    return contentParts;
  }

  /// 构建Gemini API的内容结构
  ///
  /// 参数:
  ///   message - 用户输入的文本消息
  ///   chatHistory - 聊天历史记录（用于上下文）
  ///   attachments - 附件列表（可选）
  ///   systemPrompt - 系统提示词（自定义指令）
  ///   enableHistory - 是否启用历史上下文
  ///   historyContextLength - 历史上下文长度（对话轮数）
  /// 返回值:
  ///   Gemini API要求的contents列表，包含角色和内容部件
  /// 说明:
  ///   1. 支持系统提示词转换为用户-模型对话对
  ///   2. 支持聊天历史上下文的截断和格式化
  ///   3. 整合文件附件到内容部件中
  ///   4. 遵循Gemini API的消息格式规范
  Future<List<Map<String, dynamic>>> _buildGeminiContents(
    String message,
    List<Message> chatHistory,
    List<Attachment> attachments,
    String systemPrompt,
    bool enableHistory,
    int historyContextLength,
  ) async {
    final contents = <Map<String, dynamic>>[];

    if (systemPrompt.isNotEmpty) {
      contents.add({
        'role': 'user',
        'parts': <Map<String, dynamic>>[
          {'text': systemPrompt}
        ]
      });
      contents.add({
        'role': 'model',
        'parts': <Map<String, dynamic>>[
          {'text': 'Understood. I will follow these instructions.'}
        ]
      });
    }

    if (enableHistory && chatHistory.isNotEmpty) {
      final recentHistory = chatHistory
          .where((msg) =>
              msg.status != MessageStatus.error &&
              msg.content.trim().isNotEmpty)
          .toList()
          .reversed
          .take(historyContextLength * 2)
          .toList()
          .reversed
          .toList();

      for (final historyMsg in recentHistory) {
        contents.add({
          'role': historyMsg.isUser ? 'user' : 'model',
          'parts': <Map<String, dynamic>>[
            {'text': historyMsg.content}
          ]
        });
      }
    }

    final userMessageParts = <Map<String, dynamic>>[];

    if (message.isNotEmpty) {
      userMessageParts.add({'text': message});
    }

    if (attachments.isNotEmpty) {
      final fileParts = await _prepareFilesForGemini(attachments);
      userMessageParts.addAll(fileParts);
    }

    if (userMessageParts.isNotEmpty) {
      if (contents.isNotEmpty && contents.last['role'] == 'user') {
        final lastParts =
            (contents.last['parts'] as List<Map<String, dynamic>>);
        lastParts.addAll(userMessageParts);
      } else {
        contents.add({'role': 'user', 'parts': userMessageParts});
      }
    }

    return contents;
  }

  /// 为Gemini API准备文件附件内容
  ///
  /// 参数:
  ///   attachments - 附件列表
  /// 返回值:
  ///   包含文件内容的部件列表，可直接添加到Gemini消息中
  /// 说明:
  ///   1. 检查附件总大小限制
  ///   2. 验证文件存在性
  ///   3. 处理媒体文件（图片/视频/音频）的Base64编码
  ///   4. 提取文本文件内容（如果文件大小允许）
  ///   5. 处理文件处理过程中的各种异常情况
  Future<List<Map<String, dynamic>>> _prepareFilesForGemini(
      List<Attachment> attachments) async {
    final fileParts = <Map<String, dynamic>>[];

    final totalSize = attachments.fold<int>(
        0, (sum, attachment) => sum + (attachment.fileSize ?? 0));
    if (totalSize > maxTotalAttachmentsSize) {
      throw Exception('附件总大小超过${maxTotalAttachmentsSize ~/ (1024 * 1024)}MB限制');
    }

    for (final attachment in attachments) {
      try {
        if (attachment.filePath == null ||
            !await _fileService.fileExists(attachment.filePath!)) {
          fileParts.add({'text': '文件 ${attachment.fileName} 不存在或已删除'});
          continue;
        }

        final file = File(attachment.filePath!);
        final fileSize = attachment.fileSize ??
            await _fileService.getFileSize(attachment.filePath!);

        if (fileSize > maxFileSizeForBase64) {
          fileParts.add({
            'text':
                '文件 ${attachment.fileName} (${_formatFileSize(fileSize)}) 过大，无法处理'
          });
          continue;
        }

        final mimeType = attachment.mimeType?.toLowerCase() ?? '';
        final isSupportedMedia = mimeType.startsWith('image/') ||
            mimeType.startsWith('video/') ||
            mimeType.startsWith('audio/');

        if (isSupportedMedia) {
          try {
            final base64Data = await _fileService.getFileBase64(file);
            String cleanBase64 = base64Data;
            if (base64Data.contains(',')) {
              cleanBase64 = base64Data.split(',').last;
            }

            fileParts.add({
              'inlineData': {
                'mimeType': attachment.mimeType ?? 'application/octet-stream',
                'data': cleanBase64
              }
            });
          } catch (e) {
            fileParts.add({'text': '处理文件 ${attachment.fileName} 时出错: $e'});
          }
        } else {
          if (fileSize <= maxFileSizeForTextExtraction) {
            try {
              final content = await _fileService.readTextFile(file);
              fileParts.add({
                'text':
                    '文件: ${attachment.fileName} (${_formatFileSize(fileSize)})\n内容:\n$content'
              });
            } catch (e) {
              fileParts.add({
                'text':
                    '附件: ${attachment.fileName} (${_formatFileSize(fileSize)}, ${attachment.mimeType ?? '未知类型'}) - 无法读取内容'
              });
            }
          } else {
            fileParts.add({
              'text':
                  '附件: ${attachment.fileName} (${_formatFileSize(fileSize)}, ${attachment.mimeType ?? '未知类型'})'
            });
          }
        }
      } catch (e) {
        fileParts.add({'text': '处理文件 ${attachment.fileName} 时出错: $e'});
      }
    }

    return fileParts;
  }

  /// 发送消息到AI模型（同步方式）
  ///
  /// 参数:
  ///   message - 用户输入的文本消息
  ///   chatHistory - 聊天历史记录（用于上下文）
  ///   attachments - 附件列表（可选，默认为空）
  /// 返回值:
  ///   返回一个`Map<String, dynamic>`，包含AI模型的响应
  ///   - 'reasoningContent': 思考过程内容（如果有）
  ///   - 'content': 最终回答内容
  /// 异常:
  ///   抛出Exception当API密钥未配置或网络请求失败时
  /// 说明:
  ///   1. 从设置服务获取所有配置参数
  ///   2. 根据API类型（OpenAI或Gemini）选择不同的处理逻辑
  ///   3. 构建完整的消息上下文（包括系统提示、历史记录、当前消息）
  ///   4. 处理文件附件（如果存在）
  ///   5. 发送HTTP请求并处理响应
  ///   6. 统一错误处理，将API错误转换为用户友好的异常消息
  Future<Map<String, dynamic>> sendMessage(
      String message, List<Message> chatHistory,
      {List<Attachment> attachments = const [],
      bool thinkingMode = false,
      String presetSystemPrompt = ''}) async {
    final apiEndpoint = await _settingsService.getApiEndpoint();
    final apiKey = await _settingsService.getApiKey();
    final model = await _settingsService.getModel();
    final temperature = await _settingsService.getTemperature();
    final maxTokens = await _settingsService.getMaxTokens();
    final enableHistory = await _settingsService.getEnableHistory();
    final historyContextLength =
        await _settingsService.getHistoryContextLength();
    final userProfile = await _userService.getUserProfile();
    final customSystemPrompt = await _settingsService.getCustomSystemPrompt();
    final apiType = await _settingsService.getApiType();

    // 决定使用哪个系统提示词：优先使用预设提示词
    final String systemPromptToUse = presetSystemPrompt.isNotEmpty
        ? presetSystemPrompt
        : customSystemPrompt;

    if (apiKey.isEmpty) {
      throw Exception('请先在设置中配置API密钥');
    }

    if (thinkingMode && message.isNotEmpty) {
      message = '/think \n\n 请分步思考并解决以下问题：$message';
    } else if (!thinkingMode && message.isNotEmpty) {
      message = '/no_think \n\n 不要进行推理：$message';
    }

    try {
      List<Map<String, dynamic>> messages = [];

      String baseSystemPrompt =
          '用户的名字是"${userProfile.username}",请在对话中适当地使用这个名字来称呼用户。';
      String fullSystemPrompt = baseSystemPrompt;
      if (systemPromptToUse.isNotEmpty) {
        fullSystemPrompt += systemPromptToUse;
      }
      // 替换系统提示词中的变量占位符
      fullSystemPrompt = _replaceSystemPromptVariables(fullSystemPrompt, userProfile);

      messages.add({
        'role': 'system',
        'content': fullSystemPrompt,
      });

      if (enableHistory && chatHistory.isNotEmpty) {
        final recentHistory = chatHistory
            .where((msg) =>
                msg.status != MessageStatus.error &&
                msg.content.trim().isNotEmpty)
            .toList()
            .reversed
            .take(historyContextLength * 2)
            .toList()
            .reversed
            .toList();

        for (final historyMsg in recentHistory) {
          messages.add({
            'role': historyMsg.isUser ? 'user' : 'assistant',
            'content': historyMsg.content,
          });
        }
      }

      final userMessageContent =
          await _buildOpenAIMessageContent(message, attachments);
      messages.add({
        'role': 'user',
        'content': userMessageContent,
      });

      if (apiType == 'gemini') {
        final contents = await _buildGeminiContents(
          message,
          chatHistory,
          attachments,
          fullSystemPrompt,
          enableHistory,
          historyContextLength,
        );

        final responseText = await _sendGeminiMessage(
          apiEndpoint: apiEndpoint,
          apiKey: apiKey,
          model: model,
          temperature: temperature,
          maxTokens: maxTokens,
          contents: contents,
        );

        return {
          'reasoningContent': '',
          'content': responseText,
        };
      } else {
        final response = await http.post(
          Uri.parse('$apiEndpoint/chat/completions'),
          headers: {
            'Content-Type': 'application/json',
            'Authorization': 'Bearer $apiKey',
          },
          body: jsonEncode({
            'model': model,
            'messages': messages,
            'max_tokens': maxTokens,
            'temperature': temperature,
            if (thinkingMode) 'thinking': {'type': 'enabled'},
          }),
        );

        if (response.statusCode == 200) {
          final data = jsonDecode(response.body);
          if (data is! Map<String, dynamic> ||
              data['choices'] == null ||
              (data['choices'] as List).isEmpty) {
            throw Exception('API返回了无效的响应格式: ${response.body}');
          }
          final choices = data['choices'] as List;
          final firstChoice = choices[0];
          if (firstChoice['message'] == null) {
            throw Exception('API响应中缺少message字段: ${response.body}');
          }
          final message = firstChoice['message'];
          final reasoningContent =
              message['reasoning']?.toString().trim() ??
              message['reasoning_content']?.toString().trim() ?? '';
          final content = message['content']?.toString().trim() ?? '';

          return {
            'reasoningContent': reasoningContent,
            'content': content,
          };
        } else {
          final errorData = jsonDecode(response.body);
          if (errorData is! Map<String, dynamic>) {
            throw Exception('API错误: 无效的响应格式 (状态码: ${response.statusCode})');
          }
          final errorMessage = errorData['error']?['message']?.toString() ??
              errorData['message']?.toString() ??
              '未知错误';
          throw Exception('API错误: $errorMessage (状态码: ${response.statusCode})');
        }
      }
    } catch (e) {
      if (e.toString().contains('API错误')) {
        rethrow;
      }
      throw Exception('网络错误: $e');
    }
  }

  /// 发送消息到AI模型（流式方式）
  ///
  /// 参数:
  ///   message - 用户输入的文本消息
  ///   chatHistory - 聊天历史记录（用于上下文）
  ///   attachments - 附件列表（可选，默认为空）
  /// 返回值:
  ///   返回一个`Stream<Map<String, dynamic>>`，实时输出AI模型的响应片段
  ///   Map包含 'type' 和 'content' 字段，type可以是 'reasoning' 或 'answer'
  /// 异常:
  ///   抛出Exception当API密钥未配置或网络请求失败时
  /// 说明:
  ///   1. 支持流式输出，实时显示AI响应
  ///   2. 支持思考模型的推理过程输出
  ///   3. 与sendMessage方法类似，但使用流式API
  ///   4. 处理Server-Sent Events (SSE) 数据流
  ///   5. 针对OpenAI和Gemini API提供不同的流式实现
  ///   6. 实时解析和yield响应片段
  Stream<Map<String, dynamic>> sendMessageStreaming(
      String message, List<Message> chatHistory,
      {List<Attachment> attachments = const [],
      bool thinkingMode = false,
      String presetSystemPrompt = ''}) async* {
    final apiEndpoint = await _settingsService.getApiEndpoint();
    final apiKey = await _settingsService.getApiKey();
    final model = await _settingsService.getModel();
    final temperature = await _settingsService.getTemperature();
    final maxTokens = await _settingsService.getMaxTokens();
    final enableHistory = await _settingsService.getEnableHistory();
    final historyContextLength =
        await _settingsService.getHistoryContextLength();
    final userProfile = await _userService.getUserProfile();
    final customSystemPrompt = await _settingsService.getCustomSystemPrompt();
    final apiType = await _settingsService.getApiType();

    // 决定使用哪个系统提示词：优先使用预设提示词
    final String systemPromptToUse = presetSystemPrompt.isNotEmpty
        ? presetSystemPrompt
        : customSystemPrompt;

    if (apiKey.isEmpty) {
      throw Exception('请先在设置中配置API密钥');
    }

    if (thinkingMode && message.isNotEmpty) {
      message = '/think \n\n 请分步思考并解决以下问题：$message';
    } else if (!thinkingMode && message.isNotEmpty) {
      message = '/no_think \n\n 不要进行推理：$message';
    }

    try {
      if (apiType == 'gemini') {
        // 处理系统提示词变量替换
        final String processedSystemPrompt = '用户的名字是"${userProfile.username}",请在对话中适当地使用这个名字来称呼用户。${systemPromptToUse.isNotEmpty ? systemPromptToUse : ''}';
        final String fullSystemPrompt = _replaceSystemPromptVariables(processedSystemPrompt, userProfile);

        final contents = await _buildGeminiContents(
          message,
          chatHistory,
          attachments,
          fullSystemPrompt,
          enableHistory,
          historyContextLength,
        );

        yield* _sendGeminiMessageStreaming(
          apiEndpoint: apiEndpoint,
          apiKey: apiKey,
          model: model,
          temperature: temperature,
          maxTokens: maxTokens,
          contents: contents,
        );
        return;
      }

      List<Map<String, dynamic>> messages = [];

      String baseSystemPrompt =
          '用户的名字是"${userProfile.username}",请在对话中适当地使用这个名字来称呼用户。';
      String fullSystemPrompt = baseSystemPrompt;
      if (systemPromptToUse.isNotEmpty) {
        fullSystemPrompt += systemPromptToUse;
      }
      // 替换系统提示词中的变量占位符
      fullSystemPrompt = _replaceSystemPromptVariables(fullSystemPrompt, userProfile);

      messages.add({
        'role': 'system',
        'content': fullSystemPrompt,
      });

      if (enableHistory && chatHistory.isNotEmpty) {
        final recentHistory = chatHistory
            .where((msg) =>
                msg.status != MessageStatus.error &&
                msg.content.trim().isNotEmpty)
            .toList()
            .reversed
            .take(historyContextLength * 2)
            .toList()
            .reversed
            .toList();

        for (final historyMsg in recentHistory) {
          messages.add({
            'role': historyMsg.isUser ? 'user' : 'assistant',
            'content': historyMsg.content,
          });
        }
      }

      final userMessageContent =
          await _buildOpenAIMessageContent(message, attachments);
      messages.add({
        'role': 'user',
        'content': userMessageContent,
      });

      final request = http.Request(
        'POST',
        Uri.parse('$apiEndpoint/chat/completions'),
      );
      request.headers['Content-Type'] = 'application/json';
      request.headers['Authorization'] = 'Bearer $apiKey';
      request.body = jsonEncode({
        'model': model,
        'messages': messages,
        'max_tokens': maxTokens,
        'temperature': temperature,
        'stream': true,
        if (thinkingMode) 'thinking': {'type': 'enabled'},
      });

      final client = http.Client();
      try {
        final streamedResponse = await client.send(request);

        if (streamedResponse.statusCode != 200) {
          final errorBody =
              await streamedResponse.stream.transform(utf8.decoder).join();
          final errorData = jsonDecode(errorBody);
          if (errorData is! Map<String, dynamic>) {
            throw Exception(
                'API错误: 无效的响应格式 (状态码: ${streamedResponse.statusCode})');
          }
          final errorMessage = errorData['error']?['message']?.toString() ??
              errorData['message']?.toString() ??
              '未知错误';
          throw Exception(
              'API错误: $errorMessage (状态码: ${streamedResponse.statusCode})');
        }

        final stream = streamedResponse.stream
            .transform(utf8.decoder)
            .transform(const LineSplitter());

        await for (final line in stream) {
          if (line.isEmpty) continue;
          if (line.startsWith('data: ')) {
            final data = line.substring(6);
            if (data == '[DONE]') {
              break;
            }
            try {
              final jsonData = jsonDecode(data);
              if (jsonData is! Map<String, dynamic>) {
                continue;
              }
              final choices = jsonData['choices'];
              if (choices is! List || choices.isEmpty) {
                continue;
              }
              final firstChoice = choices[0];
              if (firstChoice is! Map<String, dynamic>) {
                continue;
              }
              final delta = firstChoice['delta'];
              if (delta is! Map<String, dynamic>) {
                continue;
              }

              // 处理思考模型的推理过程
              final reasoningContent = delta['reasoning'] as String? ??
                  delta['reasoning_content'] as String?;
              if (reasoningContent != null && reasoningContent.isNotEmpty) {
                yield {'type': 'reasoning', 'content': reasoningContent};
              }

              // 处理最终回答
              if (delta.containsKey('content')) {
                final content = delta['content'] as String?;
                if (content != null && content.isNotEmpty) {
                  yield {'type': 'answer', 'content': content};
                }
              }
            } catch (e) {
              // Ignore parsing errors for incomplete JSON
            }
          }
        }
      } finally {
        client.close();
      }
    } catch (e) {
      if (e.toString().contains('API错误')) {
        rethrow;
      }
      throw Exception('网络错误: $e');
    }
  }

  /// 发送非流式请求到Gemini API
  ///
  /// 参数:
  ///   apiEndpoint - API端点URL
  ///   apiKey - API密钥
  ///   model - 模型名称
  ///   temperature - 温度参数（0.0-1.0）
  ///   maxTokens - 最大输出token数
  ///   contents - 内容列表，包含对话历史和当前消息
  /// 返回值:
  ///   Gemini模型的响应文本
  /// 异常:
  ///   抛出Exception当API请求失败或响应格式无效时
  /// 说明:
  ///   1. 构建Gemini API请求体
  ///   2. 处理URL格式，确保包含正确的路径和查询参数
  ///   3. 发送HTTP POST请求
  ///   4. 解析响应，提取文本内容
  ///   5. 处理安全过滤器阻止的情况
  ///   6. 统一错误处理，提供详细的错误信息
  Future<String> _sendGeminiMessage({
    required String apiEndpoint,
    required String apiKey,
    required String model,
    required double temperature,
    required int maxTokens,
    required List<Map<String, dynamic>> contents,
  }) async {
    try {
      final requestBody = {
        'contents': contents,
        'generationConfig': {
          'temperature': temperature,
          'maxOutputTokens': maxTokens,
        }
      };

      String url = apiEndpoint;

      if (!url.contains('/models/')) {
        final modelPath = model.contains('/') ? model : 'models/$model';
        url = url.endsWith('/')
            ? '$url$modelPath:generateContent'
            : '$url/$modelPath:generateContent';
      } else if (!url.contains(':generateContent')) {
        url = url.endsWith('/')
            ? '${url}generateContent'
            : '$url:generateContent';
      }

      if (!url.contains('?key=')) {
        url = '$url?key=$apiKey';
      }

      final response = await http.post(
        Uri.parse(url),
        headers: {
          'Content-Type': 'application/json',
        },
        body: jsonEncode(requestBody),
      );

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        if (data is! Map<String, dynamic>) {
          throw Exception('Gemini API返回了无效的响应格式');
        }

        final candidates = data['candidates'];
        if (candidates is! List || candidates.isEmpty) {
          throw Exception('Gemini API响应中缺少candidates字段');
        }

        final candidate = candidates[0];
        if (candidate['finishReason'] == 'SAFETY') {
          throw Exception('响应被安全过滤器阻止');
        }
        if (candidate['content'] != null &&
            candidate['content']['parts'] != null &&
            candidate['content']['parts'].isNotEmpty) {
          return candidate['content']['parts'][0]['text'].trim();
        }

        throw Exception('无效的Gemini API响应格式');
      } else {
        final errorData = jsonDecode(response.body);
        if (errorData is! Map<String, dynamic>) {
          throw Exception(
              'Gemini API错误: 无效的响应格式 (状态码: ${response.statusCode})');
        }
        final errorMessage = errorData['error']?['message']?.toString() ??
            errorData['message']?.toString() ??
            '未知错误';
        throw Exception(
            'Gemini API错误: $errorMessage (状态码: ${response.statusCode})');
      }
    } catch (e) {
      if (e is Exception) rethrow;
      throw Exception('Gemini API请求失败: $e');
    }
  }

  /// 发送流式请求到Gemini API
  ///
  /// 参数:
  ///   apiEndpoint - API端点URL
  ///   apiKey - API密钥
  ///   model - 模型名称
  ///   temperature - 温度参数（0.0-1.0）
  ///   maxTokens - 最大输出token数
  ///   contents - 内容列表，包含对话历史和当前消息
  /// 返回值:
  ///   返回一个`Stream<Map<String, dynamic>>`，实时输出Gemini模型的响应片段
  ///   Map包含 'type' 和 'content' 字段，type为 'answer'
  /// 异常:
  ///   抛出Exception当API请求失败或响应格式无效时
  /// 说明:
  ///   1. 构建Gemini流式API请求
  ///   2. 使用streamGenerateContent端点或添加流式参数
  ///   3. 处理Server-Sent Events (SSE) 数据流
  ///   4. 实时解析响应，yield文本片段
  ///   5. 处理连接关闭和错误情况
  Stream<Map<String, dynamic>> _sendGeminiMessageStreaming({
    required String apiEndpoint,
    required String apiKey,
    required String model,
    required double temperature,
    required int maxTokens,
    required List<Map<String, dynamic>> contents,
  }) async* {
    try {
      final requestBody = {
        'contents': contents,
        'generationConfig': {
          'temperature': temperature,
          'maxOutputTokens': maxTokens,
        }
      };

      String url;
      if (apiEndpoint.contains('streamGenerateContent')) {
        url = apiEndpoint.contains('?key=')
            ? '$apiEndpoint&alt=sse'
            : '$apiEndpoint?key=$apiKey&alt=sse';
      } else {
        url = apiEndpoint.replaceFirst(
            'generateContent', 'streamGenerateContent');
        if (!url.contains('?key=')) {
          url = '$url?key=$apiKey';
        }
        url = '$url&alt=sse';
      }

      final request = http.Request('POST', Uri.parse(url));
      request.headers['Content-Type'] = 'application/json';
      request.headers['Accept'] = 'text/event-stream';
      request.body = jsonEncode(requestBody);

      final client = http.Client();
      try {
        final streamedResponse = await client.send(request);

        if (streamedResponse.statusCode != 200) {
          final errorBody =
              await streamedResponse.stream.transform(utf8.decoder).join();
          final errorData = jsonDecode(errorBody);
          if (errorData is! Map<String, dynamic>) {
            throw Exception(
                'Gemini API错误: 无效的响应格式 (状态码: ${streamedResponse.statusCode})');
          }
          final errorMessage = errorData['error']?['message']?.toString() ??
              errorData['message']?.toString() ??
              '未知错误';
          throw Exception(
              'Gemini API错误: $errorMessage (状态码: ${streamedResponse.statusCode})');
        }

        final stream = streamedResponse.stream
            .transform(utf8.decoder)
            .transform(const LineSplitter());

        await for (final line in stream) {
          if (line.isEmpty) continue;
          if (line.startsWith('data: ')) {
            final data = line.substring(6);
            if (data == '[DONE]') {
              break;
            }
            try {
              final jsonData = jsonDecode(data);
              if (jsonData is! Map<String, dynamic>) {
                continue;
              }
              final candidates = jsonData['candidates'];
              if (candidates is! List || candidates.isEmpty) {
                continue;
              }
              final candidate = candidates[0];
              if (candidate is! Map<String, dynamic>) {
                continue;
              }
              final content = candidate['content'];
              if (content is! Map<String, dynamic>) {
                continue;
              }
              final parts = content['parts'];
              if (parts is! List || parts.isEmpty) {
                continue;
              }
              final firstPart = parts[0];
              if (firstPart is! Map<String, dynamic>) {
                continue;
              }
              final text = firstPart['text'] as String?;
              if (text != null && text.isNotEmpty) {
                yield {'type': 'answer', 'content': text};
              }
            } catch (e) {
              // 忽略解析错误
            }
          }
        }
      } finally {
        client.close();
      }
    } catch (e) {
      if (e is Exception) rethrow;
      throw Exception('Gemini API流式请求失败: $e');
    }
  }

  /// 生成对话标题
  ///
  /// 参数:
  ///   messages - 对话消息列表
  /// 返回值:
  ///   生成的对话标题（简短摘要）
  /// 异常:
  ///   抛出Exception当API密钥未配置或网络请求失败时
  /// 说明:
  ///   1. 基于对话内容生成简短标题（不超过20个字符）
  ///   2. 使用较低的温度参数以获得更稳定的输出
  ///   3. 支持OpenAI和Gemini API
  Future<String> generateConversationTitle(List<Message> messages) async {
    final apiEndpoint = await _settingsService.getApiEndpoint();
    final apiKey = await _settingsService.getApiKey();
    final model = await _settingsService.getModel();
    final apiType = await _settingsService.getApiType();

    if (apiKey.isEmpty) {
      throw Exception('请先在设置中配置API密钥');
    }

    // 提取对话摘要（前几轮对话）
    final summaryMessages = messages.take(6).toList(); // 最多3轮对话

    // 构建对话内容摘要
    final conversationSummary = summaryMessages.map((msg) {
      final role = msg.isUser ? '用户' : 'AI';
      return '$role: ${msg.content.trim()}';
    }).join('\n');

    try {
      if (apiType == 'gemini') {
        // Gemini API 生成标题
        final contents = [
          {
            'role': 'user',
            'parts': [
              {
                'text': '请根据以下对话内容生成一个简短的标题（不超过15个字），标题应该概括对话的主要内容：\n\n$conversationSummary'
              }
            ]
          }
        ];

        String url = apiEndpoint;
        if (!url.contains('/models/')) {
          final modelPath = model.contains('/') ? model : 'models/$model';
          url = url.endsWith('/')
              ? '$url$modelPath:generateContent'
              : '$url/$modelPath:generateContent';
        } else if (!url.contains(':generateContent')) {
          url = url.endsWith('/')
              ? '${url}generateContent'
              : '$url:generateContent';
        }

        if (!url.contains('?key=')) {
          url = '$url?key=$apiKey';
        }

        final response = await http.post(
          Uri.parse(url),
          headers: {
            'Content-Type': 'application/json',
          },
          body: jsonEncode({
            'contents': contents,
            'generationConfig': {
              'temperature': 0.3,
              'maxOutputTokens': 50,
            }
          }),
        );

        if (response.statusCode == 200) {
          final data = jsonDecode(response.body);
          if (data is! Map<String, dynamic>) {
            throw Exception('Gemini API返回了无效的响应格式');
          }

          final candidates = data['candidates'];
          if (candidates is! List || candidates.isEmpty) {
            throw Exception('Gemini API响应中缺少candidates字段');
          }

          final candidate = candidates[0];
          if (candidate['content'] != null &&
              candidate['content']['parts'] != null &&
              candidate['content']['parts'].isNotEmpty) {
            var title = candidate['content']['parts'][0]['text'].toString().trim();
            // 移除可能的引号
            if (title.startsWith('"') || title.startsWith('\'') || title.startsWith('|')) {
              title = title.substring(1);
            }
            if (title.endsWith('"') || title.endsWith('\'') || title.endsWith('|')) {
              title = title.substring(0, title.length - 1);
            }
            // 截断过长的标题
            if (title.length > 20) {
              title = '${title.substring(0, 20)}...';
            }
            return title;
          }

          throw Exception('无效的Gemini API响应格式');
        } else {
          final errorData = jsonDecode(response.body);
          final errorMessage = errorData['error']?['message']?.toString() ??
              errorData['message']?.toString() ??
              '未知错误';
          throw Exception('Gemini API错误: $errorMessage (状态码: ${response.statusCode})');
        }
      } else {
        // OpenAI API 生成标题
        final requestMessages = [
          {
            'role': 'system',
            'content': '你是一个专业的对话标题生成助手。请根据对话内容生成一个简短、准确的标题，不超过15个字。只返回标题，不要加引号或其他格式。'
          },
          {
            'role': 'user',
            'content': '请根据以下对话内容生成一个简短的标题：\n\n$conversationSummary'
          }
        ];

        final response = await http.post(
          Uri.parse('$apiEndpoint/chat/completions'),
          headers: {
            'Content-Type': 'application/json',
            'Authorization': 'Bearer $apiKey',
          },
          body: jsonEncode({
            'model': model,
            'messages': requestMessages,
            'max_tokens': 50,
            'temperature': 0.3,
          }),
        );

        if (response.statusCode == 200) {
          final data = jsonDecode(response.body);
          if (data is! Map<String, dynamic> ||
              data['choices'] == null ||
              (data['choices'] as List).isEmpty) {
            throw Exception('API返回了无效的响应格式');
          }

          final content = data['choices'][0]['message']['content']?.toString().trim() ?? '';
          // 移除可能的引号
          var title = content;
          if (title.startsWith('"') || title.startsWith('\'') || title.startsWith('|')) {
            title = title.substring(1);
          }
          if (title.endsWith('"') || title.endsWith('\'') || title.endsWith('|')) {
            title = title.substring(0, title.length - 1);
          }
          // 截断过长的标题
          if (title.length > 20) {
            title = '${title.substring(0, 20)}...';
          }
          return title;
        } else {
          final errorData = jsonDecode(response.body);
          final errorMessage = errorData['error']?['message']?.toString() ??
              errorData['message']?.toString() ??
              '未知错误';
          throw Exception('API错误: $errorMessage (状态码: ${response.statusCode})');
        }
      }
    } catch (e) {
      if (e is Exception) rethrow;
      throw Exception('生成标题时发生错误: $e');
    }
  }
}
