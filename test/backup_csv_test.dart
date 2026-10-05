import 'package:flutter_test/flutter_test.dart';

import 'package:qalqul/features/settings/backup_service.dart';

/// Splits a CSV document into records, honouring quoted newlines, then splits
/// each record into fields. Deliberately independent of the writer so the test
/// checks the *parsed* shape rather than trusting the escaping it just produced.
List<List<String>> parseCsv(String document) {
  final records = <List<String>>[];
  var fields = <String>[];
  final buffer = StringBuffer();
  var inQuotes = false;
  var started = false;

  for (var i = 0; i < document.length; i++) {
    final ch = document[i];
    if (inQuotes) {
      if (ch == '"') {
        if (i + 1 < document.length && document[i + 1] == '"') {
          buffer.write('"');
          i++;
        } else {
          inQuotes = false;
        }
      } else {
        buffer.write(ch);
      }
      continue;
    }
    if (ch == '"') {
      inQuotes = true;
      started = true;
    } else if (ch == ',') {
      fields.add(buffer.toString());
      buffer.clear();
      started = true;
    } else if (ch == '\n' || ch == '\r') {
      if (ch == '\r' && i + 1 < document.length && document[i + 1] == '\n') {
        i++;
      }
      fields.add(buffer.toString());
      buffer.clear();
      // Skip the blank line a trailing newline leaves behind.
      if (started || fields.any((f) => f.isNotEmpty)) {
        records.add(fields);
      }
      fields = <String>[];
      started = false;
    } else {
      buffer.write(ch);
      started = true;
    }
  }
  if (started || buffer.isNotEmpty) {
    fields.add(buffer.toString());
    records.add(fields);
  }
  return records;
}

void main() {
  group('csvCell', () {
    test('leaves plain values alone', () {
      expect(csvCell('groceries'), 'groceries');
      expect(csvCell(''), '');
    });

    test('quotes values containing a comma', () {
      expect(csvCell('rent, water'), '"rent, water"');
    });

    test('doubles embedded quotes instead of just wrapping', () {
      // The old writer produced "He said "hi", loudly", which a spreadsheet
      // parses as two fields.
      expect(csvCell('He said "hi"'), '"He said ""hi"""');
    });

    test('quotes values containing a newline', () {
      expect(csvCell('line1\nline2'), '"line1\nline2"');
    });

    test('neutralises formula injection but not real numbers', () {
      expect(csvCell('=1+1'), "'=1+1");
      expect(csvCell('+SUM(A1)'), "'+SUM(A1)");
      expect(csvCell('@import'), "'@import");
      // Numbers must stay numeric or spreadsheets show them as text.
      expect(csvCell(12.5), '12.5');
      expect(csvCell(-12.5), '-12.5');
    });

    test('renders null as an empty field', () {
      expect(csvCell(null), '');
    });
  });

  group('buildTransactionsCsv', () {
    Map<String, Object?> row({
      int id = 1,
      String kind = 'debit',
      double amount = 12.5,
      String currency = 'USD',
      String category = 'food',
      String note = '',
    }) {
      return {
        'id': id,
        'kind': kind,
        'amount': amount,
        'currency': currency,
        'category': category,
        'date': 1772000000000,
        'note': note,
        'is_recurring': 0,
        'recurrence': 'monthly',
        'next_due': 0,
      };
    }

    test('emits a header plus one line per row', () {
      final records = parseCsv(buildTransactionsCsv([row(), row(id: 2)]));
      expect(records, hasLength(3));
      expect(records.first, transactionCsvHeaders);
    });

    test('every row keeps all ten columns despite awkward text', () {
      final records = parseCsv(buildTransactionsCsv([
        row(note: 'He said "hi", loudly', category: 'food, dining'),
        row(id: 2, note: 'multi\nline'),
      ]));

      for (final record in records) {
        expect(record, hasLength(transactionCsvHeaders.length));
      }
      // A quoted newline must not split the record in two.
      expect(records, hasLength(3));
    });

    test('awkward text lands in the column it came from', () {
      final records = parseCsv(buildTransactionsCsv([
        row(note: 'He said "hi", loudly', category: 'food, dining'),
      ]));
      final fields = records.last;
      expect(fields[transactionCsvHeaders.indexOf('category')], 'food, dining');
      expect(fields[transactionCsvHeaders.indexOf('note')],
          'He said "hi", loudly');
    });

    test('an embedded newline survives the round trip', () {
      final records = parseCsv(buildTransactionsCsv([row(note: 'a\nb')]));
      expect(records.last[transactionCsvHeaders.indexOf('note')], 'a\nb');
    });

    test('a note that looks like a formula cannot execute', () {
      final csv = buildTransactionsCsv([row(note: '=cmd|calc')]);
      // Neutralised with an apostrophe, which a spreadsheet reads as text.
      expect(csv, contains("'=cmd|calc"));
      final records = parseCsv(csv);
      expect(records.last[transactionCsvHeaders.indexOf('note')],
          "'=cmd|calc");
    });

    test('an empty table still yields a header', () {
      final records = parseCsv(buildTransactionsCsv(const []));
      expect(records, hasLength(1));
      expect(records.first, transactionCsvHeaders);
    });
  });
}
