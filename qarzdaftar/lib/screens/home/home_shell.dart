import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

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
          onDestinationSelected: (i) => setState(() => _index = i),
          destinations: const [
            NavigationDestination(
              icon: Icon(Icons.people_outline),
              selectedIcon: Icon(Icons.people),
              label: 'Mijozlar',
            ),
            NavigationDestination(
              icon: Icon(Icons.swap_vert_outlined),
              selectedIcon: Icon(Icons.swap_vert),
              label: 'Tranzaksiyalar',
            ),
            NavigationDestination(
              icon: Icon(Icons.insert_chart_outlined),
              selectedIcon: Icon(Icons.insert_chart),
              label: 'Hisobot',
            ),
            NavigationDestination(
              icon: Icon(Icons.settings_outlined),
              selectedIcon: Icon(Icons.settings),
              label: 'Sozlamalar',
            ),
          ],
        ),
      ),
    );
  }
}
