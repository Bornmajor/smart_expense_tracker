import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import '../support/fakes.dart';
import '../support/pump_app.dart';

/// Typing one line, from the Add button to a saved expense.
void main() {
  late FakeExpenseRepository expenses;

  setUp(() => expenses = FakeExpenseRepository());

  Future<void> openQuickAdd(WidgetTester tester) async {
    await pumpRouterApp(tester, expenses: expenses);
    await tester.tap(find.byType(FloatingActionButton));
    await tester.pumpAndSettle();
    await tapText(tester, 'Type it in one line');
  }

  Future<void> typeLine(WidgetTester tester, String text) async {
    await tester.enterText(find.byType(TextField), text);
    await tester.pumpAndSettle();
  }

  testWidgets('shows what it understood and fills in the form', (tester) async {
    await openQuickAdd(tester);

    await typeLine(tester, 'fuel 3000 at shell yesterday');
    expect(find.text('Shell'), findsOneWidget);
    expect(find.text('Fuel'), findsOneWidget);

    await tapText(tester, 'Continue');

    expect(find.text('Add expense'), findsOneWidget);
    expect(find.text('Filled in from what you typed'), findsOneWidget);
    expect(
      tester
          .widget<TextField>(
            find.widgetWithText(TextField, 'Vendor (optional)'),
          )
          .controller!
          .text,
      'Shell',
    );
    expect(
      tester
          .widget<TextField>(find.widgetWithText(TextField, 'Title (optional)'))
          .controller!
          .text,
      'Fuel',
    );
    expect(
      tester
          .widget<TextField>(find.widgetWithText(TextField, 'Amount'))
          .controller!
          .text,
      '3000.00',
    );
  });

  testWidgets('the typed line can be saved as an expense, with a category', (
    tester,
  ) async {
    await openQuickAdd(tester);
    await typeLine(tester, 'fuel 3000 at shell');
    await tapText(tester, 'Continue');

    await tapText(tester, 'Save expense');

    final saved = expenses.saved.single;
    expect(saved.amountMinor, 300000);
    expect(saved.vendor, 'Shell');
    expect(saved.title, 'Fuel');
    expect(saved.categoryId, 'transport');
  });

  testWidgets('cannot continue without an amount', (tester) async {
    await openQuickAdd(tester);

    await typeLine(tester, 'lunch at java');

    expect(find.textContaining('Add an amount'), findsOneWidget);
    final button = tester.widget<FilledButton>(
      find.widgetWithText(FilledButton, 'Continue'),
    );
    expect(button.onPressed, isNull);
  });

  testWidgets('the sheet explains what to type until something is typed', (
    tester,
  ) async {
    await openQuickAdd(tester);

    expect(find.textContaining('Say what you spent'), findsOneWidget);
  });
}
