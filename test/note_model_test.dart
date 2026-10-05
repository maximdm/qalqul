import 'package:flutter_test/flutter_test.dart';
import 'package:qalqul/core/models/note.dart';

void main() {
  test('toMap/fromMap round trip preserves fields', () {
    final note = Note(
      id: 7,
      title: 'Ideas',
      body: 'Buy a new keyboard',
      isFavorite: true,
      createdAt: 1000,
      updatedAt: 2000,
    );
    final restored = Note.fromMap(note.toMap());
    expect(restored.id, 7);
    expect(restored.title, 'Ideas');
    expect(restored.body, 'Buy a new keyboard');
    expect(restored.isFavorite, isTrue);
    expect(restored.createdAt, 1000);
    expect(restored.updatedAt, 2000);
  });

  test('copyWith changes only given fields', () {
    final note = Note(
      title: 'A',
      body: 'b',
      createdAt: 1,
      updatedAt: 1,
    );
    final updated = note.copyWith(isFavorite: true, title: 'B');
    expect(updated.title, 'B');
    expect(updated.body, 'b');
    expect(updated.isFavorite, isTrue);
  });

  test('preview truncates long body', () {
    final note = Note(
      title: '',
      body: 'x' * 200,
      createdAt: 1,
      updatedAt: 1,
    );
    expect(note.preview.length, 81);
    expect(note.preview.endsWith('…'), isTrue);
  });

  test('isMarkdown defaults to false and round-trips', () {
    const plain = Note(title: 'A', body: 'b', createdAt: 1, updatedAt: 1);
    expect(plain.isMarkdown, isFalse);

    const md = Note(
      title: 'B',
      body: '# Heading',
      isMarkdown: true,
      createdAt: 1,
      updatedAt: 1,
    );
    expect(Note.fromMap(md.toMap()).isMarkdown, isTrue);
  });

  test('fromMap tolerates a missing is_markdown column', () {
    final note = Note.fromMap(const {
      'id': 3,
      'title': 'C',
      'body': 'd',
      'is_favorite': 0,
      'created_at': 1,
      'updated_at': 2,
    });
    expect(note.isMarkdown, isFalse);
    expect(note.isFavorite, isFalse);
  });

  test('copyWith can toggle markdown without touching the body', () {
    const note = Note(title: 'A', body: 'b', createdAt: 1, updatedAt: 1);
    final updated = note.copyWith(isMarkdown: true);
    expect(updated.isMarkdown, isTrue);
    expect(updated.body, 'b');
  });

  group('plainBody', () {
    test('strips markdown syntax from a markdown note', () {
      const note = Note(
        title: 'A',
        body: '# Heading\n\nSome **bold** text',
        isMarkdown: true,
        createdAt: 1,
        updatedAt: 1,
      );
      // Blank-line runs collapse to a single newline, as `stripMarkdown` does.
      expect(note.plainBody, 'Heading\nSome bold text');
    });

    test('leaves a plain note untouched', () {
      const note = Note(title: 'A', body: '**not** markdown',
          createdAt: 1, updatedAt: 1);
      expect(note.plainBody, '**not** markdown');
    });

    test('is not truncated, unlike preview', () {
      final note = Note(
        title: '',
        body: '${'a' * 100}needle${'b' * 100}',
        createdAt: 1,
        updatedAt: 1,
      );
      expect(note.plainBody, contains('needle'));
      expect(note.preview, isNot(contains('needle')));
    });
  });

  group('value equality', () {
    Note make() => Note(
          id: 1,
          title: 'A',
          body: 'b',
          isFavorite: true,
          createdAt: 1,
          updatedAt: 2,
        );

    test('two notes with identical fields are equal', () {
      expect(make(), equals(make()));
      expect(make().hashCode, make().hashCode);
    });

    test('differs when any field differs', () {
      expect(make() == make().copyWith(body: 'other'), isFalse);
      expect(make() == make().copyWith(title: 'other'), isFalse);
      expect(make() == make().copyWith(isFavorite: false), isFalse);
      expect(make() == make().copyWith(updatedAt: 99), isFalse);
    });

    test('is not equal to a non-Note', () {
      expect(make() == Object(), isFalse);
    });
  });
}
