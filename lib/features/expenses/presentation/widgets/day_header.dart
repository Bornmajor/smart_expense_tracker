import 'package:flutter/material.dart';

import '../../../../core/theme/app_spacing.dart';
import '../../../../core/theme/theme_x.dart';
import '../../../../core/utils/date_labels.dart';
import '../../../../core/utils/currency.dart';
import '../../../../shared/widgets/amount_row.dart';
import '../../domain/entities/expense_day_group.dart';

/// Heading above one day's expenses: the day, and what was spent that day.
class DayHeader extends StatelessWidget {
  const DayHeader({
    super.key,
    required this.group,
    required this.now,
    required this.currency,
  });

  final ExpenseDayGroup group;

  /// Passed in so "Today" and "Yesterday" are decided in one place.
  final DateTime now;
  final Currency currency;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(top: AppSpacing.md),
      child: AmountRow(
        leading: Semantics(
          header: true,
          child: Text(dayLabel(group.day, now), style: context.text.titleSmall),
        ),
        amount: currency.format(group.totalMinor),
        amountStyle: context.text.bodyMedium?.copyWith(
          color: context.scheme.onSurfaceVariant,
        ),
      ),
    );
  }
}
