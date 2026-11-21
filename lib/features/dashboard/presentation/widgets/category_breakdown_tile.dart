import 'dart:math' as math;

import 'package:flutter/material.dart';

import '../../../../core/theme/app_spacing.dart';
import '../../../../core/theme/theme_x.dart';
import '../../../../core/utils/currency.dart';
import '../../../../shared/widgets/amount_row.dart';
import '../../../budgets/domain/entities/budget_progress.dart';

/// One category row: its name and amount for the month, and one bar.
///
/// With a budget, the bar is the budget: how much of it is used, and in bold
/// what is left. Without one, the bar is the category's share of the month's
/// spending, and says so. The two are never mixed, because a full bar of
/// "share" next to a budget line reads as "budget used up".
class CategoryBreakdownTile extends StatelessWidget {
  const CategoryBreakdownTile({
    super.key,
    required this.name,
    required this.totalMinor,
    required this.share,
    required this.currency,
    this.onTap,
    this.budget,
  });

  final String name;
  final int totalMinor;

  /// Opens the expenses behind this total.
  final VoidCallback? onTap;

  /// This category's budget measured against the month, or null when it has
  /// none.
  final BudgetProgress? budget;

  /// Fraction of the month's total, from 0 to 1.
  final double share;
  final Currency currency;

  @override
  Widget build(BuildContext context) {
    final budget = this.budget;
    return Card(
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
                amount: currency.formatGlance(totalMinor),
                amountStyle: context.text.titleMedium,
              ),
              const Gap(AppSpacing.md),
              if (budget != null)
                _BudgetBar(
                  progress: budget,
                  currency: currency,
                  chevron: onTap != null,
                )
              else
                _ShareBar(share: share, chevron: onTap != null),
            ],
          ),
        ),
      ),
    );
  }
}

/// The category's share of the month, with a label that says what it is.
class _ShareBar extends StatelessWidget {
  const _ShareBar({required this.share, required this.chevron});

  final double share;
  final bool chevron;

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Expanded(
          child: ClipRRect(
            borderRadius: BorderRadius.circular(4),
            child: LinearProgressIndicator(
              value: share,
              minHeight: 8,
              color: context.scheme.primary,
              backgroundColor: context.scheme.outline,
            ),
          ),
        ),
        const Gap(AppSpacing.md),
        Text(
          '${(share * 100).round()}% of spending',
          style: context.text.bodySmall,
        ),
        if (chevron) const Icon(Icons.chevron_right, size: 20),
      ],
    );
  }
}

/// The category's budget: a bar for how much is used, and what is left in bold.
class _BudgetBar extends StatelessWidget {
  const _BudgetBar({
    required this.progress,
    required this.currency,
    required this.chevron,
  });

  final BudgetProgress progress;
  final Currency currency;
  final bool chevron;

  @override
  Widget build(BuildContext context) {
    final color = switch (progress.level) {
      BudgetLevel.onTrack => context.scheme.primary,
      BudgetLevel.near => context.semantic.warning,
      BudgetLevel.over => context.semantic.danger,
    };
    final over = progress.level == BudgetLevel.over;
    final limit = currency.formatGlance(progress.limitMinor);
    final answer = over
        ? '${currency.formatGlance(-progress.remainingMinor)} over'
        : '${currency.formatGlance(progress.remainingMinor)} left';

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
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
              child: Text.rich(
                TextSpan(
                  children: [
                    TextSpan(
                      text: answer,
                      style: context.text.titleSmall?.copyWith(
                        color: progress.level == BudgetLevel.onTrack
                            ? null
                            : color,
                      ),
                    ),
                    TextSpan(
                      text: over ? ' · budget $limit' : ' of $limit budget',
                      style: context.text.bodySmall,
                    ),
                  ],
                ),
              ),
            ),
            if (chevron) const Icon(Icons.chevron_right, size: 20),
          ],
        ),
      ],
    );
  }
}
