import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:qalqul/core/models/investment.dart';
import 'package:qalqul/features/finance/investments_repository.dart';

final investmentsProvider =
    AsyncNotifierProvider<InvestmentsNotifier, List<Investment>>(
  InvestmentsNotifier.new,
);

/// Stored holdings, loaded in `build()`. See [TransactionsNotifier] for why this
/// is async rather than a `Notifier` that returns an empty list and loads
/// behind the UI.
class InvestmentsNotifier extends AsyncNotifier<List<Investment>> {
  final _repo = InvestmentsRepository();

  @override
  Future<List<Investment>> build() => _repo.getAll();

  /// Re-reads the table without passing through a loading state, so a write
  /// does not blank the list that triggered it.
  Future<void> _reload() async {
    final items = await _repo.getAll();
    if (!ref.mounted) return;
    state = AsyncData(items);
  }

  Future<void> add(Investment i) async {
    await _repo.insert(i);
    await _reload();
  }

  Future<void> save(Investment i) async {
    await _repo.update(i);
    await _reload();
  }

  Future<void> delete(int id) async {
    await _repo.delete(id);
    await _reload();
  }
}
