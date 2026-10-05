import 'package:flutter/material.dart';
import 'package:qalqul/l10n/l10n.dart';

class AppBottomNav extends StatelessWidget {
  final int currentIndex;
  final ValueChanged<int> onTap;

  const AppBottomNav({
    super.key,
    required this.currentIndex,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    return BottomNavigationBar(
      currentIndex: currentIndex,
      onTap: onTap,
      items: [
        BottomNavigationBarItem(
          icon: const Icon(Icons.grid_view_rounded),
          label: l10n.navHome,
        ),
        BottomNavigationBarItem(
          icon: const Icon(Icons.calculate_outlined),
          label: l10n.navCalculator,
        ),
        BottomNavigationBarItem(
          icon: const Icon(Icons.note_alt_outlined),
          label: l10n.navNotes,
        ),
        BottomNavigationBarItem(
          icon: const Icon(Icons.pie_chart_outline),
          label: l10n.navFinance,
        ),
      ],
    );
  }
}
