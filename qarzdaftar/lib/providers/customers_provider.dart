import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:uuid/uuid.dart';

import '../data/repositories/customer_repository.dart';
import '../data/repositories/transaction_repository.dart';
import '../models/customer.dart';
import '../models/customer_balance.dart';
import 'auth_provider.dart';

final customerRepoProvider = Provider((ref) => CustomerRepository());
final transactionRepoProvider = Provider((ref) => TransactionRepository());

class CustomersNotifier extends AsyncNotifier<List<CustomerBalance>> {
  static const _uuid = Uuid();

  String get _ownerId {
    final id = ref.read(shopOwnerIdProvider);
    if (id == null) throw StateError('Foydalanuvchi tizimga kirmagan');
    return id;
  }

  @override
  Future<List<CustomerBalance>> build() async {
    ref.watch(shopOwnerIdProvider);
    return ref.read(customerRepoProvider).listWithBalances(_ownerId);
  }

  Future<Customer> create({
    required String name,
    String? phone,
    String? address,
    String? note,
  }) async {
    final c = Customer(
      id: _uuid.v4(),
      shopOwnerId: _ownerId,
      name: name.trim(),
      phone: phone?.trim().isEmpty == true ? null : phone?.trim(),
      address: address?.trim().isEmpty == true ? null : address?.trim(),
      note: note?.trim().isEmpty == true ? null : note?.trim(),
      createdAt: DateTime.now(),
    );
    await ref.read(customerRepoProvider).upsert(c);
    ref.invalidateSelf();
    return c;
  }

  Future<void> remove(String id) async {
    await ref.read(customerRepoProvider).delete(id);
    ref.invalidateSelf();
  }

  Future<void> refresh() async {
    ref.invalidateSelf();
    await future;
  }
}

final customersProvider =
    AsyncNotifierProvider<CustomersNotifier, List<CustomerBalance>>(
  CustomersNotifier.new,
);

final shopTotalsProvider = FutureProvider.autoDispose((ref) async {
  final ownerId = ref.watch(shopOwnerIdProvider);
  if (ownerId == null) return (totalDebt: 0.0, totalPaid: 0.0);
  ref.watch(customersProvider);
  return ref.read(transactionRepoProvider).shopTotals(ownerId);
});

final productNamesProvider = FutureProvider.autoDispose<List<String>>((ref) async {
  final ownerId = ref.watch(shopOwnerIdProvider);
  if (ownerId == null) return const [];
  ref.watch(customersProvider);
  return ref.read(transactionRepoProvider).distinctProductNames(ownerId);
});
