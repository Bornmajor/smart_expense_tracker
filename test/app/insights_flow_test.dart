import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:smart_expense_tracker/features/budgets/domain/entities/budget.dart';

import '../support/builders.dart';
import '../support/fakes.dart';
import '../support/pump_app.dart';

/// This month against last month, and the budget on the year chart.
void main() {
  final now = DateTime.now();
  // The first of this month and the first of last month are always on or before
  // today, and in the same stretch of each month.
  final thisMonth = DateTime(now.year, now.month, 1);
  final lastMonth = DateTime(now.year, now.month - 1, 1);

  FakeExpenseRepository withHistory() => FakeExpenseRepository(
    initial: [
      buildExpense(
        id: 'now',
        vendor: 'Naivas',
        amountMinor: 300000,
        date: thisMonth,
        categoryId: 'food',
      ),
      buildExpense(
        id: 'before',
        vendor: 'Naivas',
        amountMinor: 100000,
        date: lastMonth,
        categoryId: 'food',
      ),
    ],
  );

  Future<void> openHome(
    WidgetTester tester, {
    FakeExpenseRepository? expenses,
    FakeBudgetRepository? budgets,
  }) => pumpRouterApp(
    tester,
    expenses: expenses,
    budgets: budgets,
    startOnHome: true,
    screenSize: const Size(800, 2000),
  );

  group('on Home', () {
    testWidgets('shows how this month compares with last month', (
      tester,
    ) async {
      await openHome(tester, expenses: withHistory());

      expect(find.text('Compared with last month'), findsOneWidget);
      expect(find.textContaining('200% more'), findsOneWidget);
      expect(find.textContaining('Biggest change: Food, up'), findsOneWidget);
    });

    testWidgets('says nothing when there is no last month to compare', (
      tester,
    ) async {
      await openHome(
        tester,
        expenses: FakeExpenseRepository(
          initial: [
            buildExpense(id: 'now', amountMinor: 300000, date: thisMonth),
          ],
        ),
      );

      expect(find.text('Compared with last month'), findsNothing);
    });

    testWidgets('the year chart marks the monthly budget when there is one', (
      tester,
    ) async {
      await openHome(
        tester,
        expenses: withHistory(),
        budgets: FakeBudgetRepository(
          initial: const [
            Budget(scopeId: Budget.overallId, limitMinor: 500000),
          ],
        ),
      );

      expect(find.textContaining('Monthly budget'), findsOneWidget);
    });

    testWidgets('and leaves the line out when there is none', (tester) async {
      await openHome(tester, expenses: withHistory());

      expect(find.textContaining('Monthly budget'), findsNothing);
    });
  });

  group('on the Summary', () {
    Future<void> openSummary(WidgetTester tester) async {
      await pumpRouterApp(
        tester,
        expenses: withHistory(),
        screenSize: const Size(800, 2000),
      );
      await goToTab(tester, 'Summary');
    }

    testWidgets('this month is compared with last month', (tester) async {
      await openSummary(tester);

      expect(find.text('Compared with last month'), findsOneWidget);
    });

    testWidgets('a past month is not', (tester) async {
      await openSummary(tester);

      await tester.tap(find.byTooltip('Previous month'));
      await tester.pumpAndSettle();

      expect(find.text('Compared with last month'), findsNothing);
    });
  });
}
