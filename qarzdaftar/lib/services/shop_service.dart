import 'package:shared_preferences/shared_preferences.dart';

import '../models/shop_profile.dart';

class ShopService {
  ShopService._();
  static final ShopService instance = ShopService._();

  static const _kName = 'shop_name';
  static const _kOwnerPhone = 'shop_owner_phone';
  static const _kOwnerName = 'shop_owner_name';
  static const _kAddress = 'shop_address';
  static const _kAutoSms = 'shop_auto_sms_enabled';
  static const _kThemeMode = 'app_theme_mode'; // system | light | dark
  static const _kLocale = 'app_locale'; // uz_Latn | uz_Cyrl | ru

  Future<ShopProfile?> load() async {
    final prefs = await SharedPreferences.getInstance();
    final name = prefs.getString(_kName);
    if (name == null || name.isEmpty) return null;
    return ShopProfile(
      name: name,
      ownerPhone: prefs.getString(_kOwnerPhone),
      ownerName: prefs.getString(_kOwnerName),
      address: prefs.getString(_kAddress),
    );
  }

  Future<void> save(ShopProfile profile) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_kName, profile.name);
    await _put(prefs, _kOwnerPhone, profile.ownerPhone);
    await _put(prefs, _kOwnerName, profile.ownerName);
    await _put(prefs, _kAddress, profile.address);
  }

  Future<bool> isAutoSmsEnabled() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getBool(_kAutoSms) ?? false;
  }

  Future<void> setAutoSmsEnabled(bool value) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool(_kAutoSms, value);
  }

  Future<String> loadThemeMode() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getString(_kThemeMode) ?? 'system';
  }

  Future<void> saveThemeMode(String value) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_kThemeMode, value);
  }

  Future<String> loadLocale() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getString(_kLocale) ?? 'uz_Latn';
  }

  Future<void> saveLocale(String value) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_kLocale, value);
  }

  Future<void> _put(SharedPreferences prefs, String key, String? value) async {
    if (value == null || value.trim().isEmpty) {
      await prefs.remove(key);
    } else {
      await prefs.setString(key, value.trim());
    }
  }
}
