import 'package:flutter_test/flutter_test.dart';
import 'package:smart_expense_tracker/core/errors/app_failure.dart';
import 'package:smart_expense_tracker/core/errors/result.dart';
import 'package:smart_expense_tracker/features/budgets/domain/entities/budget.dart';
import 'package:smart_expense_tracker/features/budgets/domain/usecases/remove_budget.dart';
import 'package:smart_expense_tracker/features/budgets/domain/usecases/set_budget.dart';
import 'package:smart_expense_tracker/features/budgets/presentation/budget_messages.dart';
import 'package:smart_expense_tracker/features/budgets/presentation/cubit/budgets_cubit.dart';
import 'package:smart_expense_tracker/features/budgets/presentation/cubit/budgets_state.dart';

import '../../../support/fakes.dart';

void main() {
  late FakeBudgetRepository repository;
  late BudgetsCubit cubit;

  setUp(() {
    repository = FakeBudgetRepository(
      initial: const [Budget(scopeId: 'food', limitMinor: 1000)],
    );
    cubit = BudgetsCubit(
      repository,
      setBudget: SetBudget(repository),
      removeBudget: RemoveBudget(repository),
    );
  });

  tearDown(() => cubit.close());

  test('lists the budgets by scope', () async {
    await pumpEventQueue();

    final state = cubit.state as BudgetsLoaded;
    expect(state.byScope, {
      'food': const Budget(scopeId: 'food', limitMinor: 1000),
    });
  });

  test('shows a newly saved budget', () async {
    await pumpEventQueue();

    final result = await cubit.save('transport', '50');
    await pumpEventQueue();

    expect(result, isA<Success<void>>());
    expect((cubit.state as BudgetsLoaded).byScope.keys, {'food', 'transport'});
  });

  test(
    'gives back the error for an invalid amount, and saves nothing',
    () async {
      await pumpEventQueue();

      final result = await cubit.save('transport', '0');

      expect((result as Failure<void>).failure, isA<ValidationFailure>());
      expect(repository.saved, hasLength(1));
    },
  );

  test('removes a budget', () async {
    await pumpEventQueue();

    await cubit.remove('food');
    await pumpEventQueue();

    expect((cubit.state as BudgetsLoaded).byScope, isEmpty);
  });

  test('ignores a second action while one is running', () async {
    await pumpEventQueue();

    final first = cubit.save('transport', '50');
    final second = await cubit.save('health', '60');
    await first;

    expect(second, isNull);
    expect(repository.saved.map((b) => b.scopeId), isNot(contains('health')));
  });

  group('messages', () {
    test('every error has its own text', () {
      final messages = {
        budgetErrorMessage('amount_required'),
        budgetErrorMessage('amount_invalid'),
        budgetErrorMessage('amount_must_be_positive'),
        budgetErrorMessage('amount_too_large'),
      };

      expect(messages, hasLength(4));
    });

    test('a storage failure gets a general message', () {
      expect(budgetSaveError(const StorageFailure()), contains('Try again'));
    });
  });
}
