// coverage:ignore-file
import 'package:flutter/material.dart';

import '../core/theme/app_spacing.dart';
import '../core/theme/theme_x.dart';

/// Temporary screen to check the theme (fields, buttons, card, status colors).
/// Delete once real screens exist.
class ThemePreviewScreen extends StatelessWidget {
  const ThemePreviewScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Theme preview')),
      body: SingleChildScrollView(
        padding: AppSpacing.screen,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('Add expense', style: context.text.headlineMedium),
            const Gap(AppSpacing.xl),
            const TextField(decoration: InputDecoration(labelText: 'Vendor')),
            const Gap(AppSpacing.md),
            const TextField(
              keyboardType: TextInputType.numberWithOptions(decimal: true),
              decoration: InputDecoration(labelText: 'Total'),
            ),
            const Gap(AppSpacing.xl),
            Card(
              child: Padding(
                padding: AppSpacing.card,
                child: Row(
                  children: [
                    Icon(
                      Icons.warning_amber_rounded,
                      color: context.semantic.warning,
                    ),
                    const Gap(AppSpacing.sm),
                    Text(
                      '80% of Food budget used',
                      style: context.text.bodyMedium,
                    ),
                  ],
                ),
              ),
            ),
            const Gap(AppSpacing.xl),
            FilledButton(onPressed: () {}, child: const Text('Save expense')),
            const Gap(AppSpacing.md),
            OutlinedButton(onPressed: () {}, child: const Text('Cancel')),
          ],
        ),
      ),
    );
  }
}
