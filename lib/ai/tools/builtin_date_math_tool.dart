import 'dart:convert';
import 'dart:math' as math;

import '../contracts/ai_tool.dart';
import '../contracts/ai_tool_executor.dart';
import '../../utils/ai_tools/time_utils.dart';

/// Date arithmetic tool: differences, calendar addition, and date info.
///
/// Supports local time, UTC, and explicit ISO 8601 offsets. It does not
/// convert between named IANA time zones.
class BuiltInDateMathTool implements AIToolExecutor {
  BuiltInDateMathTool({this.enabled = true});

  static const String toolName = 'builtin__date_math';

  static const List<String> _weekdays = [
    'Monday',
    'Tuesday',
    'Wednesday',
    'Thursday',
    'Friday',
    'Saturday',
    'Sunday',
  ];

  static const AIToolDefinition definition = AIToolDefinition(
    name: toolName,
    description:
        'Perform date and time arithmetic. Operations: "diff" computes the '
        'duration between start and end (both default to now), including '
        'total days/hours and a calendar breakdown; "add" adds signed '
        'calendar components (years, months, weeks, days, hours, minutes, '
        'seconds) to start (defaults to now); "info" returns the weekday, '
        'day of year, ISO week, days in month, leap-year flag, and UTC '
        'offset. Dates accept ISO 8601 such as 2026-11-12 or '
        '2026-11-12T13:45:00Z, or YYYY/MM/DD; dates without an offset use '
        'the selected timezone. Month addition clamps to the last day of the '
        'target month. Business days count Monday through Friday only and '
        'do not account for holidays.',
    inputSchema: {
      'type': 'object',
      'properties': {
        'operation': {
          'type': 'string',
          'enum': ['diff', 'add', 'info'],
          'description':
              'diff: duration between start and end; add: add components '
              'to start; info: calendar details for date.',
        },
        'start': {
          'type': 'string',
          'description':
              'Start date/time for diff or add. Defaults to now. Accepts '
              'ISO 8601 or YYYY/MM/DD.',
        },
        'end': {
          'type': 'string',
          'description':
              'End date/time for diff. Defaults to now. Accepts ISO 8601 '
              'or YYYY/MM/DD.',
        },
        'date': {
          'type': 'string',
          'description':
              'Date/time for info. Defaults to now. Accepts ISO 8601 or '
              'YYYY/MM/DD.',
        },
        'years': {
          'type': 'integer',
          'description': 'Signed years to add for the add operation.',
        },
        'months': {
          'type': 'integer',
          'description': 'Signed months to add for the add operation.',
        },
        'weeks': {
          'type': 'integer',
          'description': 'Signed weeks to add for the add operation.',
        },
        'days': {
          'type': 'integer',
          'description': 'Signed days to add for the add operation.',
        },
        'hours': {
          'type': 'integer',
          'description': 'Signed hours to add for the add operation.',
        },
        'minutes': {
          'type': 'integer',
          'description': 'Signed minutes to add for the add operation.',
        },
        'seconds': {
          'type': 'integer',
          'description': 'Signed seconds to add for the add operation.',
        },
        'include_business_days': {
          'type': 'boolean',
          'description':
              'For diff, also count Monday-Friday weekdays between the '
              'start and end dates. The end date is excluded.',
        },
        'timezone': {
          'type': 'string',
          'enum': ['local', 'utc'],
          'description':
              'Timezone for naive input and output. Defaults to local. '
              'Explicit offsets in the input are always honored.',
        },
      },
      'required': ['operation'],
    },
  );

  final bool enabled;

  @override
  List<AIToolDefinition> get tools {
    return enabled ? const [definition] : const [];
  }

  @override
  Future<AIToolResult> execute(AIToolCall call) async {
    final arguments = call.arguments;
    final operation =
        arguments['operation']?.toString().trim().toLowerCase() ?? '';
    if (operation.isEmpty) {
      return _error(call, 'operation is required');
    }

    final timezone =
        arguments['timezone']?.toString().trim().toLowerCase() ?? 'local';
    if (timezone != 'local' && timezone != 'utc' && timezone != 'z') {
      return _error(call, 'timezone must be "local" or "utc"');
    }
    final useUtc = timezone == 'utc' || timezone == 'z';

    try {
      switch (operation) {
        case 'diff':
          return _diff(call, arguments, useUtc);
        case 'add':
          return _add(call, arguments, useUtc);
        case 'info':
          return _info(call, arguments, useUtc);
        default:
          return _error(
            call,
            'Unknown operation "$operation". Use diff, add, or info.',
          );
      }
    } on FormatException catch (error) {
      return _error(call, error.message);
    } on RangeError catch (error) {
      return _error(call, 'Date is outside the supported range: $error');
    } catch (error) {
      return _error(call, error.toString());
    }
  }

  AIToolResult _diff(
    AIToolCall call,
    Map<String, dynamic> arguments,
    bool useUtc,
  ) {
    final start = _readDate(arguments['start'], useUtc, 'start');
    final end = _readDate(arguments['end'], useUtc, 'end');
    final duration = end.difference(start);
    final isNegative = duration.isNegative;
    final earlier = isNegative ? end : start;
    final later = isNegative ? start : end;

    final calendar = _calendarDifference(earlier, later);
    final signedCalendar = <String, dynamic>{
      'years': isNegative ? -(calendar.years) : calendar.years,
      'months': isNegative ? -(calendar.months) : calendar.months,
      'days': isNegative ? -(calendar.days) : calendar.days,
      'hours': isNegative ? -(calendar.hours) : calendar.hours,
      'minutes': isNegative ? -(calendar.minutes) : calendar.minutes,
      'seconds': isNegative ? -(calendar.seconds) : calendar.seconds,
      'is_negative': isNegative,
    };

    final result = <String, dynamic>{
      'total_milliseconds': duration.inMilliseconds,
      'total_seconds': _number(duration.inMicroseconds / 1000000),
      'total_minutes': _number(duration.inMicroseconds / 60000000),
      'total_hours': _number(duration.inMicroseconds / 3600000000),
      'total_days': _number(duration.inMicroseconds / 86400000000),
      'total_weeks': _number(duration.inMicroseconds / 604800000000),
      'calendar': signedCalendar,
    };

    if (arguments['include_business_days'] == true) {
      final businessDays = _businessDays(earlier, later);
      result['business_days'] = isNegative ? -businessDays : businessDays;
    }

    return _result(call, {
      'operation': 'diff',
      'start': _describe(start, useUtc),
      'end': _describe(end, useUtc),
      'result': result,
    });
  }

  AIToolResult _add(
    AIToolCall call,
    Map<String, dynamic> arguments,
    bool useUtc,
  ) {
    final start = _readDate(arguments['start'], useUtc, 'start');
    final years = _readInt(arguments, 'years');
    final months = _readInt(arguments, 'months');
    final weeks = _readInt(arguments, 'weeks');
    final days = _readInt(arguments, 'days');
    final hours = _readInt(arguments, 'hours');
    final minutes = _readInt(arguments, 'minutes');
    final seconds = _readInt(arguments, 'seconds');

    if (years == 0 &&
        months == 0 &&
        weeks == 0 &&
        days == 0 &&
        hours == 0 &&
        minutes == 0 &&
        seconds == 0) {
      throw const FormatException(
        'At least one of years, months, weeks, days, hours, minutes, or '
        'seconds is required for add.',
      );
    }

    var target = _addMonths(start, years * 12 + months);
    target = _addDays(target, weeks * 7 + days);
    target = target.add(
      Duration(hours: hours, minutes: minutes, seconds: seconds),
    );
    _validateYear(target);

    return _result(call, {
      'operation': 'add',
      'start': _describe(start, useUtc),
      'result': _describe(target, useUtc),
    });
  }

  AIToolResult _info(
    AIToolCall call,
    Map<String, dynamic> arguments,
    bool useUtc,
  ) {
    final date = _readDate(
      arguments['date'] ?? arguments['start'],
      useUtc,
      'date',
    );
    final dateOnly = DateTime.utc(date.year, date.month, date.day);
    final dayOfYear =
        dateOnly.difference(DateTime.utc(date.year, 1, 1)).inDays + 1;
    final week = _isoWeek(dateOnly);

    return _result(call, {
      'operation': 'info',
      'date': _describe(date, useUtc),
      'result': {
        'weekday': _weekdays[date.weekday - 1],
        'weekday_number': date.weekday,
        'day_of_year': dayOfYear,
        'iso_week': week.week,
        'iso_week_year': week.year,
        'days_in_month': _daysInMonth(date.year, date.month),
        'is_leap_year': _isLeapYear(date.year),
        'utc_offset': _offset(date),
      },
    });
  }

  DateTime _readDate(
    Object? raw,
    bool useUtc,
    String field,
  ) {
    final text = raw?.toString().trim() ?? '';
    if (text.isEmpty) {
      final now = useUtc ? DateTime.now().toUtc() : DateTime.now();
      return now;
    }

    final lowered = text.toLowerCase();
    if (lowered == 'now') {
      return useUtc ? DateTime.now().toUtc() : DateTime.now();
    }
    if (lowered == 'today') {
      final now = useUtc ? DateTime.now().toUtc() : DateTime.now();
      return useUtc
          ? DateTime.utc(now.year, now.month, now.day)
          : DateTime(now.year, now.month, now.day);
    }

    var normalized = text.replaceAll('/', '-');
    if (normalized.contains(' ') && !normalized.contains('T')) {
      normalized = normalized.replaceFirst(' ', 'T');
    }

    final hasExplicitZone =
        RegExp(r'(Z|z|[+-]\d{2}:?\d{2})$').hasMatch(normalized);

    late DateTime parsed;
    try {
      parsed = DateTime.parse(normalized);
    } on FormatException {
      throw FormatException(
        'Invalid date "$text" for $field. Use ISO 8601 '
        '(2026-11-12 or 2026-11-12T13:45:00Z) or YYYY/MM/DD.',
      );
    }

    final DateTime instant;
    if (hasExplicitZone) {
      instant = useUtc ? parsed.toUtc() : parsed.toLocal();
    } else {
      instant = useUtc
          ? DateTime.utc(
              parsed.year,
              parsed.month,
              parsed.day,
              parsed.hour,
              parsed.minute,
              parsed.second,
              parsed.millisecond,
              parsed.microsecond,
            )
          : DateTime(
              parsed.year,
              parsed.month,
              parsed.day,
              parsed.hour,
              parsed.minute,
              parsed.second,
              parsed.millisecond,
              parsed.microsecond,
            );
    }

    _validateYear(instant);
    return instant;
  }

  static void _validateYear(DateTime date) {
    if (date.year < 1 || date.year > 9999) {
      throw FormatException(
        'Date year ${date.year} is outside the supported range 1-9999.',
      );
    }
  }

  static int _readInt(Map<String, dynamic> arguments, String key) {
    final raw = arguments[key];
    if (raw == null) return 0;
    if (raw is int) return raw;
    if (raw is num) {
      if (raw % 1 != 0) {
        throw FormatException('$key must be an integer.');
      }
      return raw.toInt();
    }
    final parsed = int.tryParse(raw.toString().trim());
    if (parsed == null) {
      throw FormatException('$key must be an integer.');
    }
    return parsed;
  }

  ({
    int years,
    int months,
    int days,
    int hours,
    int minutes,
    int seconds,
  }) _calendarDifference(DateTime earlier, DateTime later) {
    var months =
        (later.year - earlier.year) * 12 + (later.month - earlier.month);
    if (months < 0) months = 0;

    var candidate = _addMonths(earlier, months);
    if (candidate.isAfter(later)) {
      months--;
      candidate = _addMonths(earlier, months);
    }

    var days = DateTime.utc(later.year, later.month, later.day)
        .difference(DateTime.utc(
          candidate.year,
          candidate.month,
          candidate.day,
        ))
        .inDays;
    var afterDays = _addDays(candidate, days);
    while (afterDays.isAfter(later)) {
      days--;
      afterDays = _addDays(candidate, days);
    }

    final remainder = later.difference(afterDays);
    final hours = remainder.inHours;
    final minutes = remainder.inMinutes % 60;
    final seconds = remainder.inSeconds % 60;

    return (
      years: months ~/ 12,
      months: months % 12,
      days: days,
      hours: hours,
      minutes: minutes,
      seconds: seconds,
    );
  }

  static int _businessDays(DateTime earlier, DateTime later) {
    final start = DateTime.utc(earlier.year, earlier.month, earlier.day);
    final end = DateTime.utc(later.year, later.month, later.day);
    if (!end.isAfter(start)) return 0;

    final totalDays = end.difference(start).inDays;
    var count = (totalDays ~/ 7) * 5;
    final remainder = totalDays % 7;
    for (var index = 0; index < remainder; index++) {
      final weekday = (start.weekday - 1 + index) % 7 + 1;
      if (weekday <= 5) count++;
    }
    return count;
  }

  static DateTime _addMonths(DateTime date, int months) {
    final totalMonths = date.year * 12 + (date.month - 1) + months;
    final year = totalMonths ~/ 12;
    final month = totalMonths % 12 + 1;
    final day = math.min(date.day, _daysInMonth(year, month));
    return _rebuild(date, year: year, month: month, day: day);
  }

  static DateTime _addDays(DateTime date, int days) {
    return _rebuild(date, day: date.day + days);
  }

  static DateTime _rebuild(
    DateTime date, {
    int? year,
    int? month,
    int? day,
    int? hour,
    int? minute,
    int? second,
    int? millisecond,
    int? microsecond,
  }) {
    if (date.isUtc) {
      return DateTime.utc(
        year ?? date.year,
        month ?? date.month,
        day ?? date.day,
        hour ?? date.hour,
        minute ?? date.minute,
        second ?? date.second,
        millisecond ?? date.millisecond,
        microsecond ?? date.microsecond,
      );
    }
    return DateTime(
      year ?? date.year,
      month ?? date.month,
      day ?? date.day,
      hour ?? date.hour,
      minute ?? date.minute,
      second ?? date.second,
      millisecond ?? date.millisecond,
      microsecond ?? date.microsecond,
    );
  }

  static ({int week, int year}) _isoWeek(DateTime dateOnly) {
    final thursday = dateOnly.add(Duration(days: 4 - dateOnly.weekday));
    final isoYear = thursday.year;
    final januaryFourth = DateTime.utc(isoYear, 1, 4);
    final firstThursday =
        januaryFourth.add(Duration(days: 4 - januaryFourth.weekday));
    final week = thursday.difference(firstThursday).inDays ~/ 7 + 1;
    return (week: week, year: isoYear);
  }

  static int _daysInMonth(int year, int month) {
    return DateTime.utc(year, month + 1, 0).day;
  }

  static bool _isLeapYear(int year) {
    return year % 4 == 0 && (year % 100 != 0 || year % 400 == 0);
  }

  static Map<String, dynamic> _describe(DateTime date, bool useUtc) {
    return {
      'iso': _isoWithOffset(date),
      'utc': date.toUtc().toIso8601String(),
      'formatted': TimeUtils.format(time: date),
      'weekday': _weekdays[date.weekday - 1],
      'timezone': useUtc ? 'UTC' : 'local',
      'utc_offset': _offset(date),
    };
  }

  static String _isoWithOffset(DateTime date) {
    final base = '${date.year.toString().padLeft(4, '0')}-'
        '${date.month.toString().padLeft(2, '0')}-'
        '${date.day.toString().padLeft(2, '0')}'
        'T${date.hour.toString().padLeft(2, '0')}:'
        '${date.minute.toString().padLeft(2, '0')}:'
        '${date.second.toString().padLeft(2, '0')}';
    final microseconds = date.millisecond * 1000 + date.microsecond;
    final fraction = microseconds == 0
        ? ''
        : '.${microseconds.toString().padLeft(6, '0').replaceFirst(RegExp(r'0+$'), '')}';
    if (date.isUtc) return '$base${fraction}Z';
    return '$base$fraction${_offset(date)}';
  }

  static String _offset(DateTime date) {
    final offset = date.timeZoneOffset;
    final sign = offset.isNegative ? '-' : '+';
    final hours = offset.inHours.abs().toString().padLeft(2, '0');
    final minutes =
        (offset.inMinutes.abs() % 60).toString().padLeft(2, '0');
    return '$sign$hours:$minutes';
  }

  static num _number(double value) {
    if (value.isFinite &&
        value == value.roundToDouble() &&
        value.abs() < 9007199254740991) {
      return value.toInt();
    }
    return value;
  }

  static AIToolResult _result(
    AIToolCall call,
    Map<String, dynamic> payload,
  ) {
    return AIToolResult(
      toolCallId: call.id,
      name: call.name,
      content: jsonEncode(payload),
    );
  }

  static AIToolResult _error(AIToolCall call, String message) {
    return AIToolResult(
      toolCallId: call.id,
      name: call.name,
      content: jsonEncode({'error': message}),
      isError: true,
    );
  }
}
