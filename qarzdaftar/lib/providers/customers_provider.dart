import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:uuid/uuid.dart';

import '../data/repositories/customer_repository.dart';
import '../data/repositories/transaction_repository.dart';
import '../models/customer.dart';
import '../models/customer_balance.dart';
import '../services/photo_service.dart';
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
    String? photoPath,
  }) async {
    final c = Customer(
      id: _uuid.v4(),
      shopOwnerId: _ownerId,
      name: name.trim(),
      phone: phone?.trim().isEmpty == true ? null : phone?.trim(),
      address: address?.trim().isEmpty == true ? null : address?.trim(),
      note: note?.trim().isEmpty == true ? null : note?.trim(),
      photoPath: photoPath,
      createdAt: DateTime.now(),
    );
    await ref.read(customerRepoProvider).upsert(c);
    ref.invalidateSelf();
    return c;
  }

  Future<void> updateCustomer(Customer customer) async {
    await ref.read(customerRepoProvider).update(customer);
    ref.invalidateSelf();
  }

  Future<void> remove(String id) async {
    final existing = await ref.read(customerRepoProvider).getById(id);
    await ref.read(customerRepoProvider).delete(id);
    if (existing?.photoPath != null) {
      await PhotoService.instance.deleteIfExists(existing!.photoPath);
    }
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

enum CustomerFilter { all, hasDebt, overdue, cleared }

enum CustomerSort { byDebtDesc, byNameAsc, byRecent }

final customerFilterProvider =
    StateProvider<CustomerFilter>((_) => CustomerFilter.all);
final customerSortProvider =
    StateProvider<CustomerSort>((_) => CustomerSort.byDebtDesc);
