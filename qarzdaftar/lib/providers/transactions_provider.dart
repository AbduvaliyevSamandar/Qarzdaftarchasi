import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:uuid/uuid.dart';

import '../models/transaction.dart';
import 'customers_provider.dart';

final transactionsForCustomerProvider =
    FutureProvider.autoDispose.family<List<Txn>, String>((ref, customerId) async {
  ref.watch(customersProvider);
  return ref.read(transactionRepoProvider).listForCustomer(customerId);
});

class AddTransactionController {
  AddTransactionController(this.ref);
  final Ref ref;
  static const _uuid = Uuid();

  Future<void> add({
    required String customerId,
    required TxnType type,
    required double amount,
    String? productName,
    String? note,
    DateTime? occurredAt,
    DateTime? dueDate,
  }) async {
    final now = DateTime.now();
    final txn = Txn(
      id: _uuid.v4(),
      customerId: customerId,
      type: type,
      amount: amount,
      productName: productName?.trim().isEmpty == true ? null : productName?.trim(),
      note: note?.trim().isEmpty == true ? null : note?.trim(),
      occurredAt: occurredAt ?? now,
      dueDate: dueDate,
      createdAt: now,
    );
    await ref.read(transactionRepoProvider).insert(txn);
    ref.invalidate(customersProvider);
    ref.invalidate(transactionsForCustomerProvider(customerId));
  }
}

final addTransactionControllerProvider =
    Provider((ref) => AddTransactionController(ref));
