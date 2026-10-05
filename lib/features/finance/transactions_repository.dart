import 'package:qalqul/core/db/database_helper.dart';
import 'package:qalqul/core/models/transaction.dart';

class TransactionsRepository {
  Future<List<AppTransaction>> getAll() async {
    final db = await DatabaseHelper.instance.database;
    final rows = await db.query('transactions', orderBy: 'date DESC');
    return rows.map(AppTransaction.fromMap).toList();
  }

  Future<List<AppTransaction>> getByKind(String kind) async {
    final db = await DatabaseHelper.instance.database;
    final rows = await db.query(
      'transactions',
      where: 'kind = ?',
      whereArgs: [kind],
      orderBy: 'date DESC',
    );
    return rows.map(AppTransaction.fromMap).toList();
  }

  Future<int> insert(AppTransaction t) async {
    final db = await DatabaseHelper.instance.database;
    return db.insert('transactions', t.toMap());
  }

  Future<void> update(AppTransaction t) async {
    final db = await DatabaseHelper.instance.database;
    await db.update('transactions', t.toMap(), where: 'id = ?', whereArgs: [t.id]);
  }

  Future<void> delete(int id) async {
    final db = await DatabaseHelper.instance.database;
    await db.delete('transactions', where: 'id = ?', whereArgs: [id]);
  }
}
