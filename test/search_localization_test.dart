import 'package:flutter/material.dart';
import 'package:flutter_riverpod/misc.dart' show Override;
import 'package:flutter_test/flutter_test.dart';

import 'package:qalqul/core/db/database_helper.dart';
import 'package:qalqul/core/models/note.dart';
import 'package:qalqul/core/utils/search.dart';
import 'package:qalqul/features/finance/transaction_editor_screen.dart';
import 'package:qalqul/features/notes/notes_repository.dart';
import 'package:qalqul/shared/providers/settings_provider.dart';

import 'helpers/fake_settings.dart';
import 'helpers/pump_localized.dart';

/// Comfortably longer than the 80-character display preview, so a match here
/// can only come from the full body.
final _longBody = '${'filler ' * 20}needle';

void main() {
  setUpAll(() async {
    await DatabaseHelper.useTestDatabase();
  });

  tearDown(() async {
    final db = await DatabaseHelper.instance.database;
    for (final t in ['notes', 'transactions', 'app_settings']) {
      await db.delete(t);
    }
  });

  group('globalSearch reaches the whole note body', () {
    test('finds a term past the 80-character preview', () async {
      await NotesRepository().insert(Note(
        title: 'Groceries',
        body: _longBody,
        createdAt: 1,
        updatedAt: 1,
      ));

      final hits = await globalSearch('needle');
      expect(hits.where((r) => r.type == 'note'), hasLength(1));
    });

    test('exposes the full body as searchText, not the preview', () async {
      await NotesRepository().insert(Note(
        title: 'Groceries',
        body: _longBody,
        createdAt: 1,
        updatedAt: 1,
      ));

      final note = (await globalSearch('needle')).firstWhere((r) => r.type == 'note');
      expect(note.subtitle.length, lessThanOrEqualTo(81));
      expect(note.searchText, contains('needle'));
    });

    test('matches plain words inside a markdown note', () async {
      await NotesRepository().insert(Note(
        title: 'Notes',
        body: '# Heading\n\nRemember to buy **milk** today',
        isMarkdown: true,
        createdAt: 1,
        updatedAt: 1,
      ));

      expect((await globalSearch('milk')).where((r) => r.type == 'note'),
          hasLength(1));
    });
  });

  group('TransactionEditorScreen labels', () {
    final List<Override> overrides = [
      settingsProvider.overrideWith(() => FakeSettings()),
    ];

    testWidgets('derives spending labels from the locale', (tester) async {
      await pumpLocalized(
        tester,
        const TransactionEditorScreen(kind: 'spending'),
        overrides: overrides,
      );

      expect(find.text('Category'), findsOneWidget);
      expect(find.text('Date'), findsOneWidget);
    });

    testWidgets('derives credit labels from the kind', (tester) async {
      await pumpLocalized(
        tester,
        const TransactionEditorScreen(kind: 'credit'),
        overrides: overrides,
      );

      expect(find.text('Lender'), findsOneWidget);
      expect(find.text('Due date'), findsOneWidget);
    });

    testWidgets('translates the derived labels', (tester) async {
      await pumpLocalized(
        tester,
        const TransactionEditorScreen(kind: 'spending'),
        overrides: overrides,
        locale: const Locale('es'),
      );

      expect(find.text('Categoría'), findsOneWidget);
      expect(find.text('Fecha'), findsOneWidget);
      // The old hardcoded English defaults must not appear.
      expect(find.text('Category'), findsNothing);
      expect(find.text('Date'), findsNothing);
    });

    testWidgets('honours explicit overrides', (tester) async {
      await pumpLocalized(
        tester,
        const TransactionEditorScreen(
          kind: 'spending',
          categoryLabel: 'Merchant',
          dateLabel: 'When',
        ),
        overrides: overrides,
      );

      expect(find.text('Merchant'), findsOneWidget);
      expect(find.text('When'), findsOneWidget);
    });
  });
}