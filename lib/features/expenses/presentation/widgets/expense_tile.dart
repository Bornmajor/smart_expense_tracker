import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

import '../../../../core/theme/app_spacing.dart';
import '../../../../core/theme/theme_x.dart';
import '../../../../core/utils/money.dart';
import '../../domain/entities/expense.dart';

class ExpenseTile extends StatelessWidget {
  const ExpenseTile({super.key, required this.expense});

  final Expense expense;

  @override
  Widget build(BuildContext context) {
    return Card(
      child: Padding(
        padding: AppSpacing.card,
        child: Row(
          children: [
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(expense.vendor, style: context.text.titleMedium),
                  const Gap(AppSpacing.xs),
                  Text(
                    DateFormat.yMMMd().format(expense.date),
                    style: context.text.bodySmall,
                  ),
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
    );
  }
}
