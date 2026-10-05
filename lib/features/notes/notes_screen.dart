import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';
import 'package:qalqul/core/models/note.dart';
import 'package:qalqul/features/notes/note_editor_screen.dart';
import 'package:qalqul/features/notes/notes_provider.dart';
import 'package:qalqul/l10n/l10n.dart';
import 'package:qalqul/shared/widgets/app_bar.dart';
import 'package:qalqul/shared/widgets/empty_state.dart';
import 'package:qalqul/shared/widgets/load_state_views.dart';

class NotesScreen extends ConsumerWidget {
  const NotesScreen({super.key});

  /// The note list for the current search text.
  Widget _filtered(BuildContext context, NotesState state) {
    final l10n = context.l10n;
    final query = state.query.toLowerCase();
    final notes = query.isEmpty
        ? state.notes
        : state.notes
            .where(
              (n) =>
                  n.title.toLowerCase().contains(query) ||
                  n.plainBody.toLowerCase().contains(query),
            )
            .toList();

    return notes.isEmpty
        ? EmptyState(
            icon: Icons.note_alt_outlined,
            title: l10n.notesEmpty,
          )
        : ListView.builder(
            itemCount: notes.length,
            itemBuilder: (_, i) => _NoteTile(note: notes[i]),
          );
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = context.l10n;

    return Scaffold(
      appBar: QalqulAppBar(title: l10n.notesTitle),
      body: Column(
        children: [
          Padding(
            padding: const EdgeInsets.all(12),
            child: TextField(
              decoration: InputDecoration(
                hintText: l10n.notesSearchHint,
                prefixIcon: const Icon(Icons.search_outlined),
              ),
              onChanged: (v) => ref.read(notesProvider.notifier).setQuery(v),
            ),
          ),
          // The search field stays usable while the notes load: a query typed
          // now is kept by the notifier and applied when the load resolves.
          Expanded(
            child: ref.watch(notesProvider).when(
              loading: () => const LoadingView(),
              error: (error, _) => const LoadErrorView(),
              data: (state) => _filtered(context, state),
            ),
          ),
        ],
      ),
      floatingActionButton: FloatingActionButton(
        heroTag: 'notesScreenFAB',
        onPressed: () => Navigator.of(context).push(
          MaterialPageRoute(builder: (_) => const NoteEditorScreen()),
        ),
        child: const Icon(Icons.add),
      ),
    );
  }
}

class _NoteTile extends ConsumerWidget {
  final Note note;
  const _NoteTile({required this.note});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = context.l10n;
    final date = DateFormat.yMMMd().format(
      DateTime.fromMillisecondsSinceEpoch(note.updatedAt),
    );
    return ListTile(
      leading: IconButton(
        icon: Icon(
          note.isFavorite ? Icons.star : Icons.star_border,
          color: note.isFavorite ? Colors.amber : null,
        ),
        onPressed: () => ref.read(notesProvider.notifier).toggleFavorite(note),
      ),
      title: Row(
        children: [
          Expanded(
            child: Text(note.title.isEmpty ? l10n.notesUntitled : note.title),
          ),
          if (note.isMarkdown)
            const Icon(Icons.text_snippet_outlined, size: 16),
        ],
      ),
      subtitle: Text(
        '$date${note.preview.isNotEmpty ? '\n${note.preview}' : ''}',
      ),
      trailing: IconButton(
        icon: const Icon(Icons.delete_outline),
        onPressed: () => ref.read(notesProvider.notifier).delete(note.id!),
      ),
      onTap: () => Navigator.of(context).push(
        MaterialPageRoute(builder: (_) => NoteEditorScreen(note: note)),
      ),
    );
  }
}