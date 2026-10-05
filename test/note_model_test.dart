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
}
