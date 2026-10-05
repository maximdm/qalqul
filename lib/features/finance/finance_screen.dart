import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:qalqul/features/finance/budget/budget_screen.dart';
import 'package:qalqul/features/finance/credit/credit_screen.dart';
import 'package:qalqul/features/finance/finance_tabs.dart';
import 'package:qalqul/features/finance/investments/investments_screen.dart';
import 'package:qalqul/features/finance/spending/spending_screen.dart';
import 'package:qalqul/l10n/l10n.dart';
import 'package:qalqul/shared/widgets/app_bar.dart';

class FinanceScreen extends ConsumerStatefulWidget {
  const FinanceScreen({super.key});

  @override
  ConsumerState<FinanceScreen> createState() => _FinanceScreenState();
}

class _FinanceScreenState extends ConsumerState<FinanceScreen>
    with SingleTickerProviderStateMixin {
  TabController? _controller;

  @override
  void dispose() {
    _controller?.dispose();
    super.dispose();
  }

  /// Keeps a controller alive across rebuilds. The tab count is fixed by
  /// [FinanceTab], so only the very first build has to create one.
  TabController _controllerFor(int length) {
    final existing = _controller;
    if (existing != null && existing.length == length) return existing;
    existing?.dispose();
    return _controller = TabController(length: length, vsync: this);
  }

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    final order = ref.watch(financeTabOrderProvider);
    final controller = _controllerFor(order.length);

    return Scaffold(
      appBar: QalqulAppBar(
        title: l10n.financeTitle,
        bottom: PreferredSize(
          preferredSize: const Size.fromHeight(_FinanceTabStrip.height),
          child: _FinanceTabStrip(tabs: order, controller: controller),
        ),
      ),
      body: TabBarView(
        controller: controller,
        children: [for (final tab in order) _screenFor(tab)],
      ),
    );
  }

  Widget _screenFor(FinanceTab tab) => switch (tab) {
        FinanceTab.investments => const InvestmentsScreen(),
        FinanceTab.spending => const SpendingScreen(),
        FinanceTab.credit => const CreditScreen(),
        FinanceTab.budget => const BudgetScreen(),
      };
}

/// Horizontally scrollable tab strip whose tabs can also be dragged into a
/// new order. Dragging the strip scrolls it; dragging a handle reorders.
class _FinanceTabStrip extends ConsumerWidget {
  const _FinanceTabStrip({required this.tabs, required this.controller});

  /// `AppBar.bottom` sits in a plain [Column], so it gets unbounded height.
  /// A scrollable needs a bounded cross-axis extent, hence the explicit box.
  static const height = 52.0;

  final List<FinanceTab> tabs;
  final TabController controller;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = context.l10n;
    final theme = Theme.of(context);
    final notifier = ref.read(financeTabOrderProvider.notifier);

    return SizedBox(
      height: height,
      child: ReorderableListView.builder(
        scrollDirection: Axis.horizontal,
        padding: const EdgeInsets.symmetric(horizontal: 12),
        buildDefaultDragHandles: false,
        itemCount: tabs.length,
        onReorderItem: notifier.reorderItem,
        itemBuilder: (context, i) {
          final tab = tabs[i];
          return Padding(
            key: ValueKey(tab),
            padding: const EdgeInsets.symmetric(vertical: 8),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                // Only the chip listens to the controller, so swiping the page
                // doesn't rebuild the reorderable list mid-drag.
                ListenableBuilder(
                  listenable: controller,
                  builder: (context, _) => ChoiceChip(
                    label: Text(_label(tab, l10n)),
                    selected: controller.index == i,
                    onSelected: (_) => controller.animateTo(i),
                  ),
                ),
                ReorderableDragStartListener(
                  index: i,
                  child: Tooltip(
                    message: l10n.financeReorderTabs,
                    child: Icon(
                      Icons.drag_indicator,
                      size: 18,
                      color: theme.colorScheme.outline,
                    ),
                  ),
                ),
              ],
            ),
          );
        },
      ),
    );
  }

  String _label(FinanceTab tab, L10n l10n) => switch (tab) {
        FinanceTab.investments => l10n.financeTabInvestments,
        FinanceTab.spending => l10n.financeTabSpending,
        FinanceTab.credit => l10n.financeTabCredit,
        FinanceTab.budget => l10n.financeTabBudget,
      };
}