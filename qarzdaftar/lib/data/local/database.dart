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
      version: 3,
      onCreate: _onCreate,
      onUpgrade: _onUpgrade,
    );
  }

  Future<void> _onCreate(Database db, int version) async {
    await _createCustomersTable(db);
    await db.execute('CREATE INDEX idx_customers_owner ON customers(shop_owner_id)');

    await _createTransactionsTable(db);
    await db.execute('CREATE INDEX idx_txn_customer ON transactions(customer_id)');
    await db.execute('CREATE INDEX idx_txn_due ON transactions(due_date)');

    await _createReminderTable(db);
    await _createProductsTable(db);
  }

  Future<void> _onUpgrade(Database db, int oldVersion, int newVersion) async {
    if (oldVersion < 2) {
      await _createReminderTable(db);
    }
    if (oldVersion < 3) {
      await db.execute('ALTER TABLE customers ADD COLUMN photo_path TEXT');
      await _createProductsTable(db);
    }
  }

  Future<void> _createCustomersTable(Database db) async {
    await db.execute('''
      CREATE TABLE customers (
        id TEXT PRIMARY KEY,
        shop_owner_id TEXT NOT NULL,
        name TEXT NOT NULL,
        phone TEXT,
        address TEXT,
        note TEXT,
        photo_path TEXT,
        created_at TEXT NOT NULL
      )
    ''');
  }

  Future<void> _createTransactionsTable(Database db) async {
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
  }

  Future<void> _createReminderTable(Database db) async {
    await db.execute('''
      CREATE TABLE reminder_log (
        customer_id TEXT PRIMARY KEY,
        last_sent_at TEXT NOT NULL,
        FOREIGN KEY(customer_id) REFERENCES customers(id) ON DELETE CASCADE
      )
    ''');
  }

  Future<void> _createProductsTable(Database db) async {
    await db.execute('''
      CREATE TABLE products (
        id TEXT PRIMARY KEY,
        shop_owner_id TEXT NOT NULL,
        name TEXT NOT NULL,
        price REAL NOT NULL,
        unit TEXT,
        created_at TEXT NOT NULL
      )
    ''');
    await db.execute('CREATE INDEX idx_products_owner ON products(shop_owner_id)');
  }
}
