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
import 'package:qalqul/shared/widgets/load_state_views.dart';
import 'package:qalqul/shared/widgets/money_text.dart';

class InvestmentsScreen extends ConsumerWidget {
  const InvestmentsScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) => ref
      .watch(investmentsProvider)
      .when(
        loading: () => const Scaffold(body: LoadingView()),
        error: (error, _) => const Scaffold(body: LoadErrorView()),
        data: (investments) => _body(context, ref, investments),
      );

  Widget _body(
      BuildContext context, WidgetRef ref, List<Investment> investments) {
    final l10n = context.l10n;
    // Totals combine holdings across currencies, so they are built with
    // `sumRecords`: anything without an FX path is reported rather than added
    // in its original units.
    final total = sumRecords(
        ref, investments, (i) => i.currency, (i) => i.currentValueMinor);
    final principal =
        sumRecords(ref, investments, (i) => i.currency, (i) => i.principalMinor);
    final gain = total.minor - principal.minor;
    final pct =
        principal.minor > 0 ? (gain / principal.minor) * 100 : 0.0;

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
                            MoneyTotalText(total, style: theme.textTheme.titleLarge),
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
                        '${l10n.investmentsPrincipal(formatInBase(ref, i.principalMinor, from: i.currency))} · ${_date(i.asOf)}',
                      ),
                      trailing:
                          MoneyText(i.currentValueMinor, from: i.currency),
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
    // Slice sizes are ratios, so a holding with no rate path to the base
    // cannot be charted without silently charting its raw number as if it
    // were base-currency. Those are dropped here and flagged by the totals.
    final currency = ref.watch(currencyProvider);
    final slices = <(int, double)>[];
    for (var i = 0; i < items.length; i++) {
      final value = convertWith(currency, items[i].currentValueMinor,
          from: items[i].currency);
      if (value.converted) slices.add((i, value.decimal));
    }
    final total = slices.fold<double>(0, (a, s) => a + s.$2);
    if (total <= 0) return [];
    return [
      for (final (index, value) in slices)
        PieChartSectionData(
          value: value,
          color: chartColors[index % chartColors.length],
          title: '${(value / total * 100).toStringAsFixed(0)}%',
          radius: 40,
          titleStyle: Theme.of(context).textTheme.labelSmall?.copyWith(
                color: foregroundFor(chartColors[index % chartColors.length]),
              ),
        ),
    ];
  }

  String _date(int ms) {
    final d = DateTime.fromMillisecondsSinceEpoch(ms);
    return DateFormat.yMMMd().format(d);
  }
}