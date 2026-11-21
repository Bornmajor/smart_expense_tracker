import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';

import '../shared/widgets/app_snack_bar.dart';

import '../features/scan/domain/entities/recovered_photo.dart';
import '../features/scan/domain/repositories/receipt_photo_source.dart';
import 'add_expense_flow.dart';
import 'app_routes.dart';

/// Bottom navigation around the three main tabs, plus the add button.
class AppShell extends StatefulWidget {
  const AppShell({super.key, required this.navigationShell});

  final StatefulNavigationShell navigationShell;

  @override
  State<AppShell> createState() => _AppShellState();
}

class _AppShellState extends State<AppShell> {
  static const _settingsIndex = 2;

  StatefulNavigationShell get navigationShell => widget.navigationShell;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) => _recoverLostPhoto());
  }

  /// Android can close the app while the camera is open on a phone short of
  /// memory. The photo is kept, so open the scan screen on it instead of
  /// leaving the user on the list with nothing said.
  Future<void> _recoverLostPhoto() async {
    final photos = context.read<ReceiptPhotoSource>();
    final path = await photos.recoverLost();
    if (!mounted) return;
    if (path != null) {
      context.push(AppRoutes.scan, extra: RecoveredPhoto(path));
      return;
    }
    if (await photos.pickWasInterrupted() && mounted) {
      context.showWarning(
        'Android closed the app while you were choosing the file. '
        'Please try again.',
      );
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
              onPressed: () => startAddExpense(context),
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
