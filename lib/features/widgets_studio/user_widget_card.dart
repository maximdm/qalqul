import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'package:qalqul/core/models/user_widget.dart';
import 'package:qalqul/core/utils/money.dart';
import 'package:qalqul/core/utils/periods.dart';
import 'package:qalqul/features/calculator/calculator_screen.dart';
import 'package:qalqul/features/finance/currency_provider.dart';
import 'package:qalqul/features/finance/investments_provider.dart';
import 'package:qalqul/features/finance/transactions_provider.dart';
import 'package:qalqul/features/notes/notes_provider.dart';
import 'package:qalqul/l10n/l10n.dart';
import 'package:qalqul/shared/widgets/bento_card.dart';
import 'package:qalqul/shared/widgets/money_text.dart';

/// Renders one dashboard widget. The [switch] here is the single place that maps
/// a `UserWidgetKind` to its renderer — the Widget Studio uses the same enum to
/// offer the kinds.
class UserWidgetCard extends ConsumerWidget {
  final UserWidget widget;
  const UserWidgetCard(this.widget, {super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final content = switch (UserWidgetKind.fromValue(widget.kind)) {
      UserWidgetKind.noteSummary => _noteSummary(context, ref),
      UserWidgetKind.calculator => _calculator(context),
      UserWidgetKind.financeOverview => _financeOverview(context, ref),
      UserWidgetKind.spendingChart => _spendingChart(context, ref),
      UserWidgetKind.netWorth => _netWorth(context, ref),
      UserWidgetKind.monthSpend => _monthSpend(context, ref),
      UserWidgetKind.portfolioValue => _portfolioValue(context, ref),
      UserWidgetKind.billsDue => _billsDue(context, ref),
    };

    return BentoCard(title: widget.title, child: content);
  }

  /// Sums `amountOf` across [items], converting each record out of its own
  /// currency first so mixed-currency totals add up in the base currency.
  /// Delegates to `sumRecords`, which reports any currency it could not convert.
  MoneyTotal _sumInBase<T>(
    Iterable<T> items,
    WidgetRef ref,
    String Function(T) currencyOf,
    double Function(T) amountOf,
  ) =>
      sumRecords(ref, items, currencyOf, amountOf);

  Widget _noteSummary(BuildContext context, WidgetRef ref) {
    final notes = ref.watch(notesProvider).notes;
    final l10n = context.l10n;
    final recent = notes.take(3).toList();
    if (recent.isEmpty) return Text(l10n.widgetNoteEmpty);
    return ListView(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      children: [
        for (final n in recent)
          Padding(
            padding: const EdgeInsets.symmetric(vertical: 2),
            child: Text('• ${n.title.isEmpty ? l10n.notesUntitled : n.title}'),
          ),
      ],
    );
  }

  Widget _calculator(BuildContext context) => Center(
        child: FilledButton.icon(
          icon: const Icon(Icons.calculate),
          label: Text(context.l10n.widgetOpen),
          onPressed: () => Navigator.of(context).push(
            MaterialPageRoute(builder: (_) => const CalculatorScreen()),
          ),
        ),
      );

  Widget _financeOverview(BuildContext context, WidgetRef ref) {
    final inv = ref.watch(investmentsProvider);
    final tx = ref.watch(transactionsProvider);
    final total = _sumInBase(inv, ref, (i) => i.currency, (i) => i.currentValue);
    final credit = _sumInBase(
      tx.where((t) => t.kind == 'credit'),
      ref,
      (t) => t.currency,
      (t) => t.amount,
    );
    final l10n = context.l10n;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        // Already combined into the base currency, so format directly; the
        // authoritative partial-total warning lives on the finance screens.
        Text(l10n.widgetInvested(total.format())),
        const SizedBox(height: 6),
        Text(
          l10n.widgetCredit(credit.format()),
          style: TextStyle(color: Theme.of(context).colorScheme.error),
        ),
      ],
    );
  }

  Widget _spendingChart(BuildContext context, WidgetRef ref) {
    final tx = ref.watch(transactionsProvider);
    final spending = tx.where((t) => t.kind == 'spending');
    final total = _sumInBase(
      spending,
      ref,
      (t) => t.currency,
      (t) => t.amount,
    );
    final theme = Theme.of(context);
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        Text(context.l10n.widgetSpent, style: theme.textTheme.bodySmall),
        MoneyTotalText(total, style: theme.textTheme.titleLarge),
      ],
    );
  }

  Widget _netWorth(BuildContext context, WidgetRef ref) {
    final inv = ref.watch(investmentsProvider);
    final tx = ref.watch(transactionsProvider);
    final assets = _sumInBase(inv, ref, (i) => i.currency, (i) => i.currentValue);
    final credit = _sumInBase(
      tx.where((t) => t.kind == 'credit'),
      ref,
      (t) => t.currency,
      (t) => t.amount,
    );
    // A currency missing from either side makes the subtraction meaningless, so
    // `minus` carries the unconverted amounts through to the warning.
    final net = assets.minus(credit);
    final theme = Theme.of(context);
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        Text(context.l10n.kindNetWorth, style: theme.textTheme.bodySmall),
        MoneyTotalText(net, style: theme.textTheme.titleLarge),
        const SizedBox(height: 6),
        Text(
          context.l10n.widgetAssetsCredit(
            formatInBase(ref, assets.amount),
            formatInBase(ref, credit.amount),
          ),
          style: theme.textTheme.labelSmall,
        ),
      ],
    );
  }

  Widget _monthSpend(BuildContext context, WidgetRef ref) {
    final tx = ref.watch(transactionsProvider);
    final window = monthWindow(DateTime.now(), offset: widget.monthOffset);
    final category = widget.category;
    final entries = tx.where(
      (t) =>
          t.kind == 'spending' &&
          within(t.date, window) &&
          (category.isEmpty || t.category == category),
    );
    if (entries.isEmpty) {
      return Text(context.l10n.widgetMonthSpendEmpty);
    }
    final total = _sumInBase(entries, ref, (t) => t.currency, (t) => t.amount);
    final theme = Theme.of(context);
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        Text(
          context.l10n.widgetMonthSpend,
          style: theme.textTheme.bodySmall,
        ),
        MoneyTotalText(total, style: theme.textTheme.titleLarge),
        if (category.isNotEmpty) ...[
          const SizedBox(height: 4),
          Text(category, style: theme.textTheme.labelSmall),
        ],
      ],
    );
  }

  Widget _portfolioValue(BuildContext context, WidgetRef ref) {
    final inv = ref.watch(investmentsProvider);
    if (inv.isEmpty) return Text(context.l10n.widgetPortfolioEmpty);
    final value = _sumInBase(inv, ref, (i) => i.currency, (i) => i.currentValue);
    final cost = _sumInBase(inv, ref, (i) => i.currency, (i) => i.principal);
    // Gain and percentage come off the converted figures only; a holding with
    // no rate path is flagged on [value] instead of skewing the return.
    final gain = value.amount - cost.amount;
    final pct = cost.amount > 0 ? gain / cost.amount * 100 : 0.0;
    final theme = Theme.of(context);
    final scheme = theme.colorScheme;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        Text(
          context.l10n.widgetPortfolioValue,
          style: theme.textTheme.bodySmall,
        ),
        MoneyTotalText(value, style: theme.textTheme.titleLarge),
        const SizedBox(height: 4),
        Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              gain >= 0 ? Icons.trending_up : Icons.trending_down,
              size: 14,
              color: gain >= 0 ? Colors.green : scheme.error,
            ),
            const SizedBox(width: 4),
            Text(
              '${gain >= 0 ? '+' : ''}${pct.toStringAsFixed(1)}%',
              style: theme.textTheme.bodySmall?.copyWith(
                color: gain >= 0 ? Colors.green : scheme.error,
              ),
            ),
          ],
        ),
        Text(
          context.l10n.widgetPortfolioCount(inv.length),
          style: theme.textTheme.labelSmall,
        ),
      ],
    );
  }

  Widget _billsDue(BuildContext context, WidgetRef ref) {
    final tx = ref.watch(transactionsProvider);
    final now = DateTime.now();
    final withinDays = widget.billsWithinDays;
    final due = tx
        .where((t) => t.isRecurring && t.nextDue > 0)
        .where((t) {
          final days = daysBetween(now, DateTime.fromMillisecondsSinceEpoch(t.nextDue));
          return days <= withinDays;
        })
        .toList()
      ..sort((a, b) => a.nextDue.compareTo(b.nextDue));

    if (due.isEmpty) return Text(context.l10n.widgetBillsEmpty);
    final l10n = context.l10n;
    final theme = Theme.of(context);
    return ListView(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      children: [
        for (final t in due.take(4)) ...[
          Row(
            children: [
              Expanded(
                child: Text(
                  t.category.isEmpty ? l10n.commonCategory : t.category,
                  overflow: TextOverflow.ellipsis,
                  style: theme.textTheme.bodySmall,
                ),
              ),
              const SizedBox(width: 8),
              MoneyText(
                t.amount,
                from: t.currency,
                style: theme.textTheme.bodySmall,
              ),
            ],
          ),
          Text(
            _dueLabel(l10n, now, t.nextDue),
            style: theme.textTheme.labelSmall,
          ),
          const SizedBox(height: 6),
        ],
      ],
    );
  }

  String _dueLabel(L10n l10n, DateTime now, int nextDue) {
    final days = daysBetween(now, DateTime.fromMillisecondsSinceEpoch(nextDue));
    if (days < 0) return l10n.widgetBillsOverdue;
    return l10n.widgetBillsDueIn(days);
  }
}