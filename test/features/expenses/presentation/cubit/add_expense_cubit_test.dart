import 'package:bloc_test/bloc_test.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:smart_expense_tracker/core/errors/app_failure.dart';
import 'package:smart_expense_tracker/core/errors/storage_exception.dart';
import 'package:smart_expense_tracker/features/expenses/domain/usecases/save_expense.dart';
import 'package:smart_expense_tracker/features/expenses/domain/validation/expense_validation.dart';
import 'package:smart_expense_tracker/features/expenses/presentation/cubit/add_expense_cubit.dart';
import 'package:smart_expense_tracker/features/expenses/presentation/cubit/add_expense_state.dart';

import '../../../../support/fakes.dart';

void main() {
  late FakeExpenseRepository repository;
  final today = DateTime(2026, 11, 17);

  AddExpenseCubit buildCubit() => AddExpenseCubit(
    SaveExpense(repository, now: () => DateTime(2026, 11, 17, 9)),
  );

  setUp(() => repository = FakeExpenseRepository());

  group('AddExpenseCubit.submit', () {
    blocTest<AddExpenseCubit, AddExpenseState>(
      'saves a valid expense and ends in the saved state',
      build: buildCubit,
      act: (cubit) => cubit.submit(
        vendor: 'Shell',
        amountText: '45.20',
        date: today,
        categoryId: 'transport',
      ),
      expect: () => const [
        AddExpenseState(status: AddExpenseStatus.saving),
        AddExpenseState(status: AddExpenseStatus.saved),
      ],
      verify: (_) {
        expect(repository.saved.single.amountMinor, 4520);
        expect(repository.saved.single.vendor, 'Shell');
      },
    );

    blocTest<AddExpenseCubit, AddExpenseState>(
      'shows field errors from the use case and stays editable',
      build: buildCubit,
      act: (cubit) => cubit.submit(
        vendor: '',
        amountText: '',
        date: today,
        categoryId: null,
      ),
      expect: () => const [
        AddExpenseState(status: AddExpenseStatus.saving),
        AddExpenseState(
          fieldErrors: {
            ExpenseField.amount: ExpenseError.amountRequired,
            ExpenseField.category: ExpenseError.categoryRequired,
          },
        ),
      ],
      verify: (_) => expect(repository.saved, isEmpty),
    );

    blocTest<AddExpenseCubit, AddExpenseState>(
      'reports text that is not a number as an invalid amount',
      build: buildCubit,
      act: (cubit) => cubit.submit(
        vendor: 'Shell',
        amountText: '1.2.3',
        date: today,
        categoryId: 'transport',
      ),
      expect: () => const [
        AddExpenseState(status: AddExpenseStatus.saving),
        AddExpenseState(
          fieldErrors: {ExpenseField.amount: ExpenseError.amountInvalid},
        ),
      ],
    );

    blocTest<AddExpenseCubit, AddExpenseState>(
      'ends in the failed state when storage fails',
      build: () {
        repository.saveError = const StorageException('disk full');
        return buildCubit();
      },
      act: (cubit) => cubit.submit(
        vendor: 'Shell',
        amountText: '10',
        date: today,
        categoryId: 'transport',
      ),
      expect: () => const [
        AddExpenseState(status: AddExpenseStatus.saving),
        AddExpenseState(
          status: AddExpenseStatus.failed,
          failure: StorageFailure(),
        ),
      ],
    );

    blocTest<AddExpenseCubit, AddExpenseState>(
      'ignores a second submit while saving',
      build: buildCubit,
      act: (cubit) async {
        final first = cubit.submit(
          vendor: 'A',
          amountText: '1',
          date: today,
          categoryId: 'food',
        );
        await cubit.submit(
          vendor: 'B',
          amountText: '2',
          date: today,
          categoryId: 'food',
        );
        await first;
      },
      verify: (_) => expect(repository.saved, hasLength(1)),
    );
  });
}
