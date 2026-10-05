import 'package:flutter_test/flutter_test.dart';
import 'package:qalqul/core/db/database_helper.dart';
import 'package:qalqul/core/models/budget.dart';
import 'package:qalqul/core/models/fx_rate.dart';
import 'package:qalqul/core/models/investment.dart';
import 'package:qalqul/core/models/note.dart';
import 'package:qalqul/core/models/transaction.dart';
import 'package:qalqul/core/models/user_widget.dart';
import 'package:qalqul/core/utils/money.dart';
import 'package:qalqul/features/finance/budgets_repository.dart';
import 'package:qalqul/features/finance/fx_rates_repository.dart';
import 'package:qalqul/features/finance/investments_repository.dart';
import 'package:qalqul/features/finance/transactions_repository.dart';
import 'package:qalqul/features/notes/notes_repository.dart';
import 'package:qalqul/features/settings/settings_repository.dart';
import 'package:qalqul/features/widgets_studio/user_widgets_repository.dart';
import 'package:qalqul/shared/providers/settings_provider.dart';

void main() {
  setUpAll(() async {
    await DatabaseHelper.useTestDatabase();
  });

  tearDown(() async {
    final db = await DatabaseHelper.instance.database;
    for (final t in [
      'notes',
      'transactions',
      'investments',
      'budgets',
      'user_widgets',
      'fx_rates',
      'app_settings',
    ]) {
      await db.delete(t);
    }
  });

  group('NotesRepository', () {
    test('insert returns id and getAll retrieves it', () async {
      final repo = NotesRepository();
      final note = await repo.insert(
        Note(
          title: 'Ideas',
          body: 'hello',
          isFavorite: true,
          createdAt: 1,
          updatedAt: 2,
        ),
      );
      expect(note.id, isNotNull);

      final all = await repo.getAll();
      expect(all, hasLength(1));
      expect(all.first.title, 'Ideas');
      expect(all.first.isFavorite, isTrue);
    });

    test('is_markdown round-trips through the database', () async {
      final repo = NotesRepository();
      await repo.insert(Note(
        title: 'Plan',
        body: '# Heading',
        isMarkdown: true,
        createdAt: 1,
        updatedAt: 1,
      ));
      await repo.insert(Note(
        title: 'Plain',
        body: 'no syntax',
        createdAt: 1,
        updatedAt: 1,
      ));

      final all = await repo.getAll();
      expect(all.firstWhere((n) => n.title == 'Plan').isMarkdown, isTrue);
      expect(all.firstWhere((n) => n.title == 'Plain').isMarkdown, isFalse);
    });

    test('update and delete work', () async {
      final repo = NotesRepository();
      final note = await repo.insert(
        Note(title: 'A', body: 'b', createdAt: 0, updatedAt: 0),
      );
      await repo.update(note.copyWith(title: 'B'));
      expect((await repo.getAll()).first.title, 'B');

      await repo.delete(note.id!);
      expect(await repo.getAll(), isEmpty);
    });
  });

  group('TransactionsRepository', () {
    test('insert and getByKind filter', () async {
      final repo = TransactionsRepository();
      await repo.insert(AppTransaction(
        kind: 'spending',
        amount: 10,
        category: 'Food',
        date: 100,
        note: 'lunch',
      ));
      await repo.insert(AppTransaction(
        kind: 'credit',
        amount: 50,
        category: 'Lender',
        date: 200,
        note: 'loan',
      ));

      expect(await repo.getAll(), hasLength(2));
      final credit = await repo.getByKind('credit');
      expect(credit, hasLength(1));
      expect(credit.first.amount, 50);
    });

    test('update then delete', () async {
      final repo = TransactionsRepository();
      await repo.insert(AppTransaction(
        kind: 'spending',
        amount: 5,
        date: 1,
      ));
      final t = (await repo.getAll()).first;
      await repo.update(t.copyWith(amount: 7));
      expect((await repo.getAll()).first.amount, 7);

      await repo.delete(t.id!);
      expect(await repo.getAll(), isEmpty);
    });

    test('recurring fields round-trip through the database', () async {
      final repo = TransactionsRepository();
      await repo.insert(AppTransaction(
        kind: 'credit',
        amount: 20,
        date: 1,
        isRecurring: true,
        recurrence: 'weekly',
        nextDue: 123456,
      ));
      final t = (await repo.getAll()).first;
      expect(t.isRecurring, isTrue);
      expect(t.recurrence, 'weekly');
      expect(t.nextDue, 123456);

      await repo.delete(t.id!);
      expect(await repo.getAll(), isEmpty);
    });

    test('currency defaults to USD and round-trips when set', () async {
      final repo = TransactionsRepository();
      await repo.insert(AppTransaction(
        kind: 'spending',
        amount: 10,
        date: 1,
      ));
      await repo.insert(AppTransaction(
        kind: 'spending',
        amount: 20,
        currency: 'EUR',
        date: 2,
      ));

      final all = await repo.getAll();
      expect(all.firstWhere((t) => t.amount == 10).currency, defaultCurrency);
      expect(all.firstWhere((t) => t.amount == 20).currency, 'EUR');
    });
  });

  group('InvestmentsRepository', () {
    test('insert, update, delete', () async {
      final repo = InvestmentsRepository();
      final id = await repo.insert(Investment(
        name: 'VTSAX',
        principal: 1000,
        currentValue: 1100,
        asOf: 1,
      ));
      expect(id, isNotNull);

      final inv = (await repo.getAll()).first;
      await repo.update(inv.copyWith(currentValue: 1200));
      final all = await repo.getAll();
      expect(all.first.currentValue, 1200);
      expect(all.first.returnAmount, 200);

      await repo.delete(id);
      expect(await repo.getAll(), isEmpty);
    });

    test('currency round-trips', () async {
      final repo = InvestmentsRepository();
      await repo.insert(Investment(
        name: 'IWDA',
        principal: 500,
        currentValue: 520,
        asOf: 1,
        currency: 'GBP',
      ));
      expect((await repo.getAll()).first.currency, 'GBP');
    });
  });

  group('BudgetsRepository', () {
    test('insert, update, delete', () async {
      final repo = BudgetsRepository();
      final id = await repo.insert(Budget(
        name: 'Laptop',
        targetAmount: 1500,
        savedAmount: 300,
        deadline: 500,
      ));
      expect(id, isNotNull);

      final b = (await repo.getAll()).first;
      await repo.update(b.copyWith(savedAmount: 900));
      final all = await repo.getAll();
      expect(all.first.savedAmount, 900);
      expect(all.first.progress, closeTo(0.6, 1e-9));

      await repo.delete(id);
      expect(await repo.getAll(), isEmpty);
    });

    test('currency round-trips', () async {
      final repo = BudgetsRepository();
      await repo.insert(Budget(
        name: 'Trip',
        targetAmount: 900,
        savedAmount: 100,
        deadline: 500,
        currency: 'JPY',
      ));
      expect((await repo.getAll()).first.currency, 'JPY');
    });
  });

  group('UserWidgetsRepository', () {
    test('insert without id, getAll, update, delete', () async {
      final repo = UserWidgetsRepository();
      await repo.insert(UserWidget(
        kind: 'noteSummary',
        title: 'Recent',
        position: 0,
      ));
      final all = await repo.getAll();
      expect(all, hasLength(1));
      expect(all.first.id, isNotNull);

      final updated = all.first.copyWith(title: 'Pinned');
      await repo.update(updated);
      expect((await repo.getAll()).first.title, 'Pinned');

      await repo.delete(all.first.id!);
      expect(await repo.getAll(), isEmpty);
    });
  });

  group('FxRatesRepository', () {
    test('insert, getAll, delete', () async {
      final repo = FxRatesRepository();
      await repo.upsert(FxRate(base: 'USD', quote: 'EUR', rate: 0.92, asOf: 5));
      await repo.upsert(FxRate(base: 'EUR', quote: 'GBP', rate: 0.85, asOf: 5));

      final all = await repo.getAll();
      expect(all, hasLength(2));
      expect(all.first.base, 'EUR');
      expect(all.first.rate, 0.85);

      await repo.delete(all.first.id!);
      expect(await repo.getAll(), hasLength(1));
    });

    test('upsert keeps one row per pair and upper-cases codes', () async {
      final repo = FxRatesRepository();
      await repo.upsert(FxRate(base: 'usd', quote: 'eur', rate: 0.9, asOf: 1));
      await repo.upsert(FxRate(base: 'USD', quote: 'EUR', rate: 0.95, asOf: 2));

      final all = await repo.getAll();
      expect(all, hasLength(1));
      expect(all.first.base, 'USD');
      expect(all.first.quote, 'EUR');
      expect(all.first.rate, 0.95);
      expect(all.first.asOf, 2);
    });
  });

  group('SettingsRepository', () {
    test('set, getAll and overwrite', () async {
      final repo = SettingsRepository();
      expect(await repo.getAll(), isEmpty);

      await repo.set(SettingKeys.baseCurrency, 'EUR');
      await repo.set(SettingKeys.locale, 'es');
      expect(await repo.getAll(), {
        SettingKeys.baseCurrency: 'EUR',
        SettingKeys.locale: 'es',
      });

      await repo.set(SettingKeys.baseCurrency, 'GBP');
      final all = await repo.getAll();
      expect(all, hasLength(2));
      expect(all[SettingKeys.baseCurrency], 'GBP');
    });

    test('delete removes a key', () async {
      final repo = SettingsRepository();
      await repo.set(SettingKeys.appLockEnabled, 'true');
      await repo.delete(SettingKeys.appLockEnabled);
      expect(await repo.getAll(), isEmpty);
    });
  });
}
