import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:workmanager/workmanager.dart';

import '../data/local/database.dart';
import '../data/repositories/reminder_repository.dart';
import 'shop_service.dart';
import 'sms_service.dart';

const String kAutoReminderTaskName = 'qarzdaftar_auto_reminder';
const Duration kReminderInterval = Duration(hours: 8);

@pragma('vm:entry-point')
void workmanagerCallbackDispatcher() {
  Workmanager().executeTask((task, inputData) async {
    if (task != kAutoReminderTaskName) return true;
    try {
      await AppDatabase.instance.init();
      final sent = await AutoReminderService.runOnce();
      return sent >= 0;
    } catch (e) {
      return false;
    }
  });
}

class AutoReminderService {
  static const _userIdKey = 'shop_owner_id';
  static const _storage = FlutterSecureStorage(
    aOptions: AndroidOptions(encryptedSharedPreferences: true),
  );

  static Future<int> runOnce() async {
    final enabled = await ShopService.instance.isAutoSmsEnabled();
    if (!enabled) return 0;

    final userId = await _storage.read(key: _userIdKey);
    if (userId == null || userId.isEmpty) return 0;

    final shop = await ShopService.instance.load();
    if (shop == null || shop.name.trim().isEmpty) return 0;

    final repo = ReminderRepository();
    final overdue = await repo.overdueCustomers(userId);
    if (overdue.isEmpty) return 0;

    final now = DateTime.now();
    final cutoff = now.subtract(kReminderInterval - const Duration(minutes: 30));
    var sentCount = 0;

    for (final c in overdue) {
      final phone = c.phone;
      if (phone == null || phone.trim().isEmpty) continue;

      final last = await repo.lastSentFor(c.customerId);
      if (last != null && last.isAfter(cutoff)) continue;

      final message = SmsService.buildReminderText(
        customerName: c.name,
        remainingAmount: c.remaining,
        shopName: shop.name,
        ownerPhone: shop.ownerPhone,
      );
      final result = await SmsService.sendInBackground(
        phone: phone,
        message: message,
      );
      if (result.ok) {
        await repo.markSent(c.customerId, now);
        sentCount++;
      }
    }
    return sentCount;
  }

  static Future<void> initialize() async {
    await Workmanager().initialize(workmanagerCallbackDispatcher);
  }

  static Future<void> schedule() async {
    await Workmanager().registerPeriodicTask(
      kAutoReminderTaskName,
      kAutoReminderTaskName,
      frequency: kReminderInterval,
      existingWorkPolicy: ExistingPeriodicWorkPolicy.keep,
      backoffPolicy: BackoffPolicy.linear,
      backoffPolicyDelay: const Duration(minutes: 30),
      constraints: Constraints(
        networkType: NetworkType.notRequired,
        requiresBatteryNotLow: false,
        requiresCharging: false,
        requiresDeviceIdle: false,
        requiresStorageNotLow: false,
      ),
    );
  }

  static Future<void> cancel() async {
    await Workmanager().cancelByUniqueName(kAutoReminderTaskName);
  }

  static Future<void> applySettings(bool enabled) async {
    await ShopService.instance.setAutoSmsEnabled(enabled);
    if (enabled) {
      await schedule();
    } else {
      await cancel();
    }
  }
}
