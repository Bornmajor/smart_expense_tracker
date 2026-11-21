import 'dart:math' as math;

import 'package:flutter/material.dart';

import '../../../../core/theme/app_spacing.dart';
import '../../../../core/theme/theme_x.dart';
import '../../../../core/utils/currency.dart';
import '../../../../shared/widgets/amount_row.dart';

/// A small bar chart of what was spent in each month of the year, so the
/// trend is clear at a glance. The current month is highlighted, months still
/// to come are left empty, and tapping a bar opens that month.
class YearChart extends StatelessWidget {
  const YearChart({
    super.key,
    required this.year,
    required this.totals,
    required this.currentMonth,
    required this.currency,
    required this.onMonthTap,
  });

  /// The tallest a bar can be.
  static const barArea = 112.0;
  static const _letters = [
    'J',
    'F',
    'M',
    'A',
    'M',
    'J',
    'J',
    'A',
    'S',
    'O',
    'N',
    'D',
  ];
  static const _names = [
    'January',
    'February',
    'March',
    'April',
    'May',
    'June',
    'July',
    'August',
    'September',
    'October',
    'November',
    'December',
  ];

  final int year;

  /// Twelve totals in minor units, January first.
  final List<int> totals;

  /// 1 to 12.
  final int currentMonth;
  final Currency currency;

  /// Called with the month, 1 to 12.
  final ValueChanged<int> onMonthTap;

  @override
  Widget build(BuildContext context) {
    final tallest = totals.fold<int>(0, math.max);
    final yearTotal = totals.fold<int>(0, (a, b) => a + b);

    return Card(
      child: Padding(
        padding: AppSpacing.card,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // The year's total shrinks to fit, so a large text size or a big sum
            // never overflows the row.
            AmountRow(
              leading: Semantics(
                header: true,
                child: Text(
                  'Spending in $year',
                  style: context.text.titleMedium,
                ),
              ),
              amount: currency.format(yearTotal),
              amountStyle: context.text.bodySmall,
            ),
            const Gap(AppSpacing.md),
            SizedBox(
              height: barArea + 32,
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.end,
                children: [
                  for (var i = 0; i < 12; i++)
                    Expanded(
                      child: _Bar(
                        label: _letters[i],
                        semantics:
                            '${_names[i]}: ${currency.format(totals[i])}',
                        fraction: tallest == 0 ? 0 : totals[i] / tallest,
                        current: i + 1 == currentMonth,
                        future: i + 1 > currentMonth,
                        onTap: () => onMonthTap(i + 1),
                      ),
                    ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _Bar extends StatelessWidget {
  const _Bar({
    required this.label,
    required this.semantics,
    required this.fraction,
    required this.current,
    required this.future,
    required this.onTap,
  });

  final String label;
  final String semantics;
  final double fraction;
  final bool current;
  final bool future;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final color = context.scheme.primary;
    // Always a sliver, so an empty month still shows where it is.
    final height = math.max(fraction * YearChart.barArea, 3.0);
    return Semantics(
      button: true,
      label: semantics,
      excludeSemantics: true,
      child: InkWell(
        onTap: future ? null : onTap,
        child: Column(
          mainAxisAlignment: MainAxisAlignment.end,
          children: [
            Container(
              width: 14,
              height: height,
              decoration: BoxDecoration(
                color: future
                    ? context.scheme.outline.withValues(alpha: 0.4)
                    : current
                    ? color
                    : color.withValues(alpha: 0.35),
                borderRadius: BorderRadius.circular(4),
              ),
            ),
            const Gap(AppSpacing.xs),
            // The month letters are tiny labels, so they grow with the phone's
            // font size only a little. Otherwise twelve of them would not fit
            // side by side, and the chart would need more room than it has.
            MediaQuery.withClampedTextScaling(
              maxScaleFactor: 1.2,
              child: Text(
                label,
                style: context.text.bodySmall?.copyWith(
                  fontWeight: current ? FontWeight.w700 : null,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
