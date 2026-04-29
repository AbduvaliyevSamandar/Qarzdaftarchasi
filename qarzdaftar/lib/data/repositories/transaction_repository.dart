import 'package:sqflite/sqflite.dart';

import '../../models/transaction.dart';
import '../local/database.dart';

class TransactionRepository {
  Database get _db => AppDatabase.instance.db;

  Future<void> insert(Txn t) async {
    await _db.insert('transactions', t.toMap());
  }

  Future<void> delete(String id) async {
    await _db.delete('transactions', where: 'id = ?', whereArgs: [id]);
  }

  Future<List<Txn>> listForCustomer(String customerId) async {
    final rows = await _db.query(
      'transactions',
      where: 'customer_id = ?',
      whereArgs: [customerId],
      orderBy: 'occurred_at DESC',
    );
    return rows.map(Txn.fromMap).toList();
  }

  Future<List<Txn>> listOverdueForOwner(String shopOwnerId) async {
    final nowIso = DateTime.now().toIso8601String();
    final rows = await _db.rawQuery('''
      SELECT t.* FROM transactions t
      JOIN customers c ON c.id = t.customer_id
      WHERE c.shop_owner_id = ?
        AND t.type = 'debt'
        AND t.due_date IS NOT NULL
        AND t.due_date < ?
      ORDER BY t.due_date ASC
    ''', [shopOwnerId, nowIso]);
    return rows.map(Txn.fromMap).toList();
  }

  Future<List<String>> distinctProductNames(String shopOwnerId) async {
    final rows = await _db.rawQuery('''
      SELECT DISTINCT t.product_name
      FROM transactions t
      JOIN customers c ON c.id = t.customer_id
      WHERE c.shop_owner_id = ?
        AND t.product_name IS NOT NULL
        AND TRIM(t.product_name) != ''
      ORDER BY t.product_name ASC
    ''', [shopOwnerId]);
    return rows
        .map((r) => (r['product_name'] as String).trim())
        .where((s) => s.isNotEmpty)
        .toSet()
        .toList();
  }

  Future<({double totalDebt, double totalPaid})> shopTotals(String shopOwnerId) async {
    final rows = await _db.rawQuery('''
      SELECT
        COALESCE(SUM(CASE WHEN t.type = 'debt' THEN t.amount ELSE 0 END), 0) AS total_debt,
        COALESCE(SUM(CASE WHEN t.type = 'payment' THEN t.amount ELSE 0 END), 0) AS total_paid
      FROM transactions t
      JOIN customers c ON c.id = t.customer_id
      WHERE c.shop_owner_id = ?
    ''', [shopOwnerId]);
    final r = rows.first;
    return (
      totalDebt: (r['total_debt'] as num).toDouble(),
      totalPaid: (r['total_paid'] as num).toDouble(),
    );
  }
}
