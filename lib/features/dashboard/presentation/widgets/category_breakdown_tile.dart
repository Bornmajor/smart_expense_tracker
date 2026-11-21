import 'package:flutter/material.dart';

import '../../../../core/theme/app_spacing.dart';
import '../../../../core/theme/theme_x.dart';
import '../../../../core/utils/currency.dart';
import '../../../../shared/widgets/amount_row.dart';
import '../../../budgets/domain/entities/budget_progress.dart';

/// One category row: name, amount, and a bar showing its share of the month.
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
  /// none. It adds a line to the card and nothing when absent.
  final BudgetProgress? budget;

  /// Fraction of the month's total, from 0 to 1.
  final double share;
  final Currency currency;

  @override
  Widget build(BuildContext context) {
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
                amount: currency.format(totalMinor),
                amountStyle: context.text.titleMedium,
              ),
              const Gap(AppSpacing.md),
              Row(
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
                    '${(share * 100).round()}%',
                    style: context.text.bodySmall,
                  ),
                  if (onTap != null) const Icon(Icons.chevron_right, size: 20),
                ],
              ),
              if (budget != null) ...[
                const Gap(AppSpacing.sm),
                _BudgetLine(progress: budget!, currency: currency),
              ],
            ],
          ),
        ),
      ),
    );
  }
}

/// One quiet line on a category card: how much of its budget is left, or by
/// how much it is over. It turns amber near the limit and red past it.
class _BudgetLine extends StatelessWidget {
  const _BudgetLine({required this.progress, required this.currency});

  final BudgetProgress progress;
  final Currency currency;

  @override
  Widget build(BuildContext context) {
    final color = switch (progress.level) {
      BudgetLevel.onTrack => context.text.bodySmall?.color,
      BudgetLevel.near => context.semantic.warning,
      BudgetLevel.over => context.semantic.danger,
    };
    final limit = currency.format(progress.limitMinor);
    final text = progress.level == BudgetLevel.over
        ? '${currency.format(-progress.remainingMinor)} over its $limit budget'
        : '${currency.format(progress.remainingMinor)} left of $limit';
    return Row(
      children: [
        Icon(Icons.savings_outlined, size: 14, color: color),
        const SizedBox(width: AppSpacing.xs),
        Expanded(
          child: Text(
            text,
            style: context.text.bodySmall?.copyWith(color: color),
          ),
        ),
      ],
    );
  }
}
