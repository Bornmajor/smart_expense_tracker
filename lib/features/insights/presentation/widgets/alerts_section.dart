import 'package:flutter/material.dart';

import '../../../../core/theme/app_spacing.dart';
import '../../../../core/theme/theme_x.dart';
import '../../../../core/utils/currency.dart';
import '../../domain/entities/insight_alert.dart';
import '../alert_messages.dart';

/// "Heads up" cards at the top of the Summary and Home. Each can be closed.
class AlertsSection extends StatelessWidget {
  const AlertsSection({
    super.key,
    required this.alerts,
    required this.categoryNames,
    required this.currency,
    required this.onDismiss,
    this.onAction,
  });

  final List<InsightAlert> alerts;

  /// Category id -> name.
  final Map<String, String> categoryNames;
  final Currency currency;
  final ValueChanged<String> onDismiss;

  /// Called when the user taps the action on a card that has one, such as "Set
  /// a budget". Without it such a card has no button.
  final ValueChanged<InsightAlert>? onAction;

  @override
  Widget build(BuildContext context) {
    if (alerts.isEmpty) return const SizedBox.shrink();
    final action = onAction;
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
            actionLabel: alert.kind == AlertKind.noBudget && action != null
                ? 'Set a budget'
                : null,
            onAction: action == null ? null : () => action(alert),
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
    this.actionLabel,
    this.onAction,
  });

  final InsightAlert alert;
  final ({String title, String message}) text;
  final VoidCallback onDismiss;

  /// The label of a button under the message, or null for none.
  final String? actionLabel;
  final VoidCallback? onAction;

  @override
  Widget build(BuildContext context) {
    final label = actionLabel;
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
                    if (label != null && onAction != null)
                      TextButton(
                        style: TextButton.styleFrom(
                          padding: EdgeInsets.zero,
                          minimumSize: const Size(0, 36),
                          alignment: Alignment.centerLeft,
                        ),
                        onPressed: onAction,
                        child: Text(label),
                      ),
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
