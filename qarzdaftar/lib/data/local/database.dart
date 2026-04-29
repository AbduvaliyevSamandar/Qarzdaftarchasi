import 'package:path/path.dart';
import 'package:sqflite/sqflite.dart';

class AppDatabase {
  AppDatabase._();
  static final AppDatabase instance = AppDatabase._();

  Database? _db;
  Database get db {
    final d = _db;
    if (d == null) throw StateError('AppDatabase.init() chaqirilmagan');
    return d;
  }

  Future<void> init() async {
    if (_db != null) return;
    final path = join(await getDatabasesPath(), 'qarzdaftar.db');
    _db = await openDatabase(
      path,
      version: 1,
      onCreate: _onCreate,
    );
  }

  Future<void> _onCreate(Database db, int version) async {
    await db.execute('''
      CREATE TABLE customers (
        id TEXT PRIMARY KEY,
        shop_owner_id TEXT NOT NULL,
        name TEXT NOT NULL,
        phone TEXT,
        address TEXT,
        note TEXT,
        created_at TEXT NOT NULL
      )
    ''');
    await db.execute('CREATE INDEX idx_customers_owner ON customers(shop_owner_id)');

    await db.execute('''
      CREATE TABLE transactions (
        id TEXT PRIMARY KEY,
        customer_id TEXT NOT NULL,
        type TEXT NOT NULL,
        amount REAL NOT NULL,
        product_name TEXT,
        note TEXT,
        occurred_at TEXT NOT NULL,
        due_date TEXT,
        created_at TEXT NOT NULL,
        FOREIGN KEY(customer_id) REFERENCES customers(id) ON DELETE CASCADE
      )
    ''');
    await db.execute('CREATE INDEX idx_txn_customer ON transactions(customer_id)');
    await db.execute('CREATE INDEX idx_txn_due ON transactions(due_date)');
  }
}
