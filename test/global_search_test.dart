import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:qalqul/core/utils/search.dart';
import 'package:qalqul/features/search/global_search.dart';
import 'package:qalqul/l10n/l10n.dart';

import 'helpers/pump_localized.dart';

SearchResult _result(
  String type,
  String id,
  String title, {
  String subtitle = '',
  Map<String, dynamic> payload = const {},
}) =>
    SearchResult(
      type: type,
      id: id,
      title: title,
      subtitle: subtitle,
      payload: payload,
    );

/// A complete `Note.toMap()` payload: the editor is built from it, so partial
/// maps would crash the navigation under test.
Map<String, dynamic> _notePayload(String title) => {
      'id': 1,
      'title': title,
      'body': 'body of $title',
      'is_favorite': 0,
      'is_markdown': 0,
      'created_at': 0,
      'updated_at': 0,
    };

List<SearchResult> _fixture() => [
      _result('note', '1', 'Groceries plan',
          subtitle: 'milk, bread', payload: {'note': _notePayload('Groceries plan')}),
      _result('note', '2', 'Budget ideas',
          subtitle: 'sinking funds', payload: {'note': _notePayload('Budget ideas')}),
      _result('transaction', '3', 'Food',
          subtitle: 'raw', payload: {
            'transaction': {'kind': 'spending', 'amount': 24.5}
          }),
      _result('budget', '4', 'Emergency fund',
          subtitle: 'raw', payload: {
            'budget': {'targetAmount': 1000.0}
          }),
    ];

void main() {
  late L10n l10n;

  setUpAll(() async {
    l10n = await L10n.delegate.load(const Locale('en'));
  });

  /// Opens the delegate over a harness route, so `showSearch` has a Navigator.
  Future<void> openSearch(
    WidgetTester tester,
    SearchRunner runner,
  ) async {
    await pumpLocalized(
      tester,
      Builder(
        builder: (context) => Scaffold(
          body: Center(
            child: ElevatedButton(
              onPressed: () =>
                  showSearch<void>(context: context, delegate: GlobalSearch(runner: runner)),
              child: const Text('open'),
            ),
          ),
        ),
      ),
    );
    await tester.tap(find.text('open'));
    await tester.pumpAndSettle();
  }

  /// Types [text], applies the frame that re-arms the debounce, then lets the
  /// debounce elapse and the results render.
  Future<void> type(WidgetTester tester, String text) async {
    await tester.enterText(find.byType(TextField), text);
    await tester.pump();
    await tester.pump(kSearchDebounce);
    await tester.pumpAndSettle();
  }

  group('GlobalSearch', () {
    testWidgets('an empty query shows a hint and never hits the database',
        (tester) async {
      var calls = 0;
      await openSearch(tester, () async {
        calls++;
        return _fixture();
      });

      expect(find.text(l10n.searchStartTyping), findsOneWidget);
      expect(calls, 0);
    });

    testWidgets('groups results by type', (tester) async {
      await openSearch(tester, () async => _fixture());

      await type(tester, 'e');

      expect(find.text(l10n.searchGroupNotes), findsOneWidget);
      expect(find.text(l10n.searchGroupBudgets), findsOneWidget);
      expect(find.text('Groceries plan'), findsOneWidget);
      expect(find.text('Emergency fund'), findsOneWidget);
      // No investment in the fixture, so no header for it.
      expect(find.text(l10n.searchGroupInvestments), findsNothing);
    });

    testWidgets('subtitles are formatted, not raw numbers', (tester) async {
      await openSearch(tester, () async => _fixture());
      await type(tester, 'Emergency');

      // '$1000.0' would be the unformatted payload leaking into the UI.
      expect(find.textContaining(r'$1,000.00'), findsOneWidget);
    });

    testWidgets('a query that matches nothing says so', (tester) async {
      await openSearch(tester, () async => _fixture());
      await type(tester, 'zzzz');

      expect(find.text('Nothing matches “zzzz”'), findsOneWidget);
      expect(find.byIcon(Icons.search_off), findsOneWidget);
    });

    testWidgets('debounces typing into a single database read', (tester) async {
      var calls = 0;
      await openSearch(tester, () async {
        calls++;
        return _fixture();
      });

      final field = find.byType(TextField);
      for (final part in ['g', 'gr', 'gro']) {
        await tester.enterText(field, part);
        await tester.pump();
        await tester.pump(const Duration(milliseconds: 100));
      }
      // Every keystroke restarted the debounce, so nothing was queried yet.
      expect(calls, 0);

      await tester.pump(kSearchDebounce);
      await tester.pumpAndSettle();
      expect(calls, 1);

      // Further keystrokes reuse the cached snapshot.
      await type(tester, 'groceries plan');
      expect(calls, 1);
      expect(find.text('Groceries plan'), findsOneWidget);
    });

    testWidgets('clearing the query goes back to the hint', (tester) async {
      await openSearch(tester, () async => _fixture());

      await type(tester, 'e');
      expect(find.text(l10n.searchGroupNotes), findsOneWidget);

      await type(tester, '');
      expect(find.text(l10n.searchStartTyping), findsOneWidget);
    });

    testWidgets('reports a failed lookup instead of hanging on a spinner',
        (tester) async {
      await openSearch(tester, () async => throw StateError('db down'));

      await type(tester, 'e');

      expect(find.text(l10n.searchFailed), findsOneWidget);
    });

    testWidgets('a search hit opens the editor', (tester) async {
      await openSearch(tester, () async => _fixture());
      await type(tester, 'Groceries');

      await tester.tap(find.text('Groceries plan'));
      await tester.pumpAndSettle();

      // The delegate closed and the editor came up on the root navigator.
      expect(find.text(l10n.searchStartTyping), findsNothing);
      expect(find.text('Groceries plan'), findsWidgets);
    });
  });
}
