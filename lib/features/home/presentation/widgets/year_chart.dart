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
    this.budgetMinor,
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

  /// The overall monthly budget, drawn as a dashed line so months over it stand
  /// out. Null for no line.
  final int? budgetMinor;

  /// Room under each bar for its month letter.
  static const _labelArea = 20.0;
  static const _labelGap = 4.0;

  @override
  Widget build(BuildContext context) {
    final budget = budgetMinor;
    // The budget line has to fit on the chart, so it counts for the height.
    final tallest = math.max(totals.fold<int>(0, math.max), budget ?? 0);
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
            if (budget != null) ...[
              Row(
                children: [
                  SizedBox(
                    width: 24,
                    height: 2,
                    child: CustomPaint(
                      painter: _DashPainter(context.semantic.warning),
                    ),
                  ),
                  const SizedBox(width: AppSpacing.sm),
                  Expanded(
                    child: Text(
                      'Monthly budget ${currency.format(budget)}',
                      style: context.text.bodySmall,
                    ),
                  ),
                ],
              ),
              const Gap(AppSpacing.sm),
            ],
            SizedBox(
              height: barArea + _labelArea + _labelGap + 8,
              child: Stack(
                children: [
                  Positioned.fill(
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
                  if (budget != null && tallest > 0)
                    Positioned(
                      left: 0,
                      right: 0,
                      bottom:
                          _labelArea + _labelGap + budget / tallest * barArea,
                      height: 2,
                      child: IgnorePointer(
                        child: CustomPaint(
                          painter: _DashPainter(context.semantic.warning),
                        ),
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
            const SizedBox(height: YearChart._labelGap),
            // A fixed room for the month letter, so the budget line can be
            // placed exactly. The letters are tiny labels, so they grow with the
            // phone's font size only a little, and shrink to fit if they must.
            SizedBox(
              height: YearChart._labelArea,
              child: Center(
                child: FittedBox(
                  fit: BoxFit.scaleDown,
                  child: MediaQuery.withClampedTextScaling(
                    maxScaleFactor: 1.2,
                    child: Text(
                      label,
                      style: context.text.bodySmall?.copyWith(
                        fontWeight: current ? FontWeight.w700 : null,
                      ),
                    ),
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

/// A thin dashed line across the width it is given.
class _DashPainter extends CustomPainter {
  const _DashPainter(this.color);

  final Color color;

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = color
      ..strokeWidth = 2;
    const dash = 6.0;
    const gap = 4.0;
    for (var x = 0.0; x < size.width; x += dash + gap) {
      canvas.drawLine(
        Offset(x, size.height / 2),
        Offset(math.min(x + dash, size.width), size.height / 2),
        paint,
      );
    }
  }

  @override
  bool shouldRepaint(_DashPainter old) => old.color != color;
}
