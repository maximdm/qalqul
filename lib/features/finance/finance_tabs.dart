import 'package:flutter/foundation.dart' show visibleForTesting;
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:qalqul/shared/providers/settings_provider.dart';

/// The finance tabs, in the order they ship in.
enum FinanceTab { investments, spending, credit, budget }

/// Display order of the finance tabs, persisted in `app_settings`.
final financeTabOrderProvider =
    NotifierProvider<FinanceTabOrderNotifier, List<FinanceTab>>(
  FinanceTabOrderNotifier.new,
);

class FinanceTabOrderNotifier extends Notifier<List<FinanceTab>> {
  @override
  List<FinanceTab> build() {
    final stored = ref.watch(
      settingsProvider.select((s) => s[SettingKeys.financeTabOrder]),
    );
    return parseOrder(stored);
  }

  /// Rebuilds the stored order, ignoring anything unrecognised.
  ///
  /// Unknown ids are dropped (a tab that was removed in a later release),
  /// duplicates collapse, and tabs missing from the stored value are appended
  /// in shipping order — so adding a tab doesn't scramble a user's own order.
  @visibleForTesting
  static List<FinanceTab> parseOrder(String? stored) {
    if (stored == null || stored.isEmpty) return FinanceTab.values;
    final order = <FinanceTab>[];
    for (final id in stored.split(',')) {
      final name = id.trim();
      if (name.isEmpty) continue;
      final tab = FinanceTab.values.where((t) => t.name == name);
      if (tab.isEmpty || order.contains(tab.first)) continue;
      order.add(tab.first);
    }
    for (final tab in FinanceTab.values) {
      if (!order.contains(tab)) order.add(tab);
    }
    return order;
  }

  /// Moves the tab at [oldIndex] so that it ends up at [newIndex].
  ///
  /// Both are the indices `ReorderableListView` reports via `onReorderItem`,
  /// which already accounts for the removed item.
  Future<void> reorderItem(int oldIndex, int newIndex) async {
    if (oldIndex == newIndex) return;
    if (oldIndex < 0 || oldIndex >= state.length) return;
    if (newIndex < 0 || newIndex >= state.length) return;

    final next = [...state];
    next.insert(newIndex, next.removeAt(oldIndex));
    state = next;
    await ref.read(settingsProvider.notifier).set(
          SettingKeys.financeTabOrder,
          next.map((t) => t.name).join(','),
        );
  }

  /// Restores the shipping order.
  Future<void> reset() async {
    state = FinanceTab.values;
    await ref.read(settingsProvider.notifier).remove(SettingKeys.financeTabOrder);
  }
}