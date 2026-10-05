import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';
import 'package:qalqul/core/models/transaction.dart';
import 'package:qalqul/features/finance/currency_provider.dart';
import 'package:qalqul/features/finance/transaction_editor_screen.dart';
import 'package:qalqul/features/finance/transactions_provider.dart';
import 'package:qalqul/l10n/l10n.dart';
import 'package:qalqul/shared/widgets/bento_card.dart';
import 'package:qalqul/shared/widgets/empty_state.dart';
import 'package:qalqul/shared/widgets/load_state_views.dart';
import 'package:qalqul/shared/widgets/money_text.dart';

class CreditScreen extends ConsumerWidget {
  const CreditScreen({super.key});

  Widget _txSubtitle(BuildContext context, AppTransaction t) {
    final l10n = context.l10n;
    final parts = <String>[];
    if (t.note.isNotEmpty) parts.add(t.note);
    if (t.isRecurring) {
      final due = t.nextDue > 0
          ? DateTime.fromMillisecondsSinceEpoch(t.nextDue)
          : null;
      final dueStr = due != null ? DateFormat.Md().format(due) : '';
      parts.add(
        '↻ ${t.recurrence}${dueStr.isNotEmpty ? ' · ${l10n.txRecurringDue(dueStr)}' : ''}',
      );
    }
    return parts.isEmpty
        ? const SizedBox.shrink()
        : Text(parts.join(' · '), style: Theme.of(context).textTheme.bodySmall);
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) => ref
      .watch(transactionsProvider)
      .when(
        loading: () => const Scaffold(body: LoadingView()),
        error: (error, _) => const Scaffold(body: LoadErrorView()),
        data: (all) => _body(context, ref, all),
      );

  Widget _body(
      BuildContext context, WidgetRef ref, List<AppTransaction> all) {
    final l10n = context.l10n;
    final credits = all.where((t) => t.kind == 'credit').toList();
    final theme = Theme.of(context);
    final owed =
        sumRecords(ref, credits, (t) => t.currency, (t) => t.amountMinor);

    return Scaffold(
      floatingActionButton: FloatingActionButton(
        heroTag: 'creditScreenFAB',
        onPressed: () => Navigator.of(context).push(
          MaterialPageRoute(
            builder: (_) => TransactionEditorScreen(
              kind: 'credit',
              categoryLabel: l10n.creditLender,
              dateLabel: l10n.creditDueDate,
            ),
          ),
        ),
        child: const Icon(Icons.add),
      ),
      body: credits.isEmpty
          ? EmptyState(
              icon: Icons.credit_card_outlined,
              title: l10n.creditEmpty,
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
                        Text(l10n.creditOutstanding,
                            style: theme.textTheme.bodySmall),
                        MoneyTotalText(owed, style: theme.textTheme.titleLarge),
                      ],
                    ),
                  ),
                ),
                const SizedBox(height: 12),
                ...credits.map(
                  (t) => Card(
                    child: ListTile(
                      title: Text(t.category.isEmpty ? l10n.creditLender : t.category),
                      subtitle: _txSubtitle(context, t),
                      trailing: MoneyText(t.amountMinor, from: t.currency),
                      onTap: () => Navigator.of(context).push(
                        MaterialPageRoute(
                          builder: (_) => TransactionEditorScreen(
                            kind: 'credit',
                            transaction: t,
                            categoryLabel: l10n.creditLender,
                            dateLabel: l10n.creditDueDate,
                          ),
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