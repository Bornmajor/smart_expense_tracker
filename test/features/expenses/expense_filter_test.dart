import 'package:flutter_test/flutter_test.dart';
import 'package:smart_expense_tracker/features/expenses/domain/entities/expense_filter.dart';
import 'package:smart_expense_tracker/features/expenses/presentation/cubit/expense_list_cubit.dart';
import 'package:smart_expense_tracker/features/expenses/presentation/cubit/expense_list_state.dart';

import '../../support/builders.dart';
import '../../support/fakes.dart';

void main() {
  final foodNov = buildExpense(
    id: 'a',
    categoryId: 'food',
    date: DateTime(2026, 11, 3),
  );
  final foodOct = buildExpense(
    id: 'b',
    categoryId: 'food',
    date: DateTime(2026, 10, 31),
  );
  final fuelNov = buildExpense(
    id: 'c',
    categoryId: 'transport',
    date: DateTime(2026, 11, 30, 23, 59),
  );

  group('ExpenseFilter', () {
    test('a category and a month together', () {
      final filter = ExpenseFilter(
        categoryId: 'food',
        month: DateTime(2026, 11),
      );

      expect(filter.matches(foodNov), isTrue);
      expect(filter.matches(foodOct), isFalse);
      expect(filter.matches(fuelNov), isFalse);
    });

    test('a month alone takes every category, to the last minute', () {
      final filter = ExpenseFilter(month: DateTime(2026, 11, 15));

      expect(filter.matches(foodNov), isTrue);
      expect(filter.matches(fuelNov), isTrue);
      expect(filter.matches(foodOct), isFalse);
    });

    test('a category alone takes every month', () {
      const filter = ExpenseFilter(categoryId: 'food');

      expect(filter.matches(foodNov), isTrue);
      expect(filter.matches(foodOct), isTrue);
      expect(filter.matches(fuelNov), isFalse);
    });

    test('no limits takes everything', () {
      expect(const ExpenseFilter().matches(fuelNov), isTrue);
    });

    test('two filters for the same month are equal whatever the day', () {
      expect(
        ExpenseFilter(month: DateTime(2026, 11, 1)),
        ExpenseFilter(month: DateTime(2026, 11, 28)),
      );
    });
  });

  group('ExpenseListCubit with a filter', () {
    test('lists only the matching expenses', () async {
      final cubit = ExpenseListCubit(
        FakeExpenseRepository(initial: [foodNov, foodOct, fuelNov]),
        filter: ExpenseFilter(categoryId: 'food', month: DateTime(2026, 11)),
      );
      addTearDown(cubit.close);
      await pumpEventQueue();

      final loaded = cubit.state as ExpenseListLoaded;
      expect(loaded.expenses.map((e) => e.id), ['a']);
    });

    test('follows a new matching expense but ignores the others', () async {
      final repository = FakeExpenseRepository(initial: [foodNov]);
      final cubit = ExpenseListCubit(
        repository,
        filter: ExpenseFilter(categoryId: 'food', month: DateTime(2026, 11)),
      );
      addTearDown(cubit.close);
      await pumpEventQueue();

      await repository.save(
        buildExpense(id: 'd', categoryId: 'food', date: DateTime(2026, 11, 9)),
      );
      await repository.save(fuelNov);
      await pumpEventQueue();

      final loaded = cubit.state as ExpenseListLoaded;
      expect(loaded.expenses.map((e) => e.id).toSet(), {'a', 'd'});
    });

    test('without a filter it lists everything, as before', () async {
      final cubit = ExpenseListCubit(
        FakeExpenseRepository(initial: [foodNov, foodOct, fuelNov]),
      );
      addTearDown(cubit.close);
      await pumpEventQueue();

      expect((cubit.state as ExpenseListLoaded).expenses, hasLength(3));
    });
  });
}
