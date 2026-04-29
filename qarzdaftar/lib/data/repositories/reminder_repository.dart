import 'package:sqflite/sqflite.dart';

import '../local/database.dart';

class ReminderRepository {
  Database get _db => AppDatabase.instance.db;

  Future<DateTime?> lastSentFor(String customerId) async {
    final rows = await _db.query(
      'reminder_log',
      where: 'customer_id = ?',
      whereArgs: [customerId],
      limit: 1,
    );
    if (rows.isEmpty) return null;
    return DateTime.parse(rows.first['last_sent_at'] as String);
  }

  Future<void> markSent(String customerId, DateTime at) async {
    await _db.insert(
      'reminder_log',
      {
        'customer_id': customerId,
        'last_sent_at': at.toIso8601String(),
      },
      conflictAlgorithm: ConflictAlgorithm.replace,
    );
  }

  Future<List<({String customerId, String name, String? phone, double remaining})>>
      overdueCustomers(String shopOwnerId) async {
    final nowIso = DateTime.now().toIso8601String();
    final rows = await _db.rawQuery('''
      SELECT
        c.id AS customer_id,
        c.name,
        c.phone,
        COALESCE(SUM(CASE WHEN t.type = 'debt' THEN t.amount ELSE 0 END), 0) AS total_debt,
        COALESCE(SUM(CASE WHEN t.type = 'payment' THEN t.amount ELSE 0 END), 0) AS total_paid,
        MIN(CASE
          WHEN t.type = 'debt' AND t.due_date IS NOT NULL AND t.due_date < ?
          THEN t.due_date END) AS earliest_overdue
      FROM customers c
      LEFT JOIN transactions t ON t.customer_id = c.id
      WHERE c.shop_owner_id = ?
      GROUP BY c.id
      HAVING earliest_overdue IS NOT NULL
        AND (total_debt - total_paid) > 0
        AND c.phone IS NOT NULL
        AND TRIM(c.phone) != ''
    ''', [nowIso, shopOwnerId]);

    return rows.map((r) {
      final totalDebt = (r['total_debt'] as num).toDouble();
      final totalPaid = (r['total_paid'] as num).toDouble();
      return (
        customerId: r['customer_id'] as String,
        name: r['name'] as String,
        phone: r['phone'] as String?,
        remaining: totalDebt - totalPaid,
      );
    }).toList();
  }
}
