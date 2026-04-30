import 'package:sqflite/sqflite.dart';

import '../../models/customer.dart';
import '../../models/customer_balance.dart';
import '../local/database.dart';

class CustomerRepository {
  Database get _db => AppDatabase.instance.db;

  Future<void> upsert(Customer c) async {
    await _db.insert(
      'customers',
      c.toMap(),
      conflictAlgorithm: ConflictAlgorithm.replace,
    );
  }

  Future<void> update(Customer c) async {
    await _db.update(
      'customers',
      c.toMap(),
      where: 'id = ?',
      whereArgs: [c.id],
    );
  }

  Future<void> delete(String id) async {
    await _db.delete('customers', where: 'id = ?', whereArgs: [id]);
  }

  Future<Customer?> getById(String id) async {
    final rows = await _db.query('customers', where: 'id = ?', whereArgs: [id], limit: 1);
    if (rows.isEmpty) return null;
    return Customer.fromMap(rows.first);
  }

  Future<List<CustomerBalance>> listWithBalances(String shopOwnerId) async {
    final nowIso = DateTime.now().toIso8601String();
    final rows = await _db.rawQuery('''
      SELECT
        c.*,
        COALESCE(SUM(CASE WHEN t.type = 'debt' THEN t.amount ELSE 0 END), 0) AS total_debt,
        COALESCE(SUM(CASE WHEN t.type = 'payment' THEN t.amount ELSE 0 END), 0) AS total_paid,
        MAX(t.occurred_at) AS last_txn_at,
        MIN(CASE
          WHEN t.type = 'debt' AND t.due_date IS NOT NULL AND t.due_date < ?
          THEN t.due_date END) AS earliest_overdue
      FROM customers c
      LEFT JOIN transactions t ON t.customer_id = c.id
      WHERE c.shop_owner_id = ?
      GROUP BY c.id
      ORDER BY (total_debt - total_paid) DESC, c.name ASC
    ''', [nowIso, shopOwnerId]);

    return rows.map((r) {
      return CustomerBalance(
        customer: Customer.fromMap(r),
        totalDebt: (r['total_debt'] as num).toDouble(),
        totalPaid: (r['total_paid'] as num).toDouble(),
        lastTxnAt: r['last_txn_at'] != null
            ? DateTime.parse(r['last_txn_at'] as String)
            : null,
        earliestOverdueDueDate: r['earliest_overdue'] != null
            ? DateTime.parse(r['earliest_overdue'] as String)
            : null,
      );
    }).toList();
  }
}
