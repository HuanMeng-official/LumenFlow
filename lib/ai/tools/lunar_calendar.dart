class LunarCalendar {
  LunarCalendar._();

  static const int minYear = 1900;
  static const int maxYear = 2099;

  static final DateTime _baseDate = DateTime.utc(1900, 1, 31);

  static const List<int> _yearInfos = [
    0x04bd8, // 1900
    0x04ae0, 0x0a570, 0x054d5, 0x0d260, 0x0d950, // 1905
    0x16554, 0x056a0, 0x09ad0, 0x055d2, 0x04ae0, // 1910
    0x0a5b6, 0x0a4d0, 0x0d250, 0x1d255, 0x0b540, // 1915
    0x0d6a0, 0x0ada2, 0x095b0, 0x14977, 0x04970, // 1920
    0x0a4b0, 0x0b4b5, 0x06a50, 0x06d40, 0x1ab54, // 1925
    0x02b60, 0x09570, 0x052f2, 0x04970, 0x06566, // 1930
    0x0d4a0, 0x0ea50, 0x06e95, 0x05ad0, 0x02b60, // 1935
    0x186e3, 0x092e0, 0x1c8d7, 0x0c950, 0x0d4a0, // 1940
    0x1d8a6, 0x0b550, 0x056a0, 0x1a5b4, 0x025d0, // 1945
    0x092d0, 0x0d2b2, 0x0a950, 0x0b557, 0x06ca0, // 1950
    0x0b550, 0x15355, 0x04da0, 0x0a5d0, 0x14573, // 1955
    0x052b0, 0x0a9a8, 0x0e950, 0x06aa0, 0x0aea6, // 1960
    0x0ab50, 0x04b60, 0x0aae4, 0x0a570, 0x05260, // 1965
    0x0f263, 0x0d950, 0x05b57, 0x056a0, 0x096d0, // 1970
    0x04dd5, 0x04ad0, 0x0a4d0, 0x0d4d4, 0x0d250, // 1975
    0x0d558, 0x0b540, 0x0b5a0, 0x195a6, 0x095b0, // 1980
    0x049b0, 0x0a974, 0x0a4b0, 0x0b27a, 0x06a50, // 1985
    0x06d40, 0x0af46, 0x0ab60, 0x09570, 0x04af5, // 1990
    0x04970, 0x064b0, 0x074a3, 0x0ea50, 0x06b58, // 1995
    0x05ac0, 0x0ab60, 0x096d5, 0x092e0, 0x0c960, // 2000
    0x0d954, 0x0d4a0, 0x0da50, 0x07552, 0x056a0, // 2005
    0x0abb7, 0x025d0, 0x092d0, 0x0cab5, 0x0a950, // 2010
    0x0b4a0, 0x0baa4, 0x0ad50, 0x055d9, 0x04ba0, // 2015
    0x0a5b0, 0x15176, 0x052b0, 0x0a930, 0x07954, // 2020
    0x06aa0, 0x0ad50, 0x05b52, 0x04b60, 0x0a6e6, // 2025
    0x0a4e0, 0x0d260, 0x0ea65, 0x0d530, 0x05aa0, // 2030
    0x076a3, 0x096d0, 0x04afb, 0x04ad0, 0x0a4d0, // 2035
    0x1d0b6, 0x0d250, 0x0d520, 0x0dd45, 0x0b5a0, // 2040
    0x056d0, 0x055b2, 0x049b0, 0x0a577, 0x0a4b0, // 2045
    0x0aa50, 0x1b255, 0x06d20, 0x0ada0, 0x14b63, // 2050
    0x09370, 0x049f8, 0x04970, 0x064b0, 0x168a6, // 2055
    0x0ea50, 0x06aa0, 0x1a6c4, 0x0aae0, 0x092e0, // 2060
    0x0d2e3, 0x0c960, 0x0d557, 0x0d4a0, 0x0da50, // 2065
    0x05d55, 0x056a0, 0x0a6d0, 0x055d4, 0x052d0, // 2070
    0x0a9b8, 0x0a950, 0x0b4a0, 0x0b6a6, 0x0ad50, // 2075
    0x055a0, 0x0aba4, 0x0a5b0, 0x052b0, 0x0b273, // 2080
    0x06930, 0x07337, 0x06aa0, 0x0ad50, 0x14b55, // 2085
    0x04b60, 0x0a570, 0x054e4, 0x0d160, 0x0e968, // 2090
    0x0d520, 0x0daa0, 0x16aa6, 0x056d0, 0x04ae0, // 2095
    0x0a9d4, 0x0a2d0, 0x0d150, 0x0f252, // 2099
  ];

  static final List<int> _yearDays = [
    for (final info in _yearInfos) _yearLength(info),
  ];

  static const List<String> _monthNames = [
    '正月',
    '二月',
    '三月',
    '四月',
    '五月',
    '六月',
    '七月',
    '八月',
    '九月',
    '十月',
    '冬月',
    '腊月',
  ];

  static const List<String> _dayNames = [
    '初一',
    '初二',
    '初三',
    '初四',
    '初五',
    '初六',
    '初七',
    '初八',
    '初九',
    '初十',
    '十一',
    '十二',
    '十三',
    '十四',
    '十五',
    '十六',
    '十七',
    '十八',
    '十九',
    '二十',
    '廿一',
    '廿二',
    '廿三',
    '廿四',
    '廿五',
    '廿六',
    '廿七',
    '廿八',
    '廿九',
    '三十',
  ];

  static const List<String> _stems = [
    '甲',
    '乙',
    '丙',
    '丁',
    '戊',
    '己',
    '庚',
    '辛',
    '壬',
    '癸',
  ];

  static const List<String> _branches = [
    '子',
    '丑',
    '寅',
    '卯',
    '辰',
    '巳',
    '午',
    '未',
    '申',
    '酉',
    '戌',
    '亥',
  ];

  static const List<String> _zodiacs = [
    '鼠',
    '牛',
    '虎',
    '兔',
    '龙',
    '蛇',
    '马',
    '羊',
    '猴',
    '鸡',
    '狗',
    '猪',
  ];

  static LunarDateInfo solarToLunar(DateTime date) {
    final solar = DateTime.utc(date.year, date.month, date.day);
    var offset = solar.difference(_baseDate).inDays;
    if (offset < 0) {
      throw const FormatException(
        'Solar date is before the supported range (1900-01-31).',
      );
    }

    for (var index = 0; index < _yearInfos.length; index++) {
      final days = _yearDays[index];
      if (offset < days) {
        final year = minYear + index;
        final month = _monthFromOffset(_yearInfos[index], offset);
        return LunarDateInfo(
          year: year,
          month: month.month,
          day: month.day,
          isLeapMonth: month.isLeapMonth,
        );
      }
      offset -= days;
    }

    throw const FormatException(
      'Solar date is after the supported range (lunar year $maxYear).',
    );
  }

  static DateTime lunarToSolar({
    required int year,
    required int month,
    required int day,
    bool isLeapMonth = false,
  }) {
    final yearIndex = _validateYear(year);
    if (month < 1 || month > 12) {
      throw const FormatException('Lunar month must be between 1 and 12.');
    }
    if (day < 1) {
      throw const FormatException('Lunar day must be at least 1.');
    }

    final info = _yearInfos[yearIndex];
    final leapMonth = _leapMonth(info);
    if (isLeapMonth) {
      if (leapMonth != month) {
        throw FormatException('Lunar year $year has no leap month $month.');
      }
      final days = _leapMonthLength(info);
      if (day > days) {
        throw FormatException(
          'Lunar leap month $month in $year has only $days days.',
        );
      }
    } else {
      final days = _monthLength(info, month);
      if (day > days) {
        throw FormatException(
          'Lunar month $month in $year has only $days days.',
        );
      }
    }

    var offset = 0;
    for (var index = 0; index < yearIndex; index++) {
      offset += _yearDays[index];
    }

    for (var current = 1; current <= 12; current++) {
      if (current == month) {
        if (isLeapMonth) {
          offset += _monthLength(info, current);
        }
        offset += day - 1;
        return _baseDate.add(Duration(days: offset));
      }
      offset += _monthLength(info, current);
      if (leapMonth == current) {
        offset += _leapMonthLength(info);
      }
    }

    throw FormatException('Lunar month $month in $year is invalid.');
  }

  static LunarYearInfo lunarYearInfo(int year) {
    final yearIndex = _validateYear(year);
    final info = _yearInfos[yearIndex];
    final leapMonth = _leapMonth(info);
    final months = <LunarMonthInfo>[];

    for (var month = 1; month <= 12; month++) {
      months.add(
        LunarMonthInfo(
          month: month,
          days: _monthLength(info, month),
          isLeapMonth: false,
        ),
      );
      if (leapMonth == month) {
        months.add(
          LunarMonthInfo(
            month: month,
            days: _leapMonthLength(info),
            isLeapMonth: true,
          ),
        );
      }
    }

    return LunarYearInfo(
      year: year,
      leapMonth: leapMonth,
      months: months,
    );
  }

  static int _validateYear(int year) {
    if (year < minYear || year > maxYear) {
      throw FormatException(
        'Lunar year must be between $minYear and $maxYear.',
      );
    }
    return year - minYear;
  }

  static ({int month, int day, bool isLeapMonth}) _monthFromOffset(
    int info,
    int offset,
  ) {
    final leapMonth = _leapMonth(info);
    for (var month = 1; month <= 12; month++) {
      final days = _monthLength(info, month);
      if (offset < days) {
        return (month: month, day: offset + 1, isLeapMonth: false);
      }
      offset -= days;

      if (leapMonth == month) {
        final leapDays = _leapMonthLength(info);
        if (offset < leapDays) {
          return (month: month, day: offset + 1, isLeapMonth: true);
        }
        offset -= leapDays;
      }
    }
    throw const FormatException('Lunar offset is invalid.');
  }

  static int _yearLength(int info) {
    var days = 0;
    for (var month = 1; month <= 12; month++) {
      days += _monthLength(info, month);
    }
    if (_leapMonth(info) != 0) {
      days += _leapMonthLength(info);
    }
    return days;
  }

  static int _leapMonth(int info) => info & 0x0f;

  static int _monthLength(int info, int month) {
    return ((info >> (16 - month)) & 1) == 1 ? 30 : 29;
  }

  static int _leapMonthLength(int info) {
    return ((info >> 16) & 1) == 1 ? 30 : 29;
  }

  static String _ganzhi(int year) {
    final offset = (year - 4) % 60;
    return '${_stems[offset % 10]}${_branches[offset % 12]}';
  }

  static String _zodiac(int year) => _zodiacs[(year - 4) % 12];

  static String _monthName(int month, bool isLeapMonth) {
    final name = _monthNames[month - 1];
    return isLeapMonth ? '闰$name' : name;
  }
}

class LunarDateInfo {
  const LunarDateInfo({
    required this.year,
    required this.month,
    required this.day,
    required this.isLeapMonth,
  });

  final int year;
  final int month;
  final int day;
  final bool isLeapMonth;

  String get monthName => LunarCalendar._monthName(month, isLeapMonth);
  String get dayName => LunarCalendar._dayNames[day - 1];
  String get yearInGanzhi => LunarCalendar._ganzhi(year);
  String get zodiac => LunarCalendar._zodiac(year);
}

class LunarYearInfo {
  const LunarYearInfo({
    required this.year,
    required this.leapMonth,
    required this.months,
  });

  final int year;
  final int leapMonth;
  final List<LunarMonthInfo> months;

  String get yearInGanzhi => LunarCalendar._ganzhi(year);
  String get zodiac => LunarCalendar._zodiac(year);
}

class LunarMonthInfo {
  const LunarMonthInfo({
    required this.month,
    required this.days,
    required this.isLeapMonth,
  });

  final int month;
  final int days;
  final bool isLeapMonth;

  String get monthName => LunarCalendar._monthName(month, isLeapMonth);
}
