import 'package:flutter_riverpod/misc.dart' show Override;
import 'package:flutter_test/flutter_test.dart';

import 'package:qalqul/core/db/database_helper.dart';
import 'package:qalqul/core/models/fx_rate.dart';
import 'package:qalqul/core/models/investment.dart';
import 'package:qalqul/core/models/transaction.dart';
import 'package:qalqul/core/models/user_widget.dart';
import 'package:qalqul/features/finance/currency_provider.dart';
import 'package:qalqul/features/finance/fx_rates_repository.dart';
import 'package:qalqul/features/finance/investments_provider.dart';
import 'package:qalqul/features/finance/transactions_provider.dart';
import 'package:qalqul/features/settings/settings_repository.dart';
import 'package:qalqul/features/widgets_studio/user_widget_card.dart';
import 'package:qalqul/shared/providers/settings_provider.dart';

import 'helpers/fake_settings.dart';
import 'helpers/pump_localized.dart';

/// Base currency is USD and `USD/EUR = 0.5`, so EUR amounts double into USD.
const _eurRate = FxRate(base: 'USD', quote: 'EUR', rate: 0.5, asOf: 1);

void main() {
  setUpAll(() async {
    await DatabaseHelper.useTestDatabase();
  });

  setUp(() async {
    final db = await DatabaseHelper.instance.database;
    for (final t in [
      'investments',
      'transactions',
      'fx_rates',
      'app_settings',
      'notes',
    ]) {
      await db.delete(t);
    }
    await SettingsRepository().set(SettingKeys.baseCurrency, 'USD');
    await FxRatesRepository().upsert(_eurRate);
  });

  final List<Override> overrides = [
    settingsProvider.overrideWith(() => FakeSettings()),
    // The rate table is derived from `fxRatesProvider`; overriding the source
    // keeps the widget test off sqflite while still exercising the real
    // `FxRates` conversion maths.
    fxRatesProvider.overrideWith(() => _FakeFxRates([_eurRate])),
  ];

  Investment holding(String name, double value, String currency) =>
      Investment(
        name: name,
        principal: value,
        currentValue: value,
        asOf: 1,
        currency: currency,
      );

  AppTransaction tx(String kind, double amount, String currency) =>
      AppTransaction(
        kind: kind,
        amount: amount,
        category: 'General',
        date: DateTime.now().millisecondsSinceEpoch,
        currency: currency,
      );

  group('mixed-currency totals are converted before summing', () {
    testWidgets('netWorth adds assets and credit in the base currency',
        (tester) async {
      // 100 USD + 50 EUR (=100 USD) assets = 200 USD; 30 EUR (=60 USD) credit.
      await pumpLocalized(
        tester,
        UserWidgetCard(const UserWidget(kind: 'netWorth', title: 'Net worth')),
        overrides: [
          ...overrides,
          investmentsProvider
              .overrideWith(() => _FakeInvestments([
                    holding('A', 100, 'USD'),
                    holding('B', 50, 'EUR'),
                  ])),
          transactionsProvider
              .overrideWith(() => _FakeTransactions([tx('credit', 30, 'EUR')])),
        ],
      );

      // 200 - 60 = 140. Summing raw numbers would have produced 150 - 30 = 120.
      expect(find.textContaining(r'$140'), findsOneWidget);
      expect(find.textContaining(r'$120'), findsNothing);
    });

    testWidgets('portfolioValue converts value and cost', (tester) async {
      // 100 USD + 50 EUR (=100 USD) = 200 USD value, same 200 USD cost.
      await pumpLocalized(
        tester,
        UserWidgetCard(
            const UserWidget(kind: 'portfolioValue', title: 'Portfolio')),
        overrides: [
          ...overrides,
          investmentsProvider.overrideWith(() => _FakeInvestments([
                holding('A', 100, 'USD'),
                holding('B', 50, 'EUR'),
              ])),
          transactionsProvider.overrideWith(() => _FakeTransactions([])),
        ],
      );

      expect(find.textContaining(r'$200'), findsWidgets);
      // A naive sum is 150, and would report +0.0% instead of the flat 0.0%.
      expect(find.textContaining(r'$150'), findsNothing);
    });

    testWidgets('financeOverview converts both figures', (tester) async {
      await pumpLocalized(
        tester,
        UserWidgetCard(
            const UserWidget(kind: 'financeOverview', title: 'Overview')),
        overrides: [
          ...overrides,
          investmentsProvider
              .overrideWith(() => _FakeInvestments([holding('A', 50, 'EUR')])),
          transactionsProvider
              .overrideWith(() => _FakeTransactions([tx('credit', 10, 'EUR')])),
        ],
      );

      // 50 EUR = 100 USD invested; 10 EUR = 20 USD credit.
      expect(find.textContaining(r'$100'), findsOneWidget);
      expect(find.textContaining(r'$20'), findsOneWidget);
    });

    testWidgets('monthSpend converts the filtered month total',
        (tester) async {
      await pumpLocalized(
        tester,
        const UserWidgetCard(
            UserWidget(kind: 'monthSpend', title: 'This month')),
        overrides: [
          ...overrides,
          investmentsProvider.overrideWith(() => _FakeInvestments([])),
          transactionsProvider.overrideWith(() => _FakeTransactions([
                tx('spending', 40, 'USD'),
                tx('spending', 25, 'EUR'),
              ])),
        ],
      );

      // 40 + (25 EUR = 50 USD) = 90, not 65.
      expect(find.textContaining(r'$90'), findsOneWidget);
      expect(find.textContaining(r'$65'), findsNothing);
    });

    testWidgets('spendingChart converts the total', (tester) async {
      await pumpLocalized(
        tester,
        const UserWidgetCard(
            UserWidget(kind: 'spendingChart', title: 'Spent')),
        overrides: [
          ...overrides,
          investmentsProvider.overrideWith(() => _FakeInvestments([])),
          transactionsProvider.overrideWith(() => _FakeTransactions([
                tx('spending', 15, 'EUR'),
              ])),
        ],
      );

      // 15 EUR = 30 USD.
      expect(find.textContaining(r'$30'), findsOneWidget);
      expect(find.textContaining(r'$15'), findsNothing);
    });
  });
}

/// Minimal notifier overrides so the card renders from a fixed list without
/// waiting on sqflite.
class _FakeInvestments extends InvestmentsNotifier {
  _FakeInvestments(this.items);
  final List<Investment> items;

  @override
  List<Investment> build() => items;
}

class _FakeTransactions extends TransactionsNotifier {
  _FakeTransactions(this.items);
  final List<AppTransaction> items;

  @override
  List<AppTransaction> build() => items;
}

class _FakeFxRates extends FxRatesNotifier {
  _FakeFxRates(this.items);
  final List<FxRate> items;

  @override
  List<FxRate> build() => items;
}