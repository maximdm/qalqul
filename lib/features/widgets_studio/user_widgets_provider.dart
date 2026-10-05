import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:qalqul/core/models/user_widget.dart';
import 'package:qalqul/features/widgets_studio/user_widgets_repository.dart';

final userWidgetsProvider =
    NotifierProvider<UserWidgetsNotifier, List<UserWidget>>(
  UserWidgetsNotifier.new,
);

class UserWidgetsNotifier extends Notifier<List<UserWidget>> {
  final _repo = UserWidgetsRepository();

  @override
  List<UserWidget> build() {
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

  Future<void> add(UserWidget w) async {
    final next = state.length;
    await _repo.insert(w.copyWith(position: next));
    await _load();
  }

  Future<void> update(UserWidget w) async {
    await _repo.update(w);
    await _load();
  }

  Future<void> delete(int id) async {
    await _repo.delete(id);
    await _load();
  }

  Future<void> reorder(int oldIndex, int newIndex) async {
    final list = [...state];
    if (oldIndex < 0 || oldIndex >= list.length) return;
    if (newIndex < 0 || newIndex > list.length) return;
    final item = list.removeAt(oldIndex);
    list.insert(newIndex, item);
    final reordered = [
      for (var i = 0; i < list.length; i++) list[i].copyWith(position: i),
    ];
    for (final w in reordered) {
      await _repo.update(w);
    }
    state = reordered;
  }
}
