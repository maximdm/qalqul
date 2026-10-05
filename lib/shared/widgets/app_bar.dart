import 'package:flutter/material.dart';
import 'package:qalqul/features/search/global_search.dart';
import 'package:qalqul/features/settings/settings_screen.dart';
import 'package:qalqul/l10n/l10n.dart';

class QalqulAppBar extends StatelessWidget implements PreferredSizeWidget {
  final String title;
  final List<Widget>? extraActions;
  final PreferredSizeWidget? bottom;
  final bool showSettingsAction;

  const QalqulAppBar({
    super.key,
    required this.title,
    this.extraActions,
    this.bottom,
    this.showSettingsAction = true,
  });

  @override
  Size get preferredSize => Size.fromHeight(
        kToolbarHeight + (bottom?.preferredSize.height ?? 0),
      );

  @override
  Widget build(BuildContext context) {
    return AppBar(
      title: Text(title),
      bottom: bottom,
      actions: [
        ...?extraActions,
        IconButton(
          icon: const Icon(Icons.search_outlined),
          tooltip: context.l10n.searchTitle,
          onPressed: () => showSearch(
            context: context,
            delegate: GlobalSearch(),
          ),
        ),
        if (showSettingsAction)
          IconButton(
            icon: const Icon(Icons.settings_outlined),
            onPressed: () => Navigator.of(context).push(
              MaterialPageRoute(builder: (_) => const SettingsScreen()),
            ),
          ),
      ],
    );
  }
}
