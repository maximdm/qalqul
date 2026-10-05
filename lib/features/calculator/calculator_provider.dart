import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'calculator_engine.dart';

class CalculatorState {
  final String expression;
  final String result;
  final List<String> history;
  final bool isError;
  final bool degrees;
  final bool sci;
  final double? memory;

  const CalculatorState({
    this.expression = '',
    this.result = '0',
    this.history = const [],
    this.isError = false,
    this.degrees = false,
    this.sci = false,
    this.memory,
  });

  CalculatorState copyWith({
    String? expression,
    String? result,
    List<String>? history,
    bool? isError,
    bool? degrees,
    bool? sci,
    double? memory,
    bool clearMemory = false,
  }) {
    return CalculatorState(
      expression: expression ?? this.expression,
      result: result ?? this.result,
      history: history ?? this.history,
      isError: isError ?? this.isError,
      degrees: degrees ?? this.degrees,
      sci: sci ?? this.sci,
      memory: clearMemory ? null : (memory ?? this.memory),
    );
  }
}

const _operators = {'+', '−', '×', '÷', '^', '%', '^2'};

/// Trailing characters that already form a complete value, so a prefix
/// operator has to wrap the expression instead of appending to it.
const _valueEndings = {
  '0',
  '1',
  '2',
  '3',
  '4',
  '5',
  '6',
  '7',
  '8',
  '9',
  ')',
  '!',
  'π',
};

class CalculatorNotifier extends Notifier<CalculatorState> {
  bool _fresh = false;

  @override
  CalculatorState build() => const CalculatorState();

  void input(String token) {
    if (token == 'C') {
      _fresh = false;
      state = state.copyWith(expression: '', result: '0', isError: false);
      return;
    }
    if (token == '⌫') {
      _fresh = false;
      final e = state.expression;
      state = state.copyWith(
        expression: e.isNotEmpty ? e.substring(0, e.length - 1) : '',
        isError: false,
      );
      return;
    }
    if (token == '=') {
      _equals();
      return;
    }
    _fresh = false;
    final isOp = _operators.contains(token);
    var expr = _fresh
        ? (isOp ? '${state.result}$token' : token)
        : state.expression + token;
    // `x²` on an empty display should start the entry instead of erroring.
    if (expr == '^2') expr = '2';
    state = state.copyWith(expression: expr, isError: false);
  }

  /// Wraps the current value in a unary minus, or appends a pending one.
  void negate() {
    if (state.isError) return;
    final expr = _currentExpression();
    _fresh = false;
    if (expr.isEmpty) {
      state = state.copyWith(expression: '−', isError: false);
      return;
    }
    state = state.copyWith(
      expression: _endsWithValue(expr) ? '−($expr)' : '$expr−',
      isError: false,
    );
  }

  /// Turns the current value into its reciprocal, e.g. `4` → `1/(4)`.
  void reciprocal() {
    if (state.isError) return;
    final expr = _currentExpression();
    if (!_endsWithValue(expr)) return;
    _fresh = false;
    state = state.copyWith(expression: '1/($expr)', isError: false);
  }

  /// Inserts the last result, like the `ANS` key on a scientific calculator.
  void insertAnswer() {
    if (state.isError) return;
    final expr = _currentExpression();
    final value = evaluateExpression(state.result);
    if (value == null) return;
    _fresh = false;
    state = state.copyWith(expression: expr + value, isError: false);
  }

  /// The expression a prefix key should act on, collapsing a pending result.
  String _currentExpression() => _fresh ? state.result : state.expression;

  static bool _endsWithValue(String expr) =>
      expr.isNotEmpty && _valueEndings.contains(expr[expr.length - 1]);

  void _equals() {
    if (state.expression.isEmpty) return;
    final res = evaluateExpression(state.expression, degrees: state.degrees);
    if (res == null) {
      state = state.copyWith(isError: true);
      return;
    }
    state = state.copyWith(
      expression: res,
      result: res,
      isError: false,
      history: [
        '${state.expression} = $res',
        ...state.history,
      ].take(30).toList(),
    );
    _fresh = true;
  }

  void toggleDegrees() => state = state.copyWith(degrees: !state.degrees);

  void toggleSci() => state = state.copyWith(sci: !state.sci);

  void clearHistory() => state = state.copyWith(history: const []);

  double? get _memoryValue {
    final text = state.isError ? '' : state.result;
    return double.tryParse(text);
  }

  void memoryAdd() {
    final v = _memoryValue;
    if (v == null) return;
    state = state.copyWith(memory: (state.memory ?? 0) + v);
  }

  void memorySubtract() {
    final v = _memoryValue;
    if (v == null) return;
    state = state.copyWith(memory: (state.memory ?? 0) - v);
  }

  void memoryRecall() {
    if (state.memory == null) return;
    _fresh = true;
    state = state.copyWith(
      expression: state.memory!.toString(),
      result: state.memory!.toString(),
      isError: false,
    );
  }

  void memoryClear() => state = state.copyWith(clearMemory: true);
}

final calculatorProvider =
    NotifierProvider<CalculatorNotifier, CalculatorState>(
      CalculatorNotifier.new,
    );
