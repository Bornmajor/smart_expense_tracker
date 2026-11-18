import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:smart_expense_tracker/core/theme/app_theme.dart';
import 'package:smart_expense_tracker/features/expenses/presentation/widgets/add_expense_sheet.dart';
import 'package:smart_expense_tracker/features/scan/scan_features.dart';

void main() {
  AddExpenseChoice? chosen;

  /// Opens the sheet from a button. [cameraEnabled] null means the app's own
  /// setting.
  Future<void> openSheet(WidgetTester tester, {bool? cameraEnabled}) async {
    chosen = null;
    await tester.pumpWidget(
      MaterialApp(
        theme: AppTheme.light,
        home: Builder(
          builder: (context) => Scaffold(
            body: Center(
              child: TextButton(
                onPressed: () async => chosen = cameraEnabled == null
                    ? await showAddExpenseSheet(context)
                    : await showAddExpenseSheet(
                        context,
                        cameraEnabled: cameraEnabled,
                      ),
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

  group('the choices', () {
    testWidgets('are manual entry first, then a receipt photo', (tester) async {
      await openSheet(tester, cameraEnabled: false);

      final manual = tester.getTopLeft(find.text('Enter manually')).dy;
      final photo = tester.getTopLeft(find.text('Choose a receipt photo')).dy;
      expect(manual, lessThan(photo));
    });

    testWidgets('hide the camera when it is switched off', (tester) async {
      await openSheet(tester, cameraEnabled: false);

      expect(find.text('Take a photo of a receipt'), findsNothing);
    });

    testWidgets('show the camera last when it is switched on', (tester) async {
      await openSheet(tester, cameraEnabled: true);

      final photo = tester.getTopLeft(find.text('Choose a receipt photo')).dy;
      final camera = tester
          .getTopLeft(find.text('Take a photo of a receipt'))
          .dy;
      expect(photo, lessThan(camera));
    });

    testWidgets('follow the app setting when none is given', (tester) async {
      await openSheet(tester);

      expect(
        find.text('Take a photo of a receipt'),
        ScanFeatures.cameraEnabled ? findsOneWidget : findsNothing,
      );
    });
  });

  group('on a small phone with large text', () {
    testWidgets('does not overflow, and every choice can be reached', (
      tester,
    ) async {
      tester.view.physicalSize = const Size(320, 400);
      tester.view.devicePixelRatio = 1;
      addTearDown(tester.view.reset);
      tester.platformDispatcher.textScaleFactorTestValue = 2.0;
      addTearDown(tester.platformDispatcher.clearAllTestValues);

      await openSheet(tester, cameraEnabled: true);

      // The last choice may be below the visible part until it is scrolled to.
      await tester.scrollUntilVisible(
        find.text('Take a photo of a receipt'),
        50,
        scrollable: find.descendant(
          of: find.byType(BottomSheet),
          matching: find.byType(Scrollable),
        ),
      );
      expect(find.text('Take a photo of a receipt'), findsOneWidget);
      expect(tester.takeException(), isNull);
    });
  });

  group('choosing', () {
    testWidgets('manual entry', (tester) async {
      await openSheet(tester, cameraEnabled: true);

      await tester.tap(find.text('Enter manually'));
      await tester.pumpAndSettle();

      expect(chosen, AddExpenseChoice.manual);
    });

    testWidgets('a receipt photo from the gallery', (tester) async {
      await openSheet(tester, cameraEnabled: true);

      await tester.tap(find.text('Choose a receipt photo'));
      await tester.pumpAndSettle();

      expect(chosen, AddExpenseChoice.scanGallery);
    });

    testWidgets('a photo from the camera', (tester) async {
      await openSheet(tester, cameraEnabled: true);

      await tester.tap(find.text('Take a photo of a receipt'));
      await tester.pumpAndSettle();

      expect(chosen, AddExpenseChoice.scanCamera);
    });

    testWidgets('closing the sheet chooses nothing', (tester) async {
      await openSheet(tester, cameraEnabled: true);

      await tester.tapAt(const Offset(10, 10));
      await tester.pumpAndSettle();

      expect(chosen, isNull);
    });
  });

  test('the camera is off in the app for now', () {
    // See docs/roadmap.md before turning it on: on the Infinix test phone the
    // system camera makes Android kill the app.
    expect(ScanFeatures.cameraEnabled, isFalse);
  });
}
