import 'dart:async';

import 'package:flutter/material.dart';
import 'package:qalqul/core/models/budget.dart';
import 'package:qalqul/core/models/investment.dart';
import 'package:qalqul/core/models/note.dart';
import 'package:qalqul/core/models/transaction.dart';
import 'package:qalqul/core/utils/money.dart';
import 'package:qalqul/core/utils/search.dart';
import 'package:qalqul/features/finance/budget/budget_editor_screen.dart';
import 'package:qalqul/features/finance/investments/investment_editor_screen.dart';
import 'package:qalqul/features/finance/transaction_editor_screen.dart';
import 'package:qalqul/features/notes/note_editor_screen.dart';
import 'package:qalqul/l10n/l10n.dart';

/// How long to wait after the last keystroke before querying.
const Duration kSearchDebounce = Duration(milliseconds: 180);

/// Upper bound on rendered rows, so a huge database doesn't build thousands of
/// tiles for one keystroke.
const int kSearchResultLimit = 100;

/// Fetches every searchable row. Injectable so the UI can be tested without a
/// database.
typedef SearchRunner = Future<List<SearchResult>> Function();

/// App-wide search.
///
/// Reads the whole database once, then filters it in memory: typing stays
/// instant instead of running four `SELECT *`s per keystroke.
class GlobalSearch extends SearchDelegate<void> {
  GlobalSearch({this.runner});

  final SearchRunner? runner;

  /// The navigator captured while the search route is still alive. Pushing
  /// after [close] with the delegate's own context would use a defunct
  /// element, so every result opens through this instead.
  NavigatorState? _navigator;

  @override
  List<Widget>? buildActions(BuildContext context) => [
        if (query.isNotEmpty)
          IconButton(
            icon: const Icon(Icons.clear),
            tooltip: MaterialLocalizations.of(context).deleteButtonTooltip,
            onPressed: () => query = '',
          ),
      ];

  @override
  Widget? buildLeading(BuildContext context) => IconButton(
        icon: const Icon(Icons.arrow_back),
        tooltip: MaterialLocalizations.of(context).backButtonTooltip,
        onPressed: () => close(context, null),
      );

  @override
  Widget buildResults(BuildContext context) => _SearchResults(
        query: query,
        navigator: _navigatorOf(context),
        onClose: () => close(context, null),
        runner: runner,
      );

  @override
  Widget buildSuggestions(BuildContext context) => _SearchResults(
        query: query,
        navigator: _navigatorOf(context),
        onClose: () => close(context, null),
        runner: runner,
      );

  NavigatorState _navigatorOf(BuildContext context) =>
      _navigator ??= Navigator.of(context, rootNavigator: true);
}

/// Debounced, cached, grouped result list.
class _SearchResults extends StatefulWidget {
  const _SearchResults({
    required this.query,
    required this.navigator,
    required this.onClose,
    this.runner,
  });

  final String query;
  final NavigatorState navigator;
  final VoidCallback onClose;
  final SearchRunner? runner;

  @override
  State<_SearchResults> createState() => _SearchResultsState();
}

class _SearchResultsState extends State<_SearchResults> {
  Timer? _debounce;

  /// Every searchable row, loaded once and then filtered locally.
  List<SearchResult>? _all;

  bool _loading = false;
  Object? _error;

  @override
  void initState() {
    super.initState();
    _schedule();
  }

  @override
  void didUpdateWidget(_SearchResults oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.query != widget.query) _schedule();
  }

  @override
  void dispose() {
    _debounce?.cancel();
    super.dispose();
  }

  void _schedule() {
    _debounce?.cancel();
    if (widget.query.trim().isEmpty) return;
    _debounce = Timer(kSearchDebounce, _load);
  }

  Future<void> _load() async {
    if (!mounted) return;
    setState(() {
      _loading = true;
      _error = null;
    });
    try {
      final runner = widget.runner ?? () => globalSearch('');
      _all ??= await runner();
      if (!mounted) return;
      setState(() => _loading = false);
    } on Object catch (e) {
      if (!mounted) return;
      setState(() {
        _loading = false;
        _error = e;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    final q = widget.query.trim();

    if (q.isEmpty) {
      return _Message(icon: Icons.search, text: l10n.searchStartTyping);
    }
    if (_error != null) {
      return _Message(icon: Icons.error_outline, text: l10n.searchFailed);
    }
    if (_all == null) {
      return Center(
        child: CircularProgressIndicator(value: _loading ? null : 0),
      );
    }

    final matches = filterResults(_all!, q);
    if (matches.isEmpty) {
      return _Message(
        icon: Icons.search_off,
        text: l10n.searchNoMatchesFor(q),
        detail: l10n.searchNoMatches,
      );
    }

    final visible =
        matches.take(kSearchResultLimit).toList(growable: false);
    final hidden = matches.length - visible.length;
    final groups = <String, List<SearchResult>>{};
    for (final r in visible) {
      groups.putIfAbsent(r.type, () => []).add(r);
    }

    return ListView(
      children: [
        for (final entry in groups.entries) ...[
          _SectionHeader(label: _sectionLabel(entry.key, l10n)),
          for (final r in entry.value)
            ListTile(
              leading: _icon(entry.key),
              title: Text(r.title, maxLines: 1, overflow: TextOverflow.ellipsis),
              subtitle: _subtitle(entry.key, r),
              onTap: () => _open(r),
            ),
        ],
        if (hidden > 0)
          Padding(
            padding: const EdgeInsets.all(16),
            child: Text(
              l10n.searchMoreResults(hidden),
              textAlign: TextAlign.center,
              style: Theme.of(context).textTheme.bodySmall,
            ),
          ),
      ],
    );
  }

  static String _sectionLabel(String type, L10n l10n) => switch (type) {
        'note' => l10n.searchGroupNotes,
        'transaction' => l10n.searchGroupTransactions,
        'investment' => l10n.searchGroupInvestments,
        'budget' => l10n.searchGroupBudgets,
        _ => l10n.searchGroupOther,
      };

  /// Rows are opened through the captured navigator, because the search route
  /// is gone by the time the push happens.
  void _open(SearchResult r) {
    final navigator = widget.navigator;
    widget.onClose();
    switch (r.type) {
      case 'note':
        navigator.push(MaterialPageRoute(
          builder: (_) => NoteEditorScreen(
            note: Note.fromMap(r.payload['note'] as Map<String, dynamic>),
          ),
        ));
      case 'transaction':
        final t = AppTransaction.fromMap(
            r.payload['transaction'] as Map<String, dynamic>);
        navigator.push(MaterialPageRoute(
          builder: (context) => TransactionEditorScreen(
            kind: t.kind,
            transaction: t,
            categoryLabel: t.kind == 'credit'
                ? context.l10n.creditLender
                : context.l10n.commonCategory,
            dateLabel:
                t.kind == 'credit' ? context.l10n.creditDueDate : context.l10n.commonDate,
          ),
        ));
      case 'investment':
        navigator.push(MaterialPageRoute(
          builder: (_) => InvestmentEditorScreen(
            investment: Investment.fromMap(
                r.payload['investment'] as Map<String, dynamic>),
          ),
        ));
      case 'budget':
        navigator.push(MaterialPageRoute(
          builder: (_) => BudgetEditorScreen(
            budget: Budget.fromMap(r.payload['budget'] as Map<String, dynamic>),
          ),
        ));
    }
  }

  Widget? _subtitle(String type, SearchResult r) {
    final l10n = context.l10n;
    final text = switch (type) {
      'note' => r.subtitle,
      'transaction' =>
        '${_kindLabel(r, l10n)} · ${formatMoney(_amountOf(r))}',
      'investment' => l10n.investmentsPrincipal(
        formatMoney(_amountOf(r, key: 'principal')),
      ),
      'budget' =>
        '${l10n.budgetTargetField}: ${formatMoney(_amountOf(r, key: 'targetAmount'))}',
      _ => r.subtitle,
    };
    if (text.isEmpty) return null;
    return Text(text, maxLines: 1, overflow: TextOverflow.ellipsis);
  }

  static String _kindLabel(SearchResult r, L10n l10n) {
    final kind = r.payload['transaction'] is Map
        ? (r.payload['transaction'] as Map)['kind'] as String? ?? ''
        : '';
    return kind == 'credit' ? l10n.financeTabCredit : l10n.financeTabSpending;
  }

  /// Money values are read off the payload, which keeps formatting out of the
  /// repositories and lets the UI pick a currency.
  static double _amountOf(SearchResult r, {String key = 'amount'}) {
    final payload = r.payload[r.type];
    if (payload is! Map) return 0;
    final raw = payload[key];
    return raw is num ? raw.toDouble() : 0;
  }

  static Icon _icon(String type) => switch (type) {
        'note' => const Icon(Icons.note),
        'transaction' => const Icon(Icons.receipt),
        'investment' => const Icon(Icons.trending_up),
        'budget' => const Icon(Icons.savings),
        _ => const Icon(Icons.search),
      };
}

/// Non-interactive heading above one group of results.
class _SectionHeader extends StatelessWidget {
  const _SectionHeader({required this.label});

  final String label;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 20, 16, 4),
      child: Text(
        label,
        style: theme.textTheme.labelMedium
            ?.copyWith(color: theme.colorScheme.primary),
      ),
    );
  }
}

/// Centred icon + label used for the empty, loading-failed and no-hit states.
class _Message extends StatelessWidget {
  const _Message({required this.icon, required this.text, this.detail});

  final IconData icon;
  final String text;
  final String? detail;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(icon, size: 48, color: theme.colorScheme.outline),
            const SizedBox(height: 16),
            Text(
              text,
              textAlign: TextAlign.center,
              style: theme.textTheme.titleSmall,
            ),
            if (detail != null) ...[
              const SizedBox(height: 6),
              Text(
                detail!,
                textAlign: TextAlign.center,
                style: theme.textTheme.bodySmall
                    ?.copyWith(color: theme.colorScheme.outline),
              ),
            ],
          ],
        ),
      ),
    );
  }
}
