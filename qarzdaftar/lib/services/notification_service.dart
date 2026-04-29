import 'dart:async';

import 'package:flutter_local_notifications/flutter_local_notifications.dart';

class NotificationService {
  NotificationService._();
  static final NotificationService instance = NotificationService._();

  static const String overdueChannelId = 'overdue_channel';
  static const String overdueChannelName = 'Qarz muddati';
  static const String overdueChannelDesc =
      'Qarz qaytarish muddati o\'tib ketgan mijozlar haqida eslatma';

  static const String payloadCustomerPrefix = 'customer:';

  final FlutterLocalNotificationsPlugin _plugin =
      FlutterLocalNotificationsPlugin();

  final StreamController<String> _tapStream = StreamController.broadcast();

  Stream<String> get onNotificationTap => _tapStream.stream;

  Future<void> init() async {
    const android = AndroidInitializationSettings('@mipmap/ic_launcher');
    const ios = DarwinInitializationSettings();
    await _plugin.initialize(
      const InitializationSettings(android: android, iOS: ios),
      onDidReceiveNotificationResponse: _onTap,
      onDidReceiveBackgroundNotificationResponse: _onTapBackground,
    );

    final androidImpl = _plugin
        .resolvePlatformSpecificImplementation<
            AndroidFlutterLocalNotificationsPlugin>();
    if (androidImpl != null) {
      await androidImpl.requestNotificationsPermission();
      await androidImpl.createNotificationChannel(
        const AndroidNotificationChannel(
          overdueChannelId,
          overdueChannelName,
          description: overdueChannelDesc,
          importance: Importance.high,
        ),
      );
    }

    final launch = await _plugin.getNotificationAppLaunchDetails();
    if (launch?.didNotificationLaunchApp == true) {
      final payload = launch?.notificationResponse?.payload;
      if (payload != null && payload.isNotEmpty) {
        Future.microtask(() => _tapStream.add(payload));
      }
    }
  }

  void _onTap(NotificationResponse response) {
    final payload = response.payload;
    if (payload != null && payload.isNotEmpty) {
      _tapStream.add(payload);
    }
  }

  Future<void> showOverdueReminder({
    required String customerId,
    required String customerName,
    required double remainingAmount,
  }) async {
    final id = customerId.hashCode & 0x7fffffff;
    final amount = remainingAmount.toStringAsFixed(0);

    const details = NotificationDetails(
      android: AndroidNotificationDetails(
        overdueChannelId,
        overdueChannelName,
        channelDescription: overdueChannelDesc,
        importance: Importance.high,
        priority: Priority.high,
        category: AndroidNotificationCategory.reminder,
      ),
      iOS: DarwinNotificationDetails(),
    );

    await _plugin.show(
      id,
      'Qarz muddati o\'tdi',
      '$customerName — $amount so\'m. Eslatma SMS yuborish uchun bosing.',
      details,
      payload: '$payloadCustomerPrefix$customerId',
    );
  }
}

@pragma('vm:entry-point')
void _onTapBackground(NotificationResponse response) {
  // Background tap handler — doesn't need to do much.
  // The app will read launch payload from getNotificationAppLaunchDetails on cold start.
}
