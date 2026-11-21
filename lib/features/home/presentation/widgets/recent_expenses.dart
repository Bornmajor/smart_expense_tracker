import 'package:flutter/material.dart';

import '../../../../core/theme/app_spacing.dart';
import '../../../../core/theme/theme_x.dart';
import '../../../../core/utils/currency.dart';
import '../../../expenses/domain/entities/expense.dart';
import '../../../expenses/presentation/widgets/expense_tile.dart';

/// The latest few expenses, with a link to all of them.
class RecentExpenses extends StatelessWidget {
  const RecentExpenses({
    super.key,
    required this.expenses,
    required this.categoryNames,
    required this.currency,
    required this.onOpen,
    required this.onSeeAll,
  });

  final List<Expense> expenses;

  /// Category id to name.
  final Map<String, String> categoryNames;
  final Currency currency;

  /// Opens an expense to edit it.
  final ValueChanged<Expense> onOpen;
  final VoidCallback onSeeAll;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Expanded(
              child: Semantics(
                header: true,
                child: Text('Recent', style: context.text.titleMedium),
              ),
            ),
            TextButton(onPressed: onSeeAll, child: const Text('See all')),
          ],
        ),
        const Gap(AppSpacing.xs),
        for (final expense in expenses)
          Padding(
            padding: const EdgeInsets.only(bottom: AppSpacing.sm),
            child: ExpenseTile(
              expense: expense,
              currency: currency,
              categoryName: categoryNames[expense.categoryId],
              onTap: () => onOpen(expense),
            ),
          ),
      ],
    );
  }
}
