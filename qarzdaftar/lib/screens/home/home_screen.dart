import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../models/customer_balance.dart';
import '../../providers/customers_provider.dart';
import '../../widgets/customer_tile.dart';
import '../../widgets/balance_card.dart';
import '../customers/add_customer_screen.dart';
import '../customers/customer_detail_screen.dart';
import '../settings/settings_screen.dart';

class HomeScreen extends ConsumerStatefulWidget {
  const HomeScreen({super.key});

  @override
  ConsumerState<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends ConsumerState<HomeScreen> {
  final _searchCtrl = TextEditingController();
  String _query = '';
  DateTime? _lastBackPress;

  @override
  void dispose() {
    _searchCtrl.dispose();
    super.dispose();
  }

  Future<bool> _onWillPop() async {
    final now = DateTime.now();
    if (_lastBackPress == null ||
        now.difference(_lastBackPress!) > const Duration(seconds: 2)) {
      _lastBackPress = now;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Chiqish uchun yana bir marta bosing'),
          duration: Duration(seconds: 2),
        ),
      );
      return false;
    }
    return true;
  }

  List<CustomerBalance> _filter(List<CustomerBalance> list) {
    if (_query.isEmpty) return list;
    final q = _query.toLowerCase();
    return list.where((cb) {
      final c = cb.customer;
      if (c.name.toLowerCase().contains(q)) return true;
      if (c.phone != null && c.phone!.contains(q)) return true;
      if (c.address != null && c.address!.toLowerCase().contains(q)) return true;
      return false;
    }).toList();
  }

  @override
  Widget build(BuildContext context) {
    final customersAsync = ref.watch(customersProvider);
    final totalsAsync = ref.watch(shopTotalsProvider);

    return PopScope(
      canPop: false,
      onPopInvokedWithResult: (didPop, _) async {
        if (didPop) return;
        final canExit = await _onWillPop();
        if (canExit) SystemNavigator.pop();
      },
      child: Scaffold(
        appBar: AppBar(
          title: const Text(
            'Qarz Daftarchasi',
            style: TextStyle(fontWeight: FontWeight.w700),
          ),
          actions: [
            IconButton(
              icon: const Icon(Icons.settings_outlined),
              onPressed: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(builder: (_) => const SettingsScreen()),
                );
              },
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
                  padding: const EdgeInsets.fromLTRB(16, 4, 16, 8),
                  child: TextField(
                    controller: _searchCtrl,
                    onChanged: (v) => setState(() => _query = v.trim()),
                    decoration: InputDecoration(
                      hintText: 'Mijoz qidirish (ism, telefon, manzil)',
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
              const SliverToBoxAdapter(
                child: Padding(
                  padding: EdgeInsets.fromLTRB(16, 4, 16, 8),
                  child: Text(
                    'Mijozlar',
                    style: TextStyle(fontSize: 18, fontWeight: FontWeight.w600),
                  ),
                ),
              ),
              customersAsync.when(
                loading: () => const SliverFillRemaining(
                  child: Center(child: CircularProgressIndicator()),
                ),
                error: (e, _) => SliverFillRemaining(
                  child: Center(child: Text('Xatolik: $e')),
                ),
                data: (list) {
                  final filtered = _filter(list);
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
                          child: Text('Hech narsa topilmadi'),
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
              MaterialPageRoute(builder: (_) => const AddCustomerScreen()),
            );
          },
          icon: const Icon(Icons.person_add_alt_1),
          label: const Text('Mijoz qo\'shish'),
        ),
      ),
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
