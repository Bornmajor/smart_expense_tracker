import 'dart:math' as math;

import 'package:flutter/material.dart';

import '../../../../core/theme/app_spacing.dart';
import '../../../../core/theme/theme_x.dart';
import '../../../../core/utils/currency.dart';
import '../../../budgets/domain/entities/budget.dart';
import '../../../budgets/domain/entities/budget_progress.dart';
import '../../../safe_to_spend/domain/entities/safe_to_spend.dart';

/// The first thing on the home screen: how this month is going. With an overall
/// budget it shows what was spent, how much is left, and what is safe to spend
/// each day. Without one it shows what was spent and invites the user to set a
/// budget.
class MoneyCard extends StatelessWidget {
  const MoneyCard({
    super.key,
    required this.spentMinor,
    required this.currency,
    required this.onOpen,
    required this.onSetBudget,
    this.budget,
    this.safeToSpend,
  });

  final int spentMinor;
  final Currency currency;
  final Budget? budget;
  final SafeToSpend? safeToSpend;

  /// Opens the month in detail.
  final VoidCallback onOpen;

  /// Opens the screen where a budget is set.
  final VoidCallback onSetBudget;

  Color _barColor(BuildContext context, BudgetLevel level) => switch (level) {
    BudgetLevel.onTrack => context.scheme.primary,
    BudgetLevel.near => context.semantic.warning,
    BudgetLevel.over => context.semantic.danger,
  };

  @override
  Widget build(BuildContext context) {
    final overall = budget;
    return Card(
      clipBehavior: Clip.antiAlias,
      child: InkWell(
        onTap: onOpen,
        child: Padding(
          padding: const EdgeInsets.all(AppSpacing.xl),
          child: overall == null
              ? _withoutBudget(context)
              : _withBudget(context, overall),
        ),
      ),
    );
  }

  Widget _withoutBudget(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text('Spent this month', style: context.text.bodyMedium),
        const Gap(AppSpacing.xs),
        _amount(context, currency.format(spentMinor)),
        const Gap(AppSpacing.md),
        Text(
          'Set a monthly budget to see how much you have left, and what is '
          'safe to spend each day.',
          style: context.text.bodySmall,
        ),
        const Gap(AppSpacing.sm),
        TextButton(
          onPressed: onSetBudget,
          child: const Text('Set a monthly budget'),
        ),
      ],
    );
  }

  Widget _withBudget(BuildContext context, Budget overall) {
    final progress = BudgetProgress(budget: overall, spentMinor: spentMinor);
    final safe = safeToSpend;
    final over = progress.level == BudgetLevel.over;
    final color = _barColor(context, progress.level);

    final line = safe == null
        ? null
        : safe.isOver
        ? 'The rest of the month is already spoken for'
        : '${currency.format(safe.perDayMinor)} a day · '
              '${safe.daysLeft == 1 ? 'last day' : '${safe.daysLeft} days to go'}';

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text('This month', style: context.text.bodyMedium),
        const Gap(AppSpacing.xs),
        _amount(context, currency.format(spentMinor)),
        const Gap(AppSpacing.xs),
        Text(
          'of ${currency.format(overall.limitMinor)} budget',
          style: context.text.bodyMedium,
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
        Text(
          over
              ? '${currency.format(-progress.remainingMinor)} over'
              : '${currency.format(progress.remainingMinor)} left',
          style: context.text.titleSmall?.copyWith(color: over ? color : null),
        ),
        if (line != null) ...[
          const Gap(AppSpacing.xs),
          Text(line, style: context.text.bodySmall),
        ],
      ],
    );
  }

  /// One line that shrinks to fit, so a big sum or a large text size never
  /// wraps or overflows.
  Widget _amount(BuildContext context, String text) => FittedBox(
    fit: BoxFit.scaleDown,
    alignment: Alignment.centerLeft,
    child: Text(
      text,
      maxLines: 1,
      softWrap: false,
      style: context.text.headlineMedium,
    ),
  );
}
