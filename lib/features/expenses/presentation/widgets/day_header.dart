import 'package:flutter/material.dart';

import '../../../../core/theme/app_spacing.dart';
import '../../../../core/theme/theme_x.dart';
import '../../../../core/utils/date_labels.dart';
import '../../../../core/utils/money.dart';
import '../../domain/entities/expense_day_group.dart';

/// Heading above one day's expenses: the day, and what was spent that day.
class DayHeader extends StatelessWidget {
  const DayHeader({super.key, required this.group, required this.now});

  final ExpenseDayGroup group;

  /// Passed in so "Today" and "Yesterday" are decided in one place.
  final DateTime now;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(top: AppSpacing.md),
      child: Row(
        children: [
          Expanded(
            child: Semantics(
              header: true,
              child: Text(
                dayLabel(group.day, now),
                style: context.text.titleSmall,
              ),
            ),
          ),
          Text(
            Money.format(group.totalMinor),
            style: context.text.bodyMedium?.copyWith(
              color: context.scheme.onSurfaceVariant,
            ),
          ),
        ],
      ),
    );
  }
}
