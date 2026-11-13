import 'dart:convert';

import '../../services/user_service.dart';
import '../contracts/ai_tool.dart';
import '../contracts/ai_tool_executor.dart';

/// Reads the locally stored user profile on demand.
///
/// The profile is intentionally not injected into the system prompt: the model
/// only receives the name, gender, and birthday when it asks for them.
class BuiltInUserProfileTool implements AIToolExecutor {
  BuiltInUserProfileTool({this.enabled = true, UserService? userService})
    : _userService = userService ?? UserService();

  static const String toolName = 'builtin__get_user_profile';

  static const AIToolDefinition definition = AIToolDefinition(
    name: toolName,
    description:
        "Get the current user's profile: name, gender, and birthday. Use this "
        'when you need to address the user by name or refer to their personal '
        'details. Do not guess these values.',
    inputSchema: {
      'type': 'object',
      'properties': <String, dynamic>{},
      'additionalProperties': false,
    },
  );

  final bool enabled;
  final UserService _userService;

  @override
  List<AIToolDefinition> get tools {
    return enabled ? const [definition] : const [];
  }

  @override
  Future<AIToolResult> execute(AIToolCall call) async {
    try {
      final profile = await _userService.getUserProfile();
      final birthday = profile.birthday;
      return AIToolResult(
        toolCallId: call.id,
        name: call.name,
        content: jsonEncode({
          'name': profile.username,
          'gender': profile.gender,
          'birthday': birthday?.toIso8601String().split('T').first,
        }),
      );
    } catch (error) {
      return AIToolResult(
        toolCallId: call.id,
        name: call.name,
        content: jsonEncode({'error': error.toString()}),
        isError: true,
      );
    }
  }
}
