import 'dart:convert';

import '../contracts/ai_tool.dart';
import '../contracts/ai_tool_executor.dart';

/// Converts a numeric value between common measurement units.
class BuiltInUnitConvertTool implements AIToolExecutor {
  BuiltInUnitConvertTool({this.enabled = true});

  static const String toolName = 'builtin__unit_convert';

  static const List<String> _categories = [
    'length',
    'mass',
    'temperature',
    'area',
    'volume',
    'speed',
    'data',
    'time',
  ];

  static const List<_Unit> _units = [
    // Length (base: meter)
    _Unit('meter', 'length', 1, ['m', 'meter', 'meters', 'metre', 'metres']),
    _Unit('kilometer', 'length', 1000, [
      'km',
      'kilometer',
      'kilometers',
      'kilometre',
      'kilometres',
    ]),
    _Unit('centimeter', 'length', 0.01, [
      'cm',
      'centimeter',
      'centimeters',
      'centimetre',
      'centimetres',
    ]),
    _Unit('millimeter', 'length', 0.001, [
      'mm',
      'millimeter',
      'millimeters',
      'millimetre',
      'millimetres',
    ]),
    _Unit('micrometer', 'length', 1e-6, [
      'um',
      'µm',
      'micrometer',
      'micrometers',
      'micrometre',
      'micrometres',
    ]),
    _Unit('nanometer', 'length', 1e-9, [
      'nm',
      'nanometer',
      'nanometers',
      'nanometre',
      'nanometres',
    ]),
    _Unit('inch', 'length', 0.0254, ['in', 'inch', 'inches']),
    _Unit('foot', 'length', 0.3048, ['ft', 'foot', 'feet']),
    _Unit('yard', 'length', 0.9144, ['yd', 'yard', 'yards']),
    _Unit('mile', 'length', 1609.344, ['mi', 'mile', 'miles']),
    _Unit('nautical_mile', 'length', 1852, [
      'nmi',
      'nautical_mile',
      'nautical_miles',
      'nautical mile',
      'nautical miles',
    ]),

    // Mass (base: kilogram)
    _Unit('kilogram', 'mass', 1, ['kg', 'kilogram', 'kilograms']),
    _Unit('gram', 'mass', 0.001, ['g', 'gram', 'grams']),
    _Unit('milligram', 'mass', 1e-6, [
      'mg',
      'milligram',
      'milligrams',
    ]),
    _Unit('microgram', 'mass', 1e-9, [
      'ug',
      'µg',
      'microgram',
      'micrograms',
    ]),
    _Unit('tonne', 'mass', 1000, ['t', 'tonne', 'tonnes', 'ton', 'tons']),
    _Unit('pound', 'mass', 0.45359237, ['lb', 'lbs', 'pound', 'pounds']),
    _Unit('ounce', 'mass', 0.028349523125, ['oz', 'ounce', 'ounces']),
    _Unit('stone', 'mass', 6.35029318, ['st', 'stone', 'stones']),

    // Temperature (converted with affine formulas)
    _Unit('celsius', 'temperature', 1, [
      'c',
      '°c',
      'celsius',
      'centigrade',
      'degree_celsius',
      'degrees_celsius',
    ]),
    _Unit('fahrenheit', 'temperature', 1, [
      'f',
      '°f',
      'fahrenheit',
    ]),
    _Unit('kelvin', 'temperature', 1, ['k', 'kelvin']),
    _Unit('rankine', 'temperature', 1, ['r', '°r', 'rankine']),

    // Area (base: square meter)
    _Unit('square_meter', 'area', 1, [
      'm2',
      'm²',
      'sqm',
      'square_meter',
      'square_meters',
      'square_metre',
      'square_metres',
    ]),
    _Unit('square_kilometer', 'area', 1e6, [
      'km2',
      'km²',
      'sqkm',
      'square_kilometer',
      'square_kilometers',
    ]),
    _Unit('square_centimeter', 'area', 1e-4, [
      'cm2',
      'cm²',
      'square_centimeter',
      'square_centimeters',
    ]),
    _Unit('square_millimeter', 'area', 1e-6, [
      'mm2',
      'mm²',
      'square_millimeter',
      'square_millimeters',
    ]),
    _Unit('hectare', 'area', 10000, ['ha', 'hectare', 'hectares']),
    _Unit('acre', 'area', 4046.8564224, ['acre', 'acres']),
    _Unit('square_foot', 'area', 0.09290304, [
      'ft2',
      'ft²',
      'sqft',
      'square_foot',
      'square_feet',
    ]),
    _Unit('square_inch', 'area', 0.00064516, [
      'in2',
      'in²',
      'sqin',
      'square_inch',
      'square_inches',
    ]),
    _Unit('square_mile', 'area', 2589988.110336, [
      'mi2',
      'mi²',
      'sqmi',
      'square_mile',
      'square_miles',
    ]),

    // Volume (base: cubic meter)
    _Unit('cubic_meter', 'volume', 1, [
      'm3',
      'm³',
      'cubic_meter',
      'cubic_meters',
      'cubic_metre',
      'cubic_metres',
    ]),
    _Unit('liter', 'volume', 0.001, [
      'l',
      'liter',
      'liters',
      'litre',
      'litres',
    ]),
    _Unit('milliliter', 'volume', 1e-6, [
      'ml',
      'milliliter',
      'milliliters',
      'millilitre',
      'millilitres',
    ]),
    _Unit('cubic_centimeter', 'volume', 1e-6, [
      'cm3',
      'cm³',
      'cc',
      'cubic_centimeter',
      'cubic_centimeters',
    ]),
    _Unit('gallon_us', 'volume', 0.003785411784, [
      'gal',
      'gallon',
      'gallons',
      'gallon_us',
      'us_gallon',
      'us_gallons',
    ]),
    _Unit('gallon_imperial', 'volume', 0.00454609, [
      'gal_imp',
      'imperial_gallon',
      'imperial_gallons',
      'uk_gallon',
      'uk_gallons',
    ]),
    _Unit('quart_us', 'volume', 0.000946352946, [
      'qt',
      'quart',
      'quarts',
      'quart_us',
      'us_quart',
    ]),
    _Unit('pint_us', 'volume', 0.000473176473, [
      'pt',
      'pint',
      'pints',
      'pint_us',
      'us_pint',
    ]),
    _Unit('cup_us', 'volume', 0.0002365882365, [
      'cup',
      'cups',
      'cup_us',
      'us_cup',
    ]),
    _Unit('fluid_ounce_us', 'volume', 2.95735295625e-5, [
      'fl_oz',
      'floz',
      'fluid_ounce',
      'fluid_ounces',
      'fluid_ounce_us',
      'us_fluid_ounce',
    ]),
    _Unit('tablespoon_us', 'volume', 1.478676478125e-5, [
      'tbsp',
      'tablespoon',
      'tablespoons',
      'tablespoon_us',
    ]),
    _Unit('teaspoon_us', 'volume', 4.92892159375e-6, [
      'tsp',
      'teaspoon',
      'teaspoons',
      'teaspoon_us',
    ]),

    // Speed (base: meter per second)
    _Unit('meter_per_second', 'speed', 1, [
      'm/s',
      'mps',
      'meter_per_second',
      'meters_per_second',
      'metre_per_second',
      'metres_per_second',
    ]),
    _Unit('kilometer_per_hour', 'speed', 0.2777777777777778, [
      'km/h',
      'kmh',
      'kph',
      'kilometer_per_hour',
      'kilometers_per_hour',
      'kilometre_per_hour',
      'kilometres_per_hour',
    ]),
    _Unit('mile_per_hour', 'speed', 0.44704, [
      'mph',
      'mi/h',
      'mile_per_hour',
      'miles_per_hour',
    ]),
    _Unit('knot', 'speed', 0.5144444444444445, [
      'kn',
      'kt',
      'knot',
      'knots',
    ]),
    _Unit('foot_per_second', 'speed', 0.3048, [
      'ft/s',
      'fps',
      'foot_per_second',
      'feet_per_second',
    ]),

    // Data (base: byte)
    _Unit('bit', 'data', 0.125, ['bit', 'bits', 'b']),
    _Unit('byte', 'data', 1, ['byte', 'bytes', 'B']),
    _Unit('kilobyte', 'data', 1000, ['kb', 'kilobyte', 'kilobytes']),
    _Unit('megabyte', 'data', 1e6, ['mb', 'megabyte', 'megabytes']),
    _Unit('gigabyte', 'data', 1e9, ['gb', 'gigabyte', 'gigabytes']),
    _Unit('terabyte', 'data', 1e12, ['tb', 'terabyte', 'terabytes']),
    _Unit('kibibyte', 'data', 1024, ['kib', 'kibibyte', 'kibibytes']),
    _Unit('mebibyte', 'data', 1048576, [
      'mib',
      'mebibyte',
      'mebibytes',
    ]),
    _Unit('gibibyte', 'data', 1073741824, [
      'gib',
      'gibibyte',
      'gibibytes',
    ]),
    _Unit('tebibyte', 'data', 1099511627776, [
      'tib',
      'tebibyte',
      'tebibytes',
    ]),

    // Time (base: second)
    _Unit('nanosecond', 'time', 1e-9, [
      'ns',
      'nanosecond',
      'nanoseconds',
    ]),
    _Unit('microsecond', 'time', 1e-6, [
      'us',
      'µs',
      'microsecond',
      'microseconds',
    ]),
    _Unit('millisecond', 'time', 0.001, [
      'ms',
      'millisecond',
      'milliseconds',
    ]),
    _Unit('second', 'time', 1, [
      's',
      'sec',
      'secs',
      'second',
      'seconds',
    ]),
    _Unit('minute', 'time', 60, [
      'min',
      'mins',
      'minute',
      'minutes',
    ]),
    _Unit('hour', 'time', 3600, ['h', 'hr', 'hrs', 'hour', 'hours']),
    _Unit('day', 'time', 86400, ['d', 'day', 'days']),
    _Unit('week', 'time', 604800, ['w', 'wk', 'week', 'weeks']),
  ];

  static final Map<String, List<_Unit>> _exactIndex = _buildIndex(
    lowercaseOnly: false,
  );
  static final Map<String, List<_Unit>> _lowerIndex = _buildIndex(
    lowercaseOnly: true,
  );

  static Map<String, List<_Unit>> _buildIndex({required bool lowercaseOnly}) {
    final index = <String, List<_Unit>>{};
    for (final unit in _units) {
      final aliases = {unit.id, ...unit.aliases};
      for (final alias in aliases) {
        if (lowercaseOnly && alias != alias.toLowerCase()) continue;
        index.putIfAbsent(alias, () => <_Unit>[]).add(unit);
      }
    }
    return index;
  }

  static const AIToolDefinition definition = AIToolDefinition(
    name: toolName,
    description:
        'Convert a numeric value between units. Categories and canonical '
        'units: length (meter, kilometer, centimeter, millimeter, '
        'micrometer, nanometer, inch, foot, yard, mile, nautical_mile); '
        'mass (kilogram, gram, milligram, microgram, tonne, pound, ounce, '
        'stone); temperature (celsius, fahrenheit, kelvin, rankine); area '
        '(square_meter, square_kilometer, square_centimeter, '
        'square_millimeter, hectare, acre, square_foot, square_inch, '
        'square_mile); volume (cubic_meter, liter, milliliter, '
        'cubic_centimeter, gallon_us, gallon_imperial, quart_us, pint_us, '
        'cup_us, fluid_ounce_us, tablespoon_us, teaspoon_us); speed '
        '(meter_per_second, kilometer_per_hour, mile_per_hour, knot, '
        'foot_per_second); data (bit, byte, kilobyte, megabyte, gigabyte, '
        'terabyte, kibibyte, mebibyte, gibibyte, tebibyte); time '
        '(nanosecond, microsecond, millisecond, second, minute, hour, day, '
        'week). Common symbols and aliases such as m, kg, °C, ft, mph, KB, '
        'and KiB are accepted. In data, kilobyte is 1000 bytes and kibibyte '
        'is 1024 bytes. Provide category when a symbol is ambiguous.',
    inputSchema: {
      'type': 'object',
      'properties': {
        'value': {
          'type': 'number',
          'description': 'Numeric value to convert.',
        },
        'from': {
          'type': 'string',
          'description': 'Source unit id or symbol, for example "celsius".',
        },
        'to': {
          'type': 'string',
          'description':
              'Target unit id or symbol, for example "fahrenheit".',
        },
        'category': {
          'type': 'string',
          'enum': _categories,
          'description':
              'Optional category. Use it when a symbol is ambiguous or '
              'when the units are not in the same category.',
        },
        'precision': {
          'type': 'integer',
          'description':
              'Significant digits for the formatted result, from 1 to 15. '
              'Defaults to 6.',
        },
      },
      'required': ['value', 'from', 'to'],
    },
  );

  final bool enabled;

  @override
  List<AIToolDefinition> get tools {
    return enabled ? const [definition] : const [];
  }

  @override
  Future<AIToolResult> execute(AIToolCall call) async {
    try {
      final value = _readValue(call.arguments['value']);
      final fromRaw = call.arguments['from']?.toString().trim() ?? '';
      final toRaw = call.arguments['to']?.toString().trim() ?? '';
      if (fromRaw.isEmpty) {
        throw const FormatException('from is required');
      }
      if (toRaw.isEmpty) {
        throw const FormatException('to is required');
      }

      final requestedCategory =
          call.arguments['category']?.toString().trim().toLowerCase();
      final resolved = _resolve(fromRaw, toRaw, requestedCategory);
      final precision = _readPrecision(call.arguments['precision']);
      final converted = _convert(
        resolved.from,
        resolved.to,
        value,
      );
      if (!converted.isFinite) {
        throw const FormatException('The converted value is not finite.');
      }

      return AIToolResult(
        toolCallId: call.id,
        name: call.name,
        content: jsonEncode({
          'value': value,
          'from': resolved.from.id,
          'to': resolved.to.id,
          'category': resolved.category,
          'result': _normalize(converted),
          'formatted': _format(converted, precision),
        }),
      );
    } on FormatException catch (error) {
      return _error(call, error.message);
    } catch (error) {
      return _error(call, error.toString());
    }
  }

  static double _readValue(Object? raw) {
    if (raw == null) {
      throw const FormatException('value is required');
    }
    if (raw is num) {
      final value = raw.toDouble();
      if (!value.isFinite) {
        throw const FormatException('value must be a finite number');
      }
      return value;
    }
    final parsed = double.tryParse(raw.toString().trim());
    if (parsed == null || !parsed.isFinite) {
      throw const FormatException('value must be a finite number');
    }
    return parsed;
  }

  static int _readPrecision(Object? raw) {
    if (raw == null) return 6;
    final precision = raw is num
        ? raw.toInt()
        : int.tryParse(raw.toString().trim());
    if (precision == null || precision < 1 || precision > 15) {
      throw const FormatException('precision must be between 1 and 15');
    }
    return precision;
  }

  static ({_Unit from, _Unit to, String category}) _resolve(
    String fromRaw,
    String toRaw,
    String? requestedCategory,
  ) {
    if (requestedCategory != null &&
        !_categories.contains(requestedCategory)) {
      throw FormatException(
        'Unknown category "$requestedCategory". Valid categories: '
        '${_categories.join(', ')}.',
      );
    }

    var fromCandidates = _lookup(fromRaw);
    var toCandidates = _lookup(toRaw);
    if (fromCandidates.isEmpty) {
      throw FormatException(
        'Unknown unit "$fromRaw". ${_unitHelp(requestedCategory)}',
      );
    }
    if (toCandidates.isEmpty) {
      throw FormatException(
        'Unknown unit "$toRaw". ${_unitHelp(requestedCategory)}',
      );
    }

    if (requestedCategory != null) {
      fromCandidates = fromCandidates
          .where((unit) => unit.category == requestedCategory)
          .toList();
      toCandidates = toCandidates
          .where((unit) => unit.category == requestedCategory)
          .toList();
      if (fromCandidates.isEmpty) {
        throw FormatException(
          'Unknown unit "$fromRaw" for category $requestedCategory. '
          '${_unitHelp(requestedCategory)}',
        );
      }
      if (toCandidates.isEmpty) {
        throw FormatException(
          'Unknown unit "$toRaw" for category $requestedCategory. '
          '${_unitHelp(requestedCategory)}',
        );
      }
    }

    final fromCategories =
        fromCandidates.map((unit) => unit.category).toSet();
    final toCategories = toCandidates.map((unit) => unit.category).toSet();
    final common = fromCategories.intersection(toCategories);
    if (common.isEmpty) {
      throw FormatException(
        'Units "$fromRaw" and "$toRaw" belong to different categories '
        '(${fromCategories.join('/')} and ${toCategories.join('/')}). '
        'Specify a category.',
      );
    }

    final category = requestedCategory ??
        (common.length == 1
            ? common.single
            : throw FormatException(
                'Ambiguous units "$fromRaw" and "$toRaw". Specify a '
                'category: ${common.join(', ')}.',
              ));

    final fromMatches = fromCandidates
        .where((unit) => unit.category == category)
        .toList();
    final toMatches =
        toCandidates.where((unit) => unit.category == category).toList();
    if (fromMatches.length != 1) {
      throw FormatException(
        'Ambiguous unit "$fromRaw" in category $category. Use a full '
        'unit id such as ${_unitIds(category)}.',
      );
    }
    if (toMatches.length != 1) {
      throw FormatException(
        'Ambiguous unit "$toRaw" in category $category. Use a full '
        'unit id such as ${_unitIds(category)}.',
      );
    }

    return (
      from: fromMatches.single,
      to: toMatches.single,
      category: category,
    );
  }

  static List<_Unit> _lookup(String raw) {
    final exact = _exactIndex[raw];
    if (exact != null) return exact;
    return _lowerIndex[raw.toLowerCase()] ?? const <_Unit>[];
  }

  static String _unitHelp(String? category) {
    if (category != null) {
      return 'Available $category units: ${_unitIds(category)}.';
    }
    return 'Valid categories: ${_categories.join(', ')}.';
  }

  static String _unitIds(String category) {
    return _units
        .where((unit) => unit.category == category)
        .map((unit) => unit.id)
        .join(', ');
  }

  static double _convert(_Unit from, _Unit to, double value) {
    if (from.category == 'temperature') {
      return _fromCelsius(to.id, _toCelsius(from.id, value));
    }
    return value * from.factor / to.factor;
  }

  static double _toCelsius(String unitId, double value) {
    return switch (unitId) {
      'celsius' => value,
      'fahrenheit' => (value - 32) * 5 / 9,
      'kelvin' => value - 273.15,
      'rankine' => (value - 491.67) * 5 / 9,
      _ => throw FormatException('Unsupported temperature unit "$unitId".'),
    };
  }

  static double _fromCelsius(String unitId, double value) {
    return switch (unitId) {
      'celsius' => value,
      'fahrenheit' => value * 9 / 5 + 32,
      'kelvin' => value + 273.15,
      'rankine' => (value + 273.15) * 9 / 5,
      _ => throw FormatException('Unsupported temperature unit "$unitId".'),
    };
  }

  static num _normalize(double value) {
    if (value == value.roundToDouble() && value.abs() < 9007199254740991) {
      return value.toInt();
    }
    return value;
  }

  static String _format(double value, int precision) {
    if (value == 0) return '0';
    final rounded = double.parse(value.toStringAsPrecision(precision));
    if (rounded == rounded.roundToDouble() &&
        rounded.abs() < 1e15) {
      return rounded.toInt().toString();
    }
    return rounded.toString();
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

class _Unit {
  const _Unit(this.id, this.category, this.factor, this.aliases);

  final String id;
  final String category;
  final double factor;
  final List<String> aliases;
}
