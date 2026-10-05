import 'package:qalqul/core/db/database_helper.dart';

/// Key/value store for device-local preferences (locale, base currency, app
/// lock, theme mode). Not part of the backup payload — settings are per device.
class SettingsRepository {
  Future<Map<String, String>> getAll() async {
    final db = await DatabaseHelper.instance.database;
    final rows = await db.query('app_settings');
    return {
      for (final r in rows) r['key'] as String: r['value'] as String,
    };
  }

  Future<void> set(String key, String value) async {
    final db = await DatabaseHelper.instance.database;
    final existing = await db.query(
      'app_settings',
      columns: ['key'],
      where: 'key = ?',
      whereArgs: [key],
      limit: 1,
    );
    if (existing.isEmpty) {
      await db.insert('app_settings', {'key': key, 'value': value});
    } else {
      await db.update(
        'app_settings',
        {'value': value},
        where: 'key = ?',
        whereArgs: [key],
      );
    }
  }

  Future<void> delete(String key) async {
    final db = await DatabaseHelper.instance.database;
    await db.delete('app_settings', where: 'key = ?', whereArgs: [key]);
  }
}