import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:intl/intl.dart';
import 'package:smart_expense_tracker/features/expenses/domain/entities/expense.dart';

import '../support/builders.dart';
import '../support/fakes.dart';
import '../support/pump_app.dart';

/// From a row on the Summary to the expenses behind it, and back.
void main() {
  final today = DateTime.now();
  final lastMonth = DateTime(today.year, today.month - 1, 15);
  final monthLabel = DateFormat.yMMMM().format(today);

  late FakeExpenseRepository expenses;

  final food1 = buildExpense(
    id: 'f1',
    vendor: 'Naivas',
    amountMinor: 10000,
    date: today,
    categoryId: 'food',
  );
  final food2 = buildExpense(
    id: 'f2',
    vendor: 'Java House',
    amountMinor: 25000,
    date: today,
    categoryId: 'food',
  );
  final transport = buildExpense(
    id: 't1',
    vendor: 'Uber',
    amountMinor: 40000,
    date: today,
    categoryId: 'transport',
  );
  final oldFood = buildExpense(
    id: 'f0',
    vendor: 'Old Bakery',
    amountMinor: 5000,
    date: lastMonth,
    categoryId: 'food',
  );

  Future<void> openSummary(WidgetTester tester, [List<Expense>? list]) async {
    expenses = FakeExpenseRepository(
      initial: list ?? [food1, food2, transport, oldFood],
    );
    await pumpRouterApp(tester, expenses: expenses);
    await goToTab(tester, 'Summary');
  }

  Future<void> openFood(WidgetTester tester) async {
    await tester.tap(
      find
          .ancestor(of: find.text('Food'), matching: find.byType(InkWell))
          .first,
    );
    await tester.pumpAndSettle();
  }

  testWidgets('tapping a category lists its expenses for that month only', (
    tester,
  ) async {
    await openSummary(tester);

    await openFood(tester);

    expect(find.text('Naivas'), findsOneWidget);
    expect(find.text('Java House'), findsOneWidget);
    // Another category, and the same category in another month, stay out.
    expect(find.text('Uber'), findsNothing);
    expect(find.text('Old Bakery'), findsNothing);
    expect(find.textContaining(monthLabel), findsOneWidget);
    expect(find.textContaining('2 expenses'), findsOneWidget);
  });

  testWidgets('going back returns to the Summary', (tester) async {
    await openSummary(tester);
    await openFood(tester);

    await tester.pageBack();
    await tester.pumpAndSettle();

    expect(find.text('By category'), findsOneWidget);
    expect(find.text('Naivas'), findsNothing);
  });

  testWidgets('an expense can be opened for editing from there', (
    tester,
  ) async {
    await openSummary(tester);
    await openFood(tester);

    await tester.tap(find.text('Naivas'));
    await tester.pumpAndSettle();

    expect(find.text('Edit expense'), findsOneWidget);
  });

  testWidgets('deleting one updates the list and keeps Undo', (tester) async {
    await openSummary(tester);
    await openFood(tester);

    await tester.drag(find.text('Naivas'), const Offset(-600, 0));
    await tester.pumpAndSettle();

    expect(find.text('Naivas'), findsNothing);
    expect(find.text('Java House'), findsOneWidget);
    expect(find.text('Expense deleted'), findsOneWidget);
    expect(find.textContaining('1 expense '), findsOneWidget);

    await tester.tap(find.text('Undo'));
    await tester.pumpAndSettle();

    expect(find.text('Naivas'), findsOneWidget);
  });

  testWidgets('shows the list of the past month when that month is open', (
    tester,
  ) async {
    await openSummary(tester);
    await tester.tap(find.byTooltip('Previous month'));
    await tester.pumpAndSettle();

    await openFood(tester);

    expect(find.text('Old Bakery'), findsOneWidget);
    expect(find.text('Naivas'), findsNothing);
  });
}
