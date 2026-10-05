import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:qalqul/features/finance/finance_tabs.dart';
import 'package:qalqul/shared/providers/settings_provider.dart';

import 'helpers/fake_settings.dart';

void main() {
  ProviderContainer container([Map<String, String> settings = const {}]) {
    final c = ProviderContainer(
      overrides: [settingsProvider.overrideWith(() => FakeSettings(settings))],
    );
    addTearDown(c.dispose);
    return c;
  }

  List<String> ids(List<FinanceTab> order) =>
      order.map((t) => t.name).toList();

  group('parseOrder', () {
    test('falls back to the shipping order', () {
      expect(
        FinanceTabOrderNotifier.parseOrder(null),
        FinanceTab.values,
      );
      expect(
        FinanceTabOrderNotifier.parseOrder(''),
        FinanceTab.values,
      );
    });

    test('keeps a stored order', () {
      expect(
        ids(FinanceTabOrderNotifier.parseOrder('credit,investments')),
        ['credit', 'investments', 'spending', 'budget'],
      );
    });

    test('drops unknown ids, so a removed tab cannot break the strip', () {
      expect(
        ids(FinanceTabOrderNotifier.parseOrder('credit,nope,budget')),
        ['credit', 'budget', 'investments', 'spending'],
      );
    });

    test('appends tabs missing from the stored value', () {
      expect(
        ids(FinanceTabOrderNotifier.parseOrder('budget')),
        ['budget', 'investments', 'spending', 'credit'],
      );
    });

    test('collapses duplicates and stray whitespace', () {
      expect(
        ids(FinanceTabOrderNotifier.parseOrder(' credit , credit ,spending')),
        ['credit', 'spending', 'investments', 'budget'],
      );
    });
  });

  group('financeTabOrderProvider', () {
    test('defaults to the shipping order', () {
      expect(ids(container().read(financeTabOrderProvider)), [
        'investments',
        'spending',
        'credit',
        'budget',
      ]);
    });

    test('reads the stored order', () {
      final c = container({
        SettingKeys.financeTabOrder: 'budget,credit,spending,investments',
      });
      expect(ids(c.read(financeTabOrderProvider)), [
        'budget',
        'credit',
        'spending',
        'investments',
      ]);
    });

    test('reorderItem moves a tab and persists the new order', () async {
      final c = container();
      final n = c.read(financeTabOrderProvider.notifier);

      await n.reorderItem(3, 0);

      expect(ids(c.read(financeTabOrderProvider)), [
        'budget',
        'investments',
        'spending',
        'credit',
      ]);
      expect(
        c.read(settingsProvider)[SettingKeys.financeTabOrder],
        'budget,investments,spending,credit',
      );
    });

    test('reorderItem keeps every tab exactly once', () async {
      final c = container();
      final n = c.read(financeTabOrderProvider.notifier);

      await n.reorderItem(0, 2);

      final order = c.read(financeTabOrderProvider);
      expect(order.toSet(), FinanceTab.values.toSet());
      expect(order.length, FinanceTab.values.length);
    });

    test('reorderItem ignores a no-op move', () async {
      final c = container();
      final n = c.read(financeTabOrderProvider.notifier);

      await n.reorderItem(1, 1);

      expect(ids(c.read(financeTabOrderProvider)), [
        'investments',
        'spending',
        'credit',
        'budget',
      ]);
      expect(c.read(settingsProvider), isEmpty);
    });

    test('reorderItem ignores out-of-range indices', () async {
      final c = container();
      final n = c.read(financeTabOrderProvider.notifier);

      await n.reorderItem(0, 9);
      await n.reorderItem(-1, 0);

      expect(ids(c.read(financeTabOrderProvider)), [
        'investments',
        'spending',
        'credit',
        'budget',
      ]);
    });

    test('reset restores the shipping order', () async {
      final c = container({
        SettingKeys.financeTabOrder: 'budget,credit,spending,investments',
      });

      await c.read(financeTabOrderProvider.notifier).reset();

      expect(c.read(financeTabOrderProvider), FinanceTab.values);
      expect(
        c.read(settingsProvider).containsKey(SettingKeys.financeTabOrder),
        isFalse,
      );
    });
  });
}