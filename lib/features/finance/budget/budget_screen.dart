import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';
import 'package:qalqul/core/models/budget.dart';
import 'package:qalqul/core/utils/periods.dart';
import 'package:qalqul/features/finance/budget/budget_editor_screen.dart';
import 'package:qalqul/features/finance/budgets_provider.dart';
import 'package:qalqul/features/finance/currency_provider.dart';
import 'package:qalqul/features/finance/transactions_provider.dart';
import 'package:qalqul/l10n/l10n.dart';
import 'package:qalqul/shared/widgets/bento_card.dart';
import 'package:qalqul/shared/widgets/empty_state.dart';
import 'package:qalqul/shared/widgets/money_text.dart';

class BudgetScreen extends ConsumerWidget {
  const BudgetScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = context.l10n;
    final budgets = ref.watch(budgetsProvider);
    final transactions = ref.watch(transactionsProvider);
    final theme = Theme.of(context);

    // Spend is only meaningful over a period: sum the current month per category.
    final window = monthWindow(DateTime.now());
    final spentByCategory = <String, double>{};
    for (final t in transactions.where((t) => t.kind == 'spending')) {
      if (!within(t.date, window)) continue;
      spentByCategory[t.category] = (spentByCategory[t.category] ?? 0) +
          toBase(ref, t.amount, from: t.currency);
    }

    return Scaffold(
      floatingActionButton: FloatingActionButton(
        heroTag: 'budgetScreenFAB',
        onPressed: () => Navigator.of(context).push(
          MaterialPageRoute(builder: (_) => const BudgetEditorScreen()),
        ),
        child: const Icon(Icons.add),
      ),
      body: budgets.isEmpty
          ? EmptyState(
              icon: Icons.savings_outlined,
              title: l10n.budgetEmpty,
            )
          : ListView(
              padding: const EdgeInsets.all(12),
              children: [
                for (final b in budgets)
                  BentoCard(
                    child: Padding(
                      padding: const EdgeInsets.all(12),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              Expanded(
                                child: Text(b.name,
                                    style: theme.textTheme.titleMedium),
                              ),
                              if (b.category.isNotEmpty)
                                Text(b.category,
                                    style: theme.textTheme.bodySmall),
                            ],
                          ),
                          const SizedBox(height: 8),
                          _progress(b, spentByCategory[b.category] ?? 0, ref),
                          const SizedBox(height: 8),
                          Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              _current(
                                  l10n, b, spentByCategory[b.category] ?? 0, ref),
                              MoneyText(
                                b.targetAmount,
                                from: b.currency,
                                style: theme.textTheme.bodyMedium,
                              ),
                            ],
                          ),
                          const SizedBox(height: 4),
                          Text(_deadline(l10n, b.deadline),
                              style: theme.textTheme.bodySmall),
                        ],
                      ),
                    ),
                  ),
              ],
            ),
    );
  }

  Widget _progress(Budget b, double spent, WidgetRef ref) {
    final target = toBase(ref, b.targetAmount, from: b.currency);
    final value = b.category.isNotEmpty && target > 0
        ? (spent / target).clamp(0.0, 1.0)
        : (target > 0
            ? (toBase(ref, b.savedAmount, from: b.currency) / target)
                .clamp(0.0, 1.0)
            : 0.0);
    return LinearProgressIndicator(
      value: value,
      minHeight: 10,
      borderRadius: BorderRadius.circular(6),
    );
  }

  Widget _current(L10n l10n, Budget b, double spent, WidgetRef ref) {
    if (b.category.isNotEmpty) {
      return Text(l10n.budgetSpent(formatInBase(ref, spent)));
    }
    return MoneyText(b.savedAmount, from: b.currency);
  }

  String _deadline(L10n l10n, int ms) {
    final d = DateTime.fromMillisecondsSinceEpoch(ms);
    final now = DateTime.now();
    final days = daysBetween(now, d);
    final date = DateFormat.yMMMd().format(d);
    if (days >= 0) return l10n.budgetDueIn(days, date);
    return l10n.budgetOverdueBy(-days, date);
  }
}