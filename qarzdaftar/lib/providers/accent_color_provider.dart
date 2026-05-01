import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../services/shop_service.dart';
import '../theme/app_theme.dart';

class AccentChoice {
  const AccentChoice({required this.label, required this.color});
  final String label;
  final Color color;
}

const List<AccentChoice> kAccents = [
  AccentChoice(label: 'Ko\'k', color: Color(0xFF0D6EFD)),
  AccentChoice(label: 'Yashil', color: Color(0xFF16A34A)),
  AccentChoice(label: 'Binafsha', color: Color(0xFF8B5CF6)),
  AccentChoice(label: 'Sariq', color: Color(0xFFF59E0B)),
  AccentChoice(label: 'Pushti', color: Color(0xFFEC4899)),
  AccentChoice(label: 'Qora', color: Color(0xFF1F2937)),
];

class AccentController extends AsyncNotifier<Color> {
  @override
  Future<Color> build() async {
    final saved = await ShopService.instance.loadAccentColor();
    if (saved == null) return AppTheme.primary;
    return Color(saved);
  }

  Future<void> setColor(Color color) async {
    state = AsyncData(color);
    await ShopService.instance.saveAccentColor(color.value);
  }
}

final accentColorProvider =
    AsyncNotifierProvider<AccentController, Color>(AccentController.new);
