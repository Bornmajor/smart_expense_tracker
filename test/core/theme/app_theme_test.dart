import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:smart_expense_tracker/core/theme/app_colors.dart';
import 'package:smart_expense_tracker/core/theme/app_semantic_colors.dart';
import 'package:smart_expense_tracker/core/theme/app_spacing.dart';
import 'package:smart_expense_tracker/core/theme/app_theme.dart';
import 'package:smart_expense_tracker/core/theme/theme_x.dart';
import 'package:smart_expense_tracker/core/utils/color_contrast.dart';

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

    test('an empty field is visible against the screen in light mode', () {
      // The fill matches the screen color, so the border has to show it.
      final theme = AppTheme.light;
      final border = theme.inputDecorationTheme.enabledBorder!.borderSide;

      expect(border.style, BorderStyle.solid);
      expect(
        contrastRatio(border.color, theme.scaffoldBackgroundColor),
        greaterThanOrEqualTo(3),
      );
      expect(
        contrastRatio(border.color, theme.inputDecorationTheme.fillColor!),
        greaterThanOrEqualTo(3),
      );
    });

    test('the focused border is stronger than the resting one', () {
      final input = AppTheme.light.inputDecorationTheme;

      expect(
        input.focusedBorder!.borderSide.width,
        greaterThan(input.enabledBorder!.borderSide.width),
      );
    });

    test('dark fields stand out by their fill, with no border', () {
      final theme = AppTheme.dark;

      expect(
        theme.inputDecorationTheme.enabledBorder!.borderSide,
        BorderSide.none,
      );
      expect(
        theme.inputDecorationTheme.fillColor,
        isNot(theme.scaffoldBackgroundColor),
      );
    });

    test('primary buttons are full width and 52 high', () {
      final style = AppTheme.light.filledButtonTheme.style!;

      expect(style.minimumSize!.resolve({}), const Size.fromHeight(52));
    });
  });

  group('navigation bar contrast', () {
    test('the selected icon stands out from its indicator in both themes', () {
      for (final theme in [AppTheme.light, AppTheme.dark]) {
        final nav = theme.navigationBarTheme;
        final selected = nav.iconTheme!.resolve({WidgetState.selected})!.color!;

        expect(
          contrastRatio(selected, nav.indicatorColor!),
          greaterThanOrEqualTo(4.5),
          reason: '${theme.brightness} selected icon on indicator',
        );
      }
    });

    test('unselected icons are readable on the bar in both themes', () {
      for (final theme in [AppTheme.light, AppTheme.dark]) {
        final nav = theme.navigationBarTheme;
        final unselected = nav.iconTheme!.resolve({})!.color!;

        expect(
          contrastRatio(unselected, nav.backgroundColor!),
          greaterThanOrEqualTo(4.5),
          reason: '${theme.brightness} unselected icon on bar',
        );
      }
    });

    test('the selected icon keeps the on-primary color', () {
      for (final theme in [AppTheme.light, AppTheme.dark]) {
        final selected = theme.navigationBarTheme.iconTheme!.resolve({
          WidgetState.selected,
        })!.color;

        expect(selected, theme.colorScheme.onPrimary);
      }
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
