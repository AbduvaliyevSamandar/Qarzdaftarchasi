import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'providers/accent_color_provider.dart';
import 'providers/theme_provider.dart';
import 'screens/customers/customer_detail_screen.dart';
import 'screens/splash/splash_screen.dart';
import 'services/notification_service.dart';
import 'theme/app_theme.dart';

final GlobalKey<NavigatorState> rootNavigatorKey = GlobalKey<NavigatorState>();

class QarzDaftarApp extends ConsumerStatefulWidget {
  const QarzDaftarApp({super.key});

  @override
  ConsumerState<QarzDaftarApp> createState() => _QarzDaftarAppState();
}

class _QarzDaftarAppState extends ConsumerState<QarzDaftarApp> {
  @override
  void initState() {
    super.initState();
    NotificationService.instance.onNotificationTap.listen(_handleTap);
  }

  void _handleTap(String payload) {
    if (!payload.startsWith(NotificationService.payloadCustomerPrefix)) return;
    final customerId = payload.substring(
      NotificationService.payloadCustomerPrefix.length,
    );
    if (customerId.isEmpty) return;

    final navigator = rootNavigatorKey.currentState;
    if (navigator == null) {
      Future.delayed(const Duration(milliseconds: 500), () => _handleTap(payload));
      return;
    }
    navigator.push(
      MaterialPageRoute(
        builder: (_) => CustomerDetailScreen(customerId: customerId),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final themeMode = ref.watch(themeModeProvider).valueOrNull ?? ThemeMode.system;
    final accent = ref.watch(accentColorProvider).valueOrNull ?? AppTheme.primary;
    return MaterialApp(
      title: 'Qarz Daftarchasi',
      debugShowCheckedModeBanner: false,
      theme: AppTheme.light(seed: accent),
      darkTheme: AppTheme.dark(seed: accent),
      themeMode: themeMode,
      navigatorKey: rootNavigatorKey,
      home: const SplashScreen(),
    );
  }
}
