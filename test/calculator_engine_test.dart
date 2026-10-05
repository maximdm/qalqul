import 'package:flutter_test/flutter_test.dart';
import 'package:qalqul/core/utils/expression.dart';
import 'package:qalqul/features/calculator/calculator_engine.dart';

void main() {
  test('basic arithmetic respects precedence', () {
    expect(evaluateExpression('2+3*4'), '14');
  });

  test('power operator', () {
    expect(evaluateExpression('2^8'), '256');
  });

  test('square root', () {
    expect(evaluateExpression('sqrt(16)'), '4');
  });

  test('natural log of 1', () {
    expect(evaluateExpression('ln(1)'), '0');
  });

  test('trig with pi constant (radians)', () {
    expect(evaluateExpression('sin(pi/2)'), '1');
  });

  test('base-10 log via binary log(base, arg)', () {
    expect(evaluateExpression('log(10,1000)'), '3');
  });

  test('exponential function e(1)', () {
    final r = evaluateExpression('e(1)');
    expect(r, isNotNull);
    expect(r!.startsWith('2.718'), isTrue);
  });

  test('degrees mode converts trig argument', () {
    expect(evaluateExpression('sin(90)', degrees: true), '1');
  });

  test('square root key token', () {
    expect(evaluateExpression('√(16)'), '4');
    expect(evaluateExpression('√(9+7)'), '4');
    expect(evaluateExpression('√16)'), '4');
  });

  test('factorial', () {
    expect(evaluateExpression('5!'), '120');
    expect(evaluateExpression('0!'), '1');
    expect(evaluateExpression('3!+1'), '7');
  });

  test('unary minus', () {
    expect(evaluateExpression('−5'), '-5');
    expect(evaluateExpression('(−3)^2'), '9');
    expect(evaluateExpression('−(2+3)'), '-5');
  });

  test('inverse trig in radians', () {
    expect(evaluateExpression('arcsin(0.5)'), '0.5235987756');
    expect(evaluateExpression('arccos(0.5)'), '1.0471975512');
    expect(evaluateExpression('arctan(1)'), '0.7853981634');
  });

  test('inverse trig in degrees is not corrupted by the sin replacement', () {
    expect(evaluateExpr('arcsin(30)', degrees: true), closeTo(31.573961, 1e-6));
    expect(evaluateExpr('arctan(45)', degrees: true), closeTo(38.146026, 1e-6));
    expect(evaluateExpr('arcsin(0.5)', degrees: true), closeTo(0.5, 1e-4));
    expect(evaluateExpr('sin(30)', degrees: true), closeTo(0.5, 1e-9));
    expect(evaluateExpression('sin(90)', degrees: true), '1');
  });

  test('inverse trig outside the real domain returns null', () {
    expect(evaluateExpr('arccos(60)', degrees: true), isNull);
  });

  test('nth root via nrt(index, value)', () {
    expect(evaluateExpression('nrt(3,8)'), '2');
    expect(evaluateExpression('nrt(2,16)'), '4');
  });

  test('log with an arbitrary base', () {
    expect(evaluateExpression('log(2,8)'), '3');
  });

  test('absolute value', () {
    expect(evaluateExpression('abs(−3)'), '3');
  });

  test('reciprocal and square tokens', () {
    expect(evaluateExpression('1/(4)'), '0.25');
    expect(evaluateExpression('5^2'), '25');
  });

  test('modulo', () {
    expect(evaluateExpression('5%3'), '2');
  });

  test('invalid expression returns null', () {
    expect(evaluateExpression('sin('), isNull);
    expect(evaluateExpression('1/0'), isNull);
  });
}
