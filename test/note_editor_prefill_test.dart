import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:qalqul/features/notes/note_editor_screen.dart';

import 'helpers/pump_localized.dart';

void main() {
  testWidgets('prefills title and body from initial values', (tester) async {
    await pumpLocalized(
      tester,
      const NoteEditorScreen(
        initialTitle: 'Calculation',
        initialBody: '12 × 8 = 96',
      ),
    );

    final fields = tester.widgetList<TextField>(find.byType(TextField)).toList();
    expect(fields, hasLength(2));
    expect(fields[0].controller?.text, 'Calculation');
    expect(fields[1].controller?.text, '12 × 8 = 96');
  });
}