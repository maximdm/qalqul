import 'package:flutter_test/flutter_test.dart';
import 'package:qalqul/features/notes/note_expression.dart';

void main() {
  test('evaluates a plain expression', () {
    expect(NoteExpression.evaluate('', '2 + 2'), 4);
    expect(NoteExpression.evaluate('', '3 * (4 + 1)'), 15);
    expect(NoteExpression.evaluate('', '10 / 4'), 2.5);
  });

  test('substitutes variables defined earlier in the text', () {
    expect(
      NoteExpression.evaluate('width = 10\nheight = 5', 'width * height'),
      50,
    );
    expect(NoteExpression.evaluate('a = 2\nb = a * 3', 'b + 1'), 7);
  });

  test('supports chained definitions across lines', () {
    expect(
      NoteExpression.evaluate('x = 2\ny = x ^ 2\nz = x + y', 'z * 2'),
      12,
    );
  });

  test('returns null for invalid expressions', () {
    expect(NoteExpression.evaluate('', '2 +'), isNull);
    expect(NoteExpression.evaluate('', 'foo('), isNull);
    expect(NoteExpression.evaluate('', ''), isNull);
  });
}
