import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'package:qalqul/shared/services/quick_actions_service.dart';

/// Overridden in tests to avoid the platform channel.
final quickActionsServiceProvider =
    Provider<QuickActionsService>((ref) => QuickActionsService());

/// The shortcut waiting to be handled, or `null` when there is none.
///
/// Shortcuts can arrive before the shell is listening (a cold start from the
/// launcher), so the action is parked here instead of being acted on
/// immediately.
final pendingShortcutProvider =
    NotifierProvider<PendingShortcut, QuickActionType?>(PendingShortcut.new);

class PendingShortcut extends Notifier<QuickActionType?> {
  @override
  QuickActionType? build() => null;

  void raise(QuickActionType type) => state = type;

  /// Clears the pending action so the same shortcut can fire again.
  void consume() => state = null;
}
