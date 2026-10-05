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
    AsyncNotifierProvider<NotesNotifier, NotesState>(NotesNotifier.new);

/// Stored notes plus the search box's current text.
///
/// The notes load in `build()` and so arrive as an [AsyncValue]; the query is
/// typed into, so [setQuery] has to be able to write it before the notes land,
/// which is why the query lives beside them rather than inside the load.
class NotesNotifier extends AsyncNotifier<NotesState> {
  final _repo = NotesRepository();

  @override
  Future<NotesState> build() async {
    final notes = await _repo.getAll();
    return NotesState(notes: notes, query: _query);
  }

  String _query = '';

  /// Re-reads the notes without passing through a loading state, keeping the
  /// query the user has typed.
  Future<void> _reload() async {
    final notes = await _repo.getAll();
    if (!ref.mounted) return;
    // Element-wise: `List ==` is identity-based, so comparing the lists
    // directly would always report a change and rebuild every note consumer
    // on each load.
    final current = state.value;
    if (current != null && listEquals(current.notes, notes)) return;
    state = AsyncData(NotesState(notes: notes, query: _query));
  }

  Future<void> add(Note note) async {
    await _repo.insert(note);
    await _reload();
  }

  Future<void> save(Note note) async {
    await _repo.update(note);
    await _reload();
  }

  Future<void> delete(int id) async {
    await _repo.delete(id);
    await _reload();
  }

  Future<void> toggleFavorite(Note note) async {
    await save(
      note.copyWith(
        isFavorite: !note.isFavorite,
        updatedAt: DateTime.now().millisecondsSinceEpoch,
      ),
    );
  }

  /// Records the search text.
  ///
  /// Kept in a field as well as the state so a query typed while the notes are
  /// still loading is not lost when the load resolves.
  void setQuery(String q) {
    _query = q;
    final current = state.value;
    // Nothing loaded yet: `build()` will pick `_query` up when it resolves.
    if (current == null) return;
    state = AsyncData(current.copyWith(query: q));
  }
}
