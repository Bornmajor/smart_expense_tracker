import 'package:flutter/material.dart';

import '../../../../core/theme/app_spacing.dart';
import '../../../../core/theme/theme_x.dart';
import '../../../../core/utils/currency.dart';
import '../../domain/entities/month_comparison.dart';
import '../comparison_messages.dart';

/// How this month compares with the same stretch of last month, in a few words:
/// the amount so far, more or less than last month, and what changed most.
class MonthComparisonCard extends StatelessWidget {
  const MonthComparisonCard({
    super.key,
    required this.comparison,
    required this.currency,
    this.biggestChangeName,
  });

  final MonthComparison comparison;
  final Currency currency;

  /// The name of the category that changed most, if there is one.
  final String? biggestChangeName;

  @override
  Widget build(BuildContext context) {
    final text = comparisonText(comparison, biggestChangeName, currency);
    // Spending going up is the one to notice, so it is the warm color.
    final icon = comparison.aboutTheSame
        ? (Icons.trending_flat, context.scheme.onSurfaceVariant)
        : comparison.deltaMinor > 0
        ? (Icons.trending_up, context.semantic.warning)
        : (Icons.trending_down, context.semantic.success);

    return Semantics(
      container: true,
      label:
          'Compared with last month. ${text.headline}. ${text.detail}.'
          '${text.biggest == null ? '' : ' ${text.biggest}.'}',
      excludeSemantics: true,
      child: Card(
        child: Padding(
          padding: AppSpacing.card,
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Icon(icon.$1, color: icon.$2),
              const SizedBox(width: AppSpacing.md),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Compared with last month',
                      style: context.text.bodySmall,
                    ),
                    const Gap(AppSpacing.xs),
                    Text(text.headline, style: context.text.titleMedium),
                    const Gap(AppSpacing.xs),
                    Text(text.detail, style: context.text.bodyMedium),
                    if (text.biggest != null) ...[
                      const Gap(AppSpacing.xs),
                      Text(text.biggest!, style: context.text.bodySmall),
                    ],
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
