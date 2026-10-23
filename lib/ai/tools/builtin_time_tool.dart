import 'dart:convert';

import '../contracts/ai_tool.dart';
import '../contracts/ai_tool_executor.dart';
import '../../utils/ai_tools/time_utils.dart';

/// In-app time tool exposed to tool-capable models.
class BuiltInTimeTool implements AIToolExecutor {
  BuiltInTimeTool({this.enabled = true});

  static const String toolName = 'builtin__get_time';

  static const AIToolDefinition definition = AIToolDefinition(
    name: toolName,
    description:
        'Get the current date and time. Use this when the user asks for the '
        'current time or date.',
    inputSchema: {
      'type': 'object',
      'properties': {
        'timezone': {
          'type': 'string',
          'description':
              "Optional: pass 'utc' for UTC; otherwise the device's local "
              'time is returned.',
        },
      },
    },
  );

  final bool enabled;

  @override
  List<AIToolDefinition> get tools {
    return enabled ? const [definition] : const [];
  }

  @override
  Future<AIToolResult> execute(AIToolCall call) async {
    final requested =
        call.arguments['timezone']?.toString().trim().toLowerCase();
    final useUtc = requested == 'utc' || requested == 'z';

    final localNow = DateTime.now();
    final now = useUtc ? localNow.toUtc() : localNow;
    final offset = useUtc ? Duration.zero : localNow.timeZoneOffset;
    final sign = offset.isNegative ? '-' : '+';
    final hours = offset.inHours.abs().toString().padLeft(2, '0');
    final minutes =
        (offset.inMinutes.abs() % 60).toString().padLeft(2, '0');

    final payload = <String, dynamic>{
      'timezone': useUtc ? 'UTC' : 'local',
      'utc_offset': '$sign$hours:$minutes',
      'iso': now.toIso8601String(),
      'formatted': TimeUtils.format(time: now),
      'timestamp_ms': now.millisecondsSinceEpoch,
    };

    return AIToolResult(
      toolCallId: call.id,
      name: call.name,
      content: jsonEncode(payload),
    );
  }
}
