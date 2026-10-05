import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:qalqul/core/theme.dart';
import 'package:qalqul/features/calculator/calculator_screen.dart';
import 'package:qalqul/l10n/l10n.dart';

Future<void> _pump(WidgetTester tester, ThemeData theme) {
  return tester.pumpWidget(
    ProviderScope(
      child: MaterialApp(
        theme: theme,
        localizationsDelegates: L10n.localizationsDelegates,
        supportedLocales: L10n.supportedLocales,
        home: const CalculatorScreen(),
      ),
    ),
  );
}

TextButton _button(WidgetTester tester, String label) => tester.widget<TextButton>(
      find.ancestor(of: find.text(label), matching: find.byType(TextButton)),
    );

Color? _bg(WidgetTester tester, String label) =>
    _button(tester, label).style?.backgroundColor?.resolve(const <WidgetState>{});

void main() {
  testWidgets('equals key is tinted like the other operators', (tester) async {
    await _pump(tester, AppTheme.light);
    await tester.pumpAndSettle();

    expect(_bg(tester, '='), _bg(tester, '+'));
  });

  testWidgets('equals key is round', (tester) async {
    await _pump(tester, AppTheme.light);
    await tester.pumpAndSettle();

    expect(
      _button(tester, '=').style?.shape?.resolve(const <WidgetState>{}),
      isA<CircleBorder>(),
    );
  });

  testWidgets('other keys keep the rounded square shape', (tester) async {
    await _pump(tester, AppTheme.light);
    await tester.pumpAndSettle();

    expect(
      _button(tester, '+').style?.shape?.resolve(const <WidgetState>{}),
      isA<RoundedRectangleBorder>(),
    );
  });

  testWidgets('scientific toggle reveals the scientific pad', (tester) async {
    await _pump(tester, AppTheme.light);
    await tester.pumpAndSettle();

    expect(find.text('n!'), findsNothing);

    await tester.tap(find.text('SCI'));
    await tester.pumpAndSettle();

    expect(find.text('n!'), findsOneWidget);
    expect(find.text('sin⁻¹'), findsOneWidget);
    expect(find.text('Ans'), findsOneWidget);
    // The main pad stays reachable underneath.
    expect(find.text('7'), findsOneWidget);
  });
}