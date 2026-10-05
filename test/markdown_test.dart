import 'package:flutter_test/flutter_test.dart';

import 'package:qalqul/core/utils/markdown.dart';

void main() {
  group('stripMarkdown', () {
    test('removes heading markers', () {
      expect(stripMarkdown('# Budget'), 'Budget');
      expect(stripMarkdown('### Deep heading'), 'Deep heading');
    });

    test('removes list and quote prefixes', () {
      expect(stripMarkdown('- milk\n- eggs'), 'milk\neggs');
      expect(stripMarkdown('1. rent\n2. power'), 'rent\npower');
      expect(stripMarkdown('> quoted note'), 'quoted note');
    });

    test('keeps link text and image alt text', () {
      expect(stripMarkdown('see [the docs](https://example.com) now'),
          'see the docs now');
      expect(stripMarkdown('![chart](chart.png)'), 'chart');
    });

    test('keeps inline code contents', () {
      expect(stripMarkdown('run `flutter test` first'), 'run flutter test first');
    });

    test('removes emphasis, html and thematic breaks', () {
      expect(stripMarkdown('**bold** and *italic*'), 'bold and italic');
      expect(stripMarkdown('<b>tagged</b>'), 'tagged');
      expect(stripMarkdown('above\n\n---\n\nbelow'), 'above\nbelow');
    });

    test('collapses whitespace and blank lines', () {
      expect(stripMarkdown('a   b\n\n\nc  '), 'a b\nc');
    });

    test('leaves plain text untouched', () {
      expect(stripMarkdown('2 + 2 = 4'), '2 + 2 = 4');
    });

    test('handles empty input', () {
      expect(stripMarkdown(''), '');
      expect(stripMarkdown('\n\n'), '');
    });
  });

  group('looksLikeMarkdown', () {
    test('detects block and inline markers', () {
      expect(looksLikeMarkdown('# Title'), isTrue);
      expect(looksLikeMarkdown('- item'), isTrue);
      expect(looksLikeMarkdown('1. item'), isTrue);
      expect(looksLikeMarkdown('> quote'), isTrue);
      expect(looksLikeMarkdown('**bold**'), isTrue);
      expect(looksLikeMarkdown('`code`'), isTrue);
      expect(looksLikeMarkdown('[link](url)'), isTrue);
    });

    test('rejects plain notes', () {
      expect(looksLikeMarkdown('Groceries 24.50'), isFalse);
      expect(looksLikeMarkdown(''), isFalse);
    });
  });
}