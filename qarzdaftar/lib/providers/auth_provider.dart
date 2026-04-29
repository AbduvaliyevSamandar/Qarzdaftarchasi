import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../services/auth_service.dart';

final authStateProvider = StreamProvider<User?>((ref) {
  return AuthService.instance.authStateChanges();
});

final currentUserProvider = Provider<User?>((ref) {
  return ref.watch(authStateProvider).valueOrNull;
});

final shopOwnerIdProvider = Provider<String?>((ref) {
  return ref.watch(currentUserProvider)?.uid;
});
