import 'dart:async';
import 'package:flutter/foundation.dart';
import '../models/message.dart';
import '../services/conversation_service.dart';

/// Owns one streaming AI send: append the placeholder, consume chunks,
/// persist intermediate/final states, and ignore events after finalization.
class ChatSendController {
  ChatSendController({
    required this._conversationService,
    required this._conversationId,
    required this._initialMessage,
    required List<Message> history,
    required this._openStream,
    required this._onUpdate,
    required this._onComplete,
    required this._onError,
    required this._onStopped,
    this.onToolEvent,
    required this._errorContentBuilder,
    required this._emptyResponseContent,
    this._persistInterval = const Duration(milliseconds: 500),
    String initialAnswer = '',
    String initialReasoning = '',
    this._appendInitialMessage = true,
  }) : _answer = StringBuffer(initialAnswer),
       _reasoning = StringBuffer(initialReasoning);

  final ConversationService _conversationService;
  final String _conversationId;
  final Message _initialMessage;
  final Stream<Map<String, dynamic>> Function() _openStream;
  final void Function(Message message) _onUpdate;
  final void Function(Message message) _onComplete;
  final void Function(Message message) _onError;
  final void Function(Message message) _onStopped;
  final void Function(Map<String, dynamic> event)? onToolEvent;
  final String Function(Object error) _errorContentBuilder;
  final String _emptyResponseContent;
  final Duration _persistInterval;
  final bool _appendInitialMessage;

  final StringBuffer _answer;
  final StringBuffer _reasoning;

  StreamSubscription<Map<String, dynamic>>? _subscription;
  Timer? _persistTimer;
  DateTime? _lastPersistAt;
  Message? _pendingPersist;
  bool _started = false;
  bool _finalized = false;
  bool _active = true;
  int _receivedChunks = 0;

  bool get isActive => _active && !_finalized;

  /// History excludes the trailing current-user message and AI placeholder.
  static List<Message> buildHistory(List<Message> messages) {
    if (messages.length < 2) return const [];
    return messages.sublist(0, messages.length - 2);
  }

  /// Drops the target AI message and every later turn so regenerate resends
  /// the preceding user turn without appending a new answer out of order.
  static List<Message> truncateForRegenerate(
    List<Message> messages,
    String aiMessageId,
  ) {
    final index = messages.indexWhere((message) => message.id == aiMessageId);
    if (index == -1) return List<Message>.from(messages);
    return messages.sublist(0, index);
  }

  Future<void> start() async {
    if (_started || _finalized) return;
    _started = true;

    if (_appendInitialMessage) {
      await _conversationService.appendMessage(
        _conversationId,
        _initialMessage,
      );
    }

    if (_finalized) return;

    try {
      _subscription = _openStream().listen(
        _handleChunk,
        onError: _handleError,
        onDone: _handleDone,
        cancelOnError: true,
      );
    } catch (error) {
      await _finalizeError(error);
    }
  }

  void _handleChunk(Map<String, dynamic> chunk) {
    if (!_active || _finalized) return;

    final type = chunk['type'] as String?;
    if (type == 'tool_call' ||
        type == 'tool_result' ||
        type == 'tool_status') {
      onToolEvent?.call(chunk);
      return;
    }

    _receivedChunks++;
    final content = chunk['content'] as String? ?? '';

    if (type == 'reasoning') {
      _reasoning.write(content);
    } else {
      _answer.write(content);
    }

    final message = _build(MessageStatus.sending);
    _onUpdate(message);
    _schedulePersist(message);
  }

  Future<void> _handleDone() async {
    if (!_active || _finalized) return;

    if (_receivedChunks == 0) {
      await _finalizeError(null, empty: true);
      return;
    }

    await _finalize(_build(MessageStatus.sent), _onComplete);
  }

  void _handleError(Object error, StackTrace stackTrace) {
    if (!_active || _finalized) return;
    unawaited(_finalizeError(error));
  }

  Future<void> stop() async {
    if (!_active || _finalized) return;

    _active = false;
    final subscription = _subscription;
    _subscription = null;
    if (subscription != null) {
      // Do not await cancellation: the upstream may be suspended in a slow
      // tool call. The UI must stop immediately; late events are ignored.
      unawaited(subscription.cancel());
    }
    await _finalize(_build(MessageStatus.stopped), _onStopped);
  }

  Future<void> dispose() async {
    _active = false;
    _finalized = true;
    _persistTimer?.cancel();
    _persistTimer = null;
    _pendingPersist = null;
    await _subscription?.cancel();
    _subscription = null;
  }

  Future<void> _finalizeError(Object? error, {bool empty = false}) async {
    if (_finalized) return;

    final errorContent = empty
        ? _emptyResponseContent
        : _errorContentBuilder(error ?? 'Unknown error');
    final content = _answer.isEmpty
        ? errorContent
        : '${_answer.toString()}\n\n$errorContent';

    final message = _buildMessage(
      content,
      _reasoning.isEmpty ? null : _reasoning.toString(),
      MessageStatus.error,
    );
    await _finalize(message, _onError);
  }

  Future<void> _finalize(
    Message message,
    void Function(Message message) callback,
  ) async {
    if (_finalized) return;

    _finalized = true;
    _active = false;
    _persistTimer?.cancel();
    _persistTimer = null;
    _pendingPersist = null;

    await _subscription?.cancel();
    _subscription = null;

    try {
      await _conversationService.updateMessage(_conversationId, message);
    } catch (error) {
      debugPrint('ChatSendController: failed to persist final state: $error');
    }

    callback(message);
  }

  Message _build(MessageStatus status) {
    return _buildMessage(
      _answer.toString(),
      _reasoning.isEmpty ? null : _reasoning.toString(),
      status,
    );
  }

  Message _buildMessage(
    String content,
    String? reasoning,
    MessageStatus status,
  ) {
    var variants = _initialMessage.variants;
    var activeVariantIndex = _initialMessage.activeVariantIndex;

    if (variants.isNotEmpty) {
      final updated = List<MessageVariant>.from(variants);
      final index = activeVariantIndex.clamp(0, updated.length - 1);
      updated[index] = MessageVariant(
        content: content,
        reasoningContent: reasoning,
        timestamp: _initialMessage.timestamp,
        status: status,
      );
      variants = updated;
      activeVariantIndex = index;
    }

    return Message(
      id: _initialMessage.id,
      content: content,
      reasoningContent: reasoning,
      isUser: _initialMessage.isUser,
      timestamp: _initialMessage.timestamp,
      status: status,
      attachments: _initialMessage.attachments,
      variants: variants,
      activeVariantIndex: activeVariantIndex,
    );
  }

  void _schedulePersist(Message message) {
    if (_finalized) return;

    final now = DateTime.now();
    final last = _lastPersistAt;

    // Leading edge: persist the first chunk immediately and at most one write
    // per interval thereafter. A trailing debounce would never fire during
    // continuous token streaming.
    if (last == null || now.difference(last) >= _persistInterval) {
      _lastPersistAt = now;
      _persistTimer?.cancel();
      _persistTimer = null;
      _pendingPersist = null;
      _persist(message);
      return;
    }

    _pendingPersist = message;
    _persistTimer ??= Timer(_persistInterval - now.difference(last), () {
      _persistTimer = null;
      final pending = _pendingPersist;
      if (pending == null || _finalized) return;
      _pendingPersist = null;
      _lastPersistAt = DateTime.now();
      _persist(pending);
    });
  }

  void _persist(Message message) {
    unawaited(
      _conversationService
          .updateMessage(_conversationId, message)
          .catchError((Object error) {
        debugPrint(
          'ChatSendController: failed to persist intermediate state: $error',
        );
      }),
    );
  }
}
