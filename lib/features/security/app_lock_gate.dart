import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'package:qalqul/features/security/app_lock_provider.dart';
import 'package:qalqul/l10n/l10n.dart';

/// Wraps the app shell and covers it whenever app lock is engaged.
///
/// Re-locks on resume after the configured grace period (see
/// [AppLockNotifier.onResumed]).
class AppLockGate extends ConsumerStatefulWidget {
  final Widget child;
  const AppLockGate({super.key, required this.child});

  @override
  ConsumerState<AppLockGate> createState() => _AppLockGateState();
}

class _AppLockGateState extends ConsumerState<AppLockGate>
    with WidgetsBindingObserver {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    // If lock is already on when the app starts, try immediately so a cold
    // start doesn't demand a tap before showing the prompt.
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) return;
      final state = ref.read(appLockProvider);
      if (state.phase == AppLockPhase.locked) {
        ref.read(appLockProvider.notifier).unlock();
      }
    });
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    super.dispose();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    final notifier = ref.read(appLockProvider.notifier);
    switch (state) {
      case AppLifecycleState.resumed:
        notifier.onResumed();
      case AppLifecycleState.paused:
      case AppLifecycleState.inactive:
      case AppLifecycleState.hidden:
      case AppLifecycleState.detached:
        notifier.onPaused();
    }
  }

  @override
  Widget build(BuildContext context) {
    final state = ref.watch(appLockProvider);
    return Stack(
      children: [
        widget.child,
        if (state.phase == AppLockPhase.unavailable)
          _Overlay(
            title: context.l10n.lockUnavailableTitle,
            body: context.l10n.lockUnavailableBody,
            actionLabel: context.l10n.lockContinue,
            onAction: () => ref.read(appLockProvider.notifier).continueWithoutLock(),
          )
        else if (state.coversContent)
          _Overlay(
            title: context.l10n.lockTitle,
            body: state.phase == AppLockPhase.failed
                ? context.l10n.lockFailed
                : '',
            actionLabel: state.phase == AppLockPhase.authenticating
                ? context.l10n.commonRetry
                : context.l10n.lockUnlock,
            busy: state.phase == AppLockPhase.authenticating,
            onAction: () => ref.read(appLockProvider.notifier).unlock(),
          ),
      ],
    );
  }
}

class _Overlay extends StatelessWidget {
  final String title;
  final String body;
  final String actionLabel;
  final bool busy;
  final VoidCallback onAction;

  const _Overlay({
    required this.title,
    required this.body,
    required this.actionLabel,
    required this.onAction,
    this.busy = false,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Positioned.fill(
      child: Material(
        color: theme.colorScheme.surface,
        child: SafeArea(
          child: Center(
            child: Padding(
              padding: const EdgeInsets.all(24),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(
                    Icons.lock_outline,
                    size: 48,
                    color: theme.colorScheme.primary,
                  ),
                  const SizedBox(height: 16),
                  Text(title, style: theme.textTheme.titleMedium),
                  if (body.isNotEmpty) ...[
                    const SizedBox(height: 8),
                    Text(
                      body,
                      textAlign: TextAlign.center,
                      style: theme.textTheme.bodySmall,
                    ),
                  ],
                  const SizedBox(height: 20),
                  FilledButton.icon(
                    onPressed: busy ? null : onAction,
                    icon: busy
                        ? const SizedBox(
                            width: 16,
                            height: 16,
                            child: CircularProgressIndicator(strokeWidth: 2),
                          )
                        : const Icon(Icons.lock_open),
                    label: Text(actionLabel),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}