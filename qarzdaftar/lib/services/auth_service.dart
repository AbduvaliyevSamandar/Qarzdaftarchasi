import 'dart:convert';
import 'dart:math';

import 'package:crypto/crypto.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:uuid/uuid.dart';

class AuthService {
  AuthService._();
  static final AuthService instance = AuthService._();

  static const _kUserId = 'shop_owner_id';
  static const _kPinHash = 'pin_hash';
  static const _kPinSalt = 'pin_salt';
  static const _kIsLoggedIn = 'is_logged_in';

  static const _storage = FlutterSecureStorage(
    aOptions: AndroidOptions(encryptedSharedPreferences: true),
  );

  Future<bool> hasPin() async {
    final hash = await _storage.read(key: _kPinHash);
    return hash != null && hash.isNotEmpty;
  }

  Future<String> ensureUserId() async {
    var id = await _storage.read(key: _kUserId);
    if (id == null || id.isEmpty) {
      id = const Uuid().v4();
      await _storage.write(key: _kUserId, value: id);
    }
    return id;
  }

  Future<String?> currentUserId() => _storage.read(key: _kUserId);

  Future<bool> isLoggedIn() async {
    final v = await _storage.read(key: _kIsLoggedIn);
    return v == 'true';
  }

  Future<void> setupPin(String pin) async {
    final salt = _generateSalt();
    final hash = _hash(pin, salt);
    await _storage.write(key: _kPinSalt, value: salt);
    await _storage.write(key: _kPinHash, value: hash);
    await _storage.write(key: _kIsLoggedIn, value: 'true');
    await ensureUserId();
  }

  Future<bool> verifyPin(String pin) async {
    final salt = await _storage.read(key: _kPinSalt);
    final stored = await _storage.read(key: _kPinHash);
    if (salt == null || stored == null) return false;
    final hash = _hash(pin, salt);
    if (hash == stored) {
      await _storage.write(key: _kIsLoggedIn, value: 'true');
      return true;
    }
    return false;
  }

  Future<bool> changePin(String oldPin, String newPin) async {
    if (!await verifyPin(oldPin)) return false;
    final salt = _generateSalt();
    final hash = _hash(newPin, salt);
    await _storage.write(key: _kPinSalt, value: salt);
    await _storage.write(key: _kPinHash, value: hash);
    return true;
  }

  Future<void> lock() async {
    await _storage.write(key: _kIsLoggedIn, value: 'false');
  }

  Future<void> resetEverything() async {
    await _storage.deleteAll();
  }

  String _generateSalt() {
    final rand = Random.secure();
    final bytes = List<int>.generate(16, (_) => rand.nextInt(256));
    return base64Encode(bytes);
  }

  String _hash(String pin, String salt) {
    final bytes = utf8.encode('$salt::$pin');
    return sha256.convert(bytes).toString();
  }
}
