import 'package:flutter_local_notifications/flutter_local_notifications.dart';

class NotificationService {
  NotificationService._();
  static final NotificationService instance = NotificationService._();

  final FlutterLocalNotificationsPlugin _plugin = FlutterLocalNotificationsPlugin();

  Future<void> init() async {
    const android = AndroidInitializationSettings('@mipmap/ic_launcher');
    const ios = DarwinInitializationSettings();
    await _plugin.initialize(
      const InitializationSettings(android: android, iOS: ios),
    );
  }

  Future<void> showOverdueAlert({
    required int id,
    required String customerName,
    required double amount,
  }) async {
    const details = NotificationDetails(
      android: AndroidNotificationDetails(
        'overdue_channel',
        'Qarz muddati',
        channelDescription: 'Qarz qaytarish muddati o\'tib ketgan mijozlar',
        importance: Importance.high,
        priority: Priority.high,
      ),
      iOS: DarwinNotificationDetails(),
    );
    await _plugin.show(
      id,
      'Qarz muddati o\'tdi',
      '$customerName — ${amount.toStringAsFixed(0)} so\'m qaytarishi kerak edi',
      details,
    );
  }
}
