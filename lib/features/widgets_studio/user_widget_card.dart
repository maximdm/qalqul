import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'package:qalqul/core/models/investment.dart';
import 'package:qalqul/core/models/transaction.dart';
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
    int Function(T) amountOf,
  ) =>
      sumRecords(ref, items, currencyOf, amountOf);

  /// Renders [content] only once every provider in [sources] has data.
  ///
  /// A dashboard card is a poor place for a full-screen spinner, but falling back
  /// to an empty list is worse: `$0 invested` or an empty list on a cold start
  /// reads as "you have nothing here" rather than "not loaded yet". So a card
  /// shows a quiet placeholder until it knows the real answer.
  Widget _whenReady(
    Iterable<AsyncValue<Object?>> sources,
    Widget Function() content,
  ) {
    if (sources.any((s) => s.hasError)) return const _CardError();
    if (sources.any((s) => s.isLoading)) return const _CardPlaceholder();
    return content();
  }

  Widget _noteSummary(BuildContext context, WidgetRef ref) {
    final l10n = context.l10n;
    final notes = ref.watch(notesProvider);
    return _whenReady([notes], () {
      final recent = notes.requireValue.notes.take(3).toList();
      if (recent.isEmpty) return Text(l10n.widgetNoteEmpty);
      return ListView(
        shrinkWrap: true,
        physics: const NeverScrollableScrollPhysics(),
        children: [
          for (final n in recent)
            Padding(
              padding: const EdgeInsets.symmetric(vertical: 2),
              child: Text(
                  '• ${n.title.isEmpty ? l10n.notesUntitled : n.title}'),
            ),
        ],
      );
    });
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
    return _whenReady(
      [inv, tx],
      () => _financeOverviewBody(context, ref, inv, tx),
    );
  }

  Widget _financeOverviewBody(
    BuildContext context,
    WidgetRef ref,
    AsyncValue<List<Investment>> inv,
    AsyncValue<List<AppTransaction>> tx,
  ) {
    final total = _sumInBase(inv.requireValue, ref,
        (i) => i.currency, (i) => i.currentValueMinor);
    final credit = _sumInBase(
      tx.requireValue.where((t) => t.kind == 'credit'),
      ref,
      (t) => t.currency,
      (t) => t.amountMinor,
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
    return _whenReady([tx], () {
      final spending =
          tx.requireValue.where((t) => t.kind == 'spending');
      final total = _sumInBase(
        spending,
        ref,
        (t) => t.currency,
        (t) => t.amountMinor,
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
    });
  }

  Widget _netWorth(BuildContext context, WidgetRef ref) {
    final inv = ref.watch(investmentsProvider);
    final tx = ref.watch(transactionsProvider);
    return _whenReady([inv, tx], () {
      final assets = _sumInBase(inv.requireValue, ref,
          (i) => i.currency, (i) => i.currentValueMinor);
      final credit = _sumInBase(
        tx.requireValue.where((t) => t.kind == 'credit'),
        ref,
        (t) => t.currency,
        (t) => t.amountMinor,
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
              formatInBase(ref, assets.minor),
              formatInBase(ref, credit.minor),
            ),
            style: theme.textTheme.labelSmall,
          ),
        ],
      );
    });
  }

  Widget _monthSpend(BuildContext context, WidgetRef ref) {
    final tx = ref.watch(transactionsProvider);
    final window = monthWindow(DateTime.now(), offset: widget.monthOffset);
    final category = widget.category;
    return _whenReady([tx], () {
      final entries = tx.requireValue.where(
        (t) =>
            t.kind == 'spending' &&
            within(t.date, window) &&
            (category.isEmpty || t.category == category),
      );
      if (entries.isEmpty) {
        return Text(context.l10n.widgetMonthSpendEmpty);
      }
      final total =
          _sumInBase(entries, ref, (t) => t.currency, (t) => t.amountMinor);
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
    });
  }

  Widget _portfolioValue(BuildContext context, WidgetRef ref) {
    final inv = ref.watch(investmentsProvider);
    return _whenReady([inv], () {
      final holdings = inv.requireValue;
      if (holdings.isEmpty) return Text(context.l10n.widgetPortfolioEmpty);
      final value = _sumInBase(
          holdings, ref, (i) => i.currency, (i) => i.currentValueMinor);
      final cost = _sumInBase(
          holdings, ref, (i) => i.currency, (i) => i.principalMinor);
      // Gain and percentage come off the converted figures only; a holding with
      // no rate path is flagged on [value] instead of skewing the return.
      final gain = value.minor - cost.minor;
      final pct = cost.minor > 0 ? gain / cost.minor * 100 : 0.0;
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
            context.l10n.widgetPortfolioCount(holdings.length),
            style: theme.textTheme.labelSmall,
          ),
        ],
      );
    });
  }

  Widget _billsDue(BuildContext context, WidgetRef ref) {
    final tx = ref.watch(transactionsProvider);
    return _whenReady([tx], () {
      final now = DateTime.now();
      final withinDays = widget.billsWithinDays;
      final due = tx.requireValue
          .where((t) => t.isRecurring && t.nextDue > 0)
          .where((t) {
            final days =
                daysBetween(now, DateTime.fromMillisecondsSinceEpoch(t.nextDue));
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
                  t.amountMinor,
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
    });
  }

  String _dueLabel(L10n l10n, DateTime now, int nextDue) {
    final days = daysBetween(now, DateTime.fromMillisecondsSinceEpoch(nextDue));
    if (days < 0) return l10n.widgetBillsOverdue;
    return l10n.widgetBillsDueIn(days);
  }
}

/// Neutral stand-in for a dashboard card whose data is still loading.
///
/// Deliberately not an indeterminate progress indicator. Cards sit several to a
/// grid, so a looping animation is visual noise at best; it also never settles,
/// which makes `pumpAndSettle` time out in any widget test that boots the
/// dashboard. A static skeleton bar conveys the same "not ready yet" without
/// either problem.
class _CardPlaceholder extends StatelessWidget {
  const _CardPlaceholder();

  @override
  Widget build(BuildContext context) => Align(
        alignment: Alignment.topLeft,
        child: Padding(
          padding: const EdgeInsets.symmetric(vertical: 10),
          child: Container(
            height: 10,
            width: 96,
            decoration: BoxDecoration(
              color: Theme.of(context).colorScheme.outlineVariant,
              borderRadius: BorderRadius.circular(5),
            ),
          ),
        ),
      );
}

/// Failure state for a single card. See [LoadErrorView] for why the error itself
/// is not rendered.
class _CardError extends StatelessWidget {
  const _CardError();

  @override
  Widget build(BuildContext context) => Align(
        alignment: Alignment.topLeft,
        child: Text(
          context.l10n.commonLoadFailed,
          style: Theme.of(context).textTheme.bodySmall,
        ),
      );
}