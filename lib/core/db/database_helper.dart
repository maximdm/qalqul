import 'dart:async';
import 'dart:io';

import 'package:flutter/foundation.dart';
import 'package:path/path.dart';
import 'package:qalqul/core/utils/money.dart';
import 'package:sqflite_common_ffi/sqflite_common_ffi.dart';
import 'package:sqflite_common_ffi_web/sqflite_ffi_web.dart';

class DatabaseHelper {
  static const _dbName = 'qalqul.db';
  static const _dbVersion = 6;

  DatabaseHelper._();
  static final DatabaseHelper instance = DatabaseHelper._();

  Database? _database;

  Future<Database> get database async {
    _database ??= await _init();
    return _database!;
  }

  /// Test-only hook: point the singleton at an isolated in-memory database so
  /// repository tests don't touch the on-device file DB.
  ///
  /// Reuses [_onCreate] rather than restating the table list, so a new domain
  /// can't be added to the app schema and quietly missed by the test schema.
  static Future<void> useTestDatabase() async {
    sqfliteFfiInit();
    databaseFactory = databaseFactoryFfi;
    instance._database = await openDatabase(
      inMemoryDatabasePath,
      version: _dbVersion,
      onCreate: instance._onCreate,
    );
  }

  /// Test-only hook: open the database file at [path] through the real app
  /// entry point, [_onCreate]/[_onUpgrade] included.
  ///
  /// A migration can only be tested by upgrading a file that already holds an
  /// older schema, and an in-memory database cannot survive being closed. Tests
  /// seed a v5 file with [openDatabase] and then hand the path here to let the
  /// app's own upgrade path run against it.
  @visibleForTesting
  static Future<void> useDatabaseAt(String path) async {
    sqfliteFfiInit();
    databaseFactory = databaseFactoryFfi;
    instance._database = await openDatabase(
      path,
      version: _dbVersion,
      onCreate: instance._onCreate,
      onUpgrade: instance._onUpgrade,
    );
  }

  /// Test-only hook: close the open database and forget the cached handle, so a
  /// test can delete the file behind it or point the singleton at another one.
  @visibleForTesting
  static Future<void> closeTestDatabase() async {
    final open = instance._database;
    instance._database = null;
    await open?.close();
  }

  Future<Database> _init() async {
    // On the web there is no dart:io filesystem, so sqflite uses the
    // WASM build backed by IndexedDB. `Platform` is unsupported there and
    // would throw, so branch on kIsWeb before touching it.
    if (kIsWeb) {
      databaseFactory = databaseFactoryFfiWeb;
      return openDatabase(
        _dbName,
        version: _dbVersion,
        onCreate: _onCreate,
        onUpgrade: _onUpgrade,
      );
    }
    if (Platform.isWindows || Platform.isLinux) {
      sqfliteFfiInit();
      databaseFactory = databaseFactoryFfi;
    }
    final dir = await getDatabasesPath();
    final path = join(dir, _dbName);
    return openDatabase(
      path,
      version: _dbVersion,
      onCreate: _onCreate,
      onUpgrade: _onUpgrade,
    );
  }

  Future<void> _onCreate(Database db, int version) async {
    await _createNotes(db);
    await _createTransactions(db);
    await _createInvestments(db);
    await _createBudgets(db);
    await _createUserWidgets(db);
    await _createFxRates(db);
    await _createAppSettings(db);
  }

  Future<void> _onUpgrade(Database db, int oldVersion, int newVersion) async {
    if (oldVersion < 2) {
      await _createTransactions(db);
      await _createInvestments(db);
      await _createBudgets(db);
    }
    if (oldVersion < 3) {
      await _createUserWidgets(db);
    }
    if (oldVersion < 4) {
      await db.execute(
        'ALTER TABLE transactions ADD COLUMN is_recurring INTEGER NOT NULL DEFAULT 0',
      );
      await db.execute(
        "ALTER TABLE transactions ADD COLUMN recurrence TEXT NOT NULL DEFAULT 'monthly'",
      );
      await db.execute(
        'ALTER TABLE transactions ADD COLUMN next_due INTEGER NOT NULL DEFAULT 0',
      );
    }
    if (oldVersion < 5) {
      // Markdown flag on notes.
      await db.execute(
        'ALTER TABLE notes ADD COLUMN is_markdown INTEGER NOT NULL DEFAULT 0',
      );
      // Per-record currency (default matches the pre-multi-currency behaviour).
      for (final table in ['transactions', 'investments', 'budgets']) {
        await db.execute(
          "ALTER TABLE $table ADD COLUMN currency TEXT NOT NULL DEFAULT 'USD'",
        );
      }
      await _createFxRates(db);
      await _createAppSettings(db);
    }
    if (oldVersion < 6) {
      await _migrateMoneyToMinorUnits(db);
    }
  }

  /// Multiplier SQL yielding a row's minor-unit scale from its currency.
  ///
  /// Generated from [supportedCurrencies] rather than written out by hand: a
  /// currency with a different number of fraction digits (JPY has none) must not
  /// be scaled by 100 during a migration, and hardcoding that would let the two
  /// lists drift apart silently.
  String _scaleCaseSql() {
    final clauses = <String>[
      for (final c in supportedCurrencies)
        if (c.scale != 100) "WHEN '${c.code}' THEN ${c.scale}",
    ];
    return 'CASE UPPER(currency) ${clauses.join(' ')} ELSE 100 END';
  }

  /// Rewrites the money columns from decimal `REAL` to integer minor units.
  ///
  /// SQLite cannot change a declared column type, and the multiplier differs per
  /// currency, so each table is rebuilt and copied through a scale-aware
  /// expression. `onUpgrade` runs inside a transaction, so a failure anywhere
  /// here leaves the old tables untouched.
  ///
  /// Written out per table rather than looped over a description: the column
  /// lists differ enough that a generic version needed more scaffolding than it
  /// saved.
  Future<void> _migrateMoneyToMinorUnits(Database db) async {
    final scale = _scaleCaseSql();

    await db.execute('DROP TABLE IF EXISTS transactions_v6');
    await _createTransactions(db, table: 'transactions_v6');
    await db.execute('''
      INSERT INTO transactions_v6
        (id, kind, amount_minor, category, date, note,
         is_recurring, recurrence, next_due, currency)
      SELECT id, kind, CAST(ROUND(amount * $scale) AS INTEGER), category, date,
             note, is_recurring, recurrence, next_due, currency
      FROM transactions
    ''');
    await db.execute('DROP TABLE transactions');
    await db.execute('ALTER TABLE transactions_v6 RENAME TO transactions');

    await db.execute('DROP TABLE IF EXISTS investments_v6');
    await _createInvestments(db, table: 'investments_v6');
    await db.execute('''
      INSERT INTO investments_v6
        (id, name, principal_minor, current_value_minor, as_of, currency)
      SELECT id, name, CAST(ROUND(principal * $scale) AS INTEGER),
             CAST(ROUND(current_value * $scale) AS INTEGER), as_of, currency
      FROM investments
    ''');
    await db.execute('DROP TABLE investments');
    await db.execute('ALTER TABLE investments_v6 RENAME TO investments');

    await db.execute('DROP TABLE IF EXISTS budgets_v6');
    await _createBudgets(db, table: 'budgets_v6');
    await db.execute('''
      INSERT INTO budgets_v6
        (id, name, target_minor, saved_minor, deadline, category, currency)
      SELECT id, name, CAST(ROUND(target_amount * $scale) AS INTEGER),
             CAST(ROUND(saved_amount * $scale) AS INTEGER), deadline, category,
             currency
      FROM budgets
    ''');
    await db.execute('DROP TABLE budgets');
    await db.execute('ALTER TABLE budgets_v6 RENAME TO budgets');
  }

  Future<void> _createNotes(Database db) async {
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
  }

  Future<void> _createTransactions(Database db, {String table = 'transactions'}) async {
    await db.execute('''
      CREATE TABLE $table (
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        kind TEXT NOT NULL,
        amount_minor INTEGER NOT NULL,
        category TEXT NOT NULL DEFAULT '',
        date INTEGER NOT NULL,
        note TEXT NOT NULL DEFAULT '',
        is_recurring INTEGER NOT NULL DEFAULT 0,
        recurrence TEXT NOT NULL DEFAULT 'monthly',
        next_due INTEGER NOT NULL DEFAULT 0,
        currency TEXT NOT NULL DEFAULT 'USD'
      )
    ''');
  }

  Future<void> _createInvestments(Database db, {String table = 'investments'}) async {
    await db.execute('''
      CREATE TABLE $table (
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        name TEXT NOT NULL,
        principal_minor INTEGER NOT NULL,
        current_value_minor INTEGER NOT NULL,
        as_of INTEGER NOT NULL,
        currency TEXT NOT NULL DEFAULT 'USD'
      )
    ''');
  }

  Future<void> _createBudgets(Database db, {String table = 'budgets'}) async {
    await db.execute('''
      CREATE TABLE $table (
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        name TEXT NOT NULL,
        target_minor INTEGER NOT NULL,
        saved_minor INTEGER NOT NULL DEFAULT 0,
        deadline INTEGER NOT NULL,
        category TEXT NOT NULL DEFAULT '',
        currency TEXT NOT NULL DEFAULT 'USD'
      )
    ''');
  }

  Future<void> _createUserWidgets(Database db) async {
    await db.execute('''
      CREATE TABLE user_widgets (
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        kind TEXT NOT NULL,
        title TEXT NOT NULL,
        config TEXT NOT NULL DEFAULT '{}',
        position INTEGER NOT NULL DEFAULT 0
      )
    ''');
  }

  /// Manual FX rates: 1 unit of [base] buys [rate] units of [quote].
  Future<void> _createFxRates(Database db) async {
    await db.execute('''
      CREATE TABLE fx_rates (
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        base TEXT NOT NULL,
        quote TEXT NOT NULL,
        rate REAL NOT NULL,
        as_of INTEGER NOT NULL,
        UNIQUE (base, quote)
      )
    ''');
  }

  /// Device-local key/value preferences (locale, base currency, app lock…).
  Future<void> _createAppSettings(Database db) async {
    await db.execute('''
      CREATE TABLE app_settings (
        key TEXT PRIMARY KEY,
        value TEXT NOT NULL
      )
    ''');
  }
}
