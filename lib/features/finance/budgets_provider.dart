import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:qalqul/core/models/budget.dart';
import 'package:qalqul/features/finance/budgets_repository.dart';

final budgetsProvider =
    NotifierProvider<BudgetsNotifier, List<Budget>>(BudgetsNotifier.new);

class BudgetsNotifier extends Notifier<List<Budget>> {
  final _repo = BudgetsRepository();

  @override
  List<Budget> build() {
    _load();
    return const [];
  }

  Future<void> _load() async {
    state = await _repo.getAll();
  }

  Future<void> add(Budget b) async {
    await _repo.insert(b);
    await _load();
  }

  Future<void> update(Budget b) async {
    await _repo.update(b);
    await _load();
  }

  Future<void> delete(int id) async {
    await _repo.delete(id);
    await _load();
  }
}
