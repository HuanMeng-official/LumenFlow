enum AIErrorType {
  network,
  timeout,
  cancelled,
  authentication,
  rateLimit,
  server,
  invalidResponse,
  unsupported,
}

class AIError implements Exception {
  final AIErrorType type;
  final String message;
  final int? statusCode;
  final Object? cause;

  const AIError({
    required this.type,
    required this.message,
    this.statusCode,
    this.cause,
  });

  bool get isRetryable {
    if (type == AIErrorType.network ||
        type == AIErrorType.timeout ||
        type == AIErrorType.rateLimit) {
      return true;
    }
    if (type == AIErrorType.server) {
      return statusCode == null || statusCode! >= 500;
    }
    return false;
  }

  @override
  String toString() {
    final status = statusCode == null ? '' : ', statusCode: $statusCode';
    return 'AIError(${type.name}$status): $message';
  }
}
