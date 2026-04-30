import 'package:flutter/material.dart';

import '../models/customer_balance.dart';
import '../theme/app_theme.dart';
import '../utils/formatters.dart';
import 'customer_avatar.dart';

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
            : Theme.of(context).textTheme.bodyLarge?.color;

    final accent = isClean
        ? AppTheme.success
        : isOverdue
            ? AppTheme.danger
            : AppTheme.warning;

    return Card(
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
      clipBehavior: Clip.antiAlias,
      child: InkWell(
        onTap: onTap,
        child: Row(
          children: [
            Container(width: 4, height: 80, color: accent),
            Expanded(
              child: Padding(
                padding: const EdgeInsets.all(12),
                child: Row(
                  children: [
                    CustomerAvatar(
                      name: balance.customer.name,
                      photoPath: balance.customer.photoPath,
                      size: 48,
                    ),
                    const SizedBox(width: 12),
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
                          if (balance.customer.phone != null)
                            Text(
                              balance.customer.phone!,
                              style: const TextStyle(
                                color: AppTheme.textSecondary,
                                fontSize: 13,
                              ),
                            ),
                          if (balance.lastTxnAt != null)
                            Text(
                              Formatters.relativeDays(balance.lastTxnAt!),
                              style: const TextStyle(
                                color: AppTheme.textSecondary,
                                fontSize: 11,
                              ),
                            ),
                        ],
                      ),
                    ),
                    const SizedBox(width: 8),
                    Column(
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
                            padding: const EdgeInsets.symmetric(
                              horizontal: 6,
                              vertical: 2,
                            ),
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
                        ] else if (isClean) ...[
                          const SizedBox(height: 4),
                          Container(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 6,
                              vertical: 2,
                            ),
                            decoration: BoxDecoration(
                              color: AppTheme.success.withValues(alpha: 0.1),
                              borderRadius: BorderRadius.circular(4),
                            ),
                            child: const Text(
                              'Qarzi yo\'q',
                              style: TextStyle(
                                color: AppTheme.success,
                                fontSize: 11,
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                          ),
                        ],
                      ],
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
