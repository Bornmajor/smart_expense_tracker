import 'dart:math' as math;

import 'package:flutter/material.dart';

import '../../../../core/theme/app_spacing.dart';
import '../../../../core/theme/theme_x.dart';
import '../../../../core/utils/currency.dart';
import '../../../../shared/widgets/amount_row.dart';
import '../../domain/entities/budget_progress.dart';

/// One budget: what was spent, a bar, and, in bold, what is left of the limit.
/// The bar and the amount turn amber near the limit and red once it is passed.
class BudgetProgressTile extends StatelessWidget {
  const BudgetProgressTile({
    super.key,
    required this.name,
    required this.progress,
    required this.currency,
    this.onTap,
  });

  final String name;
  final BudgetProgress progress;
  final Currency currency;

  /// Opens the expenses behind this budget.
  final VoidCallback? onTap;

  Color _color(BuildContext context) => switch (progress.level) {
    BudgetLevel.onTrack => context.scheme.primary,
    BudgetLevel.near => context.semantic.warning,
    BudgetLevel.over => context.semantic.danger,
  };

  /// "KSh 28,946 left" or "KSh 1,510 over".
  String _answer() {
    final remaining = progress.remainingMinor;
    return remaining >= 0
        ? '${currency.formatGlance(remaining)} left'
        : '${currency.formatGlance(-remaining)} over';
  }

  @override
  Widget build(BuildContext context) {
    final color = _color(context);
    final over = progress.level == BudgetLevel.over;
    final percent = (progress.fraction * 100).round();
    final limit = currency.formatGlance(progress.limitMinor);

    return Semantics(
      label: over
          ? '$name budget, ${_answer()}'
          : '$name budget, $percent percent used, ${_answer()}',
      excludeSemantics: true,
      child: Card(
        clipBehavior: Clip.antiAlias,
        child: InkWell(
          onTap: onTap,
          child: Padding(
            padding: AppSpacing.card,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                AmountRow(
                  leading: Text(name, style: context.text.titleMedium),
                  amount: '${currency.formatGlance(progress.spentMinor)} spent',
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
                    // The answer is the bold part; the limit is context.
                    Expanded(
                      child: Text.rich(
                        TextSpan(
                          children: [
                            TextSpan(
                              text: _answer(),
                              style: context.text.titleSmall?.copyWith(
                                color: progress.level == BudgetLevel.onTrack
                                    ? null
                                    : color,
                              ),
                            ),
                            TextSpan(
                              text: over ? ' · budget $limit' : ' of $limit',
                              style: context.text.bodySmall,
                            ),
                          ],
                        ),
                      ),
                    ),
                    // Past the limit the amount over says it all; a figure such
                    // as 251% is harder to read than "KSh 1,510 over".
                    if (!over)
                      Text('$percent% used', style: context.text.bodySmall),
                  ],
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
