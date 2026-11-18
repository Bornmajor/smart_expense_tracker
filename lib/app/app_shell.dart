import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../features/expenses/presentation/widgets/add_expense_sheet.dart';
import '../features/scan/domain/entities/receipt_source.dart';
import 'app_routes.dart';

/// Bottom navigation around the three main tabs, plus the add button.
class AppShell extends StatelessWidget {
  const AppShell({super.key, required this.navigationShell});

  final StatefulNavigationShell navigationShell;

  static const _settingsIndex = 2;

  Future<void> _onAdd(BuildContext context) async {
    final choice = await showAddExpenseSheet(context);
    if (!context.mounted || choice == null) return;

    switch (choice) {
      case AddExpenseChoice.manual:
        context.push(AppRoutes.addExpense);
      case AddExpenseChoice.scanGallery:
        context.push(AppRoutes.scan, extra: ReceiptSource.gallery);
      case AddExpenseChoice.scanCamera:
        context.push(AppRoutes.scan, extra: ReceiptSource.camera);
    }
  }

  @override
  Widget build(BuildContext context) {
    final index = navigationShell.currentIndex;
    return Scaffold(
      // Sides only: each page's app bar handles the top, and the navigation
      // bar and Scaffold handle the bottom. This keeps content out of a
      // landscape notch.
      body: SafeArea(top: false, bottom: false, child: navigationShell),
      floatingActionButton: index == _settingsIndex
          ? null
          : FloatingActionButton.extended(
              onPressed: () => _onAdd(context),
              icon: const Icon(Icons.add),
              label: const Text('Add expense'),
            ),
      bottomNavigationBar: NavigationBar(
        selectedIndex: index,
        onDestinationSelected: (value) =>
            navigationShell.goBranch(value, initialLocation: value == index),
        destinations: const [
          NavigationDestination(
            icon: Icon(Icons.receipt_long_outlined),
            selectedIcon: Icon(Icons.receipt_long),
            label: 'Expenses',
          ),
          NavigationDestination(
            icon: Icon(Icons.pie_chart_outline),
            selectedIcon: Icon(Icons.pie_chart),
            label: 'Summary',
          ),
          NavigationDestination(
            icon: Icon(Icons.settings_outlined),
            selectedIcon: Icon(Icons.settings),
            label: 'Settings',
          ),
        ],
      ),
    );
  }
}
