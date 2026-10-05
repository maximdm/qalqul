import 'package:qalqul/core/db/database_helper.dart';
import 'package:qalqul/core/models/budget.dart';

class BudgetsRepository {
  Future<List<Budget>> getAll() async {
    final db = await DatabaseHelper.instance.database;
    final rows = await db.query('budgets', orderBy: 'deadline ASC');
    return rows.map(Budget.fromMap).toList();
  }

  Future<int> insert(Budget b) async {
    final db = await DatabaseHelper.instance.database;
    return db.insert('budgets', b.toMap());
  }

  Future<void> update(Budget b) async {
    final db = await DatabaseHelper.instance.database;
    await db.update('budgets', b.toMap(), where: 'id = ?', whereArgs: [b.id]);
  }

  Future<void> delete(int id) async {
    final db = await DatabaseHelper.instance.database;
    await db.delete('budgets', where: 'id = ?', whereArgs: [id]);
  }
}
