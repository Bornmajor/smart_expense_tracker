import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';

import '../shared/widgets/app_snack_bar.dart';

import '../features/expenses/presentation/widgets/add_expense_sheet.dart';
import '../features/scan/domain/entities/recovered_photo.dart';
import '../features/mpesa/domain/usecases/import_mpesa.dart';
import '../features/mpesa/presentation/widgets/mpesa_sheet.dart';
import '../features/quick_add/domain/usecases/quick_add.dart';
import '../features/quick_add/presentation/widgets/quick_add_sheet.dart';
import '../features/scan/domain/entities/receipt_source.dart';
import '../features/scan/domain/repositories/receipt_photo_source.dart';
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

  Future<void> _onAdd(BuildContext context) async {
    final choice = await showAddExpenseSheet(context);
    if (!context.mounted || choice == null) return;

    switch (choice) {
      case AddExpenseChoice.manual:
        context.push(AppRoutes.addExpense);
      case AddExpenseChoice.mpesa:
        await _addFromMpesa(context);
      case AddExpenseChoice.quickAdd:
        final text = await showQuickAddSheet(context);
        if (text == null || !context.mounted) return;
        final result = await context.read<QuickAdd>()(text);
        if (!context.mounted) return;
        context.push(AppRoutes.addExpense, extra: result);
      case AddExpenseChoice.scanFile:
        context.push(AppRoutes.scan, extra: ReceiptSource.file);
      case AddExpenseChoice.scanCamera:
        context.push(AppRoutes.scan, extra: ReceiptSource.camera);
    }
  }

  /// A pasted M-Pesa message, read into a filled-in form. A message that was
  /// already added asks first, so the same payment is not recorded twice.
  Future<void> _addFromMpesa(BuildContext context) async {
    final text = await showMpesaSheet(context);
    if (text == null || !context.mounted) return;
    final import = await context.read<ImportMpesa>()(text);
    if (!context.mounted) return;

    final result = import.result;
    switch (import.status) {
      case MpesaStatus.ready:
        context.push(AppRoutes.addExpense, extra: result);
      case MpesaStatus.alreadyAdded:
        final again = await showDialog<bool>(
          context: context,
          builder: (context) => AlertDialog(
            title: const Text('Already added'),
            content: const Text(
              'An expense from this M-Pesa message is already saved. Add it '
              'again?',
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(context, false),
                child: const Text('Cancel'),
              ),
              TextButton(
                onPressed: () => Navigator.pop(context, true),
                child: const Text('Add again'),
              ),
            ],
          ),
        );
        if (again == true && context.mounted) {
          context.push(AppRoutes.addExpense, extra: result);
        }
      case MpesaStatus.income:
        context.showInfo('That message is money you received, not an expense.');
      case MpesaStatus.notRecognised:
        context.showWarning('No amount found in that message.');
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
