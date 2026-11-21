import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:smart_expense_tracker/features/budgets/domain/entities/budget.dart';

import '../support/builders.dart';
import '../support/fakes.dart';
import '../support/pump_app.dart';

/// The first screen of the app.
void main() {
  final today = DateTime.now();

  Future<void> openHome(
    WidgetTester tester, {
    FakeExpenseRepository? expenses,
    FakeBudgetRepository? budgets,
    FakeProfileRepository? profile,
    Size screenSize = const Size(800, 1600),
  }) => pumpRouterApp(
    tester,
    expenses: expenses,
    budgets: budgets,
    profile: profile,
    screenSize: screenSize,
    startOnHome: true,
  );

  FakeExpenseRepository someExpenses() => FakeExpenseRepository(
    initial: [
      for (var i = 0; i < 7; i++)
        buildExpense(
          id: 'e$i',
          vendor: 'Shop $i',
          amountMinor: 10000,
          date: today,
        ),
    ],
  );

  testWidgets('opens on Home, with the greeting and the name', (tester) async {
    await openHome(tester, profile: FakeProfileRepository('Maja'));

    expect(find.textContaining(', Maja'), findsOneWidget);
    expect(
      find.descendant(
        of: find.byType(NavigationBar),
        matching: find.text('Home'),
      ),
      findsOneWidget,
    );
  });

  testWidgets('a new app welcomes the user instead of showing empty numbers', (
    tester,
  ) async {
    await openHome(tester);

    expect(find.text('Let\'s add your first expense'), findsOneWidget);
    expect(find.text('Recent'), findsNothing);
    expect(find.textContaining('Spending in'), findsNothing);
  });

  testWidgets('with expenses it shows the month, the year and the latest', (
    tester,
  ) async {
    await openHome(tester, expenses: someExpenses());

    expect(find.text('Spent this month'), findsOneWidget);
    expect(find.text('Spending in ${today.year}'), findsOneWidget);
    expect(find.text('Recent'), findsOneWidget);
    // Only the latest five of the seven.
    expect(find.textContaining('Shop '), findsNWidgets(5));
  });

  testWidgets('with a budget it shows what is left', (tester) async {
    await openHome(
      tester,
      expenses: someExpenses(),
      budgets: FakeBudgetRepository(
        initial: const [Budget(scopeId: Budget.overallId, limitMinor: 500000)],
      ),
    );

    expect(find.text('This month'), findsOneWidget);
    expect(find.textContaining('left'), findsWidgets);
    expect(find.text('Set a monthly budget'), findsNothing);
  });

  testWidgets('without a budget it offers to set one', (tester) async {
    await openHome(tester, expenses: someExpenses());

    await tester.tap(find.text('Set a monthly budget'));
    await tester.pumpAndSettle();

    expect(find.text('Budgets'), findsWidgets);
  });

  testWidgets('See all opens the Expenses tab', (tester) async {
    await openHome(tester, expenses: someExpenses());

    await tester.tap(find.text('See all'));
    await tester.pumpAndSettle();

    // All seven are listed there, not just five.
    expect(find.textContaining('Shop '), findsNWidgets(7));
    expect(find.byTooltip('Search'), findsOneWidget);
  });

  testWidgets('a recent expense opens for editing', (tester) async {
    await openHome(tester, expenses: someExpenses());

    await tester.tap(find.text('Shop 0'));
    await tester.pumpAndSettle();

    expect(find.text('Edit expense'), findsOneWidget);
  });

  testWidgets('tapping the month card opens the Summary', (tester) async {
    await openHome(tester, expenses: someExpenses());

    await tester.tap(find.text('Spent this month'));
    await tester.pumpAndSettle();

    expect(find.text('By category'), findsOneWidget);
  });

  testWidgets('tapping a bar opens the expenses of that month', (tester) async {
    await openHome(tester, expenses: someExpenses());

    await tester.tap(find.bySemanticsLabel(RegExp('^${_monthName(today)}: ')));
    await tester.pumpAndSettle();

    expect(find.text('All spending'), findsOneWidget);
    expect(find.textContaining('Shop '), findsNWidgets(7));
  });

  testWidgets('the name can be changed in Settings and the greeting follows', (
    tester,
  ) async {
    await openHome(tester, profile: FakeProfileRepository('Maja'));

    await goToTab(tester, 'Settings');
    await tapText(tester, 'Your name');
    await tester.enterText(find.byType(TextField), 'Sam');
    await tapText(tester, 'Save');
    await goToTab(tester, 'Home');

    expect(find.textContaining(', Sam'), findsOneWidget);
    expect(find.textContaining('Maja'), findsNothing);
  });

  testWidgets('the Add button is on Home', (tester) async {
    await openHome(tester);

    expect(find.byType(FloatingActionButton), findsOneWidget);
  });

  testWidgets('fits a short phone at large text', (tester) async {
    tester.platformDispatcher.textScaleFactorTestValue = 1.6;
    addTearDown(tester.platformDispatcher.clearAllTestValues);

    await openHome(
      tester,
      expenses: someExpenses(),
      profile: FakeProfileRepository('Maja'),
      screenSize: const Size(360, 640),
    );

    expect(tester.takeException(), isNull);
  });
}

String _monthName(DateTime day) => const [
  'January',
  'February',
  'March',
  'April',
  'May',
  'June',
  'July',
  'August',
  'September',
  'October',
  'November',
  'December',
][day.month - 1];
