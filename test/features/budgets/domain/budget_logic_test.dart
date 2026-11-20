import 'package:flutter_test/flutter_test.dart';
import 'package:smart_expense_tracker/core/errors/app_failure.dart';
import 'package:smart_expense_tracker/core/errors/result.dart';
import 'package:smart_expense_tracker/core/errors/storage_exception.dart';
import 'package:smart_expense_tracker/features/budgets/domain/entities/budget.dart';
import 'package:smart_expense_tracker/features/budgets/domain/entities/budget_progress.dart';
import 'package:smart_expense_tracker/features/budgets/domain/usecases/evaluate_budgets.dart';
import 'package:smart_expense_tracker/features/budgets/domain/usecases/remove_budget.dart';
import 'package:smart_expense_tracker/features/budgets/domain/usecases/set_budget.dart';
import 'package:smart_expense_tracker/features/budgets/domain/validation/budget_rules.dart';
import 'package:smart_expense_tracker/features/dashboard/domain/entities/month_summary.dart';

import '../../../support/fakes.dart';

void main() {
  BudgetProgress progress(int limit, int spent) => BudgetProgress(
    budget: Budget(scopeId: 'food', limitMinor: limit),
    spentMinor: spent,
  );

  group('BudgetProgress', () {
    test('is on track well within the limit', () {
      expect(progress(1000, 0).level, BudgetLevel.onTrack);
      expect(progress(1000, 799).level, BudgetLevel.onTrack);
    });

    test('is near from exactly 80% of the limit', () {
      expect(progress(1000, 800).level, BudgetLevel.near);
      expect(progress(1000, 999).level, BudgetLevel.near);
    });

    test('reaching the limit exactly is near, not over', () {
      expect(progress(1000, 1000).level, BudgetLevel.near);
    });

    test('is over once more than the limit is spent', () {
      expect(progress(1000, 1001).level, BudgetLevel.over);
    });

    test(
      'counts the 80% line in whole numbers, so odd limits are not missed',
      () {
        // 80% of 3 is 2.4: spending 3 of 3 is near, and 2 of 3 is not yet.
        expect(progress(3, 2).level, BudgetLevel.onTrack);
        expect(progress(5, 4).level, BudgetLevel.near);
      },
    );

    test('says what is left, and how far over when the limit is passed', () {
      expect(progress(1000, 300).remainingMinor, 700);
      expect(progress(1000, 1250).remainingMinor, -250);
    });

    test('the fraction can go above one, for the screen to cap', () {
      expect(progress(1000, 250).fraction, 0.25);
      expect(progress(1000, 1500).fraction, 1.5);
    });
  });

  group('EvaluateBudgets', () {
    const evaluate = EvaluateBudgets();
    const summary = MonthSummary(
      totalMinor: 1500,
      count: 3,
      categories: [
        CategoryTotal(categoryId: 'food', totalMinor: 1000, share: 2 / 3),
        CategoryTotal(categoryId: 'transport', totalMinor: 500, share: 1 / 3),
      ],
    );

    test('measures the overall budget against the month total', () {
      final result = evaluate(summary, const [
        Budget(scopeId: Budget.overallId, limitMinor: 3000),
      ]);

      expect(result.single.spentMinor, 1500);
    });

    test('measures a category budget against that category only', () {
      final result = evaluate(summary, const [
        Budget(scopeId: 'food', limitMinor: 2000),
      ]);

      expect(result.single.spentMinor, 1000);
    });

    test('a category with no spending this month has spent nothing', () {
      final result = evaluate(summary, const [
        Budget(scopeId: 'health', limitMinor: 2000),
      ]);

      expect(result.single.spentMinor, 0);
      expect(result.single.level, BudgetLevel.onTrack);
    });

    test('has nothing to show without budgets', () {
      expect(evaluate(summary, const []), isEmpty);
    });

    test('puts the overall budget first, then the most used', () {
      final result = evaluate(summary, const [
        Budget(scopeId: 'transport', limitMinor: 1000), // 50%
        Budget(scopeId: 'food', limitMinor: 1100), // 91%
        Budget(scopeId: Budget.overallId, limitMinor: 10000), // 15%
      ]);

      expect(result.map((p) => p.budget.scopeId), [
        Budget.overallId,
        'food',
        'transport',
      ]);
    });

    test('orders equal budgets the same way every time', () {
      final result = evaluate(summary, const [
        Budget(scopeId: 'b', limitMinor: 1000),
        Budget(scopeId: 'a', limitMinor: 1000),
      ]);

      expect(result.map((p) => p.budget.scopeId), ['a', 'b']);
    });
  });

  group('SetBudget', () {
    late FakeBudgetRepository repository;
    late SetBudget setBudget;

    setUp(() {
      repository = FakeBudgetRepository();
      setBudget = SetBudget(repository);
    });

    String? errorFor(Result<void> result) =>
        ((result as Failure<void>).failure as ValidationFailure)
            .fieldErrors[BudgetField.amount];

    test('saves a valid limit in minor units', () async {
      final result = await setBudget(scopeId: 'food', amountText: '5000.50');

      expect(result, isA<Success<void>>());
      expect(repository.saved.single.limitMinor, 500050);
      expect(repository.saved.single.scopeId, 'food');
    });

    test('accepts a comma as the decimal sign', () async {
      await setBudget(scopeId: 'food', amountText: '12,5');

      expect(repository.saved.single.limitMinor, 1250);
    });

    test('can set the overall budget', () async {
      await setBudget(scopeId: Budget.overallId, amountText: '100');

      expect(repository.saved.single.isOverall, isTrue);
    });

    test('replaces an existing limit', () async {
      await setBudget(scopeId: 'food', amountText: '100');
      await setBudget(scopeId: 'food', amountText: '200');

      expect(repository.saved.single.limitMinor, 20000);
    });

    test('refuses a blank amount', () async {
      final result = await setBudget(scopeId: 'food', amountText: '  ');

      expect(errorFor(result), BudgetError.amountRequired);
      expect(repository.saved, isEmpty);
    });

    test('refuses text that is not a number', () async {
      final result = await setBudget(scopeId: 'food', amountText: 'a lot');

      expect(errorFor(result), BudgetError.amountInvalid);
    });

    test('refuses zero', () async {
      final result = await setBudget(scopeId: 'food', amountText: '0');

      expect(errorFor(result), BudgetError.amountMustBePositive);
      expect(repository.saved, isEmpty);
    });

    test('refuses more than a budget can be', () async {
      final result = await setBudget(
        scopeId: 'food',
        amountText: '1000000000.01',
      );

      expect(errorFor(result), BudgetError.amountTooLarge);
    });

    test('accepts exactly the largest budget', () async {
      final result = await setBudget(scopeId: 'food', amountText: '1000000000');

      expect(result, isA<Success<void>>());
    });

    test('reports a storage failure', () async {
      repository.saveError = const StorageException('disk full');

      final result = await setBudget(scopeId: 'food', amountText: '100');

      expect((result as Failure<void>).failure, const StorageFailure());
    });
  });

  group('RemoveBudget', () {
    test('removes the budget', () async {
      final repository = FakeBudgetRepository(
        initial: const [Budget(scopeId: 'food', limitMinor: 100)],
      );

      final result = await RemoveBudget(repository)('food');

      expect(result, isA<Success<void>>());
      expect(repository.saved, isEmpty);
    });

    test('reports a storage failure', () async {
      final repository = FakeBudgetRepository()
        ..deleteError = const StorageException('x');

      final result = await RemoveBudget(repository)('food');

      expect((result as Failure<void>).failure, const StorageFailure());
    });
  });
}
