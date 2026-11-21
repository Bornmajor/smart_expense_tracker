import 'package:flutter/material.dart';

import '../../../../core/theme/app_spacing.dart';
import '../../../../core/theme/theme_x.dart';
import '../../../../core/utils/currency.dart';
import '../../domain/entities/insight_alert.dart';
import '../alert_messages.dart';

/// "Heads up" cards at the top of the Summary. Each can be closed.
class AlertsSection extends StatelessWidget {
  const AlertsSection({
    super.key,
    required this.alerts,
    required this.categoryNames,
    required this.currency,
    required this.onDismiss,
  });

  final List<InsightAlert> alerts;

  /// Category id -> name.
  final Map<String, String> categoryNames;
  final Currency currency;
  final ValueChanged<String> onDismiss;

  @override
  Widget build(BuildContext context) {
    if (alerts.isEmpty) return const SizedBox.shrink();
    return Column(
      children: [
        for (final alert in alerts) ...[
          _AlertCard(
            alert: alert,
            text: alertText(
              alert,
              categoryNames[alert.categoryId] ?? 'Uncategorized',
              currency,
            ),
            onDismiss: () => onDismiss(alert.id),
          ),
          const Gap(AppSpacing.sm),
        ],
        const Gap(AppSpacing.md),
      ],
    );
  }
}

class _AlertCard extends StatelessWidget {
  const _AlertCard({
    required this.alert,
    required this.text,
    required this.onDismiss,
  });

  final InsightAlert alert;
  final ({String title, String message}) text;
  final VoidCallback onDismiss;

  @override
  Widget build(BuildContext context) {
    return Semantics(
      container: true,
      label: '${text.title}. ${text.message}',
      child: Card(
        child: Padding(
          padding: AppSpacing.card,
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Icon(Icons.lightbulb_outline, color: context.semantic.warning),
              const SizedBox(width: AppSpacing.md),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(text.title, style: context.text.titleMedium),
                    const Gap(AppSpacing.xs),
                    Text(text.message, style: context.text.bodyMedium),
                  ],
                ),
              ),
              IconButton(
                tooltip: 'Dismiss',
                icon: const Icon(Icons.close),
                onPressed: onDismiss,
              ),
            ],
          ),
        ),
      ),
    );
  }
}
