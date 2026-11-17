import 'package:flutter/widgets.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:smart_expense_tracker/core/theme/app_spacing.dart';

void main() {
  group('Gap', () {
    testWidgets('takes the requested size on both axes', (tester) async {
      await tester.pumpWidget(
        const Directionality(
          textDirection: TextDirection.ltr,
          child: Column(children: [Gap(AppSpacing.lg)]),
        ),
      );

      expect(tester.getSize(find.byType(Gap)), const Size.square(16));
    });
  });

  group('spacing scale', () {
    test('grows strictly so every step is visibly different', () {
      const scale = [
        AppSpacing.xs,
        AppSpacing.sm,
        AppSpacing.md,
        AppSpacing.lg,
        AppSpacing.xl,
        AppSpacing.xxl,
        AppSpacing.xxxl,
      ];

      for (var i = 1; i < scale.length; i++) {
        expect(scale[i], greaterThan(scale[i - 1]));
      }
    });
  });
}
