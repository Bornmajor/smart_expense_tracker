import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:smart_expense_tracker/core/errors/storage_exception.dart';

import '../support/fakes.dart';
import '../support/pump_app.dart';

void main() {
  late FakeExpenseRepository expenses;

  Future<void> openAddExpense(WidgetTester tester) async {
    await tester.tap(find.byType(FloatingActionButton));
    await tester.pumpAndSettle();
    await tapText(tester, 'Enter manually');
  }

  Future<void> tapSave(WidgetTester tester) => tapText(tester, 'Save expense');

  setUp(() => expenses = FakeExpenseRepository());

  testWidgets('adds an expense and shows it in the list', (tester) async {
    await pumpRouterApp(tester, expenses: expenses);
    expect(find.text('Add your first expense'), findsOneWidget);

    await openAddExpense(tester);
    await tester.enterText(find.widgetWithText(TextField, 'Amount'), '12.50');
    await tester.tap(find.text('Food'));
    await tester.pump();
    await tapSave(tester);

    expect(find.text('Expense saved'), findsOneWidget);
    expect(find.text('Add your first expense'), findsNothing);
    expect(find.text('Unknown'), findsOneWidget);
    expect(find.text('12.50'), findsOneWidget);
    expect(expenses.saved.single.categoryId, 'food');
  });

  testWidgets('shows validation messages and stays on the form', (
    tester,
  ) async {
    await pumpRouterApp(tester, expenses: expenses);

    await openAddExpense(tester);
    await tapSave(tester);

    expect(find.text('Enter an amount'), findsOneWidget);
    expect(find.text('Choose a category'), findsOneWidget);
    expect(find.text('Save expense'), findsOneWidget);
    expect(expenses.saved, isEmpty);
  });

  testWidgets('tells the user when saving fails', (tester) async {
    expenses.saveError = const StorageException('disk full');
    await pumpRouterApp(tester, expenses: expenses);

    await openAddExpense(tester);
    await tester.enterText(find.widgetWithText(TextField, 'Amount'), '5');
    await tester.tap(find.text('Transport'));
    await tester.pump();
    await tapSave(tester);

    expect(find.text('Couldn\'t save the expense. Try again.'), findsOneWidget);
  });
}
