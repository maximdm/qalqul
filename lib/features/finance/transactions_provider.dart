import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:qalqul/core/models/transaction.dart';
import 'package:qalqul/features/finance/transactions_repository.dart';

final transactionsProvider =
    NotifierProvider<TransactionsNotifier, List<AppTransaction>>(
  TransactionsNotifier.new,
);

class TransactionsNotifier extends Notifier<List<AppTransaction>> {
  final _repo = TransactionsRepository();

  @override
  List<AppTransaction> build() {
    _load();
    return const [];
  }

  Future<void> _load() async {
    final items = await _repo.getAll();
    // The provider can be disposed while the query is in flight (screen
    // teardown, a test container going away); writing state then throws.
    if (!ref.mounted) return;
    state = items;
  }

  Future<void> add(AppTransaction t) async {
    await _repo.insert(t);
    await _load();
  }

  Future<void> update(AppTransaction t) async {
    await _repo.update(t);
    await _load();
  }

  Future<void> delete(int id) async {
    await _repo.delete(id);
    await _load();
  }

  List<AppTransaction> get recurring =>
      state.where((t) => t.isRecurring).toList();

  /// Recurring items whose next due date falls within [withinDays] days.
  List<AppTransaction> dueSoon({int withinDays = 7}) {
    if (state.isEmpty) return const [];
    final now = DateTime.now();
    final limit = now.add(Duration(days: withinDays));
    return recurring.where((t) {
      if (t.nextDue <= 0) return false;
      final d = DateTime.fromMillisecondsSinceEpoch(t.nextDue);
      return !d.isBefore(now) && !d.isAfter(limit);
    }).toList();
  }
}
