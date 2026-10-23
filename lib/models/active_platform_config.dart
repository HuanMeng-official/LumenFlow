import 'ai_platform.dart';

/// Immutable snapshot of the configuration used for the next AI request.
class ActivePlatformConfig {
  final AIPlatform platform;
  final String endpoint;
  final String apiKey;
  final String model;
  final String apiType;

  const ActivePlatformConfig({
    required this.platform,
    required this.endpoint,
    required this.apiKey,
    required this.model,
    required this.apiType,
  });

  bool get isConfigured => apiKey.isNotEmpty;
}
