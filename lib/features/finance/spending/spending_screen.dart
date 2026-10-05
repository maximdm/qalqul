import 'package:fl_chart/fl_chart.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';
import 'package:qalqul/core/models/transaction.dart';
import 'package:qalqul/features/finance/chart_colors.dart';
import 'package:qalqul/features/finance/currency_provider.dart';
import 'package:qalqul/features/finance/transaction_editor_screen.dart';
import 'package:qalqul/features/finance/transactions_provider.dart';
import 'package:qalqul/l10n/l10n.dart';
import 'package:qalqul/shared/widgets/bento_card.dart';
import 'package:qalqul/shared/widgets/empty_state.dart';
import 'package:qalqul/shared/widgets/money_text.dart';

class SpendingScreen extends ConsumerWidget {
  const SpendingScreen({super.key});

  /// Recurring suffix shown under a transaction (e.g. `↻ monthly · due 3/9`).
  Widget _txSubtitle(BuildContext context, AppTransaction t) {
    final l10n = context.l10n;
    final parts = <String>[];
    if (t.note.isNotEmpty) parts.add(t.note);
    if (t.isRecurring) {
      final due = t.nextDue > 0
          ? DateTime.fromMillisecondsSinceEpoch(t.nextDue)
          : null;
      final dueStr =
          due != null ? DateFormat.Md().format(due) : '';
      parts.add('↻ ${t.recurrence}${dueStr.isNotEmpty ? ' · ${l10n.txRecurringDue(dueStr)}' : ''}');
    }
    return parts.isEmpty
        ? const SizedBox.shrink()
        : Text(parts.join(' · '), style: Theme.of(context).textTheme.bodySmall);
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = context.l10n;
    final all = ref.watch(transactionsProvider);
    final spending = all.where((t) => t.kind == 'spending').toList();
    final theme = Theme.of(context);

    final byCategory = <String, double>{};
    for (final t in spending) {
      byCategory[t.category] = (byCategory[t.category] ?? 0) +
          toBase(ref, t.amount, from: t.currency);
    }
    final cats = byCategory.keys.toList();
    final total = byCategory.values.fold(0.0, (a, b) => a + b);
    final chartColors = chartColorsOf(theme.colorScheme);

    return Scaffold(
      floatingActionButton: FloatingActionButton(
        heroTag: 'spendingScreenFAB',
        onPressed: () => Navigator.of(context).push(
          MaterialPageRoute(
            builder: (_) => const TransactionEditorScreen(kind: 'spending'),
          ),
        ),
        child: const Icon(Icons.add),
      ),
      body: spending.isEmpty
          ? EmptyState(
              icon: Icons.receipt_long_outlined,
              title: l10n.spendingEmpty,
            )
          : ListView(
              padding: const EdgeInsets.all(12),
              children: [
                BentoCard(
                  child: Padding(
                    padding: const EdgeInsets.all(12),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(l10n.spendingSpent, style: theme.textTheme.bodySmall),
                        MoneyText(total, style: theme.textTheme.titleLarge),
                        const SizedBox(height: 8),
                        SizedBox(
                          height: 140,
                          child: BarChart(
                            BarChartData(
                              barGroups: [
                                for (var i = 0; i < cats.length; i++)
                                  BarChartGroupData(
                                    x: i,
                                    barRods: [
                                      BarChartRodData(
                                        toY: byCategory[cats[i]]!,
                                        color: chartColors[i % chartColors.length],
                                        width: 18,
                                        borderRadius: BorderRadius.circular(4),
                                      ),
                                    ],
                                  ),
                              ],
                              titlesData: FlTitlesData(
                                bottomTitles: AxisTitles(
                                  sideTitles: SideTitles(
                                    showTitles: true,
                                    getTitlesWidget: (v, _) {
                                      final i = v.toInt();
                                      return i < cats.length
                                          ? Padding(
                                              padding: const EdgeInsets.only(top: 4),
                                              child: Text(
                                                cats[i].isEmpty
                                                    ? '—'
                                                    : cats[i],
                                                style: Theme.of(context).textTheme.labelSmall,
                                              ),
                                            )
                                          : const SizedBox();
                                    },
                                  ),
                                ),
                                leftTitles: const AxisTitles(
                                    sideTitles: SideTitles(showTitles: false)),
                                topTitles: const AxisTitles(
                                    sideTitles: SideTitles(showTitles: false)),
                                rightTitles: const AxisTitles(
                                    sideTitles: SideTitles(showTitles: false)),
                              ),
                              gridData: const FlGridData(show: false),
                              borderData: FlBorderData(show: false),
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
                const SizedBox(height: 12),
                ...spending.map(
                  (t) => Card(
                    child: ListTile(
                      title:
                          Text(t.category.isEmpty ? l10n.spendingUncategorized : t.category),
                      subtitle: _txSubtitle(context, t),
                      trailing: MoneyText(
                        -t.amount,
                        from: t.currency,
                        style: const TextStyle(color: Colors.red),
                      ),
                      onTap: () => Navigator.of(context).push(
                        MaterialPageRoute(
                          builder: (_) =>
                              TransactionEditorScreen(kind: 'spending', transaction: t),
                        ),
                      ),
                      onLongPress: () =>
                          ref.read(transactionsProvider.notifier).delete(t.id!),
                    ),
                  ),
                ),
              ],
            ),
    );
  }
}