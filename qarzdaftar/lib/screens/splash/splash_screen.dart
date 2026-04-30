import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../providers/auth_provider.dart';
import '../../providers/shop_provider.dart';
import '../auth/pin_login_screen.dart';
import '../auth/pin_setup_screen.dart';
import '../home/home_shell.dart';
import '../shop/shop_setup_screen.dart';

class SplashScreen extends ConsumerWidget {
  const SplashScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final auth = ref.watch(authControllerProvider);
    return auth.when(
      loading: () => const Scaffold(
        body: Center(child: CircularProgressIndicator()),
      ),
      error: (e, _) => Scaffold(
        body: Center(child: Text('Xatolik: $e')),
      ),
      data: (state) {
        switch (state.stage) {
          case AuthStage.unknown:
            return const Scaffold(
              body: Center(child: CircularProgressIndicator()),
            );
          case AuthStage.needsSetup:
            return const PinSetupScreen();
          case AuthStage.locked:
            return const PinLoginScreen();
          case AuthStage.unlocked:
            return const _AfterUnlock();
        }
      },
    );
  }
}

class _AfterUnlock extends ConsumerWidget {
  const _AfterUnlock();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final shop = ref.watch(shopProfileProvider);
    return shop.when(
      loading: () => const Scaffold(
        body: Center(child: CircularProgressIndicator()),
      ),
      error: (e, _) => Scaffold(body: Center(child: Text('Xatolik: $e'))),
      data: (profile) {
        if (profile == null || !profile.isComplete) {
          return const ShopSetupScreen();
        }
        return const HomeShell();
      },
    );
  }
}
