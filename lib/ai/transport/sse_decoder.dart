class SseEvent {
  final String? event;
  final String data;

  const SseEvent({this.event, required this.data});
}

/// Incremental Server-Sent Events decoder.
///
/// Feed raw text chunks with [add]; complete events (terminated by a blank
/// line) are returned. Call [flush] to emit a trailing event without a final
/// blank line.
class SseDecoder {
  final StringBuffer _buffer = StringBuffer();

  List<SseEvent> add(String chunk) {
    if (chunk.isEmpty) return const [];

    _buffer.write(chunk);
    _normalizeBuffer();
    return _drain();
  }

  List<SseEvent> flush() {
    if (_buffer.isEmpty) return const [];

    _normalizeBuffer();
    final content = _buffer.toString();
    _buffer.clear();

    final event = _parse(content);
    return event == null ? const [] : [event];
  }

  void _normalizeBuffer() {
    final current = _buffer.toString();
    if (!current.contains('\r')) return;

    _buffer
      ..clear()
      ..write(current.replaceAll('\r\n', '\n'));
  }

  List<SseEvent> _drain() {
    final content = _buffer.toString();
    final parts = content.split('\n\n');
    _buffer.clear();

    if (content.endsWith('\n\n')) {
      parts.removeLast();
    } else {
      final tail = parts.removeLast();
      _buffer.write(tail);
    }

    final events = <SseEvent>[];
    for (final part in parts) {
      final event = _parse(part);
      if (event != null) {
        events.add(event);
      }
    }
    return events;
  }

  SseEvent? _parse(String block) {
    String? eventName;
    final data = StringBuffer();
    var hasData = false;

    for (final line in block.split('\n')) {
      if (line.isEmpty || line.startsWith(':')) continue;

      if (line.startsWith('event:')) {
        eventName = line.substring(6).trim();
      } else if (line.startsWith('data:')) {
        var value = line.substring(5);
        if (value.startsWith(' ')) {
          value = value.substring(1);
        }
        if (hasData) {
          data.write('\n');
        }
        data.write(value);
        hasData = true;
      }
    }

    if (!hasData) return null;
    return SseEvent(event: eventName, data: data.toString());
  }
}
