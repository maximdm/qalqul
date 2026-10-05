import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'package:qalqul/features/security/app_lock_service.dart';
import 'package:qalqul/shared/providers/settings_provider.dart';

/// Seconds the app may stay backgrounded before it re-locks.
const int kDefaultLockGraceSeconds = 30;

final appLockServiceProvider = Provider<AppLockService>((ref) {
  return AppLockService();
});

final appLockEnabledProvider = Provider<bool>((ref) {
  return ref.watch(settingsProvider
          .select((s) => s[SettingKeys.appLockEnabled])) ==
      'true';
});

final appLockBiometricOnlyProvider = Provider<bool>((ref) {
  final raw = ref.watch(
      settingsProvider.select((s) => s[SettingKeys.appLockBiometricOnly]));
  // Default to biometrics-only; the passcode fallback is opt-in.
  return raw == null || raw == 'true';
});

final appLockGraceSecondsProvider = Provider<int>((ref) {
  final raw = ref.watch(
      settingsProvider.select((s) => s[SettingKeys.appLockGraceSeconds]));
  final parsed = int.tryParse(raw ?? '');
  if (parsed == null) return kDefaultLockGraceSeconds;
  return parsed.clamp(0, 3600);
});

enum AppLockPhase {
  /// App lock is switched off in settings.
  off,

  /// App lock is on and the user has authenticated — content is visible.
  unlocked,

  /// Content is covered and waiting for the user to authenticate.
  locked,

  /// An authentication prompt is on screen.
  authenticating,

  /// Authentication failed; the lock screen stays up.
  failed,

  /// The device cannot authenticate at all, so the gate steps aside rather than
  /// bricking the app on hardware without a screen lock.
  unavailable,
}

class AppLockState {
  final AppLockPhase phase;
  final int hiddenAtMs;

  const AppLockState({required this.phase, this.hiddenAtMs = 0});

  bool get coversContent => phase != AppLockPhase.off &&
      phase != AppLockPhase.unlocked &&
      phase != AppLockPhase.unavailable;

  AppLockState copyWith({AppLockPhase? phase, int? hiddenAtMs}) => AppLockState(
        phase: phase ?? this.phase,
        hiddenAtMs: hiddenAtMs ?? this.hiddenAtMs,
      );
}

final appLockProvider =
    NotifierProvider<AppLockNotifier, AppLockState>(AppLockNotifier.new);

/// Owns the locked/unlocked transition. The gate widget feeds lifecycle events
/// in via [onResumed] / [onPaused].
class AppLockNotifier extends Notifier<AppLockState> {
  AppLockService get _service => ref.read(appLockServiceProvider);

  @override
  AppLockState build() {
    final enabled = ref.watch(appLockEnabledProvider);
    return AppLockState(
      phase: enabled ? AppLockPhase.locked : AppLockPhase.off,
    );
  }

  /// Re-lock on resume if the app was backgrounded longer than the grace period.
  Future<void> onResumed() async {
    if (state.phase == AppLockPhase.off) return;
    final hiddenAt = state.hiddenAtMs;
    if (hiddenAt == 0) return;
    final away = DateTime.now().millisecondsSinceEpoch - hiddenAt;
    final grace = ref.read(appLockGraceSecondsProvider) * 1000;
    if (away < grace) {
      // Short trip away: clear the marker but stay unlocked.
      state = state.copyWith(hiddenAtMs: 0);
      return;
    }
    state = const AppLockState(phase: AppLockPhase.locked);
  }

  void onPaused() {
    if (state.phase == AppLockPhase.off) return;
    // Recorded even while unlocked: that is exactly when a long trip away
    // should force a fresh prompt.
    state = state.copyWith(
      hiddenAtMs: DateTime.now().millisecondsSinceEpoch,
    );
  }

  /// Locks immediately (the "Lock now" settings action).
  void lockNow() {
    if (state.phase == AppLockPhase.off) return;
    state = const AppLockState(phase: AppLockPhase.locked);
  }

  /// Runs the platform prompt. Returns true when the app is now unlocked.
  Future<bool> unlock() async {
    if (state.phase != AppLockPhase.locked &&
        state.phase != AppLockPhase.failed) {
      return true;
    }
    state = state.copyWith(phase: AppLockPhase.authenticating);
    final biometricOnly = ref.read(appLockBiometricOnlyProvider);
    final outcome = await _service.authenticate(
      reason: 'Unlock Qalqul',
      biometricOnly: biometricOnly,
    );
    switch (outcome) {
      case AuthOutcome.success:
        state = const AppLockState(phase: AppLockPhase.unlocked);
        return true;
      case AuthOutcome.failed:
        state = state.copyWith(phase: AppLockPhase.failed);
        return false;
      case AuthOutcome.unavailable:
        state = state.copyWith(phase: AppLockPhase.unavailable);
        return true;
    }
  }

  /// Lets the user back in after we discovered the device can't authenticate.
  void continueWithoutLock() {
    state = state.copyWith(phase: AppLockPhase.unlocked);
  }
}