import 'dart:math' as math;

import 'package:flutter/material.dart';

import '../../../../core/theme/app_spacing.dart';
import '../../../../core/theme/theme_x.dart';
import '../../../../core/utils/currency.dart';
import '../../../../shared/widgets/amount_row.dart';
import '../../domain/entities/budget_progress.dart';

/// One budget on the Summary: what was spent of the limit, a bar, and what is
/// left. The bar turns amber near the limit and red once it is passed.
class BudgetProgressTile extends StatelessWidget {
  const BudgetProgressTile({
    super.key,
    required this.name,
    required this.progress,
    required this.currency,
  });

  final String name;
  final BudgetProgress progress;
  final Currency currency;

  Color _color(BuildContext context) => switch (progress.level) {
    BudgetLevel.onTrack => context.scheme.primary,
    BudgetLevel.near => context.semantic.warning,
    BudgetLevel.over => context.semantic.danger,
  };

  String _caption() {
    final remaining = progress.remainingMinor;
    return remaining >= 0
        ? '${currency.format(remaining)} left'
        : '${currency.format(-remaining)} over';
  }

  @override
  Widget build(BuildContext context) {
    final color = _color(context);
    final percent = (progress.fraction * 100).round();
    return Semantics(
      label: progress.level == BudgetLevel.over
          ? '$name budget, over by ${currency.format(-progress.remainingMinor)}'
          : '$name budget, $percent percent used, ${_caption()}',
      excludeSemantics: true,
      child: Card(
        child: Padding(
          padding: AppSpacing.card,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              AmountRow(
                leading: Text(name, style: context.text.titleMedium),
                amount:
                    '${currency.format(progress.spentMinor)} of '
                    '${currency.format(progress.limitMinor)}',
                amountStyle: context.text.bodyMedium,
              ),
              const Gap(AppSpacing.md),
              ClipRRect(
                borderRadius: BorderRadius.circular(4),
                child: LinearProgressIndicator(
                  value: math.min(progress.fraction, 1),
                  minHeight: 8,
                  color: color,
                  backgroundColor: context.scheme.outline,
                ),
              ),
              const Gap(AppSpacing.sm),
              Row(
                children: [
                  Expanded(
                    child: Text(
                      _caption(),
                      style: context.text.bodySmall?.copyWith(
                        color: progress.level == BudgetLevel.onTrack
                            ? null
                            : color,
                        fontWeight: progress.level == BudgetLevel.onTrack
                            ? null
                            : FontWeight.w600,
                      ),
                    ),
                  ),
                  // Past the limit the amount over says it all; a figure such as
                  // 251% is harder to read than "KSh 1,510 over".
                  if (progress.level != BudgetLevel.over)
                    Text('$percent%', style: context.text.bodySmall),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}
