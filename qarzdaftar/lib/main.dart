import 'package:flutter/material.dart';
import 'package:flutter_native_splash/flutter_native_splash.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'app.dart';
import 'data/local/database.dart';
import 'services/auth_service.dart';
import 'services/auto_reminder_service.dart';
import 'services/notification_service.dart';
import 'services/shop_service.dart';

Future<void> main() async {
  final binding = WidgetsFlutterBinding.ensureInitialized();
  FlutterNativeSplash.preserve(widgetsBinding: binding);

  await AppDatabase.instance.init();
  await AuthService.instance.ensureUserId();
  await NotificationService.instance.init();
  await AutoReminderService.initialize();

  if (await ShopService.instance.isAutoSmsEnabled()) {
    await AutoReminderService.schedule();
  }

  runApp(const ProviderScope(child: QarzDaftarApp()));
  FlutterNativeSplash.remove();
}
