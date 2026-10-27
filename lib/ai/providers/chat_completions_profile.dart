import '../contracts/ai_request.dart';

typedef ChatFieldsBuilder = Map<String, dynamic> Function(AIRequest request);
typedef ChatTemperatureBuilder = double Function(AIRequest request);
typedef ChatReasoningReader = String? Function(Map<String, dynamic> delta);

String? defaultReasoningReader(Map<String, dynamic> delta) {
  final reasoning = delta['reasoning'];
  if (reasoning is String && reasoning.isNotEmpty) return reasoning;

  final content = delta['reasoning_content'];
  if (content is String && content.isNotEmpty) return content;

  return null;
}

/// Per-platform quirks for the OpenAI Chat Completions protocol.
class ChatCompletionsProfile {
  final String id;
  final String path;
  final String tokenField;
  final bool supportsTools;
  final ChatFieldsBuilder? thinkingFieldsBuilder;
  final ChatFieldsBuilder? extraFieldsBuilder;
  final ChatTemperatureBuilder? temperatureBuilder;
  final ChatReasoningReader? reasoningReader;

  /// Whether assistant history must replay `reasoning_content`.
  final bool replaysReasoningContent;

  /// Some providers reject `tool_choice` while thinking is enabled.
  final bool supportsToolChoiceWithThinking;

  const ChatCompletionsProfile({
    required this.id,
    this.path = '/chat/completions',
    this.tokenField = 'max_tokens',
    this.supportsTools = true,
    this.thinkingFieldsBuilder,
    this.extraFieldsBuilder,
    this.temperatureBuilder,
    this.reasoningReader,
    this.replaysReasoningContent = false,
    this.supportsToolChoiceWithThinking = true,
  });

  Map<String, dynamic> thinkingFields(AIRequest request) {
    return thinkingFieldsBuilder?.call(request) ?? const {};
  }

  Map<String, dynamic> extraFields(AIRequest request) {
    return extraFieldsBuilder?.call(request) ?? const {};
  }

  double temperature(AIRequest request) {
    return temperatureBuilder?.call(request) ?? request.temperature;
  }

  String? reasoningDelta(Map<String, dynamic> delta) {
    return (reasoningReader ?? defaultReasoningReader)(delta);
  }
}

Map<String, dynamic> _deepSeekThinking(AIRequest request) {
  return {
    if (request.thinkingMode) 'reasoning_effort': 'high',
    'thinking': {'type': request.thinkingMode ? 'enabled' : 'disabled'},
  };
}

Map<String, dynamic> _kimiThinking(AIRequest request) {
  if (request.model.startsWith('kimi-k3')) {
    return {
      'reasoning_effort': request.thinkingMode ? 'high' : 'low',
    };
  }
  return {
    'thinking': {'type': request.thinkingMode ? 'enabled' : 'disabled'},
  };
}

Map<String, dynamic> _minimaxThinking(AIRequest request) {
  return {
    'thinking': {'type': 'adaptive'},
    'reasoning_effort': request.thinkingMode ? 'high' : 'low',
  };
}

String? _minimaxReasoning(Map<String, dynamic> delta) {
  final content = delta['reasoning_content'];
  if (content is String && content.isNotEmpty) return content;

  final details = delta['reasoning_details'];
  if (details is List) {
    final buffer = StringBuffer();
    for (final item in details) {
      if (item is Map) {
        final text = item['text'];
        if (text is String && text.isNotEmpty) {
          buffer.write(text);
        }
      }
    }
    if (buffer.isNotEmpty) return buffer.toString();
  }

  return null;
}

Map<String, dynamic> _zhipuThinking(AIRequest request) {
  if (request.model.startsWith('glm-5.3')) {
    return {
      'thinking': {'type': 'enabled'},
      'reasoning_effort': request.thinkingMode ? 'high' : 'low',
    };
  }
  return {
    'thinking': {'type': request.thinkingMode ? 'enabled' : 'disabled'},
  };
}

Map<String, dynamic> _enableThinkingFields(AIRequest request) {
  return {
    'enable_thinking': request.thinkingMode,
    'thinking_budget': 4096,
  };
}

Map<String, dynamic> _samplingFields(AIRequest request) {
  return const {
    'top_p': 0.7,
    'top_k': 50,
  };
}

Map<String, dynamic> _mimoThinking(AIRequest request) {
  if (!request.thinkingMode) return const {};
  return {
    'thinking': {'type': 'enabled'},
  };
}

class ChatCompletionsProfiles {
  static final ChatCompletionsProfile deepseek = ChatCompletionsProfile(
    id: 'deepseek',
    thinkingFieldsBuilder: _deepSeekThinking,
    replaysReasoningContent: true,
    supportsToolChoiceWithThinking: false,
  );

  static final ChatCompletionsProfile kimi = ChatCompletionsProfile(
    id: 'kimi',
    thinkingFieldsBuilder: _kimiThinking,
  );

  static final ChatCompletionsProfile minimax = ChatCompletionsProfile(
    id: 'minimax',
    tokenField: 'max_completion_tokens',
    thinkingFieldsBuilder: _minimaxThinking,
    reasoningReader: _minimaxReasoning,
  );

  static final ChatCompletionsProfile zhipu = ChatCompletionsProfile(
    id: 'zhipu',
    thinkingFieldsBuilder: _zhipuThinking,
  );

  static final ChatCompletionsProfile siliconflow = ChatCompletionsProfile(
    id: 'siliconflow',
    thinkingFieldsBuilder: _enableThinkingFields,
    extraFieldsBuilder: _samplingFields,
  );

  static final ChatCompletionsProfile other = ChatCompletionsProfile(
    id: 'other',
    thinkingFieldsBuilder: _enableThinkingFields,
    extraFieldsBuilder: _samplingFields,
  );

  static final ChatCompletionsProfile xiaomimimo = ChatCompletionsProfile(
    id: 'xiaomimimo',
    tokenField: 'max_completion_tokens',
    thinkingFieldsBuilder: _mimoThinking,
  );

  static ChatCompletionsProfile? forType(String type) {
    switch (type) {
      case 'deepseek':
        return deepseek;
      case 'kimi':
        return kimi;
      case 'minimax':
        return minimax;
      case 'zhipu':
        return zhipu;
      case 'siliconflow':
        return siliconflow;
      case 'other':
        return other;
      case 'xiaomimimo':
        return xiaomimimo;
      default:
        return null;
    }
  }
}
