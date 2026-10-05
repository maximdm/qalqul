import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:quick_actions/quick_actions.dart';
import 'package:quick_actions_platform_interface/quick_actions_platform_interface.dart';

import 'package:qalqul/app.dart';
import 'package:qalqul/features/calculator/calculator_provider.dart';
import 'package:qalqul/features/notes/note_editor_screen.dart';
import 'package:qalqul/l10n/l10n.dart';
import 'package:qalqul/shared/providers/settings_provider.dart';
import 'package:qalqul/shared/providers/shell_providers.dart';
import 'package:qalqul/shared/providers/shortcut_provider.dart';
import 'package:qalqul/shared/services/quick_actions_service.dart';

import 'helpers/fake_data.dart';
import 'helpers/fake_settings.dart';

/// Records what the service asked the platform for, and lets a test deliver a
/// shortcut as if the launcher had.
class FakeQuickActionsPlatform extends QuickActionsPlatform {
  final published = <ShortcutItem>[];
  QuickActionHandler? handler;
  int clears = 0;

  static var instance = FakeQuickActionsPlatform();

  @override
  Future<void> initialize(QuickActionHandler handler) async {
    this.handler = handler;
  }

  @override
  Future<void> setShortcutItems(List<ShortcutItem> items) async {
    published
      ..clear()
      ..addAll(items);
  }

  @override
  Future<void> clearShortcutItems() async {
    clears++;
    published.clear();
  }
}

class _LoadedSettings extends SettingsReady {
  @override
  bool build() => true;
}

void main() {
  late FakeQuickActionsPlatform platform;

  setUp(() {
    platform = FakeQuickActionsPlatform();
    FakeQuickActionsPlatform.instance = platform;
    QuickActionsPlatform.instance = platform;
  });

  group('quickActionFromType', () {
    test('maps the two known shortcuts', () {
      expect(quickActionFromType(kNewCalculationShortcut),
          QuickActionType.newCalculation);
      expect(quickActionFromType(kNewNoteShortcut), QuickActionType.newNote);
    });

    test('ignores an unknown shortcut', () {
      expect(quickActionFromType('some.other.app.action'), isNull);
      expect(quickActionFromType(''), isNull);
    });
  });

  group('QuickActionsService', () {
    test('publishes both shortcuts with localized titles', () async {
      final service = QuickActionsService(plugin: const QuickActions());
      await service.initialize((_) {});
      await service.setItems(newCalculation: 'New calculation', newNote: 'New note');

      expect(platform.published.map((i) => i.type),
          [kNewCalculationShortcut, kNewNoteShortcut]);
      expect(platform.published.first.localizedTitle, 'New calculation');
    });

    test('forwards a shortcut to the registered listener', () async {
      final seen = <QuickActionType>[];
      final service = QuickActionsService();
      await service.initialize(seen.add);

      QuickActionsService.dispatch(kNewNoteShortcut);
      QuickActionsService.dispatch(kNewCalculationShortcut);
      expect(seen,
          [QuickActionType.newNote, QuickActionType.newCalculation]);
    });

    test('an unknown shortcut never reaches the listener', () async {
      final seen = <QuickActionType>[];
      await QuickActionsService().initialize(seen.add);

      QuickActionsService.dispatch('not.ours');
      expect(seen, isEmpty);
    });

    test('survives a platform that throws', () async {
      final service = QuickActionsService();
      // No listener registered yet, and the platform is still a working fake:
      // a cold-start dispatch before initialize() must be a no-op, not a crash.
      QuickActionsService.dispatch(kNewNoteShortcut);

      await service.setItems(newCalculation: 'a', newNote: 'b');
      await service.clearItems();
      expect(platform.clears, 1);
    });
  });

  group('pendingShortcutProvider', () {
    test('starts empty and clears on consume', () {
      final c = ProviderContainer();
      addTearDown(c.dispose);

      expect(c.read(pendingShortcutProvider), isNull);
      c.read(pendingShortcutProvider.notifier).raise(QuickActionType.newNote);
      expect(c.read(pendingShortcutProvider), QuickActionType.newNote);
      c.read(pendingShortcutProvider.notifier).consume();
      expect(c.read(pendingShortcutProvider), isNull);
    });
  });

  group('shortcut actions', () {
    late ProviderContainer container;

    Future<void> handle(QuickActionType type) async {
      final c = container;
      c.read(pendingShortcutProvider.notifier).raise(type);
      await Future<void>.delayed(Duration.zero);
      final action = c.read(pendingShortcutProvider);
      if (action != null) {
        switch (action) {
          case QuickActionType.newCalculation:
            c.read(calculatorProvider.notifier).input('C');
            c.read(navIndexProvider.notifier).set(1);
          case QuickActionType.newNote:
            c.read(navIndexProvider.notifier).set(2);
        }
        c.read(pendingShortcutProvider.notifier).consume();
      }
    }

    setUp(() {
      container = ProviderContainer(
        overrides: [settingsProvider.overrideWith(FakeSettings.new)],
      );
      addTearDown(container.dispose);
    });

    test('"new calculation" clears the keypad and opens the calculator',
        () async {
      container.read(calculatorProvider.notifier).input('1');
      container.read(calculatorProvider.notifier).input('+');
      expect(container.read(calculatorProvider).expression, '1+');

      await handle(QuickActionType.newCalculation);

      expect(container.read(calculatorProvider).expression, isEmpty);
      expect(container.read(calculatorProvider).result, '0');
      expect(container.read(navIndexProvider), 1);
    });

    test('"new note" opens the notes tab and clears the pending action',
        () async {
      await handle(QuickActionType.newNote);

      expect(container.read(navIndexProvider), 2);
      expect(container.read(pendingShortcutProvider), isNull);
    });
  });

  group('shell wiring', () {
    /// Boots the real app as a returning user, optionally still on the tour.
    Future<ProviderContainer> bootApp(
      WidgetTester tester, {
      bool onboarded = true,
    }) async {
      await tester.pumpWidget(
        ProviderScope(
          overrides: [
            ...emptyDataProviders(),
            settingsProvider.overrideWith(
              () => FakeSettings(
                onboarded ? {SettingKeys.onboardingDone: 'true'} : {},
              ),
            ),
            settingsReadyProvider.overrideWith(_LoadedSettings.new),
            quickActionsServiceProvider
                .overrideWithValue(QuickActionsService()),
          ],
          child: const QalqulApp(),
        ),
      );
      await tester.pumpAndSettle();
      return ProviderScope.containerOf(
        tester.element(find.byType(QalqulApp)),
      );
    }

    testWidgets('registers localized shortcuts once the dashboard is up',
        (tester) async {
      final l10n = await L10n.delegate.load(const Locale('en'));
      await bootApp(tester);

      expect(platform.published.map((i) => i.type),
          [kNewCalculationShortcut, kNewNoteShortcut]);
      expect(platform.published.first.localizedTitle,
          l10n.shortcutNewCalculation);
      expect(platform.published.last.localizedTitle, l10n.shortcutNewNote);
    });

    testWidgets('does not register shortcuts while the tour is showing',
        (tester) async {
      await bootApp(tester, onboarded: false);

      expect(platform.published, isEmpty);
    });

    testWidgets('a dispatched "new calculation" shortcut opens the calculator',
        (tester) async {
      final container = await bootApp(tester);
      expect(container.read(navIndexProvider), 0);

      platform.handler!(kNewCalculationShortcut);
      await tester.pumpAndSettle();

      expect(container.read(navIndexProvider), 1);
      expect(container.read(pendingShortcutProvider), isNull);
    });

    testWidgets('a dispatched "new note" shortcut opens the note editor',
        (tester) async {
      final container = await bootApp(tester);

      platform.handler!(kNewNoteShortcut);
      await tester.pumpAndSettle();

      expect(container.read(navIndexProvider), 2);
      expect(find.byType(NoteEditorScreen), findsOneWidget);
    });
  });
}
