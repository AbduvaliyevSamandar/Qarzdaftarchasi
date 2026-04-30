import 'dart:convert';
import 'dart:io';

import 'package:path/path.dart' as p;
import 'package:path_provider/path_provider.dart';
import 'package:share_plus/share_plus.dart';
import 'package:sqflite/sqflite.dart';

import '../data/local/database.dart';
import '../models/shop_profile.dart';
import 'shop_service.dart';

class BackupResult {
  BackupResult.success(this.file, this.summary)
      : ok = true,
        error = null;
  BackupResult.error(this.error)
      : ok = false,
        file = null,
        summary = null;

  final bool ok;
  final File? file;
  final String? error;
  final BackupSummary? summary;
}

class BackupSummary {
  BackupSummary({
    required this.customers,
    required this.transactions,
    required this.products,
  });
  final int customers;
  final int transactions;
  final int products;
}

class BackupService {
  BackupService._();
  static final BackupService instance = BackupService._();

  static const _kVersion = 1;

  Future<BackupResult> createBackup() async {
    try {
      final db = AppDatabase.instance.db;
      final customers = await db.query('customers');
      final transactions = await db.query('transactions');
      final products = await db.query('products');
      final reminderLog = await db.query('reminder_log');

      final shopProfile = await _shopProfileMap();

      final json = {
        'version': _kVersion,
        'created_at': DateTime.now().toIso8601String(),
        'shop_profile': shopProfile,
        'customers': customers,
        'transactions': transactions,
        'products': products,
        'reminder_log': reminderLog,
      };

      final dir = await getTemporaryDirectory();
      final stamp = DateTime.now().millisecondsSinceEpoch;
      final path = p.join(dir.path, 'qarzdaftar_backup_$stamp.json');
      final file = File(path);
      await file.writeAsString(jsonEncode(json));

      return BackupResult.success(
        file,
        BackupSummary(
          customers: customers.length,
          transactions: transactions.length,
          products: products.length,
        ),
      );
    } catch (e) {
      return BackupResult.error('Zaxira yaratishda xatolik: $e');
    }
  }

  Future<void> shareBackup(File file) async {
    await Share.shareXFiles(
      [XFile(file.path)],
      text: 'Qarz Daftarchasi — zaxira fayli',
    );
  }

  Future<BackupResult> restore(File file) async {
    try {
      final raw = await file.readAsString();
      final data = jsonDecode(raw) as Map<String, dynamic>;
      final version = data['version'] as int? ?? 0;
      if (version <= 0 || version > _kVersion) {
        return BackupResult.error('Noma\'lum yoki yaroqsiz fayl versiyasi');
      }

      final db = AppDatabase.instance.db;
      await db.transaction((txn) async {
        await txn.delete('reminder_log');
        await txn.delete('transactions');
        await txn.delete('customers');
        await txn.delete('products');

        for (final row in (data['customers'] as List? ?? [])) {
          await txn.insert(
            'customers',
            (row as Map).cast<String, Object?>(),
            conflictAlgorithm: ConflictAlgorithm.replace,
          );
        }
        for (final row in (data['transactions'] as List? ?? [])) {
          await txn.insert(
            'transactions',
            (row as Map).cast<String, Object?>(),
            conflictAlgorithm: ConflictAlgorithm.replace,
          );
        }
        for (final row in (data['products'] as List? ?? [])) {
          await txn.insert(
            'products',
            (row as Map).cast<String, Object?>(),
            conflictAlgorithm: ConflictAlgorithm.replace,
          );
        }
        for (final row in (data['reminder_log'] as List? ?? [])) {
          await txn.insert(
            'reminder_log',
            (row as Map).cast<String, Object?>(),
            conflictAlgorithm: ConflictAlgorithm.replace,
          );
        }
      });

      final shop = data['shop_profile'] as Map<String, dynamic>?;
      if (shop != null) {
        await _restoreShopProfile(shop);
      }

      final cCount = (data['customers'] as List? ?? const []).length;
      final tCount = (data['transactions'] as List? ?? const []).length;
      final pCount = (data['products'] as List? ?? const []).length;

      return BackupResult.success(
        file,
        BackupSummary(
          customers: cCount,
          transactions: tCount,
          products: pCount,
        ),
      );
    } catch (e) {
      return BackupResult.error('Faylni o\'qishda xatolik: $e');
    }
  }

  Future<Map<String, dynamic>> _shopProfileMap() async {
    final shop = await ShopService.instance.load();
    if (shop == null) return {};
    return {
      'name': shop.name,
      'owner_name': shop.ownerName,
      'owner_phone': shop.ownerPhone,
      'address': shop.address,
    };
  }

  Future<void> _restoreShopProfile(Map<String, dynamic> map) async {
    final name = map['name'] as String?;
    if (name == null || name.isEmpty) return;
    await ShopService.instance.save(ShopProfile(
      name: map['name'] as String,
      ownerName: map['owner_name'] as String?,
      ownerPhone: map['owner_phone'] as String?,
      address: map['address'] as String?,
    ));
  }
}
