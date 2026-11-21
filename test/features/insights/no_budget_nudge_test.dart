import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:smart_expense_tracker/core/theme/app_theme.dart';
import 'package:smart_expense_tracker/core/utils/currency.dart';
import 'package:smart_expense_tracker/features/budgets/domain/entities/budget.dart';
import 'package:smart_expense_tracker/features/budgets/domain/repositories/budget_repository.dart';
import 'package:smart_expense_tracker/features/expenses/domain/entities/expense.dart';
import 'package:smart_expense_tracker/features/insights/domain/entities/insight_alert.dart';
import 'package:smart_expense_tracker/features/insights/domain/usecases/find_alerts.dart';
import 'package:smart_expense_tracker/features/insights/presentation/cubit/alerts_cubit.dart';
import 'package:smart_expense_tracker/features/insights/presentation/widgets/alerts_section.dart';

import '../../support/builders.dart';
import '../../support/fakes.dart';

/// A budget list that never answers, as if the budgets had not been read yet.
class _NeverReadBudgets implements BudgetRepository {
  @override
  Stream<List<Budget>> watchAll() => const Stream.empty();

  @override
  Future<void> save(Budget budget) async {}

  @override
  Future<void> delete(String scopeId) async {}
}

void main() {
  const findAlerts = FindAlerts();
  // Saturday 21 November 2026.
  final today = DateTime(2026, 11, 21, 10);

  Expense spend(int amount, int day, {String category = 'food'}) =>
      buildExpense(
        id: '$category$day$amount',
        vendor: 'V$day',
        amountMinor: amount,
        date: DateTime(2026, 11, day),
        categoryId: category,
      );

  /// Food is 600.00 of 900.00 (two thirds), in three expenses.
  List<Expense> foodHeavy() => [
    spend(20000, 2),
    spend(20000, 5),
    spend(20000, 9),
    spend(30000, 12, category: 'transport'),
  ];

  List<InsightAlert> nudges(
    List<Expense> expenses, {
    Set<String>? budgeted = const {},
  }) => [
    for (final a in findAlerts(expenses, today, budgetedCategoryIds: budgeted))
      if (a.kind == AlertKind.noBudget) a,
  ];

  group('the nudge for a category with no budget', () {
    test('names the category that is a big share of the month', () {
      final result = nudges(foodHeavy());

      expect(result, hasLength(1));
      expect(result.single.categoryId, 'food');
      expect(result.single.amountMinor, 60000);
      expect(result.single.usualMinor, 90000);
    });

    test('is not told for a category that has a budget', () {
      expect(nudges(foodHeavy(), budgeted: {'food'}), isEmpty);
    });

    test('is not told when the budgets are not known yet', () {
      expect(nudges(foodHeavy(), budgeted: null), isEmpty);
    });

    test('is not told for a category that is a small share', () {
      final spread = [
        spend(20000, 2),
        spend(20000, 5),
        spend(20000, 9),
        spend(100000, 12, category: 'transport'),
        spend(100000, 13, category: 'bills'),
      ];

      expect(nudges(spread), isEmpty);
    });

    test('is not told for a single big purchase', () {
      expect(
        nudges([spend(90000, 2), spend(10000, 5, category: 'transport')]),
        isEmpty,
      );
    });

    test('stays quiet while the month has hardly any spending', () {
      expect(
        nudges([spend(10000, 2), spend(10000, 3), spend(10000, 4)]),
        isEmpty,
      );
    });

    test('only counts this month, and only up to today', () {
      final old = [
        for (var i = 1; i <= 4; i++)
          buildExpense(
            id: 'o$i',
            amountMinor: 30000,
            date: DateTime(2026, 10, i),
          ),
        spend(30000, 22),
      ];

      expect(nudges(old), isEmpty);
    });

    test('tells about one category at most, the biggest', () {
      final two = [
        spend(30000, 2),
        spend(30000, 3),
        spend(30000, 4),
        spend(25000, 5, category: 'bills'),
        spend(25000, 6, category: 'bills'),
        spend(25000, 7, category: 'bills'),
      ];

      final result = nudges(two);

      expect(result, hasLength(1));
      expect(result.single.categoryId, 'food');
    });

    test('keeps the same id for the same category and month', () {
      expect(nudges(foodHeavy()).single.id, 'nobudget:food:2026-11');
    });
  });

  group('AlertsCubit with budgets', () {
    AlertsCubit build(
      FakeExpenseRepository expenses,
      BudgetRepository budgets,
      FakeAlertDismissals dismissals,
    ) {
      final cubit = AlertsCubit(
        expenses,
        dismissals,
        budgets,
        now: () => today,
      );
      addTearDown(cubit.close);
      return cubit;
    }

    List<AlertKind> kinds(AlertsCubit cubit) => [
      for (final a in cubit.state) a.kind,
    ];

    test(
      'shows the nudge, and drops it once the category has a budget',
      () async {
        final budgets = FakeBudgetRepository();
        final cubit = build(
          FakeExpenseRepository(initial: foodHeavy()),
          budgets,
          FakeAlertDismissals(),
        );
        await pumpEventQueue();
        expect(kinds(cubit), contains(AlertKind.noBudget));

        await budgets.save(const Budget(scopeId: 'food', limitMinor: 100000));
        await pumpEventQueue();

        expect(kinds(cubit), isNot(contains(AlertKind.noBudget)));
      },
    );

    test(
      'does not say a category lacks a budget before they are read',
      () async {
        final cubit = build(
          FakeExpenseRepository(initial: foodHeavy()),
          _NeverReadBudgets(),
          FakeAlertDismissals(),
        );
        await pumpEventQueue();

        expect(kinds(cubit), isNot(contains(AlertKind.noBudget)));
      },
    );

    test(
      'an overall budget does not count as the category having one',
      () async {
        final cubit = build(
          FakeExpenseRepository(initial: foodHeavy()),
          FakeBudgetRepository(
            initial: const [
              Budget(scopeId: Budget.overallId, limitMinor: 500000),
            ],
          ),
          FakeAlertDismissals(),
        );
        await pumpEventQueue();

        expect(kinds(cubit), contains(AlertKind.noBudget));
      },
    );

    test('once dismissed it stays dismissed for the month', () async {
      final cubit = build(
        FakeExpenseRepository(initial: foodHeavy()),
        FakeBudgetRepository(),
        FakeAlertDismissals(),
      );
      await pumpEventQueue();

      await cubit.dismiss('nobudget:food:2026-11');

      expect(kinds(cubit), isNot(contains(AlertKind.noBudget)));
    });
  });

  group('the card', () {
    const alert = InsightAlert(
      id: 'nobudget:food:2026-11',
      kind: AlertKind.noBudget,
      categoryId: 'food',
      amountMinor: 60000,
      usualMinor: 90000,
    );

    Future<void> show(
      WidgetTester tester, {
      ValueChanged<InsightAlert>? onAction,
    }) => tester.pumpWidget(
      MaterialApp(
        theme: AppTheme.light,
        home: Scaffold(
          body: AlertsSection(
            alerts: const [alert],
            categoryNames: const {'food': 'Food'},
            currency: Currency.kes,
            onDismiss: (_) {},
            onAction: onAction,
          ),
        ),
      ),
    );

    testWidgets('says the share and offers to set a budget', (tester) async {
      InsightAlert? tapped;
      await show(tester, onAction: (a) => tapped = a);

      expect(find.text('Food has no budget'), findsOneWidget);
      expect(find.textContaining('67% of your spending'), findsOneWidget);

      await tester.tap(find.text('Set a budget'));

      expect(tapped, alert);
    });

    testWidgets('has no button where nothing can act on it', (tester) async {
      await show(tester);

      expect(find.text('Set a budget'), findsNothing);
      expect(find.text('Food has no budget'), findsOneWidget);
    });
  });
}
