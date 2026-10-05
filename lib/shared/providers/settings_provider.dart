import 'dart:ui';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'package:qalqul/features/settings/settings_repository.dart';
import 'package:qalqul/core/utils/money.dart';

/// Keys used in the `app_settings` table.
class SettingKeys {
  const SettingKeys._();

  static const locale = 'locale';
  static const baseCurrency = 'baseCurrency';
  static const appLockEnabled = 'appLockEnabled';
  static const appLockBiometricOnly = 'appLockBiometricOnly';
  static const appLockGraceSeconds = 'appLockGraceSeconds';
  static const themeMode = 'themeMode';
  static const onboardingDone = 'onboardingDone';
  static const financeTabOrder = 'financeTabOrder';
}

/// Whether the initial read from sqflite has completed.
///
/// The shell shows the splash until this flips, so a returning user never sees
/// the onboarding flash past before the stored preferences have loaded.
final settingsReadyProvider =
    NotifierProvider<SettingsReady, bool>(SettingsReady.new);

class SettingsReady extends Notifier<bool> {
  @override
  bool build() => false;

  void markLoaded() => state = true;
}

final settingsProvider =
    NotifierProvider<SettingsNotifier, Map<String, String>>(
  SettingsNotifier.new,
);

/// Device-local preferences, loaded from (and written back to) sqflite.
class SettingsNotifier extends Notifier<Map<String, String>> {
  final _repo = SettingsRepository();
  bool _dirty = false;

  @override
  Map<String, String> build() {
    _load();
    return const {};
  }

  Future<void> _load() async {
    final values = await _repo.getAll();
    // The provider may have been disposed (or rebuilt) while awaiting sqflite.
    if (!ref.mounted) return;
    // A write that landed before the initial read won must not be clobbered.
    if (!_dirty) state = values;
    ref.read(settingsReadyProvider.notifier).markLoaded();
  }

  Future<void> set(String key, String value) async {
    _dirty = true;
    state = {...state, key: value};
    // A first write is enough to know the app has data.
    ref.read(settingsReadyProvider.notifier).markLoaded();
    await _repo.set(key, value);
  }

  Future<void> remove(String key) async {
    _dirty = true;
    final next = {...state}..remove(key);
    state = next;
    await _repo.delete(key);
  }
}

/// `true` once the user has finished (or skipped) the first-run tour.
final onboardingDoneProvider = Provider<bool>((ref) {
  return ref.watch(settingsProvider.select((s) => s[SettingKeys.onboardingDone])) ==
      'true';
});

/// `null` follows the system locale.
final localeProvider = Provider<Locale?>((ref) {
  final code = ref.watch(settingsProvider.select((s) => s[SettingKeys.locale]));
  if (code == null || code.isEmpty) return null;
  final parts = code.split(RegExp('[-_]'));
  return Locale(parts.first, parts.length > 1 ? parts[1] : null);
});

/// Currency all finance amounts are converted to for display.
final baseCurrencyProvider = Provider<String>((ref) {
  final code = ref
          .watch(settingsProvider.select((s) => s[SettingKeys.baseCurrency])) ??
      defaultCurrency;
  return isSupportedCurrency(code) ? code : defaultCurrency;
});
