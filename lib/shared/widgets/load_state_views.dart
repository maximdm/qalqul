import 'package:flutter/material.dart';
import 'package:qalqul/l10n/l10n.dart';

/// Centred progress indicator for a screen waiting on its first load.
///
/// Data-backed providers expose an `AsyncValue`, so "loading" and "empty" are
/// distinct states. Showing [EmptyState]-style copy while the query is still in
/// flight is what made the dashboard flash "no data" before every load.
class LoadingView extends StatelessWidget {
  const LoadingView({super.key});

  @override
  Widget build(BuildContext context) => const Center(
        child: Padding(
          padding: EdgeInsets.all(24),
          child: CircularProgressIndicator(),
        ),
      );
}

/// Message shown when a load fails.
///
/// The underlying error is deliberately not rendered: it is a raw sqflite
/// exception, which is not something to put in front of a user.
class LoadErrorView extends StatelessWidget {
  const LoadErrorView({super.key});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Text(
          context.l10n.commonLoadFailed,
          textAlign: TextAlign.center,
          style: theme.textTheme.bodyMedium
              ?.copyWith(color: theme.colorScheme.error),
        ),
      ),
    );
  }
}
