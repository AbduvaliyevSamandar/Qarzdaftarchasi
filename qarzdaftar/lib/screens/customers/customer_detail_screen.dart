import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_slidable/flutter_slidable.dart';

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
import '../../widgets/app_snackbar.dart';
import '../../widgets/customer_avatar.dart';
import '../../widgets/money_text.dart';
import '../../widgets/sms_dialog.dart';
import '../../widgets/skeleton.dart';
import '../transactions/add_transaction_screen.dart';
import 'edit_customer_screen.dart';

class CustomerDetailScreen extends ConsumerWidget {
  const CustomerDetailScreen({super.key, required this.customerId});

  final String customerId;

  Future<void> _sendSms(BuildContext context, WidgetRef ref, CustomerBalance cb) async {
    HapticFeedback.lightImpact();
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
    HapticFeedback.lightImpact();
    final result = await SmsService.call(phone);
    if (!context.mounted) return;
    if (!result.ok) {
      AppSnack.error(context, result.error ?? 'Qo\'ng\'iroq qila olmadi');
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
          '"${customer.name}" va uning barcha tranzaksiyalari o\'chiriladi.',
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
    HapticFeedback.heavyImpact();
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
    HapticFeedback.mediumImpact();
    final removed = await ref.read(addTransactionControllerProvider).remove(txn.id);
    if (!context.mounted || removed == null) return;
    AppSnack.info(
      context,
      'Yozuv o\'chirildi',
      action: SnackBarAction(
        label: 'Qaytarish',
        textColor: AppTheme.warning,
        onPressed: () =>
            ref.read(addTransactionControllerProvider).restore(removed),
      ),
    );
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final customersAsync = ref.watch(customersProvider);
    final txnsAsync = ref.watch(transactionsForCustomerProvider(customerId));

    return Scaffold(
      appBar: AppBar(
        actions: [
          customersAsync.maybeWhen(
            data: (list) {
              final cb = _findById(list, customerId);
              if (cb == null) return const SizedBox.shrink();
              return PopupMenuButton<String>(
                itemBuilder: (_) => const [
                  PopupMenuItem(value: 'edit', child: Text('Tahrirlash')),
                  PopupMenuItem(value: 'delete', child: Text('O\'chirish')),
                ],
                onSelected: (v) {
                  if (v == 'edit') _editCustomer(context, cb.customer);
                  if (v == 'delete') _deleteCustomer(context, ref, cb.customer);
                },
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
          return CustomScrollView(
            slivers: [
              SliverToBoxAdapter(
                child: _PassportHeader(
                  balance: cb,
                  onCall: cb.customer.phone != null
                      ? () => _call(context, cb.customer.phone!)
                      : null,
                  onSms: cb.customer.phone != null
                      ? () => _sendSms(context, ref, cb)
                      : null,
                  onAddDebt: () {
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (_) => AddTransactionScreen(
                          customerId: cb.customer.id,
                        ),
                      ),
                    );
                  },
                  onAddPayment: () {
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (_) => AddTransactionScreen(
                          customerId: cb.customer.id,
                        ),
                      ),
                    );
                  },
                ),
              ),
              SliverPadding(
                padding: const EdgeInsets.fromLTRB(16, 8, 16, 8),
                sliver: SliverToBoxAdapter(
                  child: Text(
                    'Tranzaksiyalar',
                    style: Theme.of(context).textTheme.titleMedium,
                  ),
                ),
              ),
              txnsAsync.when(
                loading: () => const SliverToBoxAdapter(
                  child: SizedBox(height: 300, child: TxnListSkeleton(count: 5)),
                ),
                error: (e, _) =>
                    SliverToBoxAdapter(child: Center(child: Text('Xatolik: $e'))),
                data: (txns) {
                  if (txns.isEmpty) {
                    return SliverToBoxAdapter(
                      child: Padding(
                        padding: const EdgeInsets.all(24),
                        child: Center(
                          child: Text(
                            'Hali tranzaksiya yo\'q',
                            style: TextStyle(color: AppTheme.textSecondary),
                          ),
                        ),
                      ),
                    );
                  }
                  return SliverList.builder(
                    itemCount: txns.length,
                    itemBuilder: (context, i) => _TxnCard(
                      txn: txns[i],
                      onEdit: () => _editTxn(context, txns[i]),
                      onDelete: () => _deleteTxn(context, ref, txns[i]),
                    ),
                  );
                },
              ),
              const SliverPadding(padding: EdgeInsets.only(bottom: 88)),
            ],
          );
        },
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () {
          HapticFeedback.lightImpact();
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

class _PassportHeader extends StatelessWidget {
  const _PassportHeader({
    required this.balance,
    required this.onCall,
    required this.onSms,
    required this.onAddDebt,
    required this.onAddPayment,
  });

  final CustomerBalance balance;
  final VoidCallback? onCall;
  final VoidCallback? onSms;
  final VoidCallback onAddDebt;
  final VoidCallback onAddPayment;

  @override
  Widget build(BuildContext context) {
    final c = balance.customer;
    final status = AvatarStatusFromBalance.from(
      remaining: balance.remaining,
      totalDebt: balance.totalDebt,
      hasOverdue: balance.hasOverdue,
    );
    final color = balance.hasOverdue
        ? AppTheme.danger
        : (balance.remaining <= 0
            ? AppTheme.success
            : Theme.of(context).textTheme.titleLarge?.color);

    return Padding(
      padding: const EdgeInsets.fromLTRB(20, 4, 20, 8),
      child: Column(
        children: [
          CustomerAvatar(
            name: c.name,
            photoPath: c.photoPath,
            size: 96,
            status: status,
            heroTag: 'customer-avatar-${c.id}',
          ),
          const SizedBox(height: 14),
          Text(
            c.name,
            textAlign: TextAlign.center,
            style: const TextStyle(fontSize: 20, fontWeight: FontWeight.w700),
          ),
          const SizedBox(height: 4),
          Text(
            balance.remaining > 0 ? 'Qaytarilishi kerak' : 'Qarzi yo\'q',
            style: TextStyle(
              color: AppTheme.textSecondary,
              fontSize: 13,
            ),
          ),
          const SizedBox(height: 6),
          MoneyText(amount: balance.remaining, size: 30, color: color),
          if (balance.hasOverdue) ...[
            const SizedBox(height: 4),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
              decoration: BoxDecoration(
                color: AppTheme.danger.withValues(alpha: 0.12),
                borderRadius: BorderRadius.circular(8),
              ),
              child: const Text(
                'Muddati o\'tdi',
                style: TextStyle(
                  color: AppTheme.danger,
                  fontWeight: FontWeight.w700,
                  fontSize: 12,
                ),
              ),
            ),
          ],
          const SizedBox(height: 20),
          Row(
            children: [
              Expanded(
                child: _ActionButton(
                  icon: Icons.arrow_upward,
                  label: 'Qarz',
                  color: AppTheme.danger,
                  onTap: onAddDebt,
                ),
              ),
              const SizedBox(width: 8),
              Expanded(
                child: _ActionButton(
                  icon: Icons.arrow_downward,
                  label: 'To\'lov',
                  color: AppTheme.success,
                  onTap: onAddPayment,
                ),
              ),
              const SizedBox(width: 8),
              Expanded(
                child: _ActionButton(
                  icon: Icons.message_outlined,
                  label: 'SMS',
                  color: AppTheme.primary,
                  onTap: onSms,
                ),
              ),
              const SizedBox(width: 8),
              Expanded(
                child: _ActionButton(
                  icon: Icons.call_outlined,
                  label: 'Tel',
                  color: const Color(0xFF8B5CF6),
                  onTap: onCall,
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          Container(
            decoration: BoxDecoration(
              color: Theme.of(context).cardColor,
              borderRadius: BorderRadius.circular(14),
            ),
            child: Column(
              children: [
                if (c.phone != null)
                  _InfoRow(
                    icon: Icons.phone_outlined,
                    text: UzbPhoneInputFormatter.fromE164(c.phone),
                  ),
                if (c.address != null)
                  _InfoRow(icon: Icons.location_on_outlined, text: c.address!),
                if (c.note != null)
                  _InfoRow(icon: Icons.note_outlined, text: c.note!),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _ActionButton extends StatelessWidget {
  const _ActionButton({
    required this.icon,
    required this.label,
    required this.color,
    required this.onTap,
  });
  final IconData icon;
  final String label;
  final Color color;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    final disabled = onTap == null;
    final c = disabled ? AppTheme.textSecondary : color;
    return Material(
      color: c.withValues(alpha: 0.10),
      borderRadius: BorderRadius.circular(14),
      clipBehavior: Clip.antiAlias,
      child: InkWell(
        onTap: onTap,
        child: Padding(
          padding: const EdgeInsets.symmetric(vertical: 14),
          child: Column(
            children: [
              Icon(icon, color: c, size: 22),
              const SizedBox(height: 4),
              Text(
                label,
                style: TextStyle(
                  color: c,
                  fontWeight: FontWeight.w700,
                  fontSize: 12,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _InfoRow extends StatelessWidget {
  const _InfoRow({required this.icon, required this.text});
  final IconData icon;
  final String text;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
      child: Row(
        children: [
          Icon(icon, size: 18, color: AppTheme.textSecondary),
          const SizedBox(width: 12),
          Expanded(
            child: Text(
              text,
              style: const TextStyle(fontSize: 14),
            ),
          ),
        ],
      ),
    );
  }
}

class _TxnCard extends StatelessWidget {
  const _TxnCard({
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
    final isOver = txn.isOverdue;

    final isToday = _isToday(txn.occurredAt);

    return Slidable(
      key: ValueKey(txn.id),
      endActionPane: ActionPane(
        motion: const StretchMotion(),
        extentRatio: 0.55,
        children: [
          SlidableAction(
            onPressed: (_) => onEdit(),
            icon: Icons.edit_outlined,
            label: 'Tahrir',
            backgroundColor: AppTheme.primary,
            foregroundColor: Colors.white,
            borderRadius: BorderRadius.circular(12),
            padding: const EdgeInsets.all(4),
          ),
          SlidableAction(
            onPressed: (_) => onDelete(),
            icon: Icons.delete_outline,
            label: 'O\'chir',
            backgroundColor: AppTheme.danger,
            foregroundColor: Colors.white,
            borderRadius: BorderRadius.circular(12),
            padding: const EdgeInsets.all(4),
          ),
        ],
      ),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
        child: Material(
          color: Theme.of(context).cardColor,
          borderRadius: BorderRadius.circular(14),
          clipBehavior: Clip.antiAlias,
          child: InkWell(
            onTap: onEdit,
            child: Padding(
              padding: const EdgeInsets.all(12),
              child: Row(
                children: [
                  Container(
                    width: 40,
                    height: 40,
                    decoration: BoxDecoration(
                      color: color.withValues(alpha: 0.12),
                      shape: BoxShape.circle,
                    ),
                    child: Icon(
                      isDebt ? Icons.arrow_upward : Icons.arrow_downward,
                      color: color,
                      size: 20,
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          children: [
                            Expanded(
                              child: Text(
                                txn.productName ??
                                    (isDebt ? 'Qarz berildi' : 'To\'lov olindi'),
                                style: const TextStyle(
                                  fontWeight: FontWeight.w600,
                                  fontSize: 14,
                                ),
                              ),
                            ),
                            if (isToday) ...[
                              const SizedBox(width: 6),
                              Container(
                                padding: const EdgeInsets.symmetric(
                                  horizontal: 6,
                                  vertical: 2,
                                ),
                                decoration: BoxDecoration(
                                  color: AppTheme.success.withValues(alpha: 0.14),
                                  borderRadius: BorderRadius.circular(6),
                                ),
                                child: const Text(
                                  'Yangi',
                                  style: TextStyle(
                                    color: AppTheme.success,
                                    fontSize: 10,
                                    fontWeight: FontWeight.w700,
                                  ),
                                ),
                              ),
                            ],
                          ],
                        ),
                        const SizedBox(height: 2),
                        Text(
                          Formatters.humanDateTime(txn.occurredAt),
                          style: const TextStyle(
                            color: AppTheme.textSecondary,
                            fontSize: 12,
                          ),
                        ),
                        if (txn.dueDate != null)
                          Text(
                            'Muddat: ${Formatters.humanDate(txn.dueDate!)}'
                            '${isOver ? "  •  o'tdi" : ""}',
                            style: TextStyle(
                              color: isOver
                                  ? AppTheme.danger
                                  : AppTheme.textSecondary,
                              fontWeight:
                                  isOver ? FontWeight.w600 : FontWeight.normal,
                              fontSize: 12,
                            ),
                          ),
                        if (txn.note != null)
                          Padding(
                            padding: const EdgeInsets.only(top: 2),
                            child: Text(
                              txn.note!,
                              style: const TextStyle(
                                color: AppTheme.textSecondary,
                                fontSize: 12,
                                fontStyle: FontStyle.italic,
                              ),
                            ),
                          ),
                      ],
                    ),
                  ),
                  const SizedBox(width: 8),
                  MoneyText(
                    amount: txn.amount,
                    size: 14,
                    color: color,
                    signed: true,
                    signPositive: isDebt ? '+' : '',
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

  static bool _isToday(DateTime d) {
    final n = DateTime.now();
    return d.year == n.year && d.month == n.month && d.day == n.day;
  }
}
