import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:smart_expense_tracker/core/errors/storage_exception.dart';

import '../support/builders.dart';
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
    // On the row, and as that day's total.
    expect(find.text('12.50'), findsNWidgets(2));
    expect(expenses.saved.single.categoryId, 'food');
  });

  testWidgets('Repeat this expense makes a monthly rule', (tester) async {
    final recurring = FakeRecurringRepository();
    await pumpRouterApp(tester, expenses: expenses, recurring: recurring);

    await openAddExpense(tester);
    await tester.enterText(find.widgetWithText(TextField, 'Amount'), '12.50');
    await tester.tap(find.text('Food'));
    await tester.pump();
    await tester.ensureVisible(find.text('Repeat this expense'));
    await tester.tap(find.text('Repeat this expense'));
    await tester.pumpAndSettle();
    expect(find.text('Monthly'), findsOneWidget);
    await tapSave(tester);

    expect(find.text('Expense saved'), findsOneWidget);
    expect(recurring.created.single.amountMinor, 1250);
    expect(recurring.rules.single.frequency.label, 'Monthly');
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

  group('with saved expenses', () {
    final today = DateTime.now();
    final yesterday = today.subtract(const Duration(days: 1));

    setUp(() {
      expenses = FakeExpenseRepository(
        initial: [
          buildExpense(
            id: '1',
            vendor: 'Cafe',
            amountMinor: 500,
            date: today,
            categoryId: 'food',
          ),
          buildExpense(
            id: '2',
            vendor: 'Bus',
            amountMinor: 300,
            date: yesterday,
            categoryId: 'transport',
          ),
        ],
      );
    });

    Future<void> swipeAway(WidgetTester tester, String vendor) async {
      await tester.drag(find.text(vendor), const Offset(-500, 0));
      await tester.pumpAndSettle();
    }

    TextField field(WidgetTester tester, String label) =>
        tester.widget<TextField>(find.widgetWithText(TextField, label));

    testWidgets('groups expenses by day and names each category', (
      tester,
    ) async {
      await pumpRouterApp(tester, expenses: expenses);

      expect(find.text('Today'), findsOneWidget);
      expect(find.text('Yesterday'), findsOneWidget);
      expect(find.text('Food'), findsOneWidget);
      expect(find.text('Transport'), findsOneWidget);
      // Each amount shows on its row and as that day's total.
      expect(find.text('5.00'), findsNWidgets(2));
      expect(find.text('3.00'), findsNWidgets(2));
    });

    testWidgets('opens an expense in the form with its details filled in', (
      tester,
    ) async {
      await pumpRouterApp(tester, expenses: expenses);

      await tapText(tester, 'Cafe');

      expect(find.text('Edit expense'), findsOneWidget);
      expect(field(tester, 'Vendor (optional)').controller!.text, 'Cafe');
      expect(field(tester, 'Amount').controller!.text, '5.00');
      expect(find.text('Save changes'), findsOneWidget);
    });

    testWidgets('shows the title on the list and in the form', (tester) async {
      expenses = FakeExpenseRepository(
        initial: [
          buildExpense(
            title: 'Team lunch',
            vendor: 'Cafe',
            date: today,
            categoryId: 'food',
          ),
        ],
      );
      await pumpRouterApp(tester, expenses: expenses);

      expect(find.text('Team lunch'), findsOneWidget);
      expect(find.text('Cafe · Food'), findsOneWidget);

      await tapText(tester, 'Team lunch');

      expect(field(tester, 'Title (optional)').controller!.text, 'Team lunch');
    });

    testWidgets('adds a title to an existing expense', (tester) async {
      await pumpRouterApp(tester, expenses: expenses);

      await tapText(tester, 'Cafe');
      await tester.enterText(
        find.widgetWithText(TextField, 'Title (optional)'),
        '  Morning coffee ',
      );
      await tapText(tester, 'Save changes');

      expect(find.text('Morning coffee'), findsOneWidget);
      expect(
        expenses.saved.firstWhere((e) => e.id == '1').title,
        'Morning coffee',
      );
    });

    testWidgets('does not let the title grow past its limit', (tester) async {
      await pumpRouterApp(tester, expenses: expenses);

      await tapText(tester, 'Cafe');
      await tester.enterText(
        find.widgetWithText(TextField, 'Title (optional)'),
        'a' * 80,
      );

      expect(field(tester, 'Title (optional)').controller!.text.length, 60);
    });

    testWidgets('shows a blank vendor as empty when editing', (tester) async {
      expenses = FakeExpenseRepository(
        initial: [buildExpense(vendor: 'Unknown', date: today)],
      );
      await pumpRouterApp(tester, expenses: expenses);

      await tapText(tester, 'Unknown');

      expect(field(tester, 'Vendor (optional)').controller!.text, isEmpty);
    });

    testWidgets('saves changes to the same expense', (tester) async {
      await pumpRouterApp(tester, expenses: expenses);

      await tapText(tester, 'Cafe');
      await tester.enterText(find.widgetWithText(TextField, 'Amount'), '12.5');
      await tester.tap(find.text('Transport'));
      await tester.pump();
      await tapText(tester, 'Save changes');

      expect(find.text('Expense updated'), findsOneWidget);
      expect(find.text('Edit expense'), findsNothing);
      expect(expenses.saved, hasLength(2), reason: 'edited, not added');
      final edited = expenses.saved.firstWhere((e) => e.id == '1');
      expect(edited.amountMinor, 1250);
      expect(edited.categoryId, 'transport');
      expect(find.text('12.50'), findsNWidgets(2));
    });

    testWidgets('keeps the form open and explains a bad edit', (tester) async {
      await pumpRouterApp(tester, expenses: expenses);

      await tapText(tester, 'Cafe');
      await tester.enterText(find.widgetWithText(TextField, 'Amount'), '0');
      await tapText(tester, 'Save changes');

      expect(find.text('Amount must be greater than zero'), findsOneWidget);
      expect(find.text('Edit expense'), findsOneWidget);
      expect(expenses.saved.first.amountMinor, 500);
    });

    testWidgets('tells the user when updating fails', (tester) async {
      await pumpRouterApp(tester, expenses: expenses);

      await tapText(tester, 'Cafe');
      expenses.saveError = const StorageException('disk full');
      await tapText(tester, 'Save changes');

      expect(
        find.text('Couldn\'t update the expense. Try again.'),
        findsOneWidget,
      );
    });

    testWidgets('deletes from the edit screen after confirming', (
      tester,
    ) async {
      await pumpRouterApp(tester, expenses: expenses);

      await tapText(tester, 'Cafe');
      await tester.tap(find.byIcon(Icons.delete_outline));
      await tester.pumpAndSettle();
      expect(find.text('Delete this expense?'), findsOneWidget);
      await tapText(tester, 'Delete');

      expect(find.text('Expense deleted'), findsOneWidget);
      expect(find.text('Cafe'), findsNothing);
      expect(expenses.saved.map((e) => e.id), ['2']);
    });

    testWidgets('keeps the expense when the delete is cancelled', (
      tester,
    ) async {
      await pumpRouterApp(tester, expenses: expenses);

      await tapText(tester, 'Cafe');
      await tester.tap(find.byIcon(Icons.delete_outline));
      await tester.pumpAndSettle();
      await tapText(tester, 'Cancel');

      expect(find.text('Edit expense'), findsOneWidget);
      expect(expenses.saved, hasLength(2));
    });

    testWidgets('swipe deletes a row and Undo brings it back', (tester) async {
      await pumpRouterApp(tester, expenses: expenses);

      await swipeAway(tester, 'Cafe');

      expect(find.text('Cafe'), findsNothing);
      expect(find.text('Expense deleted'), findsOneWidget);
      expect(expenses.saved.map((e) => e.id), ['2']);

      await tapText(tester, 'Undo');

      expect(find.text('Cafe'), findsOneWidget);
      expect(expenses.saved, hasLength(2));
    });

    testWidgets('puts the row back when a swipe delete fails', (tester) async {
      expenses.deleteError = const StorageException('disk full');
      await pumpRouterApp(tester, expenses: expenses);

      await swipeAway(tester, 'Cafe');

      expect(
        find.text('Couldn\'t delete the expense. Try again.'),
        findsOneWidget,
      );
      expect(find.text('Cafe'), findsOneWidget);
    });

    testWidgets('says so when Undo cannot restore the expense', (tester) async {
      await pumpRouterApp(tester, expenses: expenses);

      await swipeAway(tester, 'Cafe');
      expenses.saveError = const StorageException('disk full');
      await tapText(tester, 'Undo');

      expect(find.text('Couldn\'t restore the expense.'), findsOneWidget);
    });
  });
}
