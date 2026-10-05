import 'package:fl_chart/fl_chart.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';
import 'package:qalqul/core/models/investment.dart';
import 'package:qalqul/features/finance/chart_colors.dart';
import 'package:qalqul/features/finance/currency_provider.dart';
import 'package:qalqul/features/finance/investments/investment_editor_screen.dart';
import 'package:qalqul/features/finance/investments_provider.dart';
import 'package:qalqul/l10n/l10n.dart';
import 'package:qalqul/shared/widgets/bento_card.dart';
import 'package:qalqul/shared/widgets/empty_state.dart';
import 'package:qalqul/shared/widgets/money_text.dart';

class InvestmentsScreen extends ConsumerWidget {
  const InvestmentsScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = context.l10n;
    final investments = ref.watch(investmentsProvider);
    // Totals are converted per holding so mixed-currency portfolios add up in
    // the user's base currency.
    double sum(double Function(Investment) pick) => investments.fold<double>(
          0,
          (acc, i) => acc + toBase(ref, pick(i), from: i.currency),
        );

    final total = sum((i) => i.currentValue);
    final principal = sum((i) => i.principal);
    final gain = total - principal;
    final pct = principal > 0 ? (gain / principal) * 100 : 0.0;

    final theme = Theme.of(context);
    final chartColors = chartColorsOf(theme.colorScheme);

    return Scaffold(
      floatingActionButton: FloatingActionButton(
        heroTag: 'investmentsScreenFAB',
        onPressed: () => Navigator.of(context).push(
          MaterialPageRoute(builder: (_) => const InvestmentEditorScreen()),
        ),
        child: const Icon(Icons.add),
      ),
      body: investments.isEmpty
          ? EmptyState(
              icon: Icons.trending_up,
              title: l10n.investmentsEmpty,
            )
          : ListView(
              padding: const EdgeInsets.all(12),
              children: [
                BentoCard(
                  child: Padding(
                    padding: const EdgeInsets.all(12),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(l10n.investmentsTotalValue,
                                style: theme.textTheme.bodySmall),
                            MoneyText(total, style: theme.textTheme.titleLarge),
                            const SizedBox(height: 4),
                            Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                Icon(
                                  gain >= 0
                                      ? Icons.trending_up
                                      : Icons.trending_down,
                                  size: 16,
                                  color: gain >= 0 ? Colors.green : Colors.red,
                                ),
                                const SizedBox(width: 4),
                                Text(
                                  '${gain >= 0 ? '+' : ''}${formatInBase(ref, gain, compact: true)} (${pct.toStringAsFixed(1)}%)',
                                  style: theme.textTheme.bodyMedium?.copyWith(
                                    color:
                                        gain >= 0 ? Colors.green : Colors.red,
                                  ),
                                ),
                              ],
                            ),
                          ],
                        ),
                        SizedBox(
                          width: 110,
                          height: 110,
                          child: PieChart(
                            PieChartData(
                              sections: _donut(investments, ref, chartColors, context),
                              centerSpaceRadius: 26,
                              sectionsSpace: 2,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
                const SizedBox(height: 12),
                ...investments.map(
                  (i) => Card(
                    child: ListTile(
                      title: Text(i.name),
                      subtitle: Text(
                        '${l10n.investmentsPrincipal(formatInBase(ref, i.principal, from: i.currency))} · ${_date(i.asOf)}',
                      ),
                      trailing: MoneyText(i.currentValue, from: i.currency),
                      onTap: () => Navigator.of(context).push(
                        MaterialPageRoute(
                          builder: (_) => InvestmentEditorScreen(investment: i),
                        ),
                      ),
                      onLongPress: () =>
                          ref.read(investmentsProvider.notifier).delete(i.id!),
                    ),
                  ),
                ),
              ],
            ),
    );
  }

  List<PieChartSectionData> _donut(
    List<Investment> items,
    WidgetRef ref,
    List<Color> chartColors,
    BuildContext context,
  ) {
    final values = [
      for (final i in items) toBase(ref, i.currentValue, from: i.currency),
    ];
    final total = values.fold<double>(0, (a, b) => a + b);
    if (total <= 0) return [];
    return [
      for (var i = 0; i < items.length; i++)
        PieChartSectionData(
          value: values[i],
          color: chartColors[i % chartColors.length],
          title: '${(values[i] / total * 100).toStringAsFixed(0)}%',
          radius: 40,
          titleStyle: Theme.of(context).textTheme.labelSmall?.copyWith(
                color: foregroundFor(chartColors[i % chartColors.length]),
              ),
        ),
    ];
  }

  String _date(int ms) {
    final d = DateTime.fromMillisecondsSinceEpoch(ms);
    return DateFormat.yMMMd().format(d);
  }
}