import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:qalqul/features/security/app_lock_provider.dart';
import 'package:qalqul/features/security/app_lock_service.dart';
import 'package:qalqul/shared/providers/settings_provider.dart';

/// Stand-in for the platform plugin: records prompts and returns [outcome].
class FakeAppLockService extends AppLockService {
  FakeAppLockService(this.outcome);

  AuthOutcome outcome;
  int prompts = 0;
  bool? lastBiometricOnly;

  @override
  Future<bool> isAvailable() async => outcome != AuthOutcome.unavailable;

  @override
  Future<bool> hasBiometrics() async => outcome == AuthOutcome.success;

  @override
  Future<AuthOutcome> authenticate({
    required String reason,
    bool biometricOnly = true,
  }) async {
    prompts++;
    lastBiometricOnly = biometricOnly;
    return outcome;
  }
}

/// Settings without touching sqflite.
class _FakeSettings extends SettingsNotifier {
  _FakeSettings(this._initial);

  final Map<String, String> _initial;

  @override
  Map<String, String> build() => Map.of(_initial);
}

void main() {
  late FakeAppLockService service;

  ProviderContainer container({
    Map<String, String> settings = const {},
  }) {
    final c = ProviderContainer(
      overrides: [
        settingsProvider.overrideWith(() => _FakeSettings(settings)),
        appLockServiceProvider.overrideWithValue(service),
      ],
    );
    addTearDown(c.dispose);
    return c;
  }

  setUp(() {
    service = FakeAppLockService(AuthOutcome.success);
  });

  group('AppLockPhase.coversContent', () {
    test('covers content while locked, prompting or failed', () {
      for (final phase in [
        AppLockPhase.locked,
        AppLockPhase.authenticating,
        AppLockPhase.failed,
      ]) {
        expect(AppLockState(phase: phase).coversContent, isTrue,
            reason: phase.name);
      }
    });

    test('does not cover content when off, unlocked or unavailable', () {
      for (final phase in [
        AppLockPhase.off,
        AppLockPhase.unlocked,
        AppLockPhase.unavailable,
      ]) {
        expect(AppLockState(phase: phase).coversContent, isFalse,
            reason: phase.name);
      }
    });
  });

  group('enabled state', () {
    test('is off when the setting is absent', () {
      final c = container();
      expect(c.read(appLockProvider).phase, AppLockPhase.off);
    });

    test('starts locked when enabled', () {
      final c = container(settings: {SettingKeys.appLockEnabled: 'true'});
      expect(c.read(appLockProvider).phase, AppLockPhase.locked);
    });

    test('ignores a non-"true" value', () {
      final c = container(settings: {SettingKeys.appLockEnabled: 'false'});
      expect(c.read(appLockProvider).phase, AppLockPhase.off);
    });
  });

  group('unlock', () {
    ProviderContainer lockedContainer({
      Map<String, String> settings = const {},
    }) =>
        container(settings: {
          SettingKeys.appLockEnabled: 'true',
          ...settings,
        });

    test('success unlocks', () async {
      final c = lockedContainer();
      expect(await c.read(appLockProvider.notifier).unlock(), isTrue);
      expect(c.read(appLockProvider).phase, AppLockPhase.unlocked);
      expect(service.prompts, 1);
    });

    test('failure keeps the gate closed and allows a retry', () async {
      service.outcome = AuthOutcome.failed;
      final c = lockedContainer();
      final notifier = c.read(appLockProvider.notifier);

      expect(await notifier.unlock(), isFalse);
      expect(c.read(appLockProvider).phase, AppLockPhase.failed);
      expect(c.read(appLockProvider).coversContent, isTrue);

      service.outcome = AuthOutcome.success;
      expect(await notifier.unlock(), isTrue);
      expect(c.read(appLockProvider).phase, AppLockPhase.unlocked);
      expect(service.prompts, 2);
    });

    test('unavailable lets the user through without bricking the app',
        () async {
      service.outcome = AuthOutcome.unavailable;
      final c = lockedContainer();
      expect(await c.read(appLockProvider.notifier).unlock(), isTrue);
      expect(c.read(appLockProvider).phase, AppLockPhase.unavailable);
      expect(c.read(appLockProvider).coversContent, isFalse);
    });

    test('is a no-op when already unlocked', () async {
      final c = lockedContainer();
      final notifier = c.read(appLockProvider.notifier);
      await notifier.unlock();
      expect(await notifier.unlock(), isTrue);
      expect(service.prompts, 1);
    });

    test('is a no-op when the lock is switched off', () async {
      final c = container();
      expect(await c.read(appLockProvider.notifier).unlock(), isTrue);
      expect(service.prompts, 0);
      expect(c.read(appLockProvider).phase, AppLockPhase.off);
    });

    test('passes the biometric-only preference through', () async {
      final c = lockedContainer();
      await c.read(appLockProvider.notifier).unlock();
      expect(service.lastBiometricOnly, isTrue);

      final withPasscode = container(settings: {
        SettingKeys.appLockEnabled: 'true',
        SettingKeys.appLockBiometricOnly: 'false',
      });
      await withPasscode.read(appLockProvider.notifier).unlock();
      expect(service.lastBiometricOnly, isFalse);
    });
  });

  group('lifecycle', () {
    test('a short trip to the background keeps the app unlocked', () async {
      final c = container(settings: {SettingKeys.appLockEnabled: 'true'});
      final notifier = c.read(appLockProvider.notifier);
      await notifier.unlock();

      notifier.onPaused();
      expect(c.read(appLockProvider).hiddenAtMs, isNot(0));

      await notifier.onResumed();
      expect(c.read(appLockProvider).phase, AppLockPhase.unlocked);
      expect(c.read(appLockProvider).hiddenAtMs, 0);
    });

    test('exceeding the grace period re-locks', () async {
      final c = container(settings: {
        SettingKeys.appLockEnabled: 'true',
        SettingKeys.appLockGraceSeconds: '0',
      });
      final notifier = c.read(appLockProvider.notifier);
      await notifier.unlock();
      expect(c.read(appLockProvider).phase, AppLockPhase.unlocked);

      notifier.onPaused();
      await notifier.onResumed();
      expect(c.read(appLockProvider).phase, AppLockPhase.locked);
    });

    test('lockNow re-locks an unlocked app', () async {
      final c = container(settings: {SettingKeys.appLockEnabled: 'true'});
      final notifier = c.read(appLockProvider.notifier);
      await notifier.unlock();

      notifier.lockNow();
      expect(c.read(appLockProvider).phase, AppLockPhase.locked);
      expect(c.read(appLockProvider).coversContent, isTrue);
    });

    test('lockNow does nothing when the feature is off', () {
      final c = container();
      c.read(appLockProvider.notifier).lockNow();
      expect(c.read(appLockProvider).phase, AppLockPhase.off);
    });

    test('pausing an unlocked app records the hide time', () async {
      final c = container(settings: {SettingKeys.appLockEnabled: 'true'});
      final notifier = c.read(appLockProvider.notifier);
      await notifier.unlock();

      notifier.onPaused();
      expect(c.read(appLockProvider).hiddenAtMs, isNot(0));
    });
  });

  group('settings-derived preferences', () {
    test('biometric-only defaults to true', () {
      final c = container();
      expect(c.read(appLockBiometricOnlyProvider), isTrue);
    });

    test('grace period defaults and clamps', () {
      expect(container().read(appLockGraceSecondsProvider),
          kDefaultLockGraceSeconds);
      expect(
        container(settings: {SettingKeys.appLockGraceSeconds: '90'})
            .read(appLockGraceSecondsProvider),
        90,
      );
      expect(
        container(settings: {SettingKeys.appLockGraceSeconds: '99999'})
            .read(appLockGraceSecondsProvider),
        3600,
      );
      expect(
        container(settings: {SettingKeys.appLockGraceSeconds: 'abc'})
            .read(appLockGraceSecondsProvider),
        kDefaultLockGraceSeconds,
      );
    });
  });
}
