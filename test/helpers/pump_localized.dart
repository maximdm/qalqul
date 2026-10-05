import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_riverpod/misc.dart' show Override;
import 'package:flutter_test/flutter_test.dart';

import 'package:qalqul/l10n/l10n.dart';

/// Pumps [child] inside a `MaterialApp` that has the generated localizations
/// installed, which every screen in the app now expects (`context.l10n`).
///
/// Pass [overrides] to seed Riverpod providers (e.g. an in-memory database).
Future<void> pumpLocalized(
  WidgetTester tester,
  Widget child, {
  List<Override> overrides = const [],
  Locale? locale,
}) async {
  await tester.pumpWidget(
    ProviderScope(
      overrides: overrides,
      child: MaterialApp(
        locale: locale,
        localizationsDelegates: L10n.localizationsDelegates,
        supportedLocales: L10n.supportedLocales,
        home: child,
      ),
    ),
  );
  await tester.pumpAndSettle();
}