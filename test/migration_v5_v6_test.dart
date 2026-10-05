import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:path/path.dart' as p;
import 'package:qalqul/core/db/database_helper.dart';
import 'package:qalqul/core/models/budget.dart';
import 'package:qalqul/core/models/investment.dart';
import 'package:qalqul/core/models/transaction.dart';
import 'package:sqflite_common_ffi/sqflite_common_ffi.dart';

/// Version 5 stored money as decimal `REAL`; version 6 stores integer minor
/// units. These tests seed a real v5 database file and let the app's own
/// [_onUpgrade] run against it, because a migration that is only exercised
/// against the schema the app creates is not really tested.
void main() {
  late Directory dir;

  setUpAll(() async {
    sqfliteFfiInit();
    databaseFactory = databaseFactoryFfi;
  });

  setUp(() async {
    dir = await Directory.systemTemp.createTemp('qalqul_migration');
  });

  tearDown(() async {
    // Windows refuses to delete a file SQLite still holds open.
    await DatabaseHelper.closeTestDatabase();
    if (dir.existsSync()) await dir.delete(recursive: true);
  });

  /// Creates a v5 database at [path] with the pre-migration schema and returns
  /// it, left open for the caller to seed.
  Future<Database> seedV5(String path) {
    return openDatabase(
      path,
      version: 5,
      onCreate: (db, _) async {
        // The exact v5 shape, copied from the schema as it shipped.
        await db.execute('''
          CREATE TABLE transactions (
            id INTEGER PRIMARY KEY AUTOINCREMENT,
            kind TEXT NOT NULL,
            amount REAL NOT NULL,
            category TEXT NOT NULL DEFAULT '',
            date INTEGER NOT NULL,
            note TEXT NOT NULL DEFAULT '',
            is_recurring INTEGER NOT NULL DEFAULT 0,
            recurrence TEXT NOT NULL DEFAULT 'monthly',
            next_due INTEGER NOT NULL DEFAULT 0,
            currency TEXT NOT NULL DEFAULT 'USD'
          )
        ''');
        await db.execute('''
          CREATE TABLE investments (
            id INTEGER PRIMARY KEY AUTOINCREMENT,
            name TEXT NOT NULL,
            principal REAL NOT NULL,
            current_value REAL NOT NULL,
            as_of INTEGER NOT NULL,
            currency TEXT NOT NULL DEFAULT 'USD'
          )
        ''');
        await db.execute('''
          CREATE TABLE budgets (
            id INTEGER PRIMARY KEY AUTOINCREMENT,
            name TEXT NOT NULL,
            target_amount REAL NOT NULL,
            saved_amount REAL NOT NULL DEFAULT 0,
            deadline INTEGER NOT NULL,
            category TEXT NOT NULL DEFAULT '',
            currency TEXT NOT NULL DEFAULT 'USD'
          )
        ''');
        // Tables v5 already had, which the migration must leave untouched.
        await db.execute('''
          CREATE TABLE notes (
            id INTEGER PRIMARY KEY AUTOINCREMENT,
            title TEXT NOT NULL DEFAULT '',
            body TEXT NOT NULL DEFAULT '',
            is_favorite INTEGER NOT NULL DEFAULT 0,
            is_markdown INTEGER NOT NULL DEFAULT 0,
            created_at INTEGER NOT NULL,
            updated_at INTEGER NOT NULL
          )
        ''');
      },
    );
  }

  /// Seeds a v5 file, closes it, and reopens it through the app's own entry
  /// point so [onUpgrade] runs for real.
  Future<Database> upgradeV5() async {
    final path = p.join(dir.path, 'qalqul.db');
    final old = await seedV5(path);
    await old.insert('transactions', {
      'kind': 'spending',
      'amount': 12.5,
      'category': 'Food',
      'date': 100,
      'note': 'lunch',
      'currency': 'USD',
    });
    await old.insert('transactions', {
      'kind': 'credit',
      'amount': 1500.0,
      'category': 'Salary',
      'date': 200,
      'currency': 'JPY',
    });
    await old.insert('investments', {
      'name': 'VTSAX',
      'principal': 1000.0,
      'current_value': 1100.5,
      'as_of': 1,
      'currency': 'USD',
    });
    await old.insert('budgets', {
      'name': 'Laptop',
      'target_amount': 1500.0,
      'saved_amount': 250.0,
      'deadline': 500,
      'category': 'Tech',
      'currency': 'USD',
    });
    await old.insert('notes', {
      'title': 'Keep me',
      'body': 'notes survive the migration',
      'created_at': 1,
      'updated_at': 2,
    });
    await old.close();

    await DatabaseHelper.useDatabaseAt(path);
    return DatabaseHelper.instance.database;
  }

  test('transaction amounts scale by the currency', () async {
    final db = await upgradeV5();
    final rows = await db.query('transactions', orderBy: 'id');

    // $12.50 becomes 1250 cents...
    expect(rows[0]['amount_minor'], 1250);
    expect(rows[0]['amount_minor'], isA<int>());
    // ...but ¥1500 stays 1500, because JPY has no minor unit.
    expect(rows[1]['amount_minor'], 1500);
    expect(rows[1]['currency'], 'JPY');
  });

  test('investment and budget columns scale too', () async {
    final db = await upgradeV5();

    final inv = await db.query('investments');
    expect(inv.first['principal_minor'], 100000);
    expect(inv.first['current_value_minor'], 110050);

    final budget = await db.query('budgets');
    expect(budget.first['target_minor'], 150000);
    expect(budget.first['saved_minor'], 25000);
  });

  test('the migration rounds rather than truncating', () async {
    final path = p.join(dir.path, 'qalqul.db');
    final old = await seedV5(path);
    await old.insert('transactions', {
      'kind': 'spending',
      'amount': 0.005,
      'category': '',
      'date': 1,
      'currency': 'USD',
    });
    await old.insert('transactions', {
      'kind': 'spending',
      'amount': 9.994,
      'category': '',
      'date': 1,
      'currency': 'USD',
    });
    await old.close();

    await DatabaseHelper.useDatabaseAt(path);
    final rows =
        await (await DatabaseHelper.instance.database).query('transactions',
            orderBy: 'id');

    expect(rows[0]['amount_minor'], 1); // 0.005 -> 0.5 cents, rounds up
    expect(rows[1]['amount_minor'], 999); // 9.994 -> 999.4 cents, rounds down
  });

  test('columns the migration does not own are preserved', () async {
    final db = await upgradeV5();
    final row = (await db.query('transactions', orderBy: 'id')).first;

    expect(row['kind'], 'spending');
    expect(row['category'], 'Food');
    expect(row['date'], 100);
    expect(row['note'], 'lunch');
    expect(row['id'], 1);

    final note = (await db.query('notes')).first;
    expect(note['title'], 'Keep me');
  });

  test('untouched domains keep their rows and their schema', () async {
    final db = await upgradeV5();
    final columns = await db.rawQuery('PRAGMA table_info(notes)');
    expect(columns.map((c) => c['name']),
        containsAll(['title', 'body', 'created_at', 'updated_at']));
  });

  test('models read upgraded rows back unchanged', () async {
    final db = await upgradeV5();

    final transactions = AppTransaction.fromMap(
      (await db.query('transactions', orderBy: 'id')).first,
    );
    expect(transactions.amountMinor, 1250);
    expect(transactions.category, 'Food');

    final investment = Investment.fromMap(
      (await db.query('investments')).first,
    );
    expect(investment.principalMinor, 100000);
    expect(investment.currentValueMinor, 110050);
    expect(investment.returnMinor, 10050);

    final budget = Budget.fromMap((await db.query('budgets')).first);
    expect(budget.targetMinor, 150000);
    expect(budget.savedMinor, 25000);
    expect(budget.progress, closeTo(25000 / 150000, 1e-9));
  });

  test('the migrated columns are really INTEGER, not REAL', () async {
    final db = await upgradeV5();
    for (final table in ['transactions', 'investments', 'budgets']) {
      final columns = await db.rawQuery('PRAGMA table_info($table)');
      for (final column in columns) {
        final name = column['name'] as String;
        if (!name.endsWith('_minor')) continue;
        expect(column['type'], 'INTEGER', reason: '$table.$name');
      }
    }
  });

  test('a fresh install creates the same schema the migration lands on', () async {
    await DatabaseHelper.useTestDatabase();
    final fresh = await DatabaseHelper.instance.database;
    final migrated = await upgradeV5();

    for (final table in ['transactions', 'investments', 'budgets']) {
      final freshColumns = await fresh.rawQuery('PRAGMA table_info($table)');
      final migratedColumns = await migrated.rawQuery('PRAGMA table_info($table)');
      expect(
        migratedColumns.map((c) => '${c['name']}:${c['type']}'),
        freshColumns.map((c) => '${c['name']}:${c['type']}'),
        reason: table,
      );
    }
  });
}
