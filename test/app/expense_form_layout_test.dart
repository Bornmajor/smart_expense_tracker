import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import '../support/fakes.dart';
import '../support/pump_app.dart';

/// The Save button stays pinned to the bottom of the form and rides up above
/// the keyboard, so the user never has to scroll or dismiss the keyboard.
void main() {
  const screen = Size(400, 800);

  Future<void> openForm(WidgetTester tester, {EdgeInsets? safePadding}) async {
    await pumpRouterApp(
      tester,
      expenses: FakeExpenseRepository(),
      screenSize: screen,
      safePadding: safePadding ?? EdgeInsets.zero,
    );
    await tester.tap(find.byType(FloatingActionButton));
    await tester.pumpAndSettle();
    await tapText(tester, 'Enter manually');
  }

  Rect saveRect(WidgetTester tester) =>
      tester.getRect(find.widgetWithText(FilledButton, 'Save expense'));

  void openKeyboard(WidgetTester tester, double height) {
    tester.view.viewInsets = FakeViewPadding(bottom: height);
  }

  testWidgets('the Save button sits at the bottom of the screen', (
    tester,
  ) async {
    await openForm(tester);

    expect(saveRect(tester).bottom, greaterThan(screen.height - 40));
  });

  testWidgets('the Save button stays clear of the gesture bar', (tester) async {
    await openForm(tester, safePadding: const EdgeInsets.only(bottom: 24));

    expect(saveRect(tester).bottom, lessThanOrEqualTo(screen.height - 24));
  });

  testWidgets('the Save button moves up above the keyboard', (tester) async {
    await openForm(tester);
    const keyboard = 300.0;

    openKeyboard(tester, keyboard);
    await tester.pumpAndSettle();

    final rect = saveRect(tester);
    expect(rect.bottom, lessThanOrEqualTo(screen.height - keyboard));
    expect(rect.bottom, greaterThan(screen.height - keyboard - 40));
  });

  testWidgets('Save still works with the keyboard open', (tester) async {
    await openForm(tester);
    await tester.enterText(find.widgetWithText(TextField, 'Amount'), '4');
    await tester.tap(find.text('Food'));
    await tester.pump();

    openKeyboard(tester, 300);
    await tester.pumpAndSettle();
    await tester.tap(find.widgetWithText(FilledButton, 'Save expense'));
    await tester.pumpAndSettle();

    expect(find.text('Expense saved'), findsOneWidget);
  });
}
