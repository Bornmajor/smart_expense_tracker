import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:smart_expense_tracker/core/theme/app_theme.dart';
import 'package:smart_expense_tracker/features/settings/domain/entities/app_theme_mode.dart';
import 'package:smart_expense_tracker/features/settings/presentation/widgets/theme_mode_selector.dart';

void main() {
  Future<void> pumpSelector(
    WidgetTester tester, {
    required double width,
    double textScale = 1,
    AppThemeMode selected = AppThemeMode.system,
    ValueChanged<AppThemeMode>? onChanged,
  }) async {
    await tester.pumpWidget(
      MaterialApp(
        theme: AppTheme.light,
        home: MediaQuery(
          data: MediaQueryData(textScaler: TextScaler.linear(textScale)),
          child: Scaffold(
            body: Center(
              child: SizedBox(
                width: width,
                child: ThemeModeSelector(
                  selected: selected,
                  onChanged: onChanged ?? (_) {},
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }

  /// Each label sits on one line, so every label is the same height.
  void expectSingleLineLabels(WidgetTester tester) {
    final heights = [
      for (final label in ['System', 'Light', 'Dark'])
        tester.getSize(find.text(label)).height,
    ];
    expect(heights.toSet(), hasLength(1), reason: 'label heights: $heights');
  }

  group('ThemeModeSelector', () {
    for (final width in [248.0, 288.0, 320.0]) {
      testWidgets('keeps every label on one line at $width wide', (
        tester,
      ) async {
        await pumpSelector(tester, width: width);

        expect(tester.takeException(), isNull);
        expectSingleLineLabels(tester);
      });
    }

    testWidgets('still fits with large text', (tester) async {
      await pumpSelector(tester, width: 288, textScale: 1.6);

      expect(tester.takeException(), isNull);
      expectSingleLineLabels(tester);
    });

    testWidgets('keeps the icon next to each label', (tester) async {
      await pumpSelector(tester, width: 288);

      expect(find.byIcon(Icons.brightness_auto_outlined), findsOneWidget);
      expect(find.byIcon(Icons.light_mode_outlined), findsOneWidget);
      expect(find.byIcon(Icons.dark_mode_outlined), findsOneWidget);
    });

    testWidgets('reports the chosen theme', (tester) async {
      AppThemeMode? chosen;
      await pumpSelector(tester, width: 288, onChanged: (m) => chosen = m);

      await tester.tap(find.text('Dark'));
      await tester.pump();

      expect(chosen, AppThemeMode.dark);
    });
  });
}
