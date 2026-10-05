import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:qalqul/core/db/database_helper.dart';
import 'package:qalqul/core/models/investment.dart';
import 'package:qalqul/core/utils/money.dart';
import 'package:qalqul/features/finance/budgets_provider.dart';
import 'package:qalqul/features/finance/investments_provider.dart';
import 'package:qalqul/features/finance/transactions_provider.dart';
import 'package:qalqul/features/notes/notes_provider.dart';
import 'package:qalqul/features/widgets_studio/user_widgets_provider.dart';

/// The data-backed notifiers are `AsyncNotifier`s: `build()` awaits its query, so
/// the read is still in flight when its provider is torn down.
void main() {
  setUpAll(() async {
    await DatabaseHelper.useTestDatabase();
  });

  /// The test database is shared by every test in this file, so a test that
  /// asserts on a single row has to start from a known-empty table.
  Future<void> clearInvestments(ProviderContainer c) async {
    await c.read(investmentsProvider.future);
    final notifier = c.read(investmentsProvider.notifier);
    for (final row in c.read(investmentsProvider).requireValue) {
      await notifier.delete(row.id!);
    }
  }

  test('tearing down a provider mid-load does not throw', () async {
    final c = ProviderContainer();

    // Reading each one starts an async sqflite query. Disposing straight away
    // leaves those queries to resolve against a dead provider: the late
    // `state = ...` used to raise UnmountedRefException, which surfaced as a
    // failure in whichever test happened to be running next.
    c.read(budgetsProvider);
    c.read(investmentsProvider);
    c.read(transactionsProvider);
    c.read(notesProvider);
    c.read(userWidgetsProvider);
    c.dispose();

    // Long enough for the queries to come back and try to write their result.
    // An unhandled async error surfacing here fails the test.
    await Future<void>.delayed(const Duration(milliseconds: 50));
  });

  test('a load is observable as loading, then as the rows', () async {
    final c = ProviderContainer();
    addTearDown(c.dispose);

    // This is the reason the providers are async: the first read must say "still
    // loading" rather than "empty". A synchronous `Notifier` returning `const []`
    // made every screen flash its empty state before the query came back.
    expect(c.read(investmentsProvider), isA<AsyncLoading>());

    await clearInvestments(c);
    await c
        .read(investmentsProvider.notifier)
        .add(Investment(
          name: 'Brokerage',
          principalMinor: toMinor(100, defaultCurrency),
          currentValueMinor: toMinor(120, defaultCurrency),
          asOf: DateTime.now().millisecondsSinceEpoch,
        ));

    expect(c.read(investmentsProvider), isA<AsyncData<List<Investment>>>());
    expect(c.read(investmentsProvider).requireValue.single.name, 'Brokerage');
  });

  test('a save refetches without blanking the visible list', () async {
    final c = ProviderContainer();
    addTearDown(c.dispose);

    final notifier = c.read(investmentsProvider.notifier);
    await c.read(investmentsProvider.future);
    await clearInvestments(c);

    // Record every state the provider publishes. Sampling the state at one
    // arbitrary moment is not enough: `_reload()` awaits the re-read, so a
    // loading state would be set and cleared inside the write and never be
    // visible to a check made before the write completes.
    final seen = <AsyncValue<List<Investment>>>[];
    c.listen(
      investmentsProvider,
      (_, next) => seen.add(next),
      fireImmediately: true,
    );
    await notifier.add(Investment(
      name: 'Brokerage',
      principalMinor: toMinor(100, defaultCurrency),
      currentValueMinor: toMinor(120, defaultCurrency),
      asOf: DateTime.now().millisecondsSinceEpoch,
    ));

    expect(seen.whereType<AsyncLoading>(), isEmpty,
        reason: 'a write must not publish a loading state');
    expect(c.read(investmentsProvider).requireValue.single.name, 'Brokerage');

    await notifier.save(Investment(
      id: c.read(investmentsProvider).requireValue.single.id,
      name: 'Renamed',
      principalMinor: toMinor(100, defaultCurrency),
      currentValueMinor: toMinor(120, defaultCurrency),
      asOf: DateTime.now().millisecondsSinceEpoch,
    ));

    expect(seen.whereType<AsyncLoading>(), isEmpty,
        reason: 'a write must not publish a loading state');
    expect(c.read(investmentsProvider).requireValue.single.name, 'Renamed');
  });
}
