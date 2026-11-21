import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';

import '../features/expenses/presentation/widgets/add_expense_sheet.dart';
import '../features/mpesa/domain/usecases/import_mpesa.dart';
import '../features/mpesa/presentation/widgets/mpesa_sheet.dart';
import '../features/quick_add/domain/usecases/quick_add.dart';
import '../features/quick_add/presentation/widgets/quick_add_sheet.dart';
import '../features/scan/domain/entities/receipt_source.dart';
import '../shared/widgets/app_snack_bar.dart';
import 'app_routes.dart';

/// Asks how the user wants to add an expense and takes them there: by hand, a
/// typed line, a pasted M-Pesa message, or a receipt. Used by the Add button
/// and by the empty screens, so every way in behaves the same.
Future<void> startAddExpense(BuildContext context) async {
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
