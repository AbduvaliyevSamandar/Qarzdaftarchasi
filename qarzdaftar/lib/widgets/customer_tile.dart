import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../models/customer_balance.dart';
import '../models/transaction.dart';
import '../providers/shop_provider.dart';
import '../services/sms_service.dart';
import '../theme/app_theme.dart';
import '../utils/formatters.dart';
import '../utils/input_formatters.dart';
import 'app_snackbar.dart';
import 'customer_avatar.dart';
import 'money_text.dart';
import 'sms_dialog.dart';

class CustomerTile extends ConsumerWidget {
  const CustomerTile({
    super.key,
    required this.balance,
    required this.onTap,
    required this.onAddDebt,
    required this.onAddPayment,
  });

  final CustomerBalance balance;
  final VoidCallback onTap;
  final void Function(TxnType type) onAddDebt;
  final void Function(TxnType type) onAddPayment;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final remaining = balance.remaining;
    final isOverdue = balance.hasOverdue;
    final isClean = remaining <= 0;

    final amountColor = isClean
        ? AppTheme.success
        : isOverdue
            ? AppTheme.danger
            : Theme.of(context).textTheme.bodyLarge?.color;

    final status = AvatarStatusFromBalance.from(
      remaining: remaining,
      totalDebt: balance.totalDebt,
      hasOverdue: isOverdue,
    );

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 5),
      child: Material(
        color: Theme.of(context).cardColor,
        borderRadius: BorderRadius.circular(16),
        clipBehavior: Clip.antiAlias,
        child: InkWell(
          onTap: () {
            HapticFeedback.lightImpact();
            onTap();
          },
          onLongPress: () {
            HapticFeedback.mediumImpact();
            _showQuickActions(context, ref);
          },
          child: Padding(
            padding: const EdgeInsets.all(12),
            child: Row(
              children: [
                CustomerAvatar(
                  name: balance.customer.name,
                  photoPath: balance.customer.photoPath,
                  size: 48,
                  status: status,
                  heroTag: 'customer-avatar-${balance.customer.id}',
                ),
                const SizedBox(width: 14),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        balance.customer.name,
                        style: const TextStyle(
                          fontWeight: FontWeight.w600,
                          fontSize: 15,
                        ),
                      ),
                      if (balance.customer.phone != null) ...[
                        const SizedBox(height: 2),
                        Text(
                          UzbPhoneInputFormatter.fromE164(balance.customer.phone),
                          style: const TextStyle(
                            color: AppTheme.textSecondary,
                            fontSize: 12.5,
                          ),
                        ),
                      ],
                      if (balance.lastTxnAt != null) ...[
                        const SizedBox(height: 2),
                        Text(
                          Formatters.humanDate(balance.lastTxnAt!),
                          style: const TextStyle(
                            color: AppTheme.textSecondary,
                            fontSize: 11,
                          ),
                        ),
                      ],
                    ],
                  ),
                ),
                const SizedBox(width: 8),
                Column(
                  crossAxisAlignment: CrossAxisAlignment.end,
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    MoneyText(
                      amount: remaining,
                      size: 15,
                      color: amountColor,
                    ),
                    if (isOverdue) ...[
                      const SizedBox(height: 4),
                      _StatusBadge(
                        label: 'Muddati o\'tdi',
                        color: AppTheme.danger,
                      ),
                    ] else if (isClean && balance.totalDebt > 0) ...[
                      const SizedBox(height: 4),
                      _StatusBadge(
                        label: 'To\'liq to\'langan',
                        color: AppTheme.success,
                      ),
                    ],
                  ],
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  void _showQuickActions(BuildContext context, WidgetRef ref) {
    showModalBottomSheet(
      context: context,
      builder: (sheetCtx) => SafeArea(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const SizedBox(height: 12),
            Container(
              width: 40,
              height: 4,
              decoration: BoxDecoration(
                color: Colors.grey.shade300,
                borderRadius: BorderRadius.circular(2),
              ),
            ),
            const SizedBox(height: 12),
            ListTile(
              leading: CustomerAvatar(
                name: balance.customer.name,
                photoPath: balance.customer.photoPath,
                size: 36,
              ),
              title: Text(
                balance.customer.name,
                style: const TextStyle(fontWeight: FontWeight.w700),
              ),
              subtitle: balance.customer.phone != null
                  ? Text(UzbPhoneInputFormatter.fromE164(balance.customer.phone))
                  : null,
            ),
            const Divider(height: 1),
            ListTile(
              leading: const CircleAvatar(
                backgroundColor: Color(0x1FDC2626),
                child: Icon(Icons.arrow_upward, color: AppTheme.danger),
              ),
              title: const Text('Qarz qo\'shish'),
              onTap: () {
                Navigator.pop(sheetCtx);
                onAddDebt(TxnType.debt);
              },
            ),
            ListTile(
              leading: const CircleAvatar(
                backgroundColor: Color(0x1F16A34A),
                child: Icon(Icons.arrow_downward, color: AppTheme.success),
              ),
              title: const Text('To\'lov olish'),
              onTap: () {
                Navigator.pop(sheetCtx);
                onAddPayment(TxnType.payment);
              },
            ),
            if (balance.customer.phone != null) ...[
              ListTile(
                leading: const CircleAvatar(
                  backgroundColor: Color(0x1F0D6EFD),
                  child: Icon(Icons.message_outlined, color: AppTheme.primary),
                ),
                title: const Text('SMS yuborish'),
                onTap: () {
                  Navigator.pop(sheetCtx);
                  _sendSms(context, ref);
                },
              ),
              ListTile(
                leading: const CircleAvatar(
                  backgroundColor: Color(0x1F8B5CF6),
                  child: Icon(Icons.call_outlined, color: Color(0xFF8B5CF6)),
                ),
                title: const Text('Qo\'ng\'iroq qilish'),
                onTap: () async {
                  Navigator.pop(sheetCtx);
                  final r = await SmsService.call(balance.customer.phone!);
                  if (!r.ok && context.mounted) {
                    AppSnack.error(context, r.error ?? 'Xatolik');
                  }
                },
              ),
            ],
            const SizedBox(height: 8),
          ],
        ),
      ),
    );
  }

  void _sendSms(BuildContext context, WidgetRef ref) {
    final shop = ref.read(shopProfileProvider).valueOrNull;
    final shopName = (shop?.name.isNotEmpty ?? false) ? shop!.name : 'do\'kon';
    final text = SmsService.buildReminderText(
      customerName: balance.customer.name,
      remainingAmount: balance.remaining,
      shopName: shopName,
      ownerPhone: shop?.ownerPhone,
    );
    SmsDialog.show(
      context: context,
      phone: UzbPhoneInputFormatter.fromE164(balance.customer.phone),
      initialMessage: text,
      recipientName: balance.customer.name,
    );
  }
}

class _StatusBadge extends StatelessWidget {
  const _StatusBadge({required this.label, required this.color});
  final String label;
  final Color color;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.12),
        borderRadius: BorderRadius.circular(8),
      ),
      child: Text(
        label,
        style: TextStyle(
          color: color,
          fontSize: 10.5,
          fontWeight: FontWeight.w700,
          letterSpacing: 0.1,
        ),
      ),
    );
  }
}
