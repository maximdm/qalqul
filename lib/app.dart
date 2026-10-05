import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:qalqul/core/theme.dart';
import 'package:qalqul/features/calculator/calculator_provider.dart';
import 'package:qalqul/features/calculator/calculator_screen.dart';
import 'package:qalqul/features/finance/finance_screen.dart';
import 'package:qalqul/features/finance/reminder_service.dart';
import 'package:qalqul/features/home/home_screen.dart';
import 'package:qalqul/features/notes/note_editor_screen.dart';
import 'package:qalqul/features/notes/notes_screen.dart';
import 'package:qalqul/features/onboarding/onboarding_screen.dart';
import 'package:qalqul/features/security/app_lock_gate.dart';
import 'package:qalqul/l10n/l10n.dart';
import 'package:qalqul/shared/brand/brand_mark.dart';
import 'package:qalqul/shared/providers/settings_provider.dart';
import 'package:qalqul/shared/providers/shell_providers.dart';
import 'package:qalqul/shared/providers/shortcut_provider.dart';
import 'package:qalqul/shared/services/quick_actions_service.dart';
import 'package:qalqul/shared/widgets/bottom_nav.dart';

class QalqulApp extends ConsumerWidget {
  const QalqulApp({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final themeMode = ref.watch(themeModeProvider);
    final locale = ref.watch(localeProvider);
    return MaterialApp(
      // Resolved from a context below MaterialApp so Localizations exists.
      onGenerateTitle: (context) => context.l10n.appTitle,
      themeMode: themeMode,
      theme: AppTheme.light,
      darkTheme: AppTheme.dark,
      debugShowCheckedModeBanner: false,
      locale: locale,
      localizationsDelegates: L10n.localizationsDelegates,
      supportedLocales: L10n.supportedLocales,
      home: AppLockGate(
        child: const _AppShell(),
      ),
    );
  }
}

/// Decides what the window shows: the splash while preferences load, the
/// first-run tour for a new install, otherwise the tabbed dashboard.
///
/// Also owns the home-screen shortcuts: they're registered once the dashboard
/// is really on screen, so a shortcut can't navigate a widget that isn't
/// mounted yet.
class _AppShell extends ConsumerStatefulWidget {
  const _AppShell();

  static const calculatorTab = 1;
  static const notesTab = 2;

  static const screens = [
    HomeScreen(),
    CalculatorScreen(),
    NotesScreen(),
    FinanceScreen(),
  ];

  @override
  ConsumerState<_AppShell> createState() => _AppShellState();
}

class _AppShellState extends ConsumerState<_AppShell> {
  bool _shortcutsRegistered = false;

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    // Dependencies (localizations, settings) are available from here on.
    if (_shortcutsRegistered) return;
    if (!ref.read(settingsReadyProvider)) return;
    if (!ref.read(onboardingDoneProvider)) return;
    _shortcutsRegistered = true;
    _registerShortcuts();
  }

  Future<void> _registerShortcuts() async {
    final l10n = context.l10n;
    final service = ref.read(quickActionsServiceProvider);
    await service.initialize(
      (type) => ref.read(pendingShortcutProvider.notifier).raise(type),
    );
    await service.setItems(
      newCalculation: l10n.shortcutNewCalculation,
      newNote: l10n.shortcutNewNote,
    );
  }

  void _handleShortcut(QuickActionType type) {
    final nav = ref.read(navIndexProvider.notifier);
    switch (type) {
      case QuickActionType.newCalculation:
        // A fresh calculation: clear the keypad and show it.
        ref.read(calculatorProvider.notifier).input('C');
        nav.set(_AppShell.calculatorTab);
      case QuickActionType.newNote:
        nav.set(_AppShell.notesTab);
        Navigator.of(context).push(
          MaterialPageRoute<void>(builder: (_) => const NoteEditorScreen()),
        );
    }
  }

  @override
  Widget build(BuildContext context) {
    // Acted on outside the build phase: the shortcut navigates.
    ref.listen<QuickActionType?>(pendingShortcutProvider, (_, next) {
      if (next == null) return;
      _handleShortcut(next);
      ref.read(pendingShortcutProvider.notifier).consume();
    });

    // Reminders are scheduled outside the widget tree, so the service has to be
    // handed the resolved localizations or its notifications stay in the
    // device language. Re-runs whenever the locale setting changes.
    ref.listen(localeProvider, (_, _) {
      unawaited(ReminderService.configure(context.l10n));
    });
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted) unawaited(ReminderService.configure(context.l10n));
    });

    if (!ref.watch(settingsReadyProvider)) {
      return const _SplashScreen();
    }
    if (!ref.watch(onboardingDoneProvider)) {
      return const OnboardingScreen();
    }

    final index = ref.watch(navIndexProvider);
    return Scaffold(
      body: IndexedStack(
        index: index,
        children: _AppShell.screens,
      ),
      bottomNavigationBar: AppBottomNav(
        currentIndex: index,
        onTap: (i) => ref.read(navIndexProvider.notifier).set(i),
      ),
    );
  }
}

/// Shown for the handful of frames before sqflite has answered, so returning
/// users never see the onboarding flash past.
class _SplashScreen extends StatelessWidget {
  const _SplashScreen();

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    return ColoredBox(
      color: scheme.primary,
      child: Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const BrandMark(size: 96),
            const SizedBox(height: 28),
            SizedBox(
              width: 22,
              height: 22,
              child: CircularProgressIndicator(
                strokeWidth: 2.4,
                color: scheme.onPrimary,
              ),
            ),
          ],
        ),
      ),
    );
  }
}