import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:qalqul/l10n/l10n.dart';
import 'package:qalqul/features/widgets_studio/user_widget_card.dart';
import 'package:qalqul/features/widgets_studio/user_widgets_provider.dart';
import 'package:qalqul/features/widgets_studio/widgets_studio_screen.dart';
import 'package:qalqul/shared/widgets/app_bar.dart';
import 'package:qalqul/shared/widgets/bento_grid.dart';
import 'package:qalqul/shared/widgets/empty_state.dart';
import 'package:qalqul/shared/widgets/load_state_views.dart';

class HomeScreen extends ConsumerWidget {
  const HomeScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = context.l10n;

    return Scaffold(
      appBar: QalqulAppBar(
        title: l10n.appTitle,
        extraActions: [
          IconButton(
            icon: const Icon(Icons.dashboard_customize_outlined),
            onPressed: () => Navigator.of(context).push(
              MaterialPageRoute(builder: (_) => const WidgetsStudioScreen()),
            ),
          ),
        ],
      ),
      body: ref.watch(userWidgetsProvider).when(
        loading: () => const LoadingView(),
        error: (error, _) => const LoadErrorView(),
        data: (widgets) => widgets.isEmpty
            ? EmptyState(
                icon: Icons.dashboard_customize_outlined,
                title: l10n.homeNoWidgets,
                action: FilledButton.icon(
                  icon: const Icon(Icons.add),
                  label: Text(l10n.homeOpenStudio),
                  onPressed: () => Navigator.of(context).push(
                    MaterialPageRoute(
                        builder: (_) => const WidgetsStudioScreen()),
                  ),
                ),
              )
            : BentoGrid(
                tiles: [
                  for (final w in widgets)
                    BentoTile(
                      crossAxisCellCount: w.cells[0],
                      mainAxisCellCount: w.cells[1],
                      child: UserWidgetCard(w),
                    ),
                ],
              ),
      ),
    );
  }
}
