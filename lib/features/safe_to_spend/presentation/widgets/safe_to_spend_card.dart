import 'package:flutter/material.dart';

import '../../../../core/theme/app_spacing.dart';
import '../../../../core/theme/theme_x.dart';
import '../../../../core/utils/currency.dart';
import '../../domain/entities/safe_to_spend.dart';

/// The answer to "how much can I spend?": an amount a day for the rest of the
/// month, with the sum behind it. Turns red when the budget is already spoken
/// for.
class SafeToSpendCard extends StatelessWidget {
  const SafeToSpendCard({
    super.key,
    required this.safeToSpend,
    required this.currency,
  });

  final SafeToSpend safeToSpend;
  final Currency currency;

  String get _daysText => safeToSpend.daysLeft == 1
      ? 'last day of the month'
      : '${safeToSpend.daysLeft} days to go';

  @override
  Widget build(BuildContext context) {
    final item = safeToSpend;
    final over = item.isOver;
    final color = over ? context.semantic.danger : null;

    final headline = over
        ? '${currency.formatGlance(-item.remainingMinor)} over'
        : '${currency.formatGlance(item.perDayMinor)} a day';
    final subtitle = over
        ? 'Your budget is already spoken for this month'
        : '${currency.formatGlance(item.remainingMinor)} left · $_daysText';
    final bills = item.upcomingMinor > 0
        ? 'After ${currency.formatGlance(item.upcomingMinor)} of bills still to come'
        : null;

    return Semantics(
      label:
          'Safe to spend. $headline. $subtitle.${bills == null ? '' : ' $bills.'}',
      excludeSemantics: true,
      child: Card(
        child: Padding(
          padding: AppSpacing.card,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                over ? 'Over budget' : 'Safe to spend',
                style: context.text.bodyMedium,
              ),
              const Gap(AppSpacing.xs),
              // One line that shrinks to fit, so a big sum or a large text
              // size never wraps or overflows.
              FittedBox(
                fit: BoxFit.scaleDown,
                alignment: Alignment.centerLeft,
                child: Text(
                  headline,
                  maxLines: 1,
                  softWrap: false,
                  style: context.text.headlineMedium?.copyWith(color: color),
                ),
              ),
              const Gap(AppSpacing.xs),
              Text(subtitle, style: context.text.bodyMedium),
              if (bills != null) ...[
                const Gap(AppSpacing.xs),
                Text(bills, style: context.text.bodySmall),
              ],
            ],
          ),
        ),
      ),
    );
  }
}
