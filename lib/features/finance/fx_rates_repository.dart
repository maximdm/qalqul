import 'package:qalqul/core/db/database_helper.dart';
import 'package:qalqul/core/models/fx_rate.dart';

/// Persists manually entered exchange rates (`1 base = rate quote`).
class FxRatesRepository {
  Future<List<FxRate>> getAll() async {
    final db = await DatabaseHelper.instance.database;
    final rows = await db.query('fx_rates', orderBy: 'base ASC, quote ASC');
    return rows.map(FxRate.fromMap).toList();
  }

  /// Inserts or updates the rate for the pair, keeping a single row per pair.
  Future<void> upsert(FxRate rate) async {
    final db = await DatabaseHelper.instance.database;
    final base = rate.base.toUpperCase();
    final quote = rate.quote.toUpperCase();
    final existing = await db.query(
      'fx_rates',
      columns: ['id'],
      where: 'base = ? AND quote = ?',
      whereArgs: [base, quote],
      limit: 1,
    );
    if (existing.isEmpty) {
      await db.insert('fx_rates', {
        'base': base,
        'quote': quote,
        'rate': rate.rate,
        'as_of': rate.asOf,
      });
    } else {
      await db.update(
        'fx_rates',
        {'rate': rate.rate, 'as_of': rate.asOf},
        where: 'id = ?',
        whereArgs: [existing.first['id']],
      );
    }
  }

  Future<void> delete(int id) async {
    final db = await DatabaseHelper.instance.database;
    await db.delete('fx_rates', where: 'id = ?', whereArgs: [id]);
  }
}