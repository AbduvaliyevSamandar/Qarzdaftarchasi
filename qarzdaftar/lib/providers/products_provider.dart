import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:uuid/uuid.dart';

import '../data/repositories/product_repository.dart';
import '../models/product.dart';
import 'auth_provider.dart';

final productRepoProvider = Provider((ref) => ProductRepository());

class ProductsNotifier extends AsyncNotifier<List<Product>> {
  static const _uuid = Uuid();

  String get _ownerId {
    final id = ref.read(shopOwnerIdProvider);
    if (id == null) throw StateError('Foydalanuvchi tizimga kirmagan');
    return id;
  }

  @override
  Future<List<Product>> build() async {
    ref.watch(shopOwnerIdProvider);
    return ref.read(productRepoProvider).list(_ownerId);
  }

  Future<Product> create({
    required String name,
    required double price,
    String? unit,
  }) async {
    final p = Product(
      id: _uuid.v4(),
      shopOwnerId: _ownerId,
      name: name.trim(),
      price: price,
      unit: unit?.trim().isEmpty == true ? null : unit?.trim(),
      createdAt: DateTime.now(),
    );
    await ref.read(productRepoProvider).upsert(p);
    ref.invalidateSelf();
    return p;
  }

  Future<void> editProduct(Product product) async {
    await ref.read(productRepoProvider).update(product);
    ref.invalidateSelf();
  }

  Future<void> remove(String id) async {
    await ref.read(productRepoProvider).delete(id);
    ref.invalidateSelf();
  }
}

final productsProvider =
    AsyncNotifierProvider<ProductsNotifier, List<Product>>(ProductsNotifier.new);
