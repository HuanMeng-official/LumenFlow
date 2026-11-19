import 'dart:convert';
import 'dart:io';

import '../models/ai_platform.dart';
import '../providers/claude_provider.dart';

/// 从 AI 平台接口拉取可用模型 ID 列表的共享辅助工具。
Future<List<String>> fetchPlatformModelsFromApi(AIPlatform platform) async {
  final client = HttpClient();

  try {
    if (platform.type == 'gemini') {
      var endpoint = platform.endpoint;
      final modelsIndex = endpoint.indexOf('/models/');
      if (modelsIndex >= 0) {
        endpoint = endpoint.substring(0, modelsIndex);
      }
      if (endpoint.endsWith('/')) {
        endpoint = endpoint.substring(0, endpoint.length - 1);
      }
      if (endpoint.endsWith('/interactions')) {
        endpoint = endpoint.substring(
          0,
          endpoint.length - '/interactions'.length,
        );
      }
      if (endpoint.endsWith('/models')) {
        endpoint = endpoint.substring(0, endpoint.length - '/models'.length);
      }
      final modelsUrl = '$endpoint/models?key=${platform.apiKey}';
      final request = await client.getUrl(Uri.parse(modelsUrl));
      final response = await request.close();
      final responseBody = await response.transform(utf8.decoder).join();

      if (response.statusCode != 200) {
        throw Exception(
          'API returned error: ${response.statusCode}\nURL: $modelsUrl\n$responseBody',
        );
      }

      final data = jsonDecode(responseBody);
      if (data is Map && data.containsKey('models')) {
        final modelsData = data['models'] as List;
        const excludedPatterns = [
          'embedding',
          'imagen',
          'veo',
          '-tts',
          'robotics',
          'computer-use',
          'nano-banana',
          'aqa',
          'deep-research',
        ];
        return modelsData
            .where((m) {
              final name = m['name'] as String? ?? '';
              final methods = m['supportedGenerationMethods'] as List? ?? [];
              if (!methods.contains('generateContent') &&
                  !methods.contains('interactions')) {
                return false;
              }
              for (final pattern in excludedPatterns) {
                if (name.contains(pattern)) return false;
              }
              return true;
            })
            .map((m) => m['name'] as String)
            .toList();
      }
      throw Exception('API returned invalid format');
    }

    if (platform.type == 'zhipu') {
      final modelsUrl = '${platform.endpoint}/models';
      final request = await client.getUrl(Uri.parse(modelsUrl));
      request.headers.add('Authorization', 'Bearer ${platform.apiKey}');
      final response = await request.close();
      final responseBody = await response.transform(utf8.decoder).join();

      if (response.statusCode != 200) {
        throw Exception(
          'API returned error: ${response.statusCode}\n$responseBody',
        );
      }
      final data = jsonDecode(responseBody);
      if (data is Map && data.containsKey('data')) {
        return (data['data'] as List).map((m) => m['id'] as String).toList();
      }
      throw Exception('API returned invalid format');
    }

    if (platform.type == 'claude') {
      var endpoint = platform.endpoint;
      if (endpoint.endsWith('/')) {
        endpoint = endpoint.substring(0, endpoint.length - 1);
      }
      final modelsUrl = '$endpoint/models';
      final request = await client.getUrl(Uri.parse(modelsUrl));
      request.headers.add('X-Api-Key', platform.apiKey);
      request.headers.add('anthropic-version', ClaudeProvider.anthropicVersion);
      request.headers.add('Content-Type', 'application/json');

      final response = await request.close();
      final responseBody = await response.transform(utf8.decoder).join();

      if (response.statusCode != 200) {
        throw Exception(
          'API returned error: ${response.statusCode}\nURL: $modelsUrl\n$responseBody',
        );
      }
      final data = jsonDecode(responseBody);
      if (data is Map && data.containsKey('data')) {
        return (data['data'] as List)
            .where((m) => m is Map && m['id'] != null)
            .map((m) => m['id'] as String)
            .toList();
      }
      throw Exception('API returned invalid format');
    }

    // OpenAI 兼容端点格式
    final String modelsUrl;
    if (platform.endpoint.endsWith('/v1') ||
        platform.endpoint.contains('/v1/')) {
      modelsUrl = '${platform.endpoint}/models';
    } else {
      modelsUrl = '${platform.endpoint}/v1/models';
    }
    final request = await client.getUrl(Uri.parse(modelsUrl));
    request.headers.add('Authorization', 'Bearer ${platform.apiKey}');

    final response = await request.close();
    final responseBody = await response.transform(utf8.decoder).join();

    if (response.statusCode != 200) {
      throw Exception(
        'API returned error: ${response.statusCode}\n$responseBody',
      );
    }
    final data = jsonDecode(responseBody);
    if (data is Map && data.containsKey('data')) {
      return (data['data'] as List).map((m) => m['id'] as String).toList();
    }
    throw Exception('API returned invalid format');
  } finally {
    client.close();
  }
}
