import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:qalqul/features/calculator/calculator_provider.dart';

void main() {
  late ProviderContainer container;
  late CalculatorNotifier n;

  setUp(() {
    container = ProviderContainer();
    n = container.read(calculatorProvider.notifier);
  });

  tearDown(() => container.dispose());

  String type(String token) {
    n.input(token);
    return container.read(calculatorProvider).expression;
  }

  String eval(String token) {
    n.input(token);
    return container.read(calculatorProvider).result;
  }

  test('scientific toggle flips the sci flag', () {
    expect(container.read(calculatorProvider).sci, isFalse);
    n.toggleSci();
    expect(container.read(calculatorProvider).sci, isTrue);
    n.toggleSci();
    expect(container.read(calculatorProvider).sci, isFalse);
  });

  test('clear keeps modes and memory but resets the entry', () {
    n.toggleSci();
    n.toggleDegrees();
    n.memoryAdd();
    n.memoryAdd();
    expect(container.read(calculatorProvider).memory, 0);

    n.input('7');
    n.input('C');

    final s = container.read(calculatorProvider);
    expect(s.expression, isEmpty);
    expect(s.result, '0');
    expect(s.sci, isTrue);
    expect(s.degrees, isTrue);
  });

  test('negate wraps a finished value', () {
    n.input('5');
    n.negate();
    expect(container.read(calculatorProvider).expression, '−(5)');
    expect(eval('='), '-5');
  });

  test('negate on an empty display starts an entry', () {
    n.negate();
    expect(container.read(calculatorProvider).expression, '−');
    n.input('7');
    expect(eval('='), '-7');
  });

  test('negate after an operator appends a pending minus', () {
    n.input('3');
    n.input('×');
    n.negate();
    expect(container.read(calculatorProvider).expression, '3×−');
    n.input('4');
    expect(eval('='), '-12');
  });

  test('reciprocal wraps the current value', () {
    n.input('4');
    n.reciprocal();
    expect(container.read(calculatorProvider).expression, '1/(4)');
    expect(eval('='), '0.25');
  });

  test('reciprocal does nothing on an incomplete entry', () {
    n.input('4');
    n.input('+');
    n.reciprocal();
    expect(container.read(calculatorProvider).expression, '4+');
  });

  test('square token continues from the last result', () {
    expect(type('^2'), '2');
    expect(eval('='), '2');

    n.input('C');
    n.input('5');
    expect(type('^2'), '5^2');
    expect(eval('='), '25');
  });

  test('answer inserts the last result', () {
    expect(eval('='), '0');
    n.input('2');
    n.input('+');
    n.input('3');
    n.input('=');
    expect(container.read(calculatorProvider).result, '5');

    n.input('+');
    n.insertAnswer();
    expect(container.read(calculatorProvider).expression, '5+5');
    expect(eval('='), '10');
  });

  test('answer inserts zero on a fresh calculator', () {
    n.insertAnswer();
    expect(container.read(calculatorProvider).expression, '0');
  });

  test('typing a digit after a prefix key continues the entry', () {
    n.input('8');
    n.reciprocal();
    n.input('3');
    expect(container.read(calculatorProvider).expression, '1/(8)3');
  });
}
