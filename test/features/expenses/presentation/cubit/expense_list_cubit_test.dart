import 'package:bloc_test/bloc_test.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:smart_expense_tracker/features/expenses/domain/entities/expense.dart';
import 'package:smart_expense_tracker/features/expenses/presentation/cubit/expense_list_cubit.dart';
import 'package:smart_expense_tracker/features/expenses/presentation/cubit/expense_list_state.dart';

import '../../../../support/fakes.dart';

void main() {
  late FakeExpenseRepository repository;

  Expense expense(String id) => Expense(
    id: id,
    vendor: 'Vendor $id',
    amountMinor: 500,
    date: DateTime(2026, 11, 16),
    categoryId: 'food',
    createdAt: DateTime(2026, 11, 16),
    updatedAt: DateTime(2026, 11, 16),
  );

  group('ExpenseListCubit', () {
    blocTest<ExpenseListCubit, ExpenseListState>(
      'emits the stored expenses',
      build: () {
        repository = FakeExpenseRepository(initial: [expense('1')]);
        return ExpenseListCubit(repository);
      },
      expect: () => [
        ExpenseListLoaded([expense('1')]),
      ],
    );

    blocTest<ExpenseListCubit, ExpenseListState>(
      'emits a new list when an expense is saved',
      build: () {
        repository = FakeExpenseRepository(initial: [expense('1')]);
        return ExpenseListCubit(repository);
      },
      act: (_) async {
        await pumpEventQueue();
        await repository.save(expense('2'));
      },
      expect: () => [
        ExpenseListLoaded([expense('1')]),
        ExpenseListLoaded([expense('1'), expense('2')]),
      ],
    );

    blocTest<ExpenseListCubit, ExpenseListState>(
      'emits an error state when the stream fails',
      build: () => ExpenseListCubit(ErrorExpenseRepository()),
      expect: () => const [ExpenseListError()],
    );
  });
}
