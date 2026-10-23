import 'ai_tool.dart';

abstract class AIToolExecutor {
  List<AIToolDefinition> get tools;

  Future<AIToolResult> execute(AIToolCall call);
}
