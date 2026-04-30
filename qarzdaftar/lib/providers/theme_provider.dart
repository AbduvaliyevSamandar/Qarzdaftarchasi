import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../services/shop_service.dart';

class ThemeModeController extends AsyncNotifier<ThemeMode> {
  @override
  Future<ThemeMode> build() async {
    final saved = await ShopService.instance.loadThemeMode();
    return _decode(saved);
  }

  Future<void> setMode(ThemeMode mode) async {
    state = AsyncData(mode);
    await ShopService.instance.saveThemeMode(_encode(mode));
  }

  String _encode(ThemeMode m) => switch (m) {
        ThemeMode.dark => 'dark',
        ThemeMode.light => 'light',
        ThemeMode.system => 'system',
      };

  ThemeMode _decode(String v) => switch (v) {
        'dark' => ThemeMode.dark,
        'light' => ThemeMode.light,
        _ => ThemeMode.system,
      };
}

final themeModeProvider =
    AsyncNotifierProvider<ThemeModeController, ThemeMode>(ThemeModeController.new);
