import 'package:flutter/material.dart';

import '../../../../core/theme/app_spacing.dart';
import '../../../../core/theme/theme_x.dart';
import '../../../../core/utils/currency.dart';
import '../../../../shared/widgets/amount_row.dart';

/// One category row: name, amount, and a bar showing its share of the month.
class CategoryBreakdownTile extends StatelessWidget {
  const CategoryBreakdownTile({
    super.key,
    required this.name,
    required this.totalMinor,
    required this.share,
    required this.currency,
  });

  final String name;
  final int totalMinor;

  /// Fraction of the month's total, from 0 to 1.
  final double share;
  final Currency currency;

  @override
  Widget build(BuildContext context) {
    return Card(
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
              ],
            ),
          ],
        ),
      ),
    );
  }
}
