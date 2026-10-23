import 'dart:convert';
import 'dart:math' as math;

import '../contracts/ai_tool.dart';
import '../contracts/ai_tool_executor.dart';

/// Offline arithmetic tool. It parses expressions instead of evaluating code.
class BuiltInCalculatorTool implements AIToolExecutor {
  BuiltInCalculatorTool({this.enabled = true});

  static const String toolName = 'builtin__calculator';
  static const int maxExpressionLength = 2000;

  static const AIToolDefinition definition = AIToolDefinition(
    name: toolName,
    description:
        'Evaluate an arithmetic expression. Supports +, -, *, /, %, ^, '
        'parentheses, unary signs, and the functions sqrt, abs, round, floor, '
        'ceil, min, max, pow, sin, cos, tan, log, ln, and exp. Constants pi and '
        'e are available. Use this for calculations instead of doing '
        'arithmetic yourself.',
    inputSchema: {
      'type': 'object',
      'properties': {
        'expression': {
          'type': 'string',
          'description':
              'The arithmetic expression to evaluate, e.g. "(3 + 5) * 2 / 7".',
        },
      },
      'required': ['expression'],
    },
  );

  final bool enabled;

  @override
  List<AIToolDefinition> get tools {
    return enabled ? const [definition] : const [];
  }

  @override
  Future<AIToolResult> execute(AIToolCall call) async {
    final expression = call.arguments['expression']?.toString().trim() ?? '';
    if (expression.isEmpty) {
      return _error(call, 'expression is required');
    }
    if (expression.length > maxExpressionLength) {
      return _error(
        call,
        'expression is longer than $maxExpressionLength characters',
      );
    }

    try {
      final result = _ExpressionParser(expression).parse();
      if (!result.isFinite) {
        return _error(call, 'result is not a finite number');
      }
      return AIToolResult(
        toolCallId: call.id,
        name: call.name,
        content: jsonEncode({
          'expression': expression,
          'result': _normalizeNumber(result),
        }),
      );
    } on FormatException catch (error) {
      return _error(call, error.message);
    } catch (error) {
      return _error(call, error.toString());
    }
  }

  AIToolResult _error(AIToolCall call, String message) {
    return AIToolResult(
      toolCallId: call.id,
      name: call.name,
      content: jsonEncode({'error': message}),
      isError: true,
    );
  }

  static num _normalizeNumber(double value) {
    const maxSafeInteger = 9007199254740991.0;
    final rounded = value.roundToDouble();
    if ((value - rounded).abs() < 1e-12 &&
        rounded.abs() <= maxSafeInteger) {
      return rounded.toInt();
    }
    return value;
  }
}

enum _TokenType {
  number,
  identifier,
  plus,
  minus,
  multiply,
  divide,
  modulo,
  power,
  leftParen,
  rightParen,
  comma,
  end,
}

class _Token {
  const _Token(this.type, this.text, this.position);

  final _TokenType type;
  final String text;
  final int position;
}

class _Tokenizer {
  _Tokenizer(this.source);

  final String source;
  final List<_Token> _tokens = [];
  int _position = 0;

  List<_Token> tokenize() {
    while (_position < source.length) {
      final character = source[_position];

      if (_isWhitespace(character)) {
        _position++;
      } else if (_isDigit(character) || character == '.') {
        _readNumber();
      } else if (_isIdentifierStart(character)) {
        _readIdentifier();
      } else {
        switch (character) {
          case '+':
            _add(_TokenType.plus, character);
          case '-':
            _add(_TokenType.minus, character);
          case '*':
            if (_peek(1) == '*') {
              _add(_TokenType.power, '**', length: 2);
            } else {
              _add(_TokenType.multiply, character);
            }
          case '/':
            _add(_TokenType.divide, character);
          case '%':
            _add(_TokenType.modulo, character);
          case '^':
            _add(_TokenType.power, character);
          case '(':
            _add(_TokenType.leftParen, character);
          case ')':
            _add(_TokenType.rightParen, character);
          case ',':
            _add(_TokenType.comma, character);
          default:
            throw FormatException(
              'Unexpected character "$character" at position $_position.',
            );
        }
      }
    }

    _tokens.add(_Token(_TokenType.end, '', source.length));
    return _tokens;
  }

  void _add(_TokenType type, String text, {int length = 1}) {
    _tokens.add(_Token(type, text, _position));
    _position += length;
  }

  String? _peek(int offset) {
    final index = _position + offset;
    return index < source.length ? source[index] : null;
  }

  void _readNumber() {
    final start = _position;
    var hasDigits = false;

    while (_position < source.length && _isDigit(source[_position])) {
      _position++;
      hasDigits = true;
    }

    if (_position < source.length && source[_position] == '.') {
      _position++;
      while (_position < source.length && _isDigit(source[_position])) {
        _position++;
        hasDigits = true;
      }
    }

    if (!hasDigits) {
      throw FormatException('Invalid number at position $start.');
    }

    if (_position < source.length &&
        (source[_position] == 'e' || source[_position] == 'E')) {
      _position++;
      if (_position < source.length &&
          (source[_position] == '+' || source[_position] == '-')) {
        _position++;
      }
      final exponentStart = _position;
      while (_position < source.length && _isDigit(source[_position])) {
        _position++;
      }
      if (_position == exponentStart) {
        throw FormatException('Invalid exponent at position $exponentStart.');
      }
    }

    final text = source.substring(start, _position);
    if (double.tryParse(text) == null) {
      throw FormatException('Invalid number "$text" at position $start.');
    }
    _tokens.add(_Token(_TokenType.number, text, start));
  }

  void _readIdentifier() {
    final start = _position;
    while (_position < source.length &&
        _isIdentifierPart(source[_position])) {
      _position++;
    }
    _tokens.add(
      _Token(
        _TokenType.identifier,
        source.substring(start, _position),
        start,
      ),
    );
  }

  static bool _isWhitespace(String character) {
    final code = character.codeUnitAt(0);
    return code == 32 || code == 9 || code == 10 || code == 13;
  }

  static bool _isDigit(String character) {
    final code = character.codeUnitAt(0);
    return code >= 48 && code <= 57;
  }

  static bool _isIdentifierStart(String character) {
    final code = character.codeUnitAt(0);
    return (code >= 65 && code <= 90) ||
        (code >= 97 && code <= 122) ||
        code == 95;
  }

  static bool _isIdentifierPart(String character) {
    return _isIdentifierStart(character) || _isDigit(character);
  }
}

class _ExpressionParser {
  _ExpressionParser(String expression)
      : _tokens = _Tokenizer(expression).tokenize();

  final List<_Token> _tokens;
  int _index = 0;

  _Token get _current => _tokens[_index];

  double parse() {
    final value = _parseAdditive();
    if (_current.type != _TokenType.end) {
      throw FormatException(
        'Unexpected "${_current.text}" at position ${_current.position}.',
      );
    }
    return value;
  }

  double _parseAdditive() {
    var value = _parseMultiplicative();
    while (true) {
      if (_match(_TokenType.plus)) {
        value += _parseMultiplicative();
      } else if (_match(_TokenType.minus)) {
        value -= _parseMultiplicative();
      } else {
        return value;
      }
    }
  }

  double _parseMultiplicative() {
    var value = _parseUnary();
    while (true) {
      if (_match(_TokenType.multiply)) {
        value *= _parseUnary();
      } else if (_match(_TokenType.divide)) {
        final divisor = _parseUnary();
        if (divisor == 0) {
          throw const FormatException('Division by zero.');
        }
        value /= divisor;
      } else if (_match(_TokenType.modulo)) {
        final divisor = _parseUnary();
        if (divisor == 0) {
          throw const FormatException('Modulo by zero.');
        }
        value %= divisor;
      } else {
        return value;
      }
    }
  }

  double _parseUnary() {
    if (_match(_TokenType.plus)) {
      return _parseUnary();
    }
    if (_match(_TokenType.minus)) {
      return -_parseUnary();
    }
    return _parsePower();
  }

  double _parsePower() {
    final base = _parsePrimary();
    if (!_match(_TokenType.power)) {
      return base;
    }

    final exponent = _parseUnary();
    final result = math.pow(base, exponent).toDouble();
    if (!result.isFinite) {
      throw const FormatException('Result is not a finite number.');
    }
    return result;
  }

  double _parsePrimary() {
    if (_match(_TokenType.number)) {
      return double.parse(_tokens[_index - 1].text);
    }

    if (_match(_TokenType.identifier)) {
      final name = _tokens[_index - 1].text.toLowerCase();
      if (_match(_TokenType.leftParen)) {
        final arguments = <double>[];
        if (!_check(_TokenType.rightParen)) {
          arguments.add(_parseAdditive());
          while (_match(_TokenType.comma)) {
            arguments.add(_parseAdditive());
          }
        }
        _expect(
          _TokenType.rightParen,
          'Expected ")" after $name arguments.',
        );
        return _callFunction(name, arguments);
      }

      switch (name) {
        case 'pi':
          return math.pi;
        case 'e':
          return math.e;
        default:
          throw FormatException('Unknown identifier "$name".');
      }
    }

    if (_match(_TokenType.leftParen)) {
      final value = _parseAdditive();
      _expect(_TokenType.rightParen, 'Expected ")".');
      return value;
    }

    throw FormatException(
      'Unexpected "${_current.text}" at position ${_current.position}.',
    );
  }

  double _callFunction(String name, List<double> arguments) {
    double unary(double Function(double) function) {
      if (arguments.length != 1) {
        throw FormatException('$name expects 1 argument.');
      }
      return function(arguments[0]);
    }

    switch (name) {
      case 'sqrt':
        return unary((value) {
          if (value < 0) {
            throw const FormatException(
              'sqrt requires a non-negative argument.',
            );
          }
          return math.sqrt(value);
        });
      case 'abs':
        return unary((value) => value.abs());
      case 'round':
        return unary((value) => value.roundToDouble());
      case 'floor':
        return unary((value) => value.floorToDouble());
      case 'ceil':
        return unary((value) => value.ceilToDouble());
      case 'sin':
        return unary((value) => math.sin(value));
      case 'cos':
        return unary((value) => math.cos(value));
      case 'tan':
        return unary((value) => math.tan(value));
      case 'exp':
        return unary((value) => math.exp(value));
      case 'ln':
        return unary((value) {
          if (value <= 0) {
            throw const FormatException(
              'ln requires a positive argument.',
            );
          }
          return math.log(value);
        });
      case 'log':
        return unary((value) {
          if (value <= 0) {
            throw const FormatException(
              'log requires a positive argument.',
            );
          }
          return math.log(value) / math.ln10;
        });
      case 'pow':
        if (arguments.length != 2) {
          throw const FormatException('pow expects 2 arguments.');
        }
        return math.pow(arguments[0], arguments[1]).toDouble();
      case 'min':
        if (arguments.isEmpty) {
          throw const FormatException('min expects at least 1 argument.');
        }
        return arguments.reduce((a, b) => a < b ? a : b);
      case 'max':
        if (arguments.isEmpty) {
          throw const FormatException('max expects at least 1 argument.');
        }
        return arguments.reduce((a, b) => a > b ? a : b);
      default:
        throw FormatException('Unknown function "$name".');
    }
  }

  bool _match(_TokenType type) {
    if (_current.type != type) return false;
    _index++;
    return true;
  }

  bool _check(_TokenType type) => _current.type == type;

  void _expect(_TokenType type, String message) {
    if (!_match(type)) {
      throw FormatException(message);
    }
  }
}
