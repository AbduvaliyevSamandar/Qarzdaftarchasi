import 'package:flutter/material.dart';

import '../theme/app_theme.dart';
import '../utils/formatters.dart';

class BalanceCard extends StatelessWidget {
  const BalanceCard({
    super.key,
    required this.totalDebt,
    required this.totalPaid,
  });

  final double totalDebt;
  final double totalPaid;

  @override
  Widget build(BuildContext context) {
    final remaining = totalDebt - totalPaid;
    return AnimatedContainer(
      duration: const Duration(milliseconds: 300),
      curve: Curves.easeOut,
      margin: const EdgeInsets.all(16),
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [AppTheme.primary, Color(0xFF4F46E5)],
        ),
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: AppTheme.primary.withValues(alpha: 0.25),
            blurRadius: 16,
            offset: const Offset(0, 6),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          const Text(
            'Olinishi kerak (jami qarz)',
            style: TextStyle(color: Colors.white70, fontSize: 14),
          ),
          const SizedBox(height: 6),
          AnimatedSwitcher(
            duration: const Duration(milliseconds: 250),
            transitionBuilder: (child, animation) => FadeTransition(
              opacity: animation,
              child: SlideTransition(
                position: Tween<Offset>(
                  begin: const Offset(0, 0.3),
                  end: Offset.zero,
                ).animate(animation),
                child: child,
              ),
            ),
            child: Text(
              Formatters.money(remaining),
              key: ValueKey(remaining),
              style: const TextStyle(
                color: Colors.white,
                fontSize: 30,
                fontWeight: FontWeight.w800,
              ),
            ),
          ),
          const SizedBox(height: 16),
          Row(
            children: [
              Expanded(
                child: _Stat(
                  label: 'Jami berilgan',
                  value: Formatters.money(totalDebt),
                ),
              ),
              Container(width: 1, height: 40, color: Colors.white24),
              Expanded(
                child: _Stat(
                  label: 'Qaytarilgan',
                  value: Formatters.money(totalPaid),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class _Stat extends StatelessWidget {
  const _Stat({required this.label, required this.value});
  final String label;
  final String value;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 8),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(label, style: const TextStyle(color: Colors.white70, fontSize: 12)),
          const SizedBox(height: 4),
          AnimatedSwitcher(
            duration: const Duration(milliseconds: 250),
            child: Text(
              value,
              key: ValueKey(value),
              style: const TextStyle(
                color: Colors.white,
                fontSize: 15,
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
        ],
      ),
    );
  }
}
