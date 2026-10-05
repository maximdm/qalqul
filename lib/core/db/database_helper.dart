import 'dart:async';
import 'dart:io';

import 'package:flutter/foundation.dart';
import 'package:path/path.dart';
import 'package:sqflite_common_ffi/sqflite_common_ffi.dart';
import 'package:sqflite_common_ffi_web/sqflite_ffi_web.dart';

class DatabaseHelper {
  static const _dbName = 'qalqul.db';
  static const _dbVersion = 5;

  DatabaseHelper._();
  static final DatabaseHelper instance = DatabaseHelper._();

  Database? _database;

  Future<Database> get database async {
    _database ??= await _init();
    return _database!;
  }

  /// Test-only hook: point the singleton at an isolated in-memory database so
  /// repository tests don't touch the on-device file DB.
  static Future<void> useTestDatabase() async {
    sqfliteFfiInit();
    databaseFactory = databaseFactoryFfi;
    instance._database = await openDatabase(
      inMemoryDatabasePath,
      version: _dbVersion,
      onCreate: (db, _) async {
        await instance._createNotes(db);
        await instance._createTransactions(db);
        await instance._createInvestments(db);
        await instance._createBudgets(db);
        await instance._createUserWidgets(db);
        await instance._createFxRates(db);
        await instance._createAppSettings(db);
      },
    );
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

  Future<void> _createTransactions(Database db) async {
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
  }

  Future<void> _createInvestments(Database db) async {
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
  }

  Future<void> _createBudgets(Database db) async {
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
