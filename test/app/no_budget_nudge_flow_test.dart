import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:smart_expense_tracker/features/budgets/domain/entities/budget.dart';

import '../support/builders.dart';
import '../support/fakes.dart';
import '../support/pump_app.dart';

/// From the nudge on Home to a budget set, and back.
void main() {
  final now = DateTime.now();
  // The first of this month is always on or before today.
  final first = DateTime(now.year, now.month, 1);

  FakeExpenseRepository foodHeavy() => FakeExpenseRepository(
    initial: [
      for (var i = 0; i < 3; i++)
        buildExpense(
          id: 'f$i',
          vendor: 'Naivas $i',
          amountMinor: 20000,
          date: first,
          categoryId: 'food',
        ),
      buildExpense(
        id: 't',
        vendor: 'Uber',
        amountMinor: 30000,
        date: first,
        categoryId: 'transport',
      ),
    ],
  );

  Future<void> openHome(WidgetTester tester, {FakeBudgetRepository? budgets}) =>
      pumpRouterApp(
        tester,
        expenses: foodHeavy(),
        budgets: budgets ?? FakeBudgetRepository(),
        startOnHome: true,
        screenSize: const Size(800, 2200),
      );

  testWidgets('Home nudges about a big category with no budget', (
    tester,
  ) async {
    await openHome(tester);

    expect(find.text('Food has no budget'), findsOneWidget);
    expect(find.textContaining('of your spending this month'), findsOneWidget);
  });

  testWidgets(
    'Set a budget opens the category page, and setting one clears it',
    (tester) async {
      final budgets = FakeBudgetRepository();
      await openHome(tester, budgets: budgets);

      await tester.tap(find.text('Set a budget'));
      await tester.pumpAndSettle();
      expect(find.text('No budget for Food'), findsOneWidget);

      await tester.tap(find.text('Set a budget'));
      await tester.pumpAndSettle();
      await tester.enterText(find.byType(TextField), '5000');
      await tester.tap(find.text('Save budget'));
      await tester.pumpAndSettle();
      expect(budgets.saved.single.scopeId, 'food');

      await tester.pageBack();
      await tester.pumpAndSettle();

      expect(find.text('Food has no budget'), findsNothing);
    },
  );

  testWidgets('no nudge once the category has a budget', (tester) async {
    await openHome(
      tester,
      budgets: FakeBudgetRepository(
        initial: const [Budget(scopeId: 'food', limitMinor: 500000)],
      ),
    );

    expect(find.text('Food has no budget'), findsNothing);
  });

  testWidgets('it can be dismissed', (tester) async {
    await openHome(tester);

    await tester.tap(find.byTooltip('Dismiss').first);
    await tester.pumpAndSettle();

    expect(find.text('Food has no budget'), findsNothing);
  });

  testWidgets('the Summary shows it too, with the same button', (tester) async {
    await pumpRouterApp(
      tester,
      expenses: foodHeavy(),
      budgets: FakeBudgetRepository(),
      screenSize: const Size(800, 2200),
    );
    await goToTab(tester, 'Summary');

    expect(find.text('Food has no budget'), findsOneWidget);

    await tester.tap(find.text('Set a budget'));
    await tester.pumpAndSettle();

    expect(find.text('No budget for Food'), findsOneWidget);
  });
}
