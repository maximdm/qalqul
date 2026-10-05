import 'package:qalqul/core/db/database_helper.dart';
import 'package:qalqul/core/models/user_widget.dart';

class UserWidgetsRepository {
  Future<List<UserWidget>> getAll() async {
    final db = await DatabaseHelper.instance.database;
    final rows = await db.query(
      'user_widgets',
      orderBy: 'position ASC, id ASC',
    );
    return rows.map(UserWidget.fromMap).toList();
  }

  Future<void> insert(UserWidget w) async {
    final db = await DatabaseHelper.instance.database;
    await db.insert('user_widgets', w.toMap()..remove('id'));
  }

  Future<void> update(UserWidget w) async {
    final db = await DatabaseHelper.instance.database;
    await db.update(
      'user_widgets',
      w.toMap(),
      where: 'id = ?',
      whereArgs: [w.id],
    );
  }

  Future<void> delete(int id) async {
    final db = await DatabaseHelper.instance.database;
    await db.delete('user_widgets', where: 'id = ?', whereArgs: [id]);
  }
}
