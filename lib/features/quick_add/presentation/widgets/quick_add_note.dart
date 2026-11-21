import 'package:flutter/material.dart';

import '../../../../core/theme/app_spacing.dart';
import '../../../../core/theme/theme_x.dart';

/// Shown above the expense form after a typed line: what was typed, and a
/// reminder to check what was understood.
class QuickAddNote extends StatelessWidget {
  const QuickAddNote({super.key, required this.heading, required this.text});

  final String heading;
  final String text;

  @override
  Widget build(BuildContext context) {
    return Card(
      child: Padding(
        padding: AppSpacing.card,
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Icon(Icons.bolt),
            const SizedBox(width: AppSpacing.md),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(heading, style: context.text.titleSmall),
                  const Gap(AppSpacing.xs),
                  Text('"$text"', style: context.text.bodyMedium),
                  const Gap(AppSpacing.xs),
                  Text(
                    'Check the details below before you save.',
                    style: context.text.bodySmall,
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
