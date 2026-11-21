import 'package:flutter/material.dart';

import '../../../../core/theme/app_spacing.dart';
import '../../../../core/theme/theme_x.dart';
import '../../../../core/utils/currency.dart';
import '../../domain/entities/budget.dart';
import '../../domain/entities/budget_progress.dart';
import 'budget_progress_tile.dart';

/// The budget for one category, at the top of that category's page. With a
/// budget it shows how much of it is used, and tapping it edits it. Without one
/// it says so and offers to set one, right where the user is looking at the
/// spending.
class CategoryBudgetStrip extends StatelessWidget {
  const CategoryBudgetStrip({
    super.key,
    required this.categoryName,
    required this.spentMinor,
    required this.currency,
    required this.onTap,
    this.budget,
  });

  final String categoryName;

  /// What was spent in the category this month.
  final int spentMinor;
  final Currency currency;

  /// The category's monthly budget, or null when none is set.
  final Budget? budget;

  /// Sets or edits the budget.
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final current = budget;
    if (current != null) {
      return BudgetProgressTile(
        name: '$categoryName budget',
        progress: BudgetProgress(budget: current, spentMinor: spentMinor),
        currency: currency,
        onTap: onTap,
      );
    }
    return Card(
      child: Padding(
        padding: AppSpacing.card,
        child: Row(
          children: [
            Icon(Icons.savings_outlined, color: context.scheme.primary),
            const SizedBox(width: AppSpacing.md),
            Expanded(
              child: Text(
                'No budget for $categoryName',
                style: context.text.bodyMedium,
              ),
            ),
            TextButton(onPressed: onTap, child: const Text('Set a budget')),
          ],
        ),
      ),
    );
  }
}
