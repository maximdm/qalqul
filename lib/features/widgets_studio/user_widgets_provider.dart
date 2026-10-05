import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:qalqul/core/models/user_widget.dart';
import 'package:qalqul/features/widgets_studio/user_widgets_repository.dart';

final userWidgetsProvider =
    AsyncNotifierProvider<UserWidgetsNotifier, List<UserWidget>>(
  UserWidgetsNotifier.new,
);

/// The dashboard layout, loaded in `build()`. See [TransactionsNotifier] for why
/// this is async rather than a `Notifier` that returns an empty list and loads
/// behind the UI.
class UserWidgetsNotifier extends AsyncNotifier<List<UserWidget>> {
  final _repo = UserWidgetsRepository();

  @override
  Future<List<UserWidget>> build() => _repo.getAll();

  /// Re-reads the table without passing through a loading state, so a write
  /// does not blank the dashboard that triggered it.
  Future<void> _reload() async {
    final items = await _repo.getAll();
    if (!ref.mounted) return;
    state = AsyncData(items);
  }

  Future<void> add(UserWidget w) async {
    final next = state.value?.length ?? 0;
    await _repo.insert(w.copyWith(position: next));
    await _reload();
  }

  Future<void> save(UserWidget w) async {
    await _repo.update(w);
    await _reload();
  }

  Future<void> delete(int id) async {
    await _repo.delete(id);
    await _reload();
  }

  /// Persists a drag-and-drop reorder.
  ///
  /// The reordered list is published immediately, without a loading state, so
  /// the tiles do not snap back to their old positions while the writes land.
  Future<void> reorder(int oldIndex, int newIndex) async {
    final list = [...?state.value];
    if (oldIndex < 0 || oldIndex >= list.length) return;
    if (newIndex < 0 || newIndex > list.length) return;
    final item = list.removeAt(oldIndex);
    list.insert(newIndex, item);
    final reordered = [
      for (var i = 0; i < list.length; i++) list[i].copyWith(position: i),
    ];
    if (!ref.mounted) return;
    state = AsyncData(reordered);
    for (final w in reordered) {
      await _repo.update(w);
    }
  }
}
