import 'package:flutter_test/flutter_test.dart';
import 'package:qalqul/core/models/budget.dart';
import 'package:qalqul/core/models/investment.dart';
import 'package:qalqul/core/models/transaction.dart';
import 'package:qalqul/core/utils/money.dart';

void main() {
  test('AppTransaction round trip preserves fields', () {
    const t = AppTransaction(
      id: 1,
      kind: 'spend',
      amountMinor: 1250,
      category: 'Food',
      date: 100,
      note: 'lunch',
    );
    final r = AppTransaction.fromMap(t.toMap());
    expect(r.amountMinor, 1250);
    expect(r.kind, 'spend');
    expect(r.category, 'Food');
  });

  test('Investment return calc', () {
    const i = Investment(
      name: 'A',
      principalMinor: 10000,
      currentValueMinor: 15000,
      asOf: 1,
    );
    expect(i.returnMinor, 5000);
    expect(i.returnPct, 50);
  });

  test('Budget progress clamps and computes', () {
    const b = Budget(
      name: 'PC',
      targetMinor: 100000,
      savedMinor: 25000,
      deadline: 1,
    );
    expect(b.progress, 0.25);
  });

  group('minor units', () {
    test('a decimal amount is stored exactly, with no float drift', () {
      // 0.1 + 0.2 != 0.3 in binary floating point. In minor units the sum of
      // two ten-cent amounts is exactly thirty cents.
      const a = AppTransaction(kind: 'spend', amountMinor: 10, date: 1);
      const b = AppTransaction(kind: 'spend', amountMinor: 20, date: 1);
      expect(a.amountMinor + b.amountMinor, 30);
      expect(toDecimal(a.amountMinor + b.amountMinor, 'USD'), 0.3);
    });

    test('round-trips a value with two decimals through toMap/fromMap', () {
      final t = AppTransaction(
        kind: 'spend',
        amountMinor: toMinor(9.99, 'EUR'),
        date: 1,
        currency: 'EUR',
      );
      expect(t.amountMinor, 999);
      expect(AppTransaction.fromMap(t.toMap()).amountMinor, 999);
      expect(toDecimal(999, 'EUR'), 9.99);
    });

    test('scale follows the currency, so JPY has no minor units', () {
      expect(toMinor(1500, 'USD'), 150000);
      expect(toMinor(1500, 'JPY'), 1500);
      expect(toDecimal(1500, 'JPY'), 1500.0);
    });

    test('toMinor is double-based, so it lands on a nearby cent', () {
      // Not a statement of intent: the double nearest 1.015 is a hair under
      // 1.015, so this rounds down. Which way a half-cent falls is a property of
      // the binary representation, not of the currency.
      expect(toMinor(1.015, 'USD'), inInclusiveRange(100, 102));
      expect(toMinor(-1.005, 'USD'), inInclusiveRange(-102, -100));
      expect(toMinor(0, 'USD'), 0);
      expect(toMinor(1500, 'JPY'), 1500);
    });
  });

  group('currency column', () {
    test('defaults to USD on every finance model', () {
      expect(const AppTransaction(kind: 'spend', amountMinor: 1, date: 1)
          .currency, defaultCurrency);
      expect(
          const Investment(
                  name: 'A', principalMinor: 1, currentValueMinor: 1, asOf: 1)
              .currency,
          defaultCurrency);
      expect(const Budget(name: 'B', targetMinor: 1, deadline: 1).currency,
          defaultCurrency);
    });

    test('round-trips through toMap/fromMap', () {
      const t = AppTransaction(
        kind: 'spend',
        amountMinor: 999,
        date: 1,
        currency: 'EUR',
      );
      expect(AppTransaction.fromMap(t.toMap()).currency, 'EUR');

      const i = Investment(
        name: 'A',
        principalMinor: 1,
        currentValueMinor: 2,
        asOf: 1,
        currency: 'JPY',
      );
      expect(Investment.fromMap(i.toMap()).currency, 'JPY');

      const b = Budget(
        name: 'B',
        targetMinor: 1,
        deadline: 1,
        currency: 'GBP',
      );
      expect(Budget.fromMap(b.toMap()).currency, 'GBP');
    });

    test('fromMap falls back to USD for rows with no currency column', () {
      const legacy = {
        'id': 1,
        'kind': 'spend',
        'amount_minor': 500,
        'category': 'Food',
        'date': 1,
        'note': '',
        'is_recurring': 0,
        'recurrence': '',
        'next_due': null,
      };
      expect(AppTransaction.fromMap(legacy).currency, defaultCurrency);
    });
  });

  group('editable text round trip', () {
    test('parses and re-renders an amount without trailing zeros', () {
      expect(minorToEditable(1250, 'USD'), '12.5');
      expect(minorToEditable(1000, 'USD'), '10');
      expect(minorToEditable(1500, 'JPY'), '1500');
    });

    test('accepts a comma decimal separator', () {
      // A Spanish or German keyboard types "12,5".
      expect(parseMinor('12,5', 'USD'), 1250);
      expect(parseMinor(' 12.50 ', 'USD'), 1250);
      expect(parseMinor('abc', 'USD'), isNull);
      expect(parseMinor('', 'USD'), isNull);
    });

    test('scales typed digits exactly, where a double would not', () {
      // Multiplying a double by the scale can land on the wrong side of a
      // half-cent boundary, so a typed $8.115 may not survive [toMinor]. The
      // string parser is exact, which is why the editors use it.
      expect(parseMinor('8.115', 'USD'), 812);
      expect(toMinor(8.115, 'USD'), inInclusiveRange(811, 812));

      expect(parseMinor('0.1', 'USD')! + parseMinor('0.2', 'USD')!, 30);
      expect(parseMinor('1.005', 'USD'), 101);
      expect(parseMinor('-12.34', 'USD'), -1234);
      expect(parseMinor('1000', 'JPY'), 1000);
      expect(parseMinor('1000.7', 'JPY'), 1001);
      expect(parseMinor('12.345', 'JPY'), 12);
    });
  });
}
