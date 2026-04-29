import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../models/shop_profile.dart';
import '../services/shop_service.dart';

class ShopController extends AsyncNotifier<ShopProfile?> {
  @override
  Future<ShopProfile?> build() => ShopService.instance.load();

  Future<void> save(ShopProfile profile) async {
    await ShopService.instance.save(profile);
    state = AsyncData(profile);
  }
}

final shopProfileProvider =
    AsyncNotifierProvider<ShopController, ShopProfile?>(ShopController.new);
