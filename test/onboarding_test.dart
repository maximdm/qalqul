import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:qalqul/features/onboarding/onboarding_screen.dart';
import 'package:qalqul/l10n/l10n.dart';
import 'package:qalqul/shared/providers/settings_provider.dart';

import 'helpers/fake_settings.dart';
import 'helpers/pump_localized.dart';

/// Marks the settings as already loaded, without touching sqflite.
class _LoadedSettings extends SettingsReady {
  @override
  bool build() => true;
}

void main() {
  late L10n l10n;

  setUpAll(() async {
    l10n = await L10n.delegate.load(const Locale('en'));
  });

  group('onboardingDoneProvider', () {
    test('is false while settings are empty (fresh install)', () {
      final c = ProviderContainer(
        overrides: [settingsProvider.overrideWith(FakeSettings.new)],
      );
      addTearDown(c.dispose);
      expect(c.read(onboardingDoneProvider), isFalse);
    });

    test('is true once the flag is stored', () {
      final c = ProviderContainer(
        overrides: [
          settingsProvider.overrideWith(
            () => FakeSettings({SettingKeys.onboardingDone: 'true'}),
          ),
        ],
      );
      addTearDown(c.dispose);
      expect(c.read(onboardingDoneProvider), isTrue);
    });

    test('ignores a non-"true" value', () {
      final c = ProviderContainer(
        overrides: [
          settingsProvider
              .overrideWith(() => FakeSettings({SettingKeys.onboardingDone: '1'})),
        ],
      );
      addTearDown(c.dispose);
      expect(c.read(onboardingDoneProvider), isFalse);
    });
  });

  group('OnboardingScreen', () {
    testWidgets('offers skip while it owns the window', (tester) async {
      await pumpLocalized(tester, const OnboardingScreen());
      expect(find.text(l10n.onboardingSkip), findsOneWidget);
      expect(find.text(l10n.onboardingNext), findsOneWidget);
      expect(find.text(l10n.onboardingWelcomeTitle), findsOneWidget);
    });

    testWidgets('offers a close button when pushed from Settings',
        (tester) async {
      var done = false;
      await pumpLocalized(
        tester,
        OnboardingScreen(onDone: (_) async => done = true),
      );
      expect(find.byIcon(Icons.close), findsOneWidget);
      expect(find.text(l10n.onboardingSkip), findsNothing);

      await tester.tap(find.byIcon(Icons.close));
      await tester.pumpAndSettle();
      expect(done, isTrue);
    });

    testWidgets('walks forward and back through the pages', (tester) async {
      await pumpLocalized(tester, const OnboardingScreen());

      expect(find.text('1 / 3'), findsOneWidget);

      await tester.tap(find.text(l10n.onboardingNext));
      await tester.pumpAndSettle();
      expect(find.text('2 / 3'), findsOneWidget);
      expect(find.text(l10n.onboardingTrickTitle), findsOneWidget);

      await tester.tap(find.text(l10n.onboardingNext));
      await tester.pumpAndSettle();
      expect(find.text('3 / 3'), findsOneWidget);
      expect(find.text(l10n.onboardingDashboardTitle), findsOneWidget);
      expect(find.text(l10n.onboardingStart), findsOneWidget);
      expect(find.text(l10n.onboardingStartEmpty), findsOneWidget);

      // Swiping past the last page snaps back instead of running off the end.
      await tester.fling(find.byType(PageView), const Offset(-400, 0), 1000);
      await tester.pumpAndSettle();
      expect(find.text('3 / 3'), findsOneWidget);

      // ...and swiping back works.
      await tester.fling(find.byType(PageView), const Offset(400, 0), 1000);
      await tester.pumpAndSettle();
      expect(find.text('2 / 3'), findsOneWidget);

      await tester.fling(find.byType(PageView), const Offset(400, 0), 1000);
      await tester.pumpAndSettle();
      expect(find.text('1 / 3'), findsOneWidget);
    });

    testWidgets('the code sample on page two shows the = trick',
        (tester) async {
      await pumpLocalized(tester, const OnboardingScreen());
      await tester.tap(find.text(l10n.onboardingNext));
      await tester.pumpAndSettle();

      expect(find.text('left = income - rent = 2000'), findsOneWidget);
    });

    testWidgets('starting empty records the flag', (tester) async {
      await pumpLocalized(tester, const OnboardingScreen());
      final container =
          ProviderScope.containerOf(tester.element(find.byType(OnboardingScreen)));

      // "Start empty" only appears on the last page.
      await tester.tap(find.text(l10n.onboardingNext));
      await tester.pumpAndSettle();
      await tester.tap(find.text(l10n.onboardingNext));
      await tester.pumpAndSettle();

      await tester.tap(find.text(l10n.onboardingStartEmpty));
      await tester.pumpAndSettle();

      expect(
        container.read(settingsProvider)[SettingKeys.onboardingDone],
        'true',
      );
      expect(container.read(onboardingDoneProvider), isTrue);
    });
  });

  group('first-run gate', () {
    Widget gate({Map<String, String> settings = const {}}) => ProviderScope(
          overrides: [
            settingsProvider.overrideWith(() => FakeSettings(settings)),
            settingsReadyProvider.overrideWith(_LoadedSettings.new),
          ],
          child: const MaterialApp(
            localizationsDelegates: L10n.localizationsDelegates,
            supportedLocales: L10n.supportedLocales,
            home: _GateUnderTest(),
          ),
        );

    testWidgets('shows the tour for a new install, then the dashboard',
        (tester) async {
      await tester.pumpWidget(gate());
      await tester.pumpAndSettle();

      expect(find.byType(OnboardingScreen), findsOneWidget);

      // Skipping without samples is enough to move on.
      await tester.tap(find.text(l10n.onboardingSkip));
      await tester.pumpAndSettle();

      expect(find.byType(OnboardingScreen), findsNothing);
      expect(find.byKey(const Key('dashboard')), findsOneWidget);
    });

    testWidgets('skips the tour for a returning user', (tester) async {
      await tester.pumpWidget(gate(settings: {SettingKeys.onboardingDone: 'true'}));
      await tester.pumpAndSettle();

      expect(find.byType(OnboardingScreen), findsNothing);
      expect(find.byKey(const Key('dashboard')), findsOneWidget);
    });
  });
}

/// Mirrors `_AppShell`: splash until settings load, then tour or dashboard.
class _GateUnderTest extends ConsumerWidget {
  const _GateUnderTest();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    if (!ref.watch(settingsReadyProvider)) {
      return const Center(child: CircularProgressIndicator());
    }
    if (!ref.watch(onboardingDoneProvider)) {
      return const OnboardingScreen();
    }
    return const SizedBox(key: Key('dashboard'));
  }
}
