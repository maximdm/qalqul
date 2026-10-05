import 'package:qalqul/core/db/database_helper.dart';
import 'package:qalqul/features/finance/budgets_repository.dart';
import 'package:qalqul/features/finance/investments_repository.dart';
import 'package:qalqul/features/finance/transactions_repository.dart';
import 'package:qalqul/features/notes/notes_repository.dart';

class SearchResult {
  final String type;
  final String id;
  final String title;
  final String subtitle;
  final Map<String, dynamic> payload;

  const SearchResult({
    required this.type,
    required this.id,
    required this.title,
    required this.subtitle,
    required this.payload,
  });

  @override
  bool operator ==(Object other) =>
      other is SearchResult &&
      other.type == type &&
      other.id == id &&
      other.title == title &&
      other.subtitle == subtitle;

  @override
  int get hashCode =>
      Object.hash(type, id, title, subtitle);
}

List<SearchResult> filterResults(List<SearchResult> all, String query) {
  final q = query.trim().toLowerCase();
  if (q.isEmpty) return all;
  return all.where((r) {
    return r.title.toLowerCase().contains(q) ||
        r.subtitle.toLowerCase().contains(q);
  }).toList();
}

Future<List<SearchResult>> globalSearch(String query) async {
  await DatabaseHelper.instance.database;
  final results = <SearchResult>[];

  final notes = await NotesRepository().getAll();
  for (final n in notes) {
    results.add(SearchResult(
      type: 'note',
      id: n.id!.toString(),
      title: n.title,
      subtitle: n.preview,
      payload: {'note': n.toMap()},
    ));
  }

  final transactions = await TransactionsRepository().getAll();
  for (final t in transactions) {
    results.add(SearchResult(
      type: 'transaction',
      id: t.id!.toString(),
      title: t.category.isEmpty ? t.kind : t.category,
      subtitle: '${t.kind} · ${t.amount} ${t.note}',
      payload: {'transaction': t.toMap()},
    ));
  }

  final investments = await InvestmentsRepository().getAll();
  for (final i in investments) {
    results.add(SearchResult(
      type: 'investment',
      id: i.id!.toString(),
      title: i.name,
      subtitle: 'Principal ${i.principal} · Value ${i.currentValue}',
      payload: {'investment': i.toMap()},
    ));
  }

  final budgets = await BudgetsRepository().getAll();
  for (final b in budgets) {
    results.add(SearchResult(
      type: 'budget',
      id: b.id!.toString(),
      title: b.name,
      subtitle: 'Target ${b.targetAmount} · Saved ${b.savedAmount}',
      payload: {'budget': b.toMap()},
    ));
  }

  return filterResults(results, query);
}
