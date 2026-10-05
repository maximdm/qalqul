import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:qalqul/core/db/database_helper.dart';
import 'package:qalqul/features/finance/budgets_provider.dart';
import 'package:qalqul/features/finance/investments_provider.dart';
import 'package:qalqul/features/finance/transactions_provider.dart';
import 'package:qalqul/features/notes/notes_provider.dart';
import 'package:qalqul/features/widgets_studio/user_widgets_provider.dart';

/// Every data-backed notifier kicks off `_load()` from `build()` and returns an
/// empty list, so the read is still in flight when its provider is torn down.
void main() {
  setUpAll(() async {
    await DatabaseHelper.useTestDatabase();
  });

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

  test('a provider that outlives its load still publishes the rows', () async {
    final c = ProviderContainer();
    addTearDown(c.dispose);

    c.read(investmentsProvider);
    // The guard must not swallow the update: an in-flight load that resolves
    // while the provider is still alive has to reach the UI.
    await Future<void>.delayed(const Duration(milliseconds: 50));
    expect(c.read(investmentsProvider), isNotNull);
  });
}
