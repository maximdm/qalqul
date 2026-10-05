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
      amount: 12.5,
      category: 'Food',
      date: 100,
      note: 'lunch',
    );
    final r = AppTransaction.fromMap(t.toMap());
    expect(r.amount, 12.5);
    expect(r.kind, 'spend');
    expect(r.category, 'Food');
  });

  test('Investment return calc', () {
    const i = Investment(name: 'A', principal: 100, currentValue: 150, asOf: 1);
    expect(i.returnAmount, 50);
    expect(i.returnPct, 50);
  });

  test('Budget progress clamps and computes', () {
    const b = Budget(name: 'PC', targetAmount: 1000, savedAmount: 250, deadline: 1);
    expect(b.progress, 0.25);
  });

  group('currency column', () {
    test('defaults to USD on every finance model', () {
      expect(const AppTransaction(kind: 'spend', amount: 1, date: 1).currency,
          defaultCurrency);
      expect(
          const Investment(name: 'A', principal: 1, currentValue: 1, asOf: 1)
              .currency,
          defaultCurrency);
      expect(const Budget(name: 'B', targetAmount: 1, deadline: 1).currency,
          defaultCurrency);
    });

    test('round-trips through toMap/fromMap', () {
      const t = AppTransaction(
        kind: 'spend',
        amount: 9.99,
        date: 1,
        currency: 'EUR',
      );
      expect(AppTransaction.fromMap(t.toMap()).currency, 'EUR');

      const i = Investment(
        name: 'A',
        principal: 1,
        currentValue: 2,
        asOf: 1,
        currency: 'JPY',
      );
      expect(Investment.fromMap(i.toMap()).currency, 'JPY');

      const b = Budget(
        name: 'B',
        targetAmount: 1,
        deadline: 1,
        currency: 'GBP',
      );
      expect(Budget.fromMap(b.toMap()).currency, 'GBP');
    });

    test('fromMap falls back to USD for pre-v5 rows', () {
      const legacy = {
        'id': 1,
        'kind': 'spend',
        'amount': 5.0,
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
}
