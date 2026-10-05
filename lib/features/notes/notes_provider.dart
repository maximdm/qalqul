import 'package:flutter/foundation.dart' show listEquals;
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:qalqul/core/models/note.dart';
import 'package:qalqul/features/notes/notes_repository.dart';

class NotesState {
  final List<Note> notes;
  final String query;

  const NotesState({this.notes = const [], this.query = ''});

  NotesState copyWith({List<Note>? notes, String? query}) => NotesState(
        notes: notes ?? this.notes,
        query: query ?? this.query,
      );
}

final notesProvider =
    NotifierProvider<NotesNotifier, NotesState>(NotesNotifier.new);

class NotesNotifier extends Notifier<NotesState> {
  final _repo = NotesRepository();

  @override
  NotesState build() {
    _load();
    return const NotesState();
  }

  Future<void> _load() async {
    final notes = await _repo.getAll();
    // The provider can be disposed while the query is in flight (screen
    // teardown, a test container going away); reading state then throws.
    if (!ref.mounted) return;
    // Element-wise: `List ==` is identity-based, so comparing the lists
    // directly would always report a change and rebuild every note consumer
    // on each load.
    if (!listEquals(state.notes, notes)) state = state.copyWith(notes: notes);
  }

  Future<void> add(Note note) async {
    await _repo.insert(note);
    await _load();
  }

  Future<void> update(Note note) async {
    await _repo.update(note);
    await _load();
  }

  Future<void> delete(int id) async {
    await _repo.delete(id);
    await _load();
  }

  Future<void> toggleFavorite(Note note) async {
    await update(
      note.copyWith(
        isFavorite: !note.isFavorite,
        updatedAt: DateTime.now().millisecondsSinceEpoch,
      ),
    );
  }

  void setQuery(String q) => state = state.copyWith(query: q);
}
