import 'package:flutter/material.dart';

import '../../../../core/theme/app_spacing.dart';
import '../../../../core/theme/theme_x.dart';
import '../../../../core/utils/money.dart';

/// One category row: name, amount, and a bar showing its share of the month.
class CategoryBreakdownTile extends StatelessWidget {
  const CategoryBreakdownTile({
    super.key,
    required this.name,
    required this.totalMinor,
    required this.share,
  });

  final String name;
  final int totalMinor;

  /// Fraction of the month's total, from 0 to 1.
  final double share;

  @override
  Widget build(BuildContext context) {
    return Card(
      child: Padding(
        padding: AppSpacing.card,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Expanded(child: Text(name, style: context.text.titleMedium)),
                Text(Money.format(totalMinor), style: context.text.titleMedium),
              ],
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
              ],
            ),
          ],
        ),
      ),
    );
  }
}
