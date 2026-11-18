import 'package:bloc_test/bloc_test.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:smart_expense_tracker/core/errors/storage_exception.dart';
import 'package:smart_expense_tracker/features/expenses/domain/entities/expense.dart';
import 'package:smart_expense_tracker/features/expenses/presentation/cubit/expense_list_cubit.dart';
import 'package:smart_expense_tracker/features/expenses/presentation/cubit/expense_list_state.dart';

import '../../../../support/builders.dart';
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

    test('groups the loaded expenses by day', () {
      final loaded = ExpenseListLoaded([
        buildExpense(id: 'a', date: DateTime(2026, 11, 17), amountMinor: 300),
        buildExpense(id: 'b', date: DateTime(2026, 11, 17), amountMinor: 200),
        buildExpense(id: 'c', date: DateTime(2026, 11, 16), amountMinor: 100),
      ]);

      expect(loaded.groups.map((g) => g.totalMinor), [500, 100]);
    });
  });

  group('ExpenseListCubit.delete', () {
    blocTest<ExpenseListCubit, ExpenseListState>(
      'deletes the expense from storage, and the list follows',
      build: () {
        repository = FakeExpenseRepository(
          initial: [expense('1'), expense('2')],
        );
        return ExpenseListCubit(repository);
      },
      act: (cubit) async {
        await pumpEventQueue();
        expect(await cubit.delete(expense('1')), isTrue);
      },
      expect: () => [
        ExpenseListLoaded([expense('1'), expense('2')]),
        ExpenseListLoaded([expense('2')]),
      ],
      verify: (_) => expect(repository.saved, [expense('2')]),
    );

    blocTest<ExpenseListCubit, ExpenseListState>(
      'keeps the list as it was and reports false when storage fails',
      build: () {
        repository = FakeExpenseRepository(
          initial: [expense('1'), expense('2')],
        );
        repository.deleteError = const StorageException('disk full');
        return ExpenseListCubit(repository);
      },
      act: (cubit) async {
        await pumpEventQueue();
        expect(await cubit.delete(expense('1')), isFalse);
      },
      expect: () => [
        ExpenseListLoaded([expense('1'), expense('2')]),
      ],
      verify: (_) => expect(repository.saved, hasLength(2)),
    );
  });

  group('ExpenseListCubit.restore', () {
    blocTest<ExpenseListCubit, ExpenseListState>(
      'saves the expense again',
      build: () {
        repository = FakeExpenseRepository();
        return ExpenseListCubit(repository);
      },
      act: (cubit) async {
        await pumpEventQueue();
        expect(await cubit.restore(expense('1')), isTrue);
      },
      verify: (_) => expect(repository.saved, [expense('1')]),
    );

    test('reports false when storage fails', () async {
      repository = FakeExpenseRepository();
      repository.saveError = const StorageException('disk full');
      final cubit = ExpenseListCubit(repository);

      expect(await cubit.restore(expense('1')), isFalse);
      await cubit.close();
    });
  });
}
