import 'package:qalqul/core/models/note.dart';
import 'package:qalqul/core/models/transaction.dart';
import 'package:qalqul/core/models/user_widget.dart';
import 'package:qalqul/core/utils/money.dart';
import 'package:qalqul/features/notes/notes_repository.dart';
import 'package:qalqul/features/finance/transactions_repository.dart';
import 'package:qalqul/features/widgets_studio/user_widgets_repository.dart';

/// Title of the note [seedSampleData] creates, so it can be found (and deleted)
/// by hand if the user does not want it.
const String kSampleNoteTitle = 'Welcome to Qalqul';

/// The demo note body. It deliberately demonstrates the `=` trick — the feature
/// that is otherwise invisible until you find it.
const String kSampleNoteBody = '''
# Welcome to Qalqul

End a line with `=` and Qalqul evaluates it while you type. Variables defined on
earlier lines are available too.

## A monthly budget

income = 3200
rent = 1200
bills = 380
left = income - rent - bills =

## Markdown works as well

- **Bold**, *italic* and `code`
- Lists like this one
- [Links](https://flutter.dev) too

Open this note and press the `=` button, or keep typing a new `…=` line.
''';

/// Inserts the demo widgets, note and a couple of transactions so the dashboard
/// isn't empty on a fresh install.
///
/// Returns `false` when there is already user data, in which case nothing is
/// written — the tour never overwrites a real database. Everything it creates is
/// ordinary data: it shows up in the lists and can be deleted like any other row.
Future<bool> seedSampleData() async {
  final widgets = UserWidgetsRepository();
  if ((await widgets.getAll()).isNotEmpty) return false;

  final notes = NotesRepository();
  if ((await notes.getAll()).isNotEmpty) return false;

  final transactions = TransactionsRepository();
  if ((await transactions.getAll()).isNotEmpty) return false;

  final now = DateTime.now();
  final nowMs = now.millisecondsSinceEpoch;
  final daysAgo = now.subtract(const Duration(days: 1)).millisecondsSinceEpoch;

  // Widgets first: `position` defines the dashboard order.
  final sampleWidgets = [
    const UserWidget(
      kind: 'noteSummary',
      title: 'Recent notes',
      config: {'size': 'l'},
      position: 0,
    ),
    const UserWidget(
      kind: 'calculator',
      title: 'Quick calc',
      config: {'size': 's'},
      position: 1,
    ),
    const UserWidget(
      kind: 'monthSpend',
      title: 'Spent this month',
      config: {'size': 'm', 'monthOffset': 0},
      position: 2,
    ),
    const UserWidget(
      kind: 'portfolioValue',
      title: 'Portfolio',
      config: {'size': 'm'},
      position: 3,
    ),
  ];
  for (final w in sampleWidgets) {
    await widgets.insert(w);
  }

  await notes.insert(Note(
    title: kSampleNoteTitle,
    body: kSampleNoteBody,
    isFavorite: true,
    isMarkdown: true,
    createdAt: nowMs,
    updatedAt: nowMs,
  ));

  await transactions.insert(AppTransaction(
    kind: 'credit',
    amountMinor: toMinor(3200, defaultCurrency),
    category: 'Salary',
    date: daysAgo,
    note: 'Monthly income',
    currency: defaultCurrency,
  ));
  await transactions.insert(AppTransaction(
    kind: 'spending',
    amountMinor: toMinor(24.5, defaultCurrency),
    category: 'Food',
    date: nowMs,
    note: 'Groceries',
    currency: defaultCurrency,
  ));

  return true;
}
