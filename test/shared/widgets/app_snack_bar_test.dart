import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:smart_expense_tracker/core/theme/app_semantic_colors.dart';
import 'package:smart_expense_tracker/core/theme/app_theme.dart';
import 'package:smart_expense_tracker/core/utils/color_contrast.dart';
import 'package:smart_expense_tracker/shared/widgets/app_snack_bar.dart';

void main() {
  late BuildContext context;

  Future<void> pumpHost(WidgetTester tester, ThemeData theme) async {
    await tester.pumpWidget(
      MaterialApp(
        theme: theme,
        home: Scaffold(
          body: Builder(
            builder: (c) {
              context = c;
              return const SizedBox.shrink();
            },
          ),
        ),
      ),
    );
  }

  Future<void> show(WidgetTester tester, void Function() action) async {
    action();
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 750));
  }

  SnackBar snackBar(WidgetTester tester) =>
      tester.widget<SnackBar>(find.byType(SnackBar));

  IconData icon(WidgetTester tester) => tester
      .widget<Icon>(
        find.descendant(of: find.byType(SnackBar), matching: find.byType(Icon)),
      )
      .icon!;

  Color? textColor(WidgetTester tester, String message) =>
      tester.widget<Text>(find.text(message)).style?.color;

  for (final theme in [AppTheme.light, AppTheme.dark]) {
    final semantic = theme.extension<AppSemanticColors>()!;
    final scheme = theme.colorScheme;

    group('snackbars in ${theme.brightness} mode', () {
      testWidgets('success uses the success color and a check icon', (
        tester,
      ) async {
        await pumpHost(tester, theme);
        await show(tester, () => context.showSuccess('Saved'));

        expect(snackBar(tester).backgroundColor, semantic.success);
        expect(icon(tester), Icons.check_circle_outline);
        expect(find.text('Saved'), findsOneWidget);
      });

      testWidgets('warning uses the warning color and a warning icon', (
        tester,
      ) async {
        await pumpHost(tester, theme);
        await show(tester, () => context.showWarning('Careful'));

        expect(snackBar(tester).backgroundColor, semantic.warning);
        expect(icon(tester), Icons.warning_amber_rounded);
      });

      testWidgets('error uses the danger color and an error icon', (
        tester,
      ) async {
        await pumpHost(tester, theme);
        await show(tester, () => context.showError('Failed'));

        expect(snackBar(tester).backgroundColor, semantic.danger);
        expect(icon(tester), Icons.error_outline);
      });

      testWidgets('info is neutral with an info icon', (tester) async {
        await pumpHost(tester, theme);
        await show(tester, () => context.showInfo('FYI'));

        expect(snackBar(tester).backgroundColor, scheme.onSurface);
        expect(icon(tester), Icons.info_outline);
      });

      testWidgets('the text is readable on every kind (4.5:1 or better)', (
        tester,
      ) async {
        await pumpHost(tester, theme);
        final actions = <String, void Function()>{
          'ok': () => context.showSuccess('ok'),
          'warn': () => context.showWarning('warn'),
          'err': () => context.showError('err'),
          'info': () => context.showInfo('info'),
        };

        for (final entry in actions.entries) {
          await show(tester, entry.value);
          final background = snackBar(tester).backgroundColor!;
          final text = textColor(tester, entry.key)!;

          expect(
            contrastRatio(text, background),
            greaterThanOrEqualTo(4.5),
            reason: '${entry.key} in ${theme.brightness} mode',
          );
        }
      });

      testWidgets('a new message replaces the one on screen', (tester) async {
        await pumpHost(tester, theme);

        await show(tester, () => context.showSuccess('First'));
        await show(tester, () => context.showError('Second'));
        await tester.pumpAndSettle();

        expect(find.text('First'), findsNothing);
        expect(find.text('Second'), findsOneWidget);
      });
    });
  }
}
