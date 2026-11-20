import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:smart_expense_tracker/core/theme/app_theme.dart';
import 'package:smart_expense_tracker/features/export/domain/entities/export_format.dart';
import 'package:smart_expense_tracker/features/export/presentation/widgets/export_sheet.dart';

void main() {
  ExportFormat? chosen;

  Future<void> openSheet(WidgetTester tester) async {
    chosen = null;
    await tester.pumpWidget(
      MaterialApp(
        theme: AppTheme.light,
        home: Builder(
          builder: (context) => Scaffold(
            body: Center(
              child: TextButton(
                onPressed: () async =>
                    chosen = await showExportSheet(context, DateTime(2026, 11)),
                child: const Text('Open'),
              ),
            ),
          ),
        ),
      ),
    );
    await tester.tap(find.text('Open'));
    await tester.pumpAndSettle();
  }

  testWidgets('names the month and offers PDF first, then CSV', (tester) async {
    await openSheet(tester);

    expect(find.text('Export November 2026'), findsOneWidget);
    final pdf = tester.getTopLeft(find.text('PDF report')).dy;
    final csv = tester.getTopLeft(find.text('CSV spreadsheet')).dy;
    expect(pdf, lessThan(csv));
  });

  testWidgets('choosing PDF returns it', (tester) async {
    await openSheet(tester);

    await tester.tap(find.text('PDF report'));
    await tester.pumpAndSettle();

    expect(chosen, ExportFormat.pdf);
  });

  testWidgets('choosing CSV returns it', (tester) async {
    await openSheet(tester);

    await tester.tap(find.text('CSV spreadsheet'));
    await tester.pumpAndSettle();

    expect(chosen, ExportFormat.csv);
  });

  testWidgets('closing the sheet chooses nothing', (tester) async {
    await openSheet(tester);

    await tester.tapAt(const Offset(10, 10));
    await tester.pumpAndSettle();

    expect(chosen, isNull);
  });

  group('on a small phone with large text and a gesture bar', () {
    testWidgets('does not overflow, and both choices can be reached', (
      tester,
    ) async {
      tester.view.physicalSize = const Size(320, 400);
      tester.view.devicePixelRatio = 1;
      const bar = FakeViewPadding(bottom: 34);
      tester.view.padding = bar;
      tester.view.viewPadding = bar;
      addTearDown(tester.view.reset);
      tester.platformDispatcher.textScaleFactorTestValue = 2.0;
      addTearDown(tester.platformDispatcher.clearAllTestValues);

      await openSheet(tester);
      final scrollable = find.descendant(
        of: find.byType(BottomSheet),
        matching: find.byType(Scrollable),
      );
      await tester.scrollUntilVisible(
        find.text('CSV spreadsheet'),
        50,
        scrollable: scrollable,
      );
      // Scroll to the very end, where the list stops above the gesture bar.
      await tester.drag(scrollable, const Offset(0, -600));
      await tester.pumpAndSettle();

      expect(find.text('CSV spreadsheet'), findsOneWidget);
      expect(tester.takeException(), isNull);

      // The last row stays above the gesture bar.
      final bottom = tester.getBottomLeft(find.text('CSV spreadsheet')).dy;
      expect(bottom, lessThanOrEqualTo(400 - 34));
    });
  });
}
