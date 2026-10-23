import 'dart:convert';

/// Tool exposed to the model.
class AIToolDefinition {
  final String name;
  final String description;
  final Map<String, dynamic> inputSchema;

  const AIToolDefinition({
    required this.name,
    required this.description,
    required this.inputSchema,
  });

  Map<String, dynamic> toOpenAIJson() {
    return {
      'type': 'function',
      'function': {
        'name': name,
        'description': description,
        'parameters': inputSchema,
      },
    };
  }
}

/// A tool invocation requested by the model.
class AIToolCall {
  final String id;
  final String name;
  final String argumentsJson;

  const AIToolCall({
    required this.id,
    required this.name,
    required this.argumentsJson,
  });

  Map<String, dynamic> get arguments {
    if (argumentsJson.trim().isEmpty) return const {};
    try {
      final decoded = jsonDecode(argumentsJson);
      if (decoded is Map<String, dynamic>) return decoded;
    } catch (_) {
      // Invalid or partial JSON is treated as no arguments.
    }
    return const {};
  }
}

/// The result of executing a tool.
class AIToolResult {
  final String toolCallId;
  final String name;
  final String content;
  final bool isError;

  const AIToolResult({
    required this.toolCallId,
    required this.name,
    required this.content,
    this.isError = false,
  });
}
