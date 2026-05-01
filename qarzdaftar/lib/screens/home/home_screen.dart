import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../models/customer_balance.dart';
import '../../models/transaction.dart';
import '../../providers/customers_provider.dart';
import '../../widgets/customer_tile.dart';
import '../../widgets/balance_card.dart';
import '../../widgets/skeleton.dart';
import '../../widgets/today_summary_card.dart';
import '../customers/customer_detail_screen.dart';
import '../customers/edit_customer_screen.dart';
import '../transactions/add_transaction_screen.dart';

class HomeScreen extends ConsumerStatefulWidget {
  const HomeScreen({super.key});

  @override
  ConsumerState<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends ConsumerState<HomeScreen> {
  final _searchCtrl = TextEditingController();
  String _query = '';

  @override
  void dispose() {
    _searchCtrl.dispose();
    super.dispose();
  }

  List<CustomerBalance> _apply(
    List<CustomerBalance> list,
    CustomerFilter filter,
    CustomerSort sort,
  ) {
    Iterable<CustomerBalance> stream = list;

    if (_query.isNotEmpty) {
      final q = _query.toLowerCase();
      stream = stream.where((cb) {
        final c = cb.customer;
        if (c.name.toLowerCase().contains(q)) return true;
        if (c.phone != null && c.phone!.contains(q)) return true;
        if (c.address != null && c.address!.toLowerCase().contains(q)) return true;
        return false;
      });
    }

    stream = switch (filter) {
      CustomerFilter.all => stream,
      CustomerFilter.hasDebt => stream.where((cb) => cb.remaining > 0),
      CustomerFilter.overdue => stream.where((cb) => cb.hasOverdue),
      CustomerFilter.cleared =>
        stream.where((cb) => cb.totalDebt > 0 && cb.remaining <= 0),
    };

    final result = stream.toList();
    result.sort((a, b) => switch (sort) {
          CustomerSort.byDebtDesc => b.remaining.compareTo(a.remaining),
          CustomerSort.byNameAsc =>
            a.customer.name.toLowerCase().compareTo(b.customer.name.toLowerCase()),
          CustomerSort.byRecent => (b.lastTxnAt ?? b.customer.createdAt)
              .compareTo(a.lastTxnAt ?? a.customer.createdAt),
        });
    return result;
  }

  @override
  Widget build(BuildContext context) {
    final customersAsync = ref.watch(customersProvider);
    final totalsAsync = ref.watch(shopTotalsProvider);
    final filter = ref.watch(customerFilterProvider);
    final sort = ref.watch(customerSortProvider);

    return Scaffold(
      appBar: AppBar(
        title: const Text(
          'Qarz Daftarchasi',
          style: TextStyle(fontWeight: FontWeight.w700),
        ),
        actions: [
          PopupMenuButton<CustomerSort>(
            icon: const Icon(Icons.sort),
            tooltip: 'Saralash',
            initialValue: sort,
            onSelected: (v) =>
                ref.read(customerSortProvider.notifier).state = v,
            itemBuilder: (_) => const [
              PopupMenuItem(
                value: CustomerSort.byDebtDesc,
                child: Text('Qarz miqdori bo\'yicha'),
              ),
              PopupMenuItem(
                value: CustomerSort.byNameAsc,
                child: Text('Ism bo\'yicha'),
              ),
              PopupMenuItem(
                value: CustomerSort.byRecent,
                child: Text('So\'nggi faollik bo\'yicha'),
              ),
            ],
          ),
        ],
      ),
      body: RefreshIndicator(
        onRefresh: () => ref.read(customersProvider.notifier).refresh(),
        child: CustomScrollView(
          slivers: [
            SliverToBoxAdapter(
              child: totalsAsync.when(
                data: (t) => BalanceCard(
                  totalDebt: t.totalDebt,
                  totalPaid: t.totalPaid,
                ),
                loading: () => const SizedBox(
                  height: 140,
                  child: Center(child: CircularProgressIndicator()),
                ),
                error: (e, _) => Padding(
                  padding: const EdgeInsets.all(16),
                  child: Text('Xatolik: $e'),
                ),
              ),
            ),
            const SliverToBoxAdapter(child: TodaySummaryCard()),
            SliverToBoxAdapter(
              child: Padding(
                padding: const EdgeInsets.fromLTRB(16, 0, 16, 8),
                child: TextField(
                  controller: _searchCtrl,
                  onChanged: (v) => setState(() => _query = v.trim()),
                  decoration: InputDecoration(
                    hintText: 'Mijoz qidirish',
                    prefixIcon: const Icon(Icons.search),
                    suffixIcon: _query.isEmpty
                        ? null
                        : IconButton(
                            icon: const Icon(Icons.clear),
                            onPressed: () {
                              _searchCtrl.clear();
                              setState(() => _query = '');
                            },
                          ),
                  ),
                ),
              ),
            ),
            SliverToBoxAdapter(
              child: SingleChildScrollView(
                scrollDirection: Axis.horizontal,
                padding: const EdgeInsets.symmetric(horizontal: 16),
                child: Row(
                  children: [
                    _FilterChip(
                      label: 'Hammasi',
                      selected: filter == CustomerFilter.all,
                      onTap: () => ref
                          .read(customerFilterProvider.notifier)
                          .state = CustomerFilter.all,
                    ),
                    const SizedBox(width: 8),
                    _FilterChip(
                      label: 'Qarzdor',
                      selected: filter == CustomerFilter.hasDebt,
                      onTap: () => ref
                          .read(customerFilterProvider.notifier)
                          .state = CustomerFilter.hasDebt,
                    ),
                    const SizedBox(width: 8),
                    _FilterChip(
                      label: 'Muddati o\'tdi',
                      selected: filter == CustomerFilter.overdue,
                      onTap: () => ref
                          .read(customerFilterProvider.notifier)
                          .state = CustomerFilter.overdue,
                    ),
                    const SizedBox(width: 8),
                    _FilterChip(
                      label: 'To\'lab bo\'lgan',
                      selected: filter == CustomerFilter.cleared,
                      onTap: () => ref
                          .read(customerFilterProvider.notifier)
                          .state = CustomerFilter.cleared,
                    ),
                  ],
                ),
              ),
            ),
            const SliverToBoxAdapter(child: SizedBox(height: 8)),
            customersAsync.when(
              loading: () => const SliverFillRemaining(
                hasScrollBody: false,
                child: SizedBox(
                  height: 400,
                  child: CustomerListSkeleton(),
                ),
              ),
              error: (e, _) => SliverFillRemaining(
                child: Center(child: Text('Xatolik: $e')),
              ),
              data: (list) {
                final filtered = _apply(list, filter, sort);
                if (list.isEmpty) {
                  return const SliverFillRemaining(
                    hasScrollBody: false,
                    child: _EmptyState(),
                  );
                }
                if (filtered.isEmpty) {
                  return const SliverFillRemaining(
                    hasScrollBody: false,
                    child: Center(
                      child: Padding(
                        padding: EdgeInsets.all(24),
                        child: Text('Bu shartga mos mijoz topilmadi'),
                      ),
                    ),
                  );
                }
                return SliverList.builder(
                  itemCount: filtered.length,
                  itemBuilder: (context, i) {
                    final cb = filtered[i];
                    return CustomerTile(
                      balance: cb,
                      onTap: () {
                        Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (_) =>
                                CustomerDetailScreen(customerId: cb.customer.id),
                          ),
                        );
                      },
                      onAddDebt: (TxnType type) {
                        Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (_) => AddTransactionScreen(
                              customerId: cb.customer.id,
                            ),
                          ),
                        );
                      },
                      onAddPayment: (TxnType type) {
                        Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (_) => AddTransactionScreen(
                              customerId: cb.customer.id,
                            ),
                          ),
                        );
                      },
                    );
                  },
                );
              },
            ),
            const SliverPadding(padding: EdgeInsets.only(bottom: 88)),
          ],
        ),
      ),
      floatingActionButton: _SpeedDialFab(
        onAddCustomer: () {
          Navigator.push(
            context,
            MaterialPageRoute(builder: (_) => const EditCustomerScreen()),
          );
        },
        onAddTransaction: () => _pickCustomerThenAddTxn(context),
      ),
    );
  }

  Future<void> _pickCustomerThenAddTxn(BuildContext context) async {
    final list = ref.read(customersProvider).valueOrNull ?? const [];
    if (list.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Avval mijoz qo\'shing')),
      );
      return;
    }
    final cb = await showModalBottomSheet<CustomerBalance>(
      context: context,
      isScrollControlled: true,
      builder: (_) => _CustomerPickerSheet(list: list),
    );
    if (cb == null || !context.mounted) return;
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => AddTransactionScreen(customerId: cb.customer.id),
      ),
    );
  }
}

class _SpeedDialFab extends StatefulWidget {
  const _SpeedDialFab({
    required this.onAddCustomer,
    required this.onAddTransaction,
  });

  final VoidCallback onAddCustomer;
  final VoidCallback onAddTransaction;

  @override
  State<_SpeedDialFab> createState() => _SpeedDialFabState();
}

class _SpeedDialFabState extends State<_SpeedDialFab>
    with SingleTickerProviderStateMixin {
  bool _open = false;
  late final AnimationController _ctrl;

  @override
  void initState() {
    super.initState();
    _ctrl = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 220),
    );
  }

  @override
  void dispose() {
    _ctrl.dispose();
    super.dispose();
  }

  void _toggle() {
    setState(() => _open = !_open);
    if (_open) {
      _ctrl.forward();
    } else {
      _ctrl.reverse();
    }
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      crossAxisAlignment: CrossAxisAlignment.end,
      children: [
        ScaleTransition(
          scale: _ctrl,
          alignment: Alignment.bottomRight,
          child: FadeTransition(
            opacity: _ctrl,
            child: Padding(
              padding: const EdgeInsets.only(bottom: 10),
              child: FloatingActionButton.extended(
                heroTag: 'fab-customer',
                onPressed: () {
                  _toggle();
                  widget.onAddCustomer();
                },
                icon: const Icon(Icons.person_add_alt_1),
                label: const Text('Mijoz'),
                backgroundColor: Theme.of(context).colorScheme.secondaryContainer,
                foregroundColor: Theme.of(context).colorScheme.onSecondaryContainer,
              ),
            ),
          ),
        ),
        ScaleTransition(
          scale: _ctrl,
          alignment: Alignment.bottomRight,
          child: FadeTransition(
            opacity: _ctrl,
            child: Padding(
              padding: const EdgeInsets.only(bottom: 10),
              child: FloatingActionButton.extended(
                heroTag: 'fab-txn',
                onPressed: () {
                  _toggle();
                  widget.onAddTransaction();
                },
                icon: const Icon(Icons.receipt_long_outlined),
                label: const Text('Yozuv'),
                backgroundColor: Theme.of(context).colorScheme.secondaryContainer,
                foregroundColor: Theme.of(context).colorScheme.onSecondaryContainer,
              ),
            ),
          ),
        ),
        FloatingActionButton(
          heroTag: 'fab-main',
          onPressed: _toggle,
          child: AnimatedRotation(
            duration: const Duration(milliseconds: 220),
            turns: _open ? 0.125 : 0,
            child: const Icon(Icons.add),
          ),
        ),
      ],
    );
  }
}

class _CustomerPickerSheet extends StatefulWidget {
  const _CustomerPickerSheet({required this.list});
  final List<CustomerBalance> list;

  @override
  State<_CustomerPickerSheet> createState() => _CustomerPickerSheetState();
}

class _CustomerPickerSheetState extends State<_CustomerPickerSheet> {
  String _q = '';

  @override
  Widget build(BuildContext context) {
    final filtered = _q.isEmpty
        ? widget.list
        : widget.list.where((cb) {
            final name = cb.customer.name.toLowerCase();
            final phone = cb.customer.phone ?? '';
            return name.contains(_q.toLowerCase()) || phone.contains(_q);
          }).toList();
    return Padding(
      padding: EdgeInsets.only(
        bottom: MediaQuery.of(context).viewInsets.bottom,
      ),
      child: SizedBox(
        height: MediaQuery.of(context).size.height * 0.7,
        child: Column(
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
            const Padding(
              padding: EdgeInsets.fromLTRB(16, 16, 16, 8),
              child: Align(
                alignment: Alignment.centerLeft,
                child: Text(
                  'Mijozni tanlang',
                  style: TextStyle(fontSize: 16, fontWeight: FontWeight.w700),
                ),
              ),
            ),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16),
              child: TextField(
                onChanged: (v) => setState(() => _q = v.trim()),
                decoration: const InputDecoration(
                  hintText: 'Qidirish',
                  prefixIcon: Icon(Icons.search),
                ),
              ),
            ),
            const SizedBox(height: 8),
            Expanded(
              child: ListView.builder(
                itemCount: filtered.length,
                itemBuilder: (_, i) {
                  final cb = filtered[i];
                  return CustomerTile(
                    balance: cb,
                    onTap: () => Navigator.pop(context, cb),
                    onAddDebt: (_) => Navigator.pop(context, cb),
                    onAddPayment: (_) => Navigator.pop(context, cb),
                  );
                },
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _FilterChip extends StatelessWidget {
  const _FilterChip({
    required this.label,
    required this.selected,
    required this.onTap,
  });
  final String label;
  final bool selected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return FilterChip(
      label: Text(label),
      selected: selected,
      onSelected: (_) => onTap(),
    );
  }
}

class _EmptyState extends StatelessWidget {
  const _EmptyState();

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.all(32),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(Icons.people_outline, size: 80, color: Colors.grey.shade400),
          const SizedBox(height: 16),
          const Text(
            'Hozircha mijoz yo\'q',
            style: TextStyle(fontSize: 18, fontWeight: FontWeight.w600),
          ),
          const SizedBox(height: 8),
          Text(
            'Pastdagi tugma orqali yangi mijoz qo\'shing',
            style: TextStyle(color: Colors.grey.shade600),
          ),
        ],
      ),
    );
  }
}
