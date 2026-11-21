import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:smart_expense_tracker/features/budgets/domain/entities/budget.dart';

import '../support/builders.dart';
import '../support/fakes.dart';
import '../support/pump_app.dart';

/// Setting and seeing a category's budget where the spending is.
void main() {
  final today = DateTime.now();

  late FakeBudgetRepository budgets;

  FakeExpenseRepository expenses() => FakeExpenseRepository(
    initial: [
      buildExpense(
        id: 'f1',
        vendor: 'Naivas',
        amountMinor: 100000,
        date: today,
        categoryId: 'food',
      ),
      buildExpense(
        id: 't1',
        vendor: 'Uber',
        amountMinor: 40000,
        date: today,
        categoryId: 'transport',
      ),
    ],
  );

  setUp(() => budgets = FakeBudgetRepository());

  Future<void> openSummary(WidgetTester tester) async {
    await pumpRouterApp(tester, expenses: expenses(), budgets: budgets);
    await goToTab(tester, 'Summary');
  }

  Future<void> openFood(WidgetTester tester) async {
    await openSummary(tester);
    await tester.tap(
      find
          .ancestor(of: find.text('Food'), matching: find.byType(InkWell))
          .first,
    );
    await tester.pumpAndSettle();
  }

  group('on a category page', () {
    testWidgets('says there is no budget and offers to set one', (
      tester,
    ) async {
      await openFood(tester);

      expect(find.text('No budget for Food'), findsOneWidget);
      expect(find.text('Set a budget'), findsOneWidget);
    });

    testWidgets('setting one shows how much is left, with a hint to start', (
      tester,
    ) async {
      await openFood(tester);

      await tester.tap(find.text('Set a budget'));
      await tester.pumpAndSettle();
      expect(find.text('Food budget'), findsOneWidget);
      expect(find.textContaining('This month: '), findsOneWidget);

      await tester.enterText(find.byType(TextField), '5000');
      await tester.tap(find.text('Save budget'));
      await tester.pumpAndSettle();

      expect(budgets.saved.single.scopeId, 'food');
      expect(budgets.saved.single.limitMinor, 500000);
      expect(find.text('Budget saved'), findsOneWidget);
      expect(find.text('No budget for Food'), findsNothing);
      expect(find.textContaining('left'), findsWidgets);
    });

    testWidgets('an existing budget shows its progress and can be changed', (
      tester,
    ) async {
      budgets = FakeBudgetRepository(
        initial: const [Budget(scopeId: 'food', limitMinor: 500000)],
      );
      await openFood(tester);
      expect(find.text('Food budget'), findsOneWidget);

      await tester.tap(find.text('Food budget'));
      await tester.pumpAndSettle();
      await tester.enterText(find.byType(TextField), '2000');
      await tester.tap(find.text('Save budget'));
      await tester.pumpAndSettle();

      expect(budgets.saved.single.limitMinor, 200000);
    });

    testWidgets('a budget can be removed from there too', (tester) async {
      budgets = FakeBudgetRepository(
        initial: const [Budget(scopeId: 'food', limitMinor: 500000)],
      );
      await openFood(tester);

      await tester.tap(find.text('Food budget'));
      await tester.pumpAndSettle();
      await tester.tap(find.text('Remove budget'));
      await tester.pumpAndSettle();

      expect(budgets.saved, isEmpty);
      expect(find.text('No budget for Food'), findsOneWidget);
    });

    testWidgets('the page for the whole month has no category budget', (
      tester,
    ) async {
      await pumpRouterApp(tester, expenses: expenses(), budgets: budgets);
      await goToTab(tester, 'Home');
      await tester.tap(
        find.bySemanticsLabel(RegExp('^[A-Z][a-z]+: ')).at(today.month - 1),
      );
      await tester.pumpAndSettle();

      expect(find.text('All spending'), findsOneWidget);
      expect(find.textContaining('No budget for'), findsNothing);
    });
  });

  group('on the Summary cards', () {
    testWidgets('a category with a budget shows how much is left', (
      tester,
    ) async {
      budgets = FakeBudgetRepository(
        initial: const [Budget(scopeId: 'food', limitMinor: 500000)],
      );
      await openSummary(tester);

      expect(find.textContaining('left of'), findsOneWidget);
    });

    testWidgets('a category without one gets no extra line or button', (
      tester,
    ) async {
      await openSummary(tester);

      expect(find.textContaining('left of'), findsNothing);
      expect(find.text('Set a budget'), findsNothing);
    });

    testWidgets('one past its budget says how much over', (tester) async {
      budgets = FakeBudgetRepository(
        initial: const [Budget(scopeId: 'food', limitMinor: 60000)],
      );
      await openSummary(tester);

      expect(find.textContaining('over its'), findsOneWidget);
    });

    testWidgets('the overall budget is not shown on any category card', (
      tester,
    ) async {
      budgets = FakeBudgetRepository(
        initial: const [Budget(scopeId: Budget.overallId, limitMinor: 900000)],
      );
      await openSummary(tester);

      expect(find.textContaining('left of'), findsNothing);
    });
  });
}
