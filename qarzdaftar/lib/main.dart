import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'app.dart';
import 'data/local/database.dart';
import 'services/auth_service.dart';
import 'services/notification_service.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();

  await AppDatabase.instance.init();
  await AuthService.instance.ensureUserId();
  await NotificationService.instance.init();

  runApp(const ProviderScope(child: QarzDaftarApp()));
}
