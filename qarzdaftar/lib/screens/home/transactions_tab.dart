import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../models/transaction.dart';
import '../../providers/auth_provider.dart';
import '../../providers/customers_provider.dart';
import '../../theme/app_theme.dart';
import '../../utils/formatters.dart';
import '../customers/customer_detail_screen.dart';

final allTransactionsProvider =
    FutureProvider.autoDispose<List<({Txn txn, String customerName})>>((ref) async {
  final ownerId = ref.watch(shopOwnerIdProvider);
  if (ownerId == null) return const [];
  ref.watch(customersProvider);
  final customers = await ref.read(customersProvider.future);
  final byId = {for (final cb in customers) cb.customer.id: cb.customer.name};
  final txns =
      await ref.read(transactionRepoProvider).listAllForOwner(ownerId, limit: 200);
  return txns
      .map((t) => (txn: t, customerName: byId[t.customerId] ?? '—'))
      .toList();
});

class TransactionsTab extends ConsumerWidget {
  const TransactionsTab({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final async = ref.watch(allTransactionsProvider);
    return Scaffold(
      appBar: AppBar(
        title: const Text(
          'Tranzaksiyalar',
          style: TextStyle(fontWeight: FontWeight.w700),
        ),
      ),
      body: async.when(
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (e, _) => Center(child: Text('Xatolik: $e')),
        data: (list) {
          if (list.isEmpty) {
            return Center(
              child: Padding(
                padding: const EdgeInsets.all(32),
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(Icons.receipt_long_outlined,
                        size: 80, color: Colors.grey.shade400),
                    const SizedBox(height: 16),
                    const Text(
                      'Hali tranzaksiya yo\'q',
                      style: TextStyle(fontSize: 18, fontWeight: FontWeight.w600),
                    ),
                  ],
                ),
              ),
            );
          }
          return RefreshIndicator(
            onRefresh: () async => ref.invalidate(allTransactionsProvider),
            child: ListView.separated(
              itemCount: list.length,
              separatorBuilder: (_, __) => const Divider(height: 1, indent: 16),
              itemBuilder: (context, i) {
                final item = list[i];
                final txn = item.txn;
                final isDebt = txn.type == TxnType.debt;
                final color = isDebt ? AppTheme.danger : AppTheme.success;
                return ListTile(
                  leading: CircleAvatar(
                    backgroundColor: color.withValues(alpha: 0.1),
                    child: Icon(
                      isDebt ? Icons.arrow_upward : Icons.arrow_downward,
                      color: color,
                    ),
                  ),
                  title: Text(
                    item.customerName,
                    style: const TextStyle(fontWeight: FontWeight.w600),
                  ),
                  subtitle: Text(
                    '${txn.productName ?? (isDebt ? "Qarz" : "To'lov")}  •  '
                    '${Formatters.dateTime(txn.occurredAt)}',
                  ),
                  trailing: Text(
                    '${isDebt ? "+" : "−"}${Formatters.money(txn.amount)}',
                    style: TextStyle(
                      color: color,
                      fontWeight: FontWeight.w700,
                      fontSize: 14,
                    ),
                  ),
                  onTap: () {
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (_) =>
                            CustomerDetailScreen(customerId: txn.customerId),
                      ),
                    );
                  },
                );
              },
            ),
          );
        },
      ),
    );
  }
}
