import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../models/customer.dart';
import '../../models/customer_balance.dart';
import '../../models/transaction.dart';
import '../../providers/customers_provider.dart';
import '../../providers/shop_provider.dart';
import '../../providers/transactions_provider.dart';
import '../../services/sms_service.dart';
import '../../theme/app_theme.dart';
import '../../utils/formatters.dart';
import '../../utils/input_formatters.dart';
import '../../widgets/customer_avatar.dart';
import '../../widgets/sms_dialog.dart';
import '../transactions/add_transaction_screen.dart';
import 'edit_customer_screen.dart';

class CustomerDetailScreen extends ConsumerWidget {
  const CustomerDetailScreen({super.key, required this.customerId});

  final String customerId;

  Future<void> _sendSms(BuildContext context, WidgetRef ref, CustomerBalance cb) async {
    final shop = ref.read(shopProfileProvider).valueOrNull;
    final shopName = (shop?.name.isNotEmpty ?? false) ? shop!.name : 'do\'kon';
    final ownerPhone = shop?.ownerPhone;
    final text = SmsService.buildReminderText(
      customerName: cb.customer.name,
      remainingAmount: cb.remaining,
      shopName: shopName,
      ownerPhone: ownerPhone,
    );
    await SmsDialog.show(
      context: context,
      phone: UzbPhoneInputFormatter.fromE164(cb.customer.phone),
      initialMessage: text,
      recipientName: cb.customer.name,
    );
  }

  Future<void> _call(BuildContext context, String phone) async {
    final result = await SmsService.call(phone);
    if (!context.mounted) return;
    if (!result.ok) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(result.error ?? 'Qo\'ng\'iroq qila olmadi')),
      );
    }
  }

  Future<void> _editCustomer(BuildContext context, Customer customer) async {
    await Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => EditCustomerScreen(existing: customer),
      ),
    );
  }

  Future<void> _deleteCustomer(
    BuildContext context,
    WidgetRef ref,
    Customer customer,
  ) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (_) => AlertDialog(
        title: const Text('Mijozni o\'chirishmi?'),
        content: Text(
          '"${customer.name}" va uning barcha tranzaksiyalari o\'chiriladi. '
          'Bu amal qaytarilmaydi.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(_, false),
            child: const Text('Bekor qilish'),
          ),
          TextButton(
            style: TextButton.styleFrom(foregroundColor: AppTheme.danger),
            onPressed: () => Navigator.pop(_, true),
            child: const Text('O\'chirish'),
          ),
        ],
      ),
    );
    if (confirmed != true) return;
    await ref.read(customersProvider.notifier).remove(customer.id);
    if (context.mounted) Navigator.pop(context);
  }

  Future<void> _editTxn(BuildContext context, Txn txn) async {
    await Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => AddTransactionScreen(
          customerId: txn.customerId,
          existing: txn,
        ),
      ),
    );
  }

  Future<void> _deleteTxn(
    BuildContext context,
    WidgetRef ref,
    Txn txn,
  ) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (_) => AlertDialog(
        title: const Text('Yozuvni o\'chirishmi?'),
        content: Text(
          '${txn.type == TxnType.debt ? 'Qarz' : 'To\'lov'} '
          '${Formatters.money(txn.amount)} o\'chiriladi.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(_, false),
            child: const Text('Bekor qilish'),
          ),
          TextButton(
            style: TextButton.styleFrom(foregroundColor: AppTheme.danger),
            onPressed: () => Navigator.pop(_, true),
            child: const Text('O\'chirish'),
          ),
        ],
      ),
    );
    if (confirmed != true) return;
    final removed = await ref.read(addTransactionControllerProvider).remove(txn.id);
    if (!context.mounted || removed == null) return;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: const Text('Yozuv o\'chirildi'),
        action: SnackBarAction(
          label: 'Qaytarish',
          onPressed: () =>
              ref.read(addTransactionControllerProvider).restore(removed),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final customersAsync = ref.watch(customersProvider);
    final txnsAsync = ref.watch(transactionsForCustomerProvider(customerId));

    return Scaffold(
      appBar: AppBar(
        title: customersAsync.maybeWhen(
          data: (list) {
            final cb = _findById(list, customerId);
            return Text(cb?.customer.name ?? 'Mijoz');
          },
          orElse: () => const Text('Mijoz'),
        ),
        actions: [
          customersAsync.maybeWhen(
            data: (list) {
              final cb = _findById(list, customerId);
              if (cb == null) return const SizedBox.shrink();
              return Row(
                children: [
                  if (cb.customer.phone != null) ...[
                    IconButton(
                      icon: const Icon(Icons.message_outlined),
                      tooltip: 'SMS yuborish',
                      onPressed: () => _sendSms(context, ref, cb),
                    ),
                    IconButton(
                      icon: const Icon(Icons.call_outlined),
                      tooltip: 'Qo\'ng\'iroq',
                      onPressed: () => _call(context, cb.customer.phone!),
                    ),
                  ],
                  PopupMenuButton<String>(
                    itemBuilder: (_) => const [
                      PopupMenuItem(value: 'edit', child: Text('Tahrirlash')),
                      PopupMenuItem(value: 'delete', child: Text('O\'chirish')),
                    ],
                    onSelected: (v) {
                      if (v == 'edit') _editCustomer(context, cb.customer);
                      if (v == 'delete') _deleteCustomer(context, ref, cb.customer);
                    },
                  ),
                ],
              );
            },
            orElse: () => const SizedBox.shrink(),
          ),
        ],
      ),
      body: customersAsync.when(
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (e, _) => Center(child: Text('Xatolik: $e')),
        data: (list) {
          final cb = _findById(list, customerId);
          if (cb == null) {
            return const Center(child: Text('Mijoz topilmadi'));
          }
          return Column(
            children: [
              _Summary(balance: cb),
              const Divider(height: 1),
              Expanded(
                child: txnsAsync.when(
                  loading: () => const Center(child: CircularProgressIndicator()),
                  error: (e, _) => Center(child: Text('Xatolik: $e')),
                  data: (txns) {
                    if (txns.isEmpty) {
                      return const Center(
                        child: Text('Hali tranzaksiya yo\'q'),
                      );
                    }
                    return ListView.separated(
                      padding: const EdgeInsets.symmetric(vertical: 8),
                      itemCount: txns.length,
                      separatorBuilder: (_, __) => const Divider(height: 1, indent: 16),
                      itemBuilder: (context, i) => _TxnTile(
                        txn: txns[i],
                        onEdit: () => _editTxn(context, txns[i]),
                        onDelete: () => _deleteTxn(context, ref, txns[i]),
                      ),
                    );
                  },
                ),
              ),
            ],
          );
        },
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () {
          Navigator.push(
            context,
            MaterialPageRoute(
              builder: (_) => AddTransactionScreen(customerId: customerId),
            ),
          );
        },
        icon: const Icon(Icons.add),
        label: const Text('Yozuv qo\'shish'),
      ),
    );
  }

  CustomerBalance? _findById(List<CustomerBalance> list, String id) {
    for (final cb in list) {
      if (cb.customer.id == id) return cb;
    }
    return null;
  }
}

class _Summary extends StatelessWidget {
  const _Summary({required this.balance});
  final CustomerBalance balance;

  @override
  Widget build(BuildContext context) {
    final c = balance.customer;
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(20),
      color: Theme.of(context).cardColor,
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          CustomerAvatar(name: c.name, photoPath: c.photoPath, size: 64),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  Formatters.money(balance.remaining),
                  style: TextStyle(
                    fontSize: 26,
                    fontWeight: FontWeight.w800,
                    color: balance.hasOverdue ? AppTheme.danger : null,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  balance.remaining > 0
                      ? 'Qaytarilishi kerak'
                      : 'Qarz yo\'q',
                  style: const TextStyle(color: AppTheme.textSecondary),
                ),
                const SizedBox(height: 12),
                if (c.phone != null)
                  _Row(
                    icon: Icons.phone_outlined,
                    text: UzbPhoneInputFormatter.fromE164(c.phone),
                  ),
                if (c.address != null)
                  _Row(icon: Icons.location_on_outlined, text: c.address!),
                if (c.note != null)
                  _Row(icon: Icons.note_outlined, text: c.note!),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _Row extends StatelessWidget {
  const _Row({required this.icon, required this.text});
  final IconData icon;
  final String text;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 3),
      child: Row(
        children: [
          Icon(icon, size: 16, color: AppTheme.textSecondary),
          const SizedBox(width: 8),
          Expanded(
            child: Text(text, style: const TextStyle(color: AppTheme.textSecondary)),
          ),
        ],
      ),
    );
  }
}

class _TxnTile extends StatelessWidget {
  const _TxnTile({
    required this.txn,
    required this.onEdit,
    required this.onDelete,
  });
  final Txn txn;
  final VoidCallback onEdit;
  final VoidCallback onDelete;

  @override
  Widget build(BuildContext context) {
    final isDebt = txn.type == TxnType.debt;
    final color = isDebt ? AppTheme.danger : AppTheme.success;
    final sign = isDebt ? '+' : '−';
    final isOver = txn.isOverdue;

    return ListTile(
      leading: CircleAvatar(
        backgroundColor: color.withValues(alpha: 0.1),
        child: Icon(
          isDebt ? Icons.arrow_upward : Icons.arrow_downward,
          color: color,
        ),
      ),
      title: Text(
        txn.productName ?? (isDebt ? 'Qarz berildi' : 'To\'lov qabul qilindi'),
        style: const TextStyle(fontWeight: FontWeight.w600),
      ),
      subtitle: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(Formatters.dateTime(txn.occurredAt)),
          if (txn.dueDate != null)
            Text(
              'Muddat: ${Formatters.date(txn.dueDate!)}'
              '${isOver ? "  •  Muddati o'tdi" : ""}',
              style: TextStyle(
                color: isOver ? AppTheme.danger : AppTheme.textSecondary,
                fontWeight: isOver ? FontWeight.w600 : FontWeight.normal,
              ),
            ),
          if (txn.note != null) Text(txn.note!),
        ],
      ),
      trailing: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(
            '$sign${Formatters.money(txn.amount)}',
            style: TextStyle(
              color: color,
              fontWeight: FontWeight.w700,
              fontSize: 15,
            ),
          ),
          PopupMenuButton<String>(
            itemBuilder: (_) => const [
              PopupMenuItem(value: 'edit', child: Text('Tahrirlash')),
              PopupMenuItem(value: 'delete', child: Text('O\'chirish')),
            ],
            onSelected: (v) {
              if (v == 'edit') onEdit();
              if (v == 'delete') onDelete();
            },
          ),
        ],
      ),
      isThreeLine: txn.dueDate != null || txn.note != null,
      onTap: onEdit,
    );
  }
}
