import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:qalqul/features/notes/note_editor_screen.dart';

import 'helpers/pump_localized.dart';

void main() {
  Future<void> enterBody(WidgetTester tester, String text) async {
    final body = find.byType(TextField).last;
    await tester.tap(body);
    await tester.pumpAndSettle();
    await tester.enterText(body, text);
    await tester.pumpAndSettle();
  }

  testWidgets('evaluates a plain expression on the current line', (tester) async {
    await pumpLocalized(tester, const NoteEditorScreen());

    await enterBody(tester, '2 + 2');
    await tester.tap(find.byIcon(Icons.functions));
    await tester.pumpAndSettle();

    final body = tester
        .widget<TextField>(find.byType(TextField).last)
        .controller!
        .text;
    expect(body, '2 + 2 = 4');
  });

  testWidgets('evaluates using variables defined earlier in the note',
      (tester) async {
    await pumpLocalized(tester, const NoteEditorScreen());

    await enterBody(tester, 'width = 10\nheight = 5\nwidth * height');
    await tester.tap(find.byIcon(Icons.functions));
    await tester.pumpAndSettle();

    final body = tester
        .widget<TextField>(find.byType(TextField).last)
        .controller!
        .text;
    expect(body, 'width = 10\nheight = 5\nwidth * height = 50');
  });

  testWidgets('Tab key evaluates the current line', (tester) async {
    await pumpLocalized(tester, const NoteEditorScreen());

    await enterBody(tester, '2 + 2');
    await tester.sendKeyEvent(LogicalKeyboardKey.tab);
    await tester.pumpAndSettle();

    final body = tester
        .widget<TextField>(find.byType(TextField).last)
        .controller!
        .text;
    expect(body, '2 + 2 = 4');
  });

  testWidgets('typing "expr =" auto-computes inline', (tester) async {
    await pumpLocalized(tester, const NoteEditorScreen());

    await enterBody(tester, '2+2=');
    await tester.pumpAndSettle();

    final body = tester
        .widget<TextField>(find.byType(TextField).last)
        .controller!
        .text;
    expect(body, '2+2=4');
  });

  testWidgets('chaining after = continues the calculation', (tester) async {
    await pumpLocalized(tester, const NoteEditorScreen());

    await enterBody(tester, '2+2=');
    await tester.pumpAndSettle();
    expect(
      tester.widget<TextField>(find.byType(TextField).last).controller!.text,
      '2+2=4',
    );

    await enterBody(tester, '2+2=4+2+2=');
    await tester.pumpAndSettle();
    expect(
      tester.widget<TextField>(find.byType(TextField).last).controller!.text,
      '2+2=4+2+2=8',
    );

    await enterBody(tester, '2+2=4+2+2=8/2=');
    await tester.pumpAndSettle();
    expect(
      tester.widget<TextField>(find.byType(TextField).last).controller!.text,
      '2+2=4+2+2=8/2=4',
    );
  });
}
