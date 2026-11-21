import 'package:flutter/material.dart';

import '../../core/theme/app_spacing.dart';
import '../../core/theme/theme_x.dart';

/// Friendly placeholder for screens with nothing to show yet.
class EmptyState extends StatelessWidget {
  const EmptyState({
    super.key,
    required this.icon,
    required this.title,
    required this.message,
    this.action,
  });

  final IconData icon;
  final String title;
  final String message;

  /// Something to do about it, such as a button, shown under the message.
  final Widget? action;

  @override
  Widget build(BuildContext context) {
    // Centered when it fits, and scrolls when it does not, such as on a short
    // screen, in landscape or at large text, so nothing is ever cut off.
    return Center(
      child: SingleChildScrollView(
        padding: AppSpacing.screen,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(icon, size: 48, color: context.scheme.onSurfaceVariant),
            const Gap(AppSpacing.lg),
            Text(title, style: context.text.titleMedium),
            const Gap(AppSpacing.sm),
            Text(
              message,
              textAlign: TextAlign.center,
              style: context.text.bodyMedium,
            ),
            if (action != null) ...[const Gap(AppSpacing.lg), action!],
          ],
        ),
      ),
    );
  }
}
