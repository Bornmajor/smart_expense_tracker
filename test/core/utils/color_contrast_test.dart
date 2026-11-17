import 'dart:ui';

import 'package:flutter_test/flutter_test.dart';
import 'package:smart_expense_tracker/core/theme/app_colors.dart';
import 'package:smart_expense_tracker/core/utils/color_contrast.dart';

void main() {
  group('contrastRatio', () {
    test('is 1 for the same color', () {
      expect(contrastRatio(AppColors.grey400, AppColors.grey400), 1);
    });

    test('is 21 for pure black on pure white, in either order', () {
      const black = Color(0xFF000000);
      const white = Color(0xFFFFFFFF);

      expect(contrastRatio(black, white), closeTo(21, 0.01));
      expect(contrastRatio(white, black), closeTo(21, 0.01));
    });
  });

  group('readableOn', () {
    test('picks black on light backgrounds and white on dark ones', () {
      expect(readableOn(AppColors.white), AppColors.black);
      expect(readableOn(AppColors.black), AppColors.white);
    });

    test('picks the better color for the status colors', () {
      expect(readableOn(AppColors.success), AppColors.black);
      expect(readableOn(AppColors.warning), AppColors.black);
      expect(readableOn(AppColors.danger), AppColors.white);
    });

    test('always reaches the 4.5 minimum on the status colors', () {
      for (final color in [
        AppColors.success,
        AppColors.warning,
        AppColors.danger,
        const Color(0xFF34D27B),
        const Color(0xFFFBBF24),
        const Color(0xFFF87171),
      ]) {
        expect(
          contrastRatio(color, readableOn(color)),
          greaterThanOrEqualTo(4.5),
          reason: 'color $color',
        );
      }
    });
  });
}
