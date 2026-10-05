import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:qalqul/core/models/investment.dart';
import 'package:qalqul/features/finance/investments_repository.dart';

final investmentsProvider =
    NotifierProvider<InvestmentsNotifier, List<Investment>>(
  InvestmentsNotifier.new,
);

class InvestmentsNotifier extends Notifier<List<Investment>> {
  final _repo = InvestmentsRepository();

  @override
  List<Investment> build() {
    _load();
    return const [];
  }

  Future<void> _load() async {
    state = await _repo.getAll();
  }

  Future<void> add(Investment i) async {
    await _repo.insert(i);
    await _load();
  }

  Future<void> update(Investment i) async {
    await _repo.update(i);
    await _load();
  }

  Future<void> delete(int id) async {
    await _repo.delete(id);
    await _load();
  }
}
