import 'package:fl_chart/fl_chart.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../providers/auth_provider.dart';
import '../../providers/customers_provider.dart';
import '../../providers/locale_provider.dart';
import '../../theme/app_theme.dart';
import '../../utils/formatters.dart';
import '../../widgets/customer_avatar.dart';
import '../../widgets/money_text.dart';
import '../../widgets/skeleton.dart';
import '../customers/customer_detail_screen.dart';

enum ReportPeriod { week, month, quarter, year }

extension ReportPeriodX on ReportPeriod {
  int get days => switch (this) {
        ReportPeriod.week => 7,
        ReportPeriod.month => 30,
        ReportPeriod.quarter => 90,
        ReportPeriod.year => 365,
      };

  String get label => switch (this) {
        ReportPeriod.week => 'Hafta',
        ReportPeriod.month => 'Oy',
        ReportPeriod.quarter => '3 oy',
        ReportPeriod.year => 'Yil',
      };
}

final reportPeriodProvider = StateProvider<ReportPeriod>((_) => ReportPeriod.month);

final periodTotalsProvider = FutureProvider.autoDispose<
    ({
      List<({DateTime day, double debt, double payment})> rows,
      double currentDebt,
      double currentPayment,
      double previousDebt,
      double previousPayment,
    })>((ref) async {
  final ownerId = ref.watch(shopOwnerIdProvider);
  final period = ref.watch(reportPeriodProvider);
  if (ownerId == null) {
    return (
      rows: <({DateTime day, double debt, double payment})>[],
      currentDebt: 0.0,
      currentPayment: 0.0,
      previousDebt: 0.0,
      previousPayment: 0.0,
    );
  }
  ref.watch(customersProvider);
  final now = DateTime.now();
  final today = DateTime(now.year, now.month, now.day + 1);
  final from = today.subtract(Duration(days: period.days));
  final prevFrom = today.subtract(Duration(days: period.days * 2));

  final repo = ref.read(transactionRepoProvider);
  final rows = await repo.dailyTotals(ownerId, from: from, to: today);
  final prevRows =
      await repo.dailyTotals(ownerId, from: prevFrom, to: from);

  double curD = 0, curP = 0, prevD = 0, prevP = 0;
  for (final r in rows) {
    curD += r.debt;
    curP += r.payment;
  }
  for (final r in prevRows) {
    prevD += r.debt;
    prevP += r.payment;
  }
  return (
    rows: rows,
    currentDebt: curD,
    currentPayment: curP,
    previousDebt: prevD,
    previousPayment: prevP,
  );
});

class ReportsScreen extends ConsumerWidget {
  const ReportsScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final tr = ref.watch(stringsProvider);
    final customersAsync = ref.watch(customersProvider);
    final period = ref.watch(reportPeriodProvider);
    final periodAsync = ref.watch(periodTotalsProvider);

    return Scaffold(
      appBar: AppBar(
        title: Text(
          tr.tabReports,
          style: const TextStyle(fontWeight: FontWeight.w700),
        ),
      ),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          customersAsync.when(
            data: (list) {
              final overdueCount = list.where((cb) => cb.hasOverdue).length;
              final hasDebt = list.where((cb) => cb.remaining > 0).length;
              final totalRem = list.fold<double>(0, (a, b) => a + b.remaining);
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
                  _StatCardMoney(
                    label: 'Olinishi kerak',
                    amount: totalRem,
                    icon: Icons.attach_money,
                    color: AppTheme.success,
                  ),
                ],
              );
            },
            loading: () => const Center(child: CircularProgressIndicator()),
            error: (e, _) => Text('Xatolik: $e'),
          ),
          const SizedBox(height: 24),
          SingleChildScrollView(
            scrollDirection: Axis.horizontal,
            child: Row(
              children: [
                for (final p in ReportPeriod.values) ...[
                  ChoiceChip(
                    label: Text(p.label),
                    selected: p == period,
                    onSelected: (_) =>
                        ref.read(reportPeriodProvider.notifier).state = p,
                  ),
                  const SizedBox(width: 8),
                ],
              ],
            ),
          ),
          const SizedBox(height: 16),
          periodAsync.when(
            loading: () => const SizedBox(
              height: 280,
              child: Center(child: CircularProgressIndicator()),
            ),
            error: (e, _) => Text('Xatolik: $e'),
            data: (data) => _PeriodSummary(
              period: period,
              currentDebt: data.currentDebt,
              currentPayment: data.currentPayment,
              previousDebt: data.previousDebt,
              previousPayment: data.previousPayment,
              rows: data.rows,
            ),
          ),
          const SizedBox(height: 24),
          const Text(
            'Eng katta qarzdor 5 mijoz',
            style: TextStyle(fontSize: 16, fontWeight: FontWeight.w700),
          ),
          const SizedBox(height: 12),
          customersAsync.when(
            loading: () => const SizedBox(
              height: 200,
              child: TxnListSkeleton(count: 4),
            ),
            error: (e, _) => Text('Xatolik: $e'),
            data: (list) {
              final top = [...list.where((cb) => cb.remaining > 0)]
                ..sort((a, b) => b.remaining.compareTo(a.remaining));
              if (top.isEmpty) {
                return Card(
                  child: ListTile(
                    leading: const Icon(Icons.celebration_outlined,
                        color: AppTheme.success),
                    title: const Text('Qarzdor yo\'q 🎉'),
                    subtitle: const Text(
                      'Barcha mijozlar qarzlarini to\'lab bo\'lishgan',
                    ),
                  ),
                );
              }
              return Column(
                children: [
                  for (final cb in top.take(5))
                    Padding(
                      padding: const EdgeInsets.only(bottom: 8),
                      child: Material(
                        color: Theme.of(context).cardColor,
                        borderRadius: BorderRadius.circular(14),
                        clipBehavior: Clip.antiAlias,
                        child: ListTile(
                          leading: CustomerAvatar(
                            name: cb.customer.name,
                            photoPath: cb.customer.photoPath,
                            size: 40,
                            status: AvatarStatusFromBalance.from(
                              remaining: cb.remaining,
                              totalDebt: cb.totalDebt,
                              hasOverdue: cb.hasOverdue,
                            ),
                          ),
                          title: Text(cb.customer.name),
                          subtitle: cb.customer.phone != null
                              ? Text(cb.customer.phone!)
                              : null,
                          trailing: MoneyText(
                            amount: cb.remaining,
                            size: 14,
                            color: cb.hasOverdue
                                ? AppTheme.danger
                                : AppTheme.warning,
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

class _PeriodSummary extends StatelessWidget {
  const _PeriodSummary({
    required this.period,
    required this.currentDebt,
    required this.currentPayment,
    required this.previousDebt,
    required this.previousPayment,
    required this.rows,
  });

  final ReportPeriod period;
  final double currentDebt;
  final double currentPayment;
  final double previousDebt;
  final double previousPayment;
  final List<({DateTime day, double debt, double payment})> rows;

  double _percentChange(double current, double previous) {
    if (previous == 0) return current == 0 ? 0 : 100;
    return ((current - previous) / previous) * 100;
  }

  @override
  Widget build(BuildContext context) {
    final debtDelta = _percentChange(currentDebt, previousDebt);
    final payDelta = _percentChange(currentPayment, previousPayment);

    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Expanded(
                  child: _SummaryMetric(
                    icon: Icons.arrow_upward,
                    color: AppTheme.danger,
                    label: 'Berilgan qarz',
                    amount: currentDebt,
                    deltaPercent: debtDelta,
                    deltaIsGood: false,
                  ),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: _SummaryMetric(
                    icon: Icons.arrow_downward,
                    color: AppTheme.success,
                    label: 'Olingan to\'lov',
                    amount: currentPayment,
                    deltaPercent: payDelta,
                    deltaIsGood: true,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),
            SizedBox(
              height: 160,
              child: _CashflowChart(rows: rows, periodDays: period.days),
            ),
            const SizedBox(height: 8),
            const Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                _Legend(color: AppTheme.danger, label: 'Qarz'),
                SizedBox(width: 16),
                _Legend(color: AppTheme.success, label: 'To\'lov'),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

class _SummaryMetric extends StatelessWidget {
  const _SummaryMetric({
    required this.icon,
    required this.color,
    required this.label,
    required this.amount,
    required this.deltaPercent,
    required this.deltaIsGood,
  });
  final IconData icon;
  final Color color;
  final String label;
  final double amount;
  final double deltaPercent;
  final bool deltaIsGood;

  @override
  Widget build(BuildContext context) {
    final goingUp = deltaPercent > 0;
    final pct = deltaPercent.abs();
    final isPositive = goingUp == deltaIsGood;
    final deltaColor = pct < 0.5
        ? AppTheme.textSecondary
        : (isPositive ? AppTheme.success : AppTheme.danger);
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Icon(icon, color: color, size: 14),
            const SizedBox(width: 4),
            Text(
              label,
              style: const TextStyle(
                fontSize: 12,
                color: AppTheme.textSecondary,
              ),
            ),
          ],
        ),
        const SizedBox(height: 4),
        MoneyText(amount: amount, size: 17, color: color),
        const SizedBox(height: 4),
        Row(
          children: [
            Icon(
              goingUp ? Icons.trending_up : Icons.trending_down,
              size: 12,
              color: deltaColor,
            ),
            const SizedBox(width: 2),
            Text(
              '${goingUp ? "+" : "−"}${pct.toStringAsFixed(0)}%',
              style: TextStyle(
                color: deltaColor,
                fontSize: 11,
                fontWeight: FontWeight.w600,
              ),
            ),
            const SizedBox(width: 4),
            const Text(
              'oldingiga',
              style: TextStyle(
                color: AppTheme.textSecondary,
                fontSize: 11,
              ),
            ),
          ],
        ),
      ],
    );
  }
}

class _StatCard extends StatelessWidget {
  const _StatCard({
    required this.label,
    required this.value,
    required this.icon,
    required this.color,
  });

  final String label;
  final String value;
  final IconData icon;
  final Color color;

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: (MediaQuery.of(context).size.width - 44) / 2,
      child: Card(
        child: Padding(
          padding: const EdgeInsets.all(14),
          child: Row(
            children: [
              Container(
                padding: const EdgeInsets.all(10),
                decoration: BoxDecoration(
                  color: color.withValues(alpha: 0.12),
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
                        fontSize: 18,
                        fontWeight: FontWeight.w800,
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

class _StatCardMoney extends StatelessWidget {
  const _StatCardMoney({
    required this.label,
    required this.amount,
    required this.icon,
    required this.color,
  });

  final String label;
  final double amount;
  final IconData icon;
  final Color color;

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: double.infinity,
      child: Card(
        child: Padding(
          padding: const EdgeInsets.all(14),
          child: Row(
            children: [
              Container(
                padding: const EdgeInsets.all(10),
                decoration: BoxDecoration(
                  color: color.withValues(alpha: 0.12),
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
                    MoneyText(amount: amount, size: 18, color: color),
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
  const _CashflowChart({required this.rows, required this.periodDays});
  final List<({DateTime day, double debt, double payment})> rows;
  final int periodDays;

  @override
  Widget build(BuildContext context) {
    final byDay = <DateTime, ({double debt, double payment})>{};
    for (final r in rows) {
      byDay[DateTime(r.day.year, r.day.month, r.day.day)] =
          (debt: r.debt, payment: r.payment);
    }

    final now = DateTime.now();
    final days = List.generate(periodDays, (i) {
      return DateTime(now.year, now.month, now.day - (periodDays - 1 - i));
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

    final divisor = periodDays > 90 ? 60 : (periodDays > 30 ? 14 : 7);

    return LineChart(
      LineChartData(
        minX: 0,
        maxX: (periodDays - 1).toDouble(),
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
              interval: divisor.toDouble(),
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
