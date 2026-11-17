import 'dart:ui';

import 'package:flutter_test/flutter_test.dart';
import 'package:smart_expense_tracker/core/theme/app_semantic_colors.dart';

void main() {
  group('AppSemanticColors', () {
    const base = AppSemanticColors(
      success: Color(0xFF00FF00),
      warning: Color(0xFFFFFF00),
      danger: Color(0xFFFF0000),
    );

    test('copyWith replaces only the given colors', () {
      final copy = base.copyWith(danger: const Color(0xFF000000));

      expect(copy.danger, const Color(0xFF000000));
      expect(copy.success, base.success);
      expect(copy.warning, base.warning);
    });

    test('lerp blends each color between the two extensions', () {
      const other = AppSemanticColors(
        success: Color(0xFF000000),
        warning: Color(0xFF000000),
        danger: Color(0xFF000000),
      );

      expect(base.lerp(other, 0).success, base.success);
      expect(base.lerp(other, 1).success, other.success);
      expect(
        base.lerp(other, 0.5).danger,
        Color.lerp(base.danger, other.danger, 0.5),
      );
    });

    test('lerp returns itself when the other extension is null', () {
      expect(base.lerp(null, 0.5), same(base));
    });

    test('light and dark variants differ so status colors stay readable', () {
      expect(
        AppSemanticColors.light.success,
        isNot(AppSemanticColors.dark.success),
      );
    });
  });
}
