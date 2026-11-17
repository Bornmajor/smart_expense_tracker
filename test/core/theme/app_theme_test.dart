import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:smart_expense_tracker/core/theme/app_colors.dart';
import 'package:smart_expense_tracker/core/theme/app_semantic_colors.dart';
import 'package:smart_expense_tracker/core/theme/app_spacing.dart';
import 'package:smart_expense_tracker/core/theme/app_theme.dart';
import 'package:smart_expense_tracker/core/theme/theme_x.dart';

void main() {
  group('AppTheme', () {
    test('light theme uses black as the primary color', () {
      final theme = AppTheme.light;

      expect(theme.colorScheme.brightness, Brightness.light);
      expect(theme.colorScheme.primary, AppColors.black);
      expect(theme.extension<AppSemanticColors>(), AppSemanticColors.light);
    });

    test(
      'dark theme inverts the primary color and uses dark status colors',
      () {
        final theme = AppTheme.dark;

        expect(theme.colorScheme.brightness, Brightness.dark);
        expect(theme.colorScheme.primary, AppColors.white);
        expect(theme.extension<AppSemanticColors>(), AppSemanticColors.dark);
      },
    );

    test('text fields are filled with the shared corner radius', () {
      final input = AppTheme.light.inputDecorationTheme;
      final border = input.border! as OutlineInputBorder;

      expect(input.filled, isTrue);
      expect(border.borderRadius, AppRadius.mdAll);
    });

    test('primary buttons are full width and 52 high', () {
      final style = AppTheme.light.filledButtonTheme.style!;

      expect(style.minimumSize!.resolve({}), const Size.fromHeight(52));
    });
  });

  group('ThemeX', () {
    testWidgets('exposes scheme, text and semantic colors from the theme', (
      tester,
    ) async {
      late BuildContext captured;
      await tester.pumpWidget(
        MaterialApp(
          theme: AppTheme.light,
          home: Builder(
            builder: (context) {
              captured = context;
              return const SizedBox.shrink();
            },
          ),
        ),
      );

      expect(captured.scheme.primary, AppColors.black);
      expect(captured.semantic.warning, AppColors.warning);
      expect(captured.text.headlineMedium?.fontSize, 28);
    });
  });
}
