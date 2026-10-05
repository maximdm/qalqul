import 'package:flutter/material.dart';
import 'package:flutter_staggered_grid_view/flutter_staggered_grid_view.dart';

class BentoTile {
  final int crossAxisCellCount;
  final int mainAxisCellCount;
  final Widget child;

  const BentoTile({
    this.crossAxisCellCount = 2,
    this.mainAxisCellCount = 2,
    required this.child,
  });
}

/// Spacing between bento tiles, shared with [StaggeredGrid] so the reserved
/// cell height below matches the grid's own layout math.
const double bentoSpacing = 12;

class BentoGrid extends StatelessWidget {
  final List<BentoTile> tiles;
  final int crossAxisCount;
  final EdgeInsetsGeometry? padding;

  const BentoGrid({
    super.key,
    required this.tiles,
    this.crossAxisCount = 4,
    this.padding,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: padding ?? const EdgeInsets.all(12),
      child: StaggeredGrid.count(
        crossAxisCount: crossAxisCount,
        mainAxisSpacing: bentoSpacing,
        crossAxisSpacing: bentoSpacing,
        children: tiles
            .map(
              (t) => StaggeredGridTile.count(
                crossAxisCellCount: t.crossAxisCellCount,
                mainAxisCellCount: t.mainAxisCellCount,
                // `StaggeredGridTile.count` only *reserves* grid space via
                // `mainAxisCellCount`; it passes an **unbounded** height to the
                // child. Pin the child to the exact reserved band so cards fill
                // the cell and widgets relying on a bounded height (Expanded,
                // ListView) lay out correctly.
                child: _SizedTile(
                  crossAxisCellCount: t.crossAxisCellCount,
                  mainAxisCellCount: t.mainAxisCellCount,
                  child: t.child,
                ),
              ),
            )
            .toList(),
      ),
    );
  }
}

/// Constrains its child to the height `StaggeredGridTile.count` reserves for it.
class _SizedTile extends StatelessWidget {
  final int crossAxisCellCount;
  final int mainAxisCellCount;
  final Widget child;

  const _SizedTile({
    required this.crossAxisCellCount,
    required this.mainAxisCellCount,
    required this.child,
  });

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        final stride =
            (constraints.maxWidth + bentoSpacing) / crossAxisCellCount;
        final height = stride * mainAxisCellCount - bentoSpacing;
        return SizedBox(height: height, child: child);
      },
    );
  }
}
