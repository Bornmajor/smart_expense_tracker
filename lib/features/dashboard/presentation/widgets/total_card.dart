import 'package:flutter/material.dart';

import '../../../../core/theme/app_spacing.dart';
import '../../../../core/theme/theme_x.dart';
import '../../../../core/utils/money.dart';

/// Highlighted card with the month's total.
class TotalCard extends StatelessWidget {
  const TotalCard({super.key, required this.totalMinor, required this.count});

  final int totalMinor;
  final int count;

  @override
  Widget build(BuildContext context) {
    final onPrimary = context.scheme.onPrimary;
    return Card(
      color: context.scheme.primary,
      child: Padding(
        padding: const EdgeInsets.all(AppSpacing.xl),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Total spent',
              style: context.text.bodyMedium?.copyWith(
                color: onPrimary.withValues(alpha: 0.7),
              ),
            ),
            const Gap(AppSpacing.sm),
            Text(
              Money.format(totalMinor),
              style: context.text.headlineMedium?.copyWith(
                color: onPrimary,
                fontSize: 34,
              ),
            ),
            const Gap(AppSpacing.xs),
            Text(
              count == 1 ? '1 expense' : '$count expenses',
              style: context.text.bodySmall?.copyWith(
                color: onPrimary.withValues(alpha: 0.7),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
