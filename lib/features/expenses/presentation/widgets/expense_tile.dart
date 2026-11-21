import 'package:flutter/material.dart';

import '../../../../core/theme/app_spacing.dart';
import '../../../../core/theme/theme_x.dart';
import '../../../../core/utils/currency.dart';
import '../../../../shared/widgets/amount_row.dart';
import '../../domain/entities/expense.dart';
import '../../domain/validation/expense_rules.dart';

/// One expense. Tap to edit.
///
/// The title leads when there is one, and the vendor moves to the line below
/// with the category. Without a title the vendor leads, as before.
class ExpenseTile extends StatelessWidget {
  const ExpenseTile({
    super.key,
    required this.expense,
    required this.currency,
    this.categoryName,
    this.onTap,
  });

  final Expense expense;
  final Currency currency;

  /// Shown on the second line. Left out when the category is not known.
  final String? categoryName;
  final VoidCallback? onTap;

  bool get _hasTitle => expense.title.isNotEmpty;

  /// The small line under the heading: vendor (when it is not the heading and
  /// is known) and category, separated by a dot.
  String get _details => [
    if (_hasTitle && expense.vendor != ExpenseRules.unknownVendor)
      expense.vendor,
    ?categoryName,
    if (expense.recurringRuleId != null) 'Repeats',
  ].join(' · ');

  @override
  Widget build(BuildContext context) {
    final details = _details;
    return Card(
      clipBehavior: Clip.antiAlias,
      child: InkWell(
        onTap: onTap,
        child: Padding(
          padding: AppSpacing.card,
          child: AmountRow(
            leading: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  _hasTitle ? expense.title : expense.vendor,
                  style: context.text.titleMedium,
                ),
                if (details.isNotEmpty) ...[
                  const Gap(AppSpacing.xs),
                  Text(details, style: context.text.bodySmall),
                ],
              ],
            ),
            amount: currency.format(expense.amountMinor),
            amountStyle: context.text.titleMedium,
          ),
        ),
      ),
    );
  }
}
