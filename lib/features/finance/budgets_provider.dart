import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:qalqul/core/models/budget.dart';
import 'package:qalqul/features/finance/budgets_repository.dart';

final budgetsProvider =
    AsyncNotifierProvider<BudgetsNotifier, List<Budget>>(BudgetsNotifier.new);

/// Stored budgets, loaded in `build()`. See [TransactionsNotifier] for why this
/// is async rather than a `Notifier` that returns an empty list and loads
/// behind the UI.
class BudgetsNotifier extends AsyncNotifier<List<Budget>> {
  final _repo = BudgetsRepository();

  @override
  Future<List<Budget>> build() => _repo.getAll();

  /// Re-reads the table without passing through a loading state, so a write
  /// does not blank the list that triggered it.
  Future<void> _reload() async {
    final items = await _repo.getAll();
    if (!ref.mounted) return;
    state = AsyncData(items);
  }

  Future<void> add(Budget b) async {
    await _repo.insert(b);
    await _reload();
  }

  Future<void> save(Budget b) async {
    await _repo.update(b);
    await _reload();
  }

  Future<void> delete(int id) async {
    await _repo.delete(id);
    await _reload();
  }
}
