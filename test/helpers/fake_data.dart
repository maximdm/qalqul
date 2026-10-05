import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:qalqul/core/models/budget.dart';
import 'package:qalqul/core/models/fx_rate.dart';
import 'package:qalqul/core/models/investment.dart';
import 'package:qalqul/core/models/transaction.dart';
import 'package:qalqul/core/models/user_widget.dart';
import 'package:qalqul/features/finance/budgets_provider.dart';
import 'package:qalqul/features/finance/currency_provider.dart';
import 'package:qalqul/features/finance/investments_provider.dart';
import 'package:qalqul/features/finance/transactions_provider.dart';
import 'package:qalqul/features/notes/notes_provider.dart';
import 'package:qalqul/features/widgets_studio/user_widgets_provider.dart';

/// Notifiers that render an empty, in-memory list instead of querying sqflite.
///
/// The real ones query sqflite in `build()`, so a test that boots the app and
/// then ends hits sqflite's 10-second `txnSynchronized` lock timer mid-flight and
/// fails with "A Timer is still pending". Worse, the stray query can resolve
/// against a provider the test already disposed. Tests that only exercise
/// navigation or wiring don't care about stored data, so they should pay for
/// none of this.
///
/// [build] is async for the same reason the real ones are: the return type is
/// part of the `AsyncNotifier` contract, and a synchronous override would not
/// compile. It resolves immediately, so nothing in a test has to await it.
mixin _EmptyData<T> on AsyncNotifier<List<T>> {
  @override
  Future<List<T>> build() async => const [];
}

class FakeBudgets extends BudgetsNotifier with _EmptyData<Budget> {}

class FakeInvestments extends InvestmentsNotifier with _EmptyData<Investment> {}

class FakeTransactions
    extends TransactionsNotifier with _EmptyData<AppTransaction> {}

class FakeFxRates extends FxRatesNotifier with _EmptyData<FxRate> {}

class FakeUserWidgets
    extends UserWidgetsNotifier with _EmptyData<UserWidget> {}

/// [NotesNotifier] is the odd one out: its state is a wrapper, not a list.
class FakeNotes extends NotesNotifier {
  @override
  Future<NotesState> build() async => const NotesState();
}

/// Overrides for every data-backed provider, for tests that boot the app but do
/// not assert on stored rows.
///
/// Typed `dynamic` because riverpod's `Override` is not public API. Spread this
/// into an `overrides:` list, whose element type is supplied by context.
List<dynamic> emptyDataProviders() => [
      budgetsProvider.overrideWith(FakeBudgets.new),
      investmentsProvider.overrideWith(FakeInvestments.new),
      transactionsProvider.overrideWith(FakeTransactions.new),
      fxRatesProvider.overrideWith(FakeFxRates.new),
      userWidgetsProvider.overrideWith(FakeUserWidgets.new),
      notesProvider.overrideWith(FakeNotes.new),
    ];
