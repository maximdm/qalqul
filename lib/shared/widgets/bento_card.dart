import 'package:flutter/material.dart';

class BentoCard extends StatelessWidget {
  final Widget child;
  final String? title;
  final EdgeInsetsGeometry? padding;

  const BentoCard({
    super.key,
    required this.child,
    this.title,
    this.padding,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Container(
      decoration: BoxDecoration(
        color: theme.cardColor,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(
          color: theme.dividerColor.withValues(alpha: 0.06),
          width: 1,
        ),
      ),
      padding: padding ?? const EdgeInsets.all(16),
      child: LayoutBuilder(
        builder: (context, constraints) {
          final hasBoundedHeight = constraints.maxHeight.isFinite;
          return Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              if (title != null) ...[
                Text(
                  title!,
                  style: theme.textTheme.titleSmall?.copyWith(
                    fontWeight: FontWeight.w600,
                    color: theme.hintColor,
                  ),
                ),
                const SizedBox(height: 10),
              ],
              // `Expanded` needs a bounded height; a parent that gives
              // unbounded height (e.g. a ListView) would otherwise throw. When
              // unbounded, fall back to the child's intrinsic height.
              if (hasBoundedHeight) Expanded(child: child) else child,
            ],
          );
        },
      ),
    );
  }
}
