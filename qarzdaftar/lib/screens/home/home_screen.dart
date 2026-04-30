import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../models/customer_balance.dart';
import '../../providers/customers_provider.dart';
import '../../widgets/customer_tile.dart';
import '../../widgets/balance_card.dart';
import '../customers/customer_detail_screen.dart';
import '../customers/edit_customer_screen.dart';

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
                child: Center(child: CircularProgressIndicator()),
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
                    );
                  },
                );
              },
            ),
            const SliverPadding(padding: EdgeInsets.only(bottom: 88)),
          ],
        ),
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () {
          Navigator.push(
            context,
            MaterialPageRoute(builder: (_) => const EditCustomerScreen()),
          );
        },
        icon: const Icon(Icons.person_add_alt_1),
        label: const Text('Mijoz qo\'shish'),
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
