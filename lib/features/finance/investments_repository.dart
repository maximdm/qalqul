import 'package:qalqul/core/db/database_helper.dart';
import 'package:qalqul/core/models/investment.dart';

class InvestmentsRepository {
  Future<List<Investment>> getAll() async {
    final db = await DatabaseHelper.instance.database;
    final rows = await db.query('investments', orderBy: 'as_of DESC');
    return rows.map(Investment.fromMap).toList();
  }

  Future<int> insert(Investment i) async {
    final db = await DatabaseHelper.instance.database;
    return db.insert('investments', i.toMap());
  }

  Future<void> update(Investment i) async {
    final db = await DatabaseHelper.instance.database;
    await db.update('investments', i.toMap(), where: 'id = ?', whereArgs: [i.id]);
  }

  Future<void> delete(int id) async {
    final db = await DatabaseHelper.instance.database;
    await db.delete('investments', where: 'id = ?', whereArgs: [id]);
  }
}
