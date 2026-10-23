import 'dart:async';

import 'ai_error.dart';

class CancellationToken {
  final Completer<void> _completer = Completer<void>();
  bool _cancelled = false;

  bool get isCancelled => _cancelled;

  Future<void> get whenCancelled => _completer.future;

  void cancel() {
    if (_cancelled) return;
    _cancelled = true;
    if (!_completer.isCompleted) {
      _completer.complete();
    }
  }

  void throwIfCancelled() {
    if (_cancelled) {
      throw const AIError(
        type: AIErrorType.cancelled,
        message: 'Request cancelled',
      );
    }
  }
}
