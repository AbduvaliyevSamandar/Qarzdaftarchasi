import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../l10n/app_locale.dart';
import '../l10n/app_strings.dart';
import '../services/shop_service.dart';

class LocaleController extends AsyncNotifier<AppLocale> {
  @override
  Future<AppLocale> build() async {
    final saved = await ShopService.instance.loadLocale();
    return AppLocale.fromCode(saved);
  }

  Future<void> setLocale(AppLocale locale) async {
    state = AsyncData(locale);
    await ShopService.instance.saveLocale(locale.code);
  }
}

final localeProvider =
    AsyncNotifierProvider<LocaleController, AppLocale>(LocaleController.new);

final stringsProvider = Provider<AppStrings>((ref) {
  final locale = ref.watch(localeProvider).valueOrNull ?? AppLocale.uzLatin;
  return AppStrings(locale);
});
