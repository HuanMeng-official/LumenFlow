import 'dart:convert';

import '../contracts/ai_tool.dart';
import '../contracts/ai_tool_executor.dart';
import 'lunar_calendar.dart';

/// Chinese lunisolar calendar conversion tool.
class BuiltInLunarCalendarTool implements AIToolExecutor {
  BuiltInLunarCalendarTool({this.enabled = true});

  static const String toolName = 'builtin__lunar_calendar';

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
        'Convert between Gregorian (solar) dates and the Chinese lunisolar '
        'calendar. Operations: "to_lunar" converts a solar date to the '
        'lunar year/month/day, leap-month flag, Chinese month and day '
        'names, ganzhi year, and zodiac; "to_solar" converts a lunar date '
        '(lunar_year, lunar_month, lunar_day, is_leap_month) to a solar '
        'date; "info" lists the leap month and month lengths for a lunar '
        'year. Supported lunar years: 1900-2099. Zodiac and ganzhi follow '
        'the lunar year, whose boundary is the lunar new year.',
    inputSchema: {
      'type': 'object',
      'properties': {
        'operation': {
          'type': 'string',
          'enum': ['to_lunar', 'to_solar', 'info'],
          'description':
              'to_lunar: solar to lunar; to_solar: lunar to solar; info: '
              'leap month and month lengths.',
        },
        'date': {
          'type': 'string',
          'description':
              'Solar date for to_lunar, for example "2024-02-10". Only the '
              'date part is used; time and timezone are ignored.',
        },
        'lunar_year': {
          'type': 'integer',
          'description': 'Lunar year for to_solar or info, 1900-2099.',
        },
        'lunar_month': {
          'type': 'integer',
          'description': 'Lunar month for to_solar, 1-12.',
        },
        'lunar_day': {
          'type': 'integer',
          'description': 'Lunar day for to_solar, starting at 1.',
        },
        'is_leap_month': {
          'type': 'boolean',
          'description':
              'Whether lunar_month refers to the leap month. Defaults to '
              'false.',
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

    try {
      switch (operation) {
        case 'to_lunar':
          return _toLunar(call, arguments);
        case 'to_solar':
          return _toSolar(call, arguments);
        case 'info':
          return _info(call, arguments);
        default:
          return _error(
            call,
            'Unknown operation "$operation". Use to_lunar, to_solar, or '
            'info.',
          );
      }
    } on FormatException catch (error) {
      return _error(call, error.message);
    } catch (error) {
      return _error(call, error.toString());
    }
  }

  AIToolResult _toLunar(
    AIToolCall call,
    Map<String, dynamic> arguments,
  ) {
    final solarDate = _parseSolarDate(arguments['date']);
    final lunar = LunarCalendar.solarToLunar(solarDate);

    return _result(call, {
      'operation': 'to_lunar',
      'solar': _solarJson(solarDate),
      'lunar': _lunarJson(lunar),
    });
  }

  AIToolResult _toSolar(
    AIToolCall call,
    Map<String, dynamic> arguments,
  ) {
    final year = _requireInt(arguments, 'lunar_year');
    final month = _requireInt(arguments, 'lunar_month');
    final day = _requireInt(arguments, 'lunar_day');
    final isLeapMonth = arguments['is_leap_month'] == true;
    final solar = LunarCalendar.lunarToSolar(
      year: year,
      month: month,
      day: day,
      isLeapMonth: isLeapMonth,
    );
    final lunar = LunarDateInfo(
      year: year,
      month: month,
      day: day,
      isLeapMonth: isLeapMonth,
    );

    return _result(call, {
      'operation': 'to_solar',
      'lunar': _lunarJson(lunar),
      'solar': _solarJson(solar),
    });
  }

  AIToolResult _info(
    AIToolCall call,
    Map<String, dynamic> arguments,
  ) {
    final year = _requireInt(arguments, 'lunar_year');
    final info = LunarCalendar.lunarYearInfo(year);

    return _result(call, {
      'operation': 'info',
      'lunar_year': info.year,
      'leap_month': info.leapMonth,
      'year_in_ganzhi': info.yearInGanzhi,
      'zodiac': info.zodiac,
      'months': [
        for (final month in info.months)
          {
            'month': month.month,
            'days': month.days,
            'is_leap_month': month.isLeapMonth,
            'month_name': month.monthName,
          },
      ],
    });
  }

  static DateTime _parseSolarDate(Object? raw) {
    final text = raw?.toString().trim() ?? '';
    if (text.isEmpty) {
      throw const FormatException('date is required');
    }

    final normalized = text.replaceAll('/', '-');
    final datePart = normalized.split('T').first.split(' ').first;
    final parts = datePart.split('-');
    if (parts.length != 3) {
      throw FormatException('Invalid date "$text". Use YYYY-MM-DD.');
    }

    final year = int.tryParse(parts[0]);
    final month = int.tryParse(parts[1]);
    final day = int.tryParse(parts[2]);
    if (year == null || month == null || day == null) {
      throw FormatException('Invalid date "$text". Use YYYY-MM-DD.');
    }

    final date = DateTime.utc(year, month, day);
    if (date.year != year || date.month != month || date.day != day) {
      throw FormatException('Invalid date "$text". Use YYYY-MM-DD.');
    }
    return date;
  }

  static int _requireInt(Map<String, dynamic> arguments, String key) {
    final raw = arguments[key];
    if (raw == null) {
      throw FormatException('$key is required');
    }
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

  static Map<String, dynamic> _solarJson(DateTime date) {
    return {
      'iso': _formatDate(date),
      'year': date.year,
      'month': date.month,
      'day': date.day,
      'weekday': _weekdays[date.weekday - 1],
    };
  }

  static Map<String, dynamic> _lunarJson(LunarDateInfo lunar) {
    return {
      'year': lunar.year,
      'month': lunar.month,
      'day': lunar.day,
      'is_leap_month': lunar.isLeapMonth,
      'month_name': lunar.monthName,
      'day_name': lunar.dayName,
      'year_in_ganzhi': lunar.yearInGanzhi,
      'zodiac': lunar.zodiac,
    };
  }

  static String _formatDate(DateTime date) {
    return '${date.year.toString().padLeft(4, '0')}-'
        '${date.month.toString().padLeft(2, '0')}-'
        '${date.day.toString().padLeft(2, '0')}';
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
