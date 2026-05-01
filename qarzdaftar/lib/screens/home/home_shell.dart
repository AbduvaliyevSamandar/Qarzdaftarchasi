import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../providers/customers_provider.dart';
import '../../providers/locale_provider.dart';
import '../reports/reports_screen.dart';
import '../settings/settings_screen.dart';
import 'home_screen.dart';
import 'transactions_tab.dart';

class HomeShell extends ConsumerStatefulWidget {
  const HomeShell({super.key});

  @override
  ConsumerState<HomeShell> createState() => _HomeShellState();
}

class _HomeShellState extends ConsumerState<HomeShell> {
  int _index = 0;
  DateTime? _lastBackPress;

  static const _tabs = [
    HomeScreen(),
    TransactionsTab(),
    ReportsScreen(),
    SettingsScreen(),
  ];

  Future<bool> _handleBack() async {
    if (_index != 0) {
      setState(() => _index = 0);
      return false;
    }
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

  @override
  Widget build(BuildContext context) {
    final tr = ref.watch(stringsProvider);
    final overdue = ref.watch(overdueCountProvider);
    return PopScope(
      canPop: false,
      onPopInvokedWithResult: (didPop, _) async {
        if (didPop) return;
        final canExit = await _handleBack();
        if (canExit) SystemNavigator.pop();
      },
      child: Scaffold(
        body: IndexedStack(index: _index, children: _tabs),
        bottomNavigationBar: NavigationBar(
          selectedIndex: _index,
          onDestinationSelected: (i) {
            HapticFeedback.selectionClick();
            setState(() => _index = i);
          },
          destinations: [
            NavigationDestination(
              icon: Badge(
                isLabelVisible: overdue > 0,
                label: Text('$overdue'),
                child: const Icon(Icons.people_outline),
              ),
              selectedIcon: Badge(
                isLabelVisible: overdue > 0,
                label: Text('$overdue'),
                child: const Icon(Icons.people),
              ),
              label: tr.tabCustomers,
            ),
            NavigationDestination(
              icon: const Icon(Icons.swap_vert_outlined),
              selectedIcon: const Icon(Icons.swap_vert),
              label: tr.tabTransactions,
            ),
            NavigationDestination(
              icon: const Icon(Icons.insert_chart_outlined),
              selectedIcon: const Icon(Icons.insert_chart),
              label: tr.tabReports,
            ),
            NavigationDestination(
              icon: const Icon(Icons.settings_outlined),
              selectedIcon: const Icon(Icons.settings),
              label: tr.tabSettings,
            ),
          ],
        ),
      ),
    );
  }
}
