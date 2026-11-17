import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:smart_expense_tracker/core/theme/app_theme.dart';
import 'package:smart_expense_tracker/features/onboarding/presentation/widgets/step_progress_bar.dart';

void main() {
  testWidgets('fills the segments up to the current step', (tester) async {
    final handle = tester.ensureSemantics();
    await tester.pumpWidget(
      MaterialApp(
        theme: AppTheme.light,
        home: const Scaffold(body: StepProgressBar(count: 3, current: 1)),
      ),
    );

    final colors = tester
        .widgetList<AnimatedContainer>(find.byType(AnimatedContainer))
        .map((c) => (c.decoration! as BoxDecoration).color)
        .toList();
    final scheme = AppTheme.light.colorScheme;

    expect(colors, [
      scheme.primary,
      scheme.primary,
      scheme.onSurface.withValues(alpha: 0.15),
    ]);
    expect(find.bySemanticsLabel('Step 2 of 3'), findsOneWidget);
    handle.dispose();
  });

  testWidgets('uses the colors it is given', (tester) async {
    await tester.pumpWidget(
      MaterialApp(
        theme: AppTheme.light,
        home: const Scaffold(
          body: StepProgressBar(
            count: 2,
            current: 0,
            activeColor: Colors.black,
            inactiveColor: Colors.white,
          ),
        ),
      ),
    );

    final colors = tester
        .widgetList<AnimatedContainer>(find.byType(AnimatedContainer))
        .map((c) => (c.decoration! as BoxDecoration).color)
        .toList();

    expect(colors, [Colors.black, Colors.white]);
  });
}
