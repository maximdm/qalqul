import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:qalqul/app.dart';
import 'package:qalqul/shared/providers/settings_provider.dart';

import 'helpers/fake_data.dart';
import 'helpers/fake_settings.dart';

/// Settings that are already loaded and past onboarding, i.e. a returning user.
class _LoadedSettings extends SettingsReady {
  @override
  bool build() => true;
}

void main() {
  testWidgets('Qalqul app bar shows title', (tester) async {
    await tester.pumpWidget(
      ProviderScope(
        // The data providers are overridden so the dashboard has no in-flight
        // load. Otherwise `LoadingView`'s spinner is on screen and
        // `pumpAndSettle` can never settle: an indeterminate progress
        // indicator animates forever by design.
        overrides: [
          settingsProvider.overrideWith(
            () => FakeSettings({SettingKeys.onboardingDone: 'true'}),
          ),
          settingsReadyProvider.overrideWith(_LoadedSettings.new),
          ...emptyDataProviders(),
        ],
        child: const QalqulApp(),
      ),
    );
    await tester.pumpAndSettle();
    expect(find.text('Qalqul'), findsWidgets);
  });

  testWidgets('a fresh install starts on the intro tour', (tester) async {
    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          settingsProvider.overrideWith(FakeSettings.new),
          settingsReadyProvider.overrideWith(_LoadedSettings.new),
          ...emptyDataProviders(),
        ],
        child: const QalqulApp(),
      ),
    );
    await tester.pumpAndSettle();

    expect(find.text('Welcome to Qalqul'), findsWidgets);
    // The dashboard must not be behind it yet.
    expect(find.text('Recent notes'), findsNothing);
  });
}
