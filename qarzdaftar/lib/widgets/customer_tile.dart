import 'package:flutter/material.dart';

import '../models/customer_balance.dart';
import '../theme/app_theme.dart';
import '../utils/formatters.dart';

class CustomerTile extends StatelessWidget {
  const CustomerTile({
    super.key,
    required this.balance,
    required this.onTap,
  });

  final CustomerBalance balance;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final remaining = balance.remaining;
    final isOverdue = balance.hasOverdue;
    final isClean = remaining <= 0;

    final amountColor = isClean
        ? AppTheme.success
        : isOverdue
            ? AppTheme.danger
            : AppTheme.textPrimary;

    return Card(
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
      child: ListTile(
        contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
        onTap: onTap,
        leading: CircleAvatar(
          backgroundColor: AppTheme.primary.withValues(alpha: 0.1),
          child: Text(
            balance.customer.name.characters.first.toUpperCase(),
            style: const TextStyle(
              color: AppTheme.primary,
              fontWeight: FontWeight.w700,
            ),
          ),
        ),
        title: Text(
          balance.customer.name,
          style: const TextStyle(fontWeight: FontWeight.w600),
        ),
        subtitle: balance.customer.phone != null
            ? Text(balance.customer.phone!)
            : null,
        trailing: Column(
          crossAxisAlignment: CrossAxisAlignment.end,
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Text(
              Formatters.money(remaining),
              style: TextStyle(
                fontWeight: FontWeight.w700,
                color: amountColor,
                fontSize: 15,
              ),
            ),
            if (isOverdue) ...[
              const SizedBox(height: 4),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                decoration: BoxDecoration(
                  color: AppTheme.danger.withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(4),
                ),
                child: const Text(
                  'Muddati o\'tdi',
                  style: TextStyle(
                    color: AppTheme.danger,
                    fontSize: 11,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
            ] else if (balance.lastTxnAt != null) ...[
              const SizedBox(height: 2),
              Text(
                Formatters.relativeDays(balance.lastTxnAt!),
                style: const TextStyle(
                  color: AppTheme.textSecondary,
                  fontSize: 11,
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }
}
