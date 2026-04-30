import 'package:sqflite/sqflite.dart';

import '../../models/product.dart';
import '../local/database.dart';

class ProductRepository {
  Database get _db => AppDatabase.instance.db;

  Future<void> upsert(Product p) async {
    await _db.insert(
      'products',
      p.toMap(),
      conflictAlgorithm: ConflictAlgorithm.replace,
    );
  }

  Future<void> update(Product p) async {
    await _db.update(
      'products',
      p.toMap(),
      where: 'id = ?',
      whereArgs: [p.id],
    );
  }

  Future<void> delete(String id) async {
    await _db.delete('products', where: 'id = ?', whereArgs: [id]);
  }

  Future<List<Product>> list(String shopOwnerId) async {
    final rows = await _db.query(
      'products',
      where: 'shop_owner_id = ?',
      whereArgs: [shopOwnerId],
      orderBy: 'name ASC',
    );
    return rows.map(Product.fromMap).toList();
  }

  Future<Product?> getById(String id) async {
    final rows = await _db.query(
      'products',
      where: 'id = ?',
      whereArgs: [id],
      limit: 1,
    );
    if (rows.isEmpty) return null;
    return Product.fromMap(rows.first);
  }
}
