import 'package:fl_chart/fl_chart.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../providers/auth_provider.dart';
import '../../providers/customers_provider.dart';
import '../../theme/app_theme.dart';
import '../../utils/formatters.dart';
import '../../widgets/customer_avatar.dart';
import '../customers/customer_detail_screen.dart';

final dailyTotalsProvider = FutureProvider.autoDispose<
    List<({DateTime day, double debt, double payment})>>((ref) async {
  final ownerId = ref.watch(shopOwnerIdProvider);
  if (ownerId == null) return const [];
  ref.watch(customersProvider);
  final now = DateTime.now();
  final from = DateTime(now.year, now.month, now.day - 29);
  final to = DateTime(now.year, now.month, now.day + 1);
  return ref.read(transactionRepoProvider).dailyTotals(
        ownerId,
        from: from,
        to: to,
      );
});

class ReportsScreen extends ConsumerWidget {
  const ReportsScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final customersAsync = ref.watch(customersProvider);
    final dailyAsync = ref.watch(dailyTotalsProvider);

    return Scaffold(
      appBar: AppBar(
        title: const Text(
          'Hisobot',
          style: TextStyle(fontWeight: FontWeight.w700),
        ),
      ),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          customersAsync.when(
            data: (list) {
              final overdueCount = list.where((cb) => cb.hasOverdue).length;
              final hasDebt = list.where((cb) => cb.remaining > 0).length;
              final totalRem =
                  list.fold<double>(0, (a, b) => a + b.remaining);
              return Wrap(
                spacing: 12,
                runSpacing: 12,
                children: [
                  _StatCard(
                    label: 'Mijozlar',
                    value: list.length.toString(),
                    icon: Icons.people_outline,
                    color: AppTheme.primary,
                  ),
                  _StatCard(
                    label: 'Qarzdor',
                    value: hasDebt.toString(),
                    icon: Icons.account_balance_wallet_outlined,
                    color: AppTheme.warning,
                  ),
                  _StatCard(
                    label: 'Muddati o\'tdi',
                    value: overdueCount.toString(),
                    icon: Icons.warning_amber_outlined,
                    color: AppTheme.danger,
                  ),
                  _StatCard(
                    label: 'Olinishi kerak',
                    value: Formatters.money(totalRem),
                    icon: Icons.attach_money,
                    color: AppTheme.success,
                    wide: true,
                  ),
                ],
              );
            },
            loading: () => const Center(child: CircularProgressIndicator()),
            error: (e, _) => Text('Xatolik: $e'),
          ),
          const SizedBox(height: 24),
          const Text(
            'Oxirgi 30 kun',
            style: TextStyle(fontSize: 16, fontWeight: FontWeight.w700),
          ),
          const SizedBox(height: 12),
          dailyAsync.when(
            loading: () => const SizedBox(
              height: 220,
              child: Center(child: CircularProgressIndicator()),
            ),
            error: (e, _) => Text('Xatolik: $e'),
            data: (rows) => _CashflowChart(rows: rows),
          ),
          const SizedBox(height: 24),
          const Text(
            'Eng katta qarzdor 5 mijoz',
            style: TextStyle(fontSize: 16, fontWeight: FontWeight.w700),
          ),
          const SizedBox(height: 12),
          customersAsync.when(
            loading: () => const SizedBox.shrink(),
            error: (e, _) => Text('Xatolik: $e'),
            data: (list) {
              final top = [...list.where((cb) => cb.remaining > 0)]
                ..sort((a, b) => b.remaining.compareTo(a.remaining));
              if (top.isEmpty) {
                return Card(
                  child: ListTile(
                    leading: const Icon(Icons.celebration_outlined),
                    title: const Text('Qarzdor yo\'q'),
                    subtitle: const Text('Barcha mijozlar to\'lab bo\'lishgan'),
                  ),
                );
              }
              return Column(
                children: [
                  for (final cb in top.take(5))
                    Card(
                      margin: const EdgeInsets.only(bottom: 8),
                      child: ListTile(
                        leading: CustomerAvatar(
                          name: cb.customer.name,
                          photoPath: cb.customer.photoPath,
                          size: 40,
                        ),
                        title: Text(cb.customer.name),
                        subtitle: cb.customer.phone != null
                            ? Text(cb.customer.phone!)
                            : null,
                        trailing: Text(
                          Formatters.money(cb.remaining),
                          style: TextStyle(
                            fontWeight: FontWeight.w700,
                            color: cb.hasOverdue
                                ? AppTheme.danger
                                : AppTheme.warning,
                          ),
                        ),
                        onTap: () {
                          Navigator.push(
                            context,
                            MaterialPageRoute(
                              builder: (_) => CustomerDetailScreen(
                                customerId: cb.customer.id,
                              ),
                            ),
                          );
                        },
                      ),
                    ),
                ],
              );
            },
          ),
        ],
      ),
    );
  }
}

class _StatCard extends StatelessWidget {
  const _StatCard({
    required this.label,
    required this.value,
    required this.icon,
    required this.color,
    this.wide = false,
  });

  final String label;
  final String value;
  final IconData icon;
  final Color color;
  final bool wide;

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: wide ? double.infinity : (MediaQuery.of(context).size.width - 44) / 2,
      child: Card(
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Row(
            children: [
              Container(
                padding: const EdgeInsets.all(10),
                decoration: BoxDecoration(
                  color: color.withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(10),
                ),
                child: Icon(icon, color: color, size: 22),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      label,
                      style: const TextStyle(
                        color: AppTheme.textSecondary,
                        fontSize: 12,
                      ),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      value,
                      style: const TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _CashflowChart extends StatelessWidget {
  const _CashflowChart({required this.rows});
  final List<({DateTime day, double debt, double payment})> rows;

  @override
  Widget build(BuildContext context) {
    final byDay = <DateTime, ({double debt, double payment})>{};
    for (final r in rows) {
      byDay[DateTime(r.day.year, r.day.month, r.day.day)] =
          (debt: r.debt, payment: r.payment);
    }

    final now = DateTime.now();
    final days = List.generate(30, (i) {
      return DateTime(now.year, now.month, now.day - (29 - i));
    });

    final debtSpots = <FlSpot>[];
    final paySpots = <FlSpot>[];
    var maxV = 1.0;
    for (var i = 0; i < days.length; i++) {
      final r = byDay[days[i]];
      final d = r?.debt ?? 0;
      final p = r?.payment ?? 0;
      debtSpots.add(FlSpot(i.toDouble(), d));
      paySpots.add(FlSpot(i.toDouble(), p));
      if (d > maxV) maxV = d;
      if (p > maxV) maxV = p;
    }

    return Card(
      child: Padding(
        padding: const EdgeInsets.fromLTRB(8, 16, 16, 8),
        child: Column(
          children: [
            SizedBox(
              height: 180,
              child: LineChart(
                LineChartData(
                  minX: 0,
                  maxX: 29,
                  minY: 0,
                  maxY: maxV * 1.15,
                  gridData: const FlGridData(show: false),
                  titlesData: FlTitlesData(
                    leftTitles: const AxisTitles(
                      sideTitles: SideTitles(showTitles: false),
                    ),
                    rightTitles: const AxisTitles(
                      sideTitles: SideTitles(showTitles: false),
                    ),
                    topTitles: const AxisTitles(
                      sideTitles: SideTitles(showTitles: false),
                    ),
                    bottomTitles: AxisTitles(
                      sideTitles: SideTitles(
                        showTitles: true,
                        interval: 7,
                        reservedSize: 22,
                        getTitlesWidget: (value, meta) {
                          final i = value.toInt();
                          if (i < 0 || i >= days.length) return const SizedBox();
                          final d = days[i];
                          return Text(
                            '${d.day}.${d.month}',
                            style: const TextStyle(fontSize: 10),
                          );
                        },
                      ),
                    ),
                  ),
                  borderData: FlBorderData(show: false),
                  lineBarsData: [
                    LineChartBarData(
                      spots: debtSpots,
                      isCurved: true,
                      color: AppTheme.danger,
                      barWidth: 2,
                      dotData: const FlDotData(show: false),
                      belowBarData: BarAreaData(
                        show: true,
                        color: AppTheme.danger.withValues(alpha: 0.1),
                      ),
                    ),
                    LineChartBarData(
                      spots: paySpots,
                      isCurved: true,
                      color: AppTheme.success,
                      barWidth: 2,
                      dotData: const FlDotData(show: false),
                      belowBarData: BarAreaData(
                        show: true,
                        color: AppTheme.success.withValues(alpha: 0.1),
                      ),
                    ),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 8),
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                _Legend(color: AppTheme.danger, label: 'Berilgan qarz'),
                SizedBox(width: 16),
                _Legend(color: AppTheme.success, label: 'Olingan to\'lov'),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

class _Legend extends StatelessWidget {
  const _Legend({required this.color, required this.label});
  final Color color;
  final String label;

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Container(
          width: 10,
          height: 10,
          decoration: BoxDecoration(color: color, shape: BoxShape.circle),
        ),
        const SizedBox(width: 6),
        Text(label, style: const TextStyle(fontSize: 12)),
      ],
    );
  }
}
