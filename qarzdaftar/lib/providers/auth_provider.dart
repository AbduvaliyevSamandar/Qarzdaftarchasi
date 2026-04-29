import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../services/auth_service.dart';

enum AuthStage { unknown, needsSetup, locked, unlocked }

class AuthState {
  const AuthState({required this.stage, this.userId});
  final AuthStage stage;
  final String? userId;
}

class AuthController extends AsyncNotifier<AuthState> {
  @override
  Future<AuthState> build() async {
    final svc = AuthService.instance;
    final hasPin = await svc.hasPin();
    if (!hasPin) {
      return const AuthState(stage: AuthStage.needsSetup);
    }
    final loggedIn = await svc.isLoggedIn();
    final userId = await svc.currentUserId();
    return AuthState(
      stage: loggedIn ? AuthStage.unlocked : AuthStage.locked,
      userId: userId,
    );
  }

  Future<void> setupPin(String pin) async {
    state = const AsyncLoading();
    await AuthService.instance.setupPin(pin);
    final userId = await AuthService.instance.currentUserId();
    state = AsyncData(AuthState(stage: AuthStage.unlocked, userId: userId));
  }

  Future<bool> unlock(String pin) async {
    final ok = await AuthService.instance.verifyPin(pin);
    if (ok) {
      final userId = await AuthService.instance.currentUserId();
      state = AsyncData(AuthState(stage: AuthStage.unlocked, userId: userId));
    }
    return ok;
  }

  Future<void> lock() async {
    await AuthService.instance.lock();
    final userId = await AuthService.instance.currentUserId();
    state = AsyncData(AuthState(stage: AuthStage.locked, userId: userId));
  }

  Future<bool> changePin(String oldPin, String newPin) {
    return AuthService.instance.changePin(oldPin, newPin);
  }
}

final authControllerProvider =
    AsyncNotifierProvider<AuthController, AuthState>(AuthController.new);

final shopOwnerIdProvider = Provider<String?>((ref) {
  return ref.watch(authControllerProvider).valueOrNull?.userId;
});
