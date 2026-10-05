import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:qalqul/core/models/transaction.dart';
import 'package:qalqul/features/finance/transactions_repository.dart';

final transactionsProvider =
    AsyncNotifierProvider<TransactionsNotifier, List<AppTransaction>>(
  TransactionsNotifier.new,
);

/// Stored transactions, loaded in `build()`.
///
/// This is an [AsyncNotifier] rather than a `Notifier` that kicks off a load and
/// returns an empty list: the old shape made "loading" and "no transactions" the
/// same value, so every screen flashed an empty state before the rows arrived.
class TransactionsNotifier extends AsyncNotifier<List<AppTransaction>> {
  final _repo = TransactionsRepository();

  @override
  Future<List<AppTransaction>> build() => _repo.getAll();

  /// Re-reads the table without passing through a loading state.
  ///
  /// Refetching after a write keeps the list honest (rows come back with their
  /// database ids and in query order), but going via `state = AsyncLoading()`
  /// would blank the list the user is looking at.
  Future<void> _reload() async {
    final items = await _repo.getAll();
    if (!ref.mounted) return;
    state = AsyncData(items);
  }

  Future<void> add(AppTransaction t) async {
    await _repo.insert(t);
    await _reload();
  }

  Future<void> save(AppTransaction t) async {
    await _repo.update(t);
    await _reload();
  }

  Future<void> delete(int id) async {
    await _repo.delete(id);
    await _reload();
  }
}
