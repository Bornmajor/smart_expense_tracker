import 'package:flutter/material.dart';

import '../../../../core/theme/app_spacing.dart';

enum AddExpenseChoice { manual, scan }

/// Bottom sheet asking how the user wants to add an expense.
/// Manual entry is listed first because scanning is optional.
Future<AddExpenseChoice?> showAddExpenseSheet(BuildContext context) {
  return showModalBottomSheet<AddExpenseChoice>(
    context: context,
    builder: (context) => const _AddExpenseSheet(),
  );
}

class _AddExpenseSheet extends StatelessWidget {
  const _AddExpenseSheet();

  @override
  Widget build(BuildContext context) {
    return SafeArea(
      child: Padding(
        padding: const EdgeInsets.only(bottom: AppSpacing.lg),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            ListTile(
              leading: const Icon(Icons.edit_note),
              title: const Text('Enter manually'),
              subtitle: const Text('Type in the details'),
              onTap: () => Navigator.pop(context, AddExpenseChoice.manual),
            ),
            ListTile(
              leading: const Icon(Icons.document_scanner_outlined),
              title: const Text('Scan receipt'),
              subtitle: const Text('Read the vendor, date, and total'),
              onTap: () => Navigator.pop(context, AddExpenseChoice.scan),
            ),
          ],
        ),
      ),
    );
  }
}
