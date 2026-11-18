import 'package:flutter/material.dart';

import '../../../../core/theme/app_spacing.dart';
import '../../../../core/theme/theme_x.dart';
import '../../../../core/utils/money.dart';
import '../../domain/entities/expense.dart';

/// One expense: vendor, category and amount. Tap to edit.
class ExpenseTile extends StatelessWidget {
  const ExpenseTile({
    super.key,
    required this.expense,
    this.categoryName,
    this.onTap,
  });

  final Expense expense;

  /// Shown under the vendor. Left out when the category is not known.
  final String? categoryName;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    return Card(
      clipBehavior: Clip.antiAlias,
      child: InkWell(
        onTap: onTap,
        child: Padding(
          padding: AppSpacing.card,
          child: Row(
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(expense.vendor, style: context.text.titleMedium),
                    if (categoryName != null) ...[
                      const Gap(AppSpacing.xs),
                      Text(categoryName!, style: context.text.bodySmall),
                    ],
                  ],
                ),
              ),
              Text(
                Money.format(expense.amountMinor),
                style: context.text.titleMedium,
              ),
            ],
          ),
        ),
      ),
    );
  }
}
