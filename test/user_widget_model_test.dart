import 'package:flutter_test/flutter_test.dart';
import 'package:qalqul/core/models/user_widget.dart';
import 'package:qalqul/l10n/l10n.dart';

void main() {
  test('toMap/fromMap round trip preserves fields', () {
    const w = UserWidget(
      id: 7,
      kind: 'financeOverview',
      title: 'Money',
      config: {'limit': 3},
      position: 2,
    );
    final back = UserWidget.fromMap(w.toMap());
    expect(back.id, 7);
    expect(back.kind, 'financeOverview');
    expect(back.title, 'Money');
    expect(back.config['limit'], 3);
    expect(back.position, 2);
  });

  test('copyWith changes only given fields', () {
    const w = UserWidget(kind: 'calculator', title: 'Calc');
    final updated = w.copyWith(title: 'Quick');
    expect(updated.kind, 'calculator');
    expect(updated.title, 'Quick');
  });

  test('kind enum fromValue falls back to noteSummary', () {
    expect(UserWidgetKind.fromValue('unknown'), UserWidgetKind.noteSummary);
    expect(UserWidgetKind.fromValue('spendingChart'),
        UserWidgetKind.spendingChart);
  });

  test('new kinds round-trip through the enum', () {
    for (final kind in [
      UserWidgetKind.monthSpend,
      UserWidgetKind.portfolioValue,
      UserWidgetKind.billsDue,
    ]) {
      expect(UserWidgetKind.fromValue(kind.value), kind);
    }
    expect(UserWidgetKind.values, hasLength(8));
  });

  test('kind labels map to generated l10n getters in every locale',
      () async {
    // Guards against adding a kind without a matching ARB entry.
    for (final locale in L10n.supportedLocales) {
      final l10n = await L10n.delegate.load(locale);
      for (final kind in UserWidgetKind.values) {
        expect(l10n.kindLabel(kind), isNotEmpty,
            reason: '${locale.languageCode}:${kind.labelKey}');
      }
    }
  });

  test('size maps to bento cells', () {
    const sizes = {
      's': [2, 1],
      'm': [2, 2],
      'l': [4, 2],
    };
    sizes.forEach((size, cells) {
      final w =
          UserWidget(kind: 'calculator', title: 't', config: {'size': size});
      expect(w.size, size);
      expect(w.cells, cells);
    });
    const unknown =
        UserWidget(kind: 'calculator', title: 't', config: {'size': 'xl'});
    expect(unknown.size, 'm');
    expect(unknown.cells, [2, 2]);
  });

  test('smart widget config getters have defaults', () {
    const w = UserWidget(kind: 'monthSpend', title: 'This month');
    expect(w.billsWithinDays, 7);
    expect(w.monthOffset, 0);
    expect(w.category, isEmpty);
  });

  test('smart widget config getters read and coerce values', () {
    const w = UserWidget(
      kind: 'billsDue',
      title: 'Bills',
      config: {'withinDays': '14', 'monthOffset': -1, 'category': 'Food'},
    );
    expect(w.billsWithinDays, 14);
    expect(w.monthOffset, -1);
    expect(w.category, 'Food');
  });

  test('config survives toMap/fromMap', () {
    const w = UserWidget(
      kind: 'billsDue',
      title: 'Bills',
      config: {'withinDays': 30, 'size': 'l'},
    );
    final back = UserWidget.fromMap(w.toMap());
    expect(back.config, {'withinDays': 30, 'size': 'l'});
    expect(back.billsWithinDays, 30);
    expect(back.size, 'l');
  });
}
