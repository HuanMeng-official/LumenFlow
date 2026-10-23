import '../contracts/ai_tool.dart';
import '../contracts/ai_tool_executor.dart';

/// Merges built-in and MCP tools and routes calls by tool name.
class CompositeToolExecutor implements AIToolExecutor {
  CompositeToolExecutor(this.executors);

  final List<AIToolExecutor> executors;

  @override
  List<AIToolDefinition> get tools {
    return [
      for (final executor in executors) ...executor.tools,
    ];
  }

  @override
  Future<AIToolResult> execute(AIToolCall call) async {
    for (final executor in executors) {
      if (executor.tools.any((tool) => tool.name == call.name)) {
        return executor.execute(call);
      }
    }

    return AIToolResult(
      toolCallId: call.id,
      name: call.name,
      content: 'Unknown tool: ${call.name}',
      isError: true,
    );
  }
}
