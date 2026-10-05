import 'dart:convert';
import 'dart:typed_data';

import 'package:file_picker/file_picker.dart';
import 'package:sqflite/sqflite.dart';

import 'package:qalqul/core/db/database_helper.dart';

/// Exports and imports the full local database as a single JSON file.
///
/// Returns a short status code: `ok`, `cancelled`, `bad`, or `error: <msg>`.
///
/// `app_settings` is deliberately excluded — locale, base currency and app lock
/// are device-local, and a backup shouldn't silently re-enable someone's lock.
class BackupService {
  static const _tables = [
    'notes',
    'transactions',
    'investments',
    'budgets',
    'user_widgets',
    'fx_rates',
  ];

  static Future<String> export() async {
    try {
      final db = await DatabaseHelper.instance.database;
      final tables = <String, dynamic>{};
      for (final t in _tables) {
        tables[t] = await db.query(t);
      }
      final payload = {
        'app': 'qalqul',
        'version': 1,
        'exportedAt': DateTime.now().toIso8601String(),
        'tables': tables,
      };

      final uri = await FilePicker.saveFile(
        dialogTitle: 'Export Qalqul backup',
        fileName: 'qalqul-backup.json',
        bytes: Uint8List.fromList(utf8.encode(jsonEncode(payload))),
        type: FileType.custom,
        allowedExtensions: ['json'],
      );
      if (uri == null) return 'cancelled';
      return 'ok';
    } catch (e) {
      return 'error: $e';
    }
  }

  static Future<String> import() async {
    try {
      final files = await FilePicker.pickFiles(
        dialogTitle: 'Import Qalqul backup',
        type: FileType.custom,
        allowedExtensions: ['json'],
      );
      if (files.isEmpty) return 'cancelled';

      final file = files.first;
      final content = utf8.decode(await file.readAsBytes());

      final data = jsonDecode(content) as Map<String, dynamic>;
      final tables = data['tables'] as Map<String, dynamic>?;
      if (tables == null) return 'bad';

      final db = await DatabaseHelper.instance.database;
      await db.transaction((txn) async {
        for (final t in _tables) {
          final rows =
              (tables[t] as List?)?.cast<Map<String, dynamic>>() ?? [];
          await txn.delete(t);
          for (final row in rows) {
            await txn.insert(
              t,
              row,
              conflictAlgorithm: ConflictAlgorithm.replace,
            );
          }
        }
      });
      return 'ok';
    } catch (e) {
      return 'error: $e';
    }
  }

  /// Exports all transactions to a CSV file (useful for spreadsheets).
  ///
  /// Amounts are written in the record's own currency; the `currency` column
  /// makes that unambiguous for the spreadsheet.
  static Future<String> exportCsv() async {
    try {
      final db = await DatabaseHelper.instance.database;
      final rows = await db.query('transactions', orderBy: 'date DESC');
      const headers = [
        'id',
        'kind',
        'amount',
        'currency',
        'category',
        'date',
        'note',
        'is_recurring',
        'recurrence',
        'next_due',
      ];
      final buffer = StringBuffer()..writeln(headers.join(','));
      for (final r in rows) {
        buffer.writeln(
          headers
              .map((h) {
                final v = r[h]?.toString() ?? '';
                return v.contains(',') || v.contains('"') ? '"$v"' : v;
              })
              .join(','),
        );
      }

      final uri = await FilePicker.saveFile(
        dialogTitle: 'Export transactions (CSV)',
        fileName: 'qalqul-transactions.csv',
        bytes: Uint8List.fromList(utf8.encode(buffer.toString())),
        type: FileType.custom,
        allowedExtensions: ['csv'],
      );
      if (uri == null) return 'cancelled';
      return 'ok';
    } catch (e) {
      return 'error: $e';
    }
  }
}