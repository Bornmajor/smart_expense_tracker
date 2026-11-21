import 'package:flutter_test/flutter_test.dart';
import 'package:smart_expense_tracker/features/expenses/domain/entities/expense_filter.dart';
import 'package:smart_expense_tracker/features/expenses/presentation/cubit/expense_list_cubit.dart';
import 'package:smart_expense_tracker/features/expenses/presentation/cubit/expense_list_state.dart';

import '../../support/builders.dart';
import '../../support/fakes.dart';

void main() {
  final milk = buildExpense(
    id: 'a',
    vendor: 'Naivas Supermarket',
    title: 'Weekly shopping',
    amountMinor: 250000,
    categoryId: 'food',
    date: DateTime(2026, 11, 10, 18, 30),
  );
  final fuel = buildExpense(
    id: 'b',
    vendor: 'Shell',
    amountMinor: 500000,
    categoryId: 'transport',
    date: DateTime(2026, 11, 12),
  );
  final lunch = buildExpense(
    id: 'c',
    vendor: 'Java House',
    title: 'Lunch with team',
    amountMinor: 80000,
    categoryId: 'food',
    date: DateTime(2026, 10, 30),
  );

  bool matches(ExpenseFilter filter, expense) => filter.matches(expense);

  group('searching by words', () {
    test('finds a word in the vendor or the title, in any case', () {
      expect(matches(const ExpenseFilter(query: 'NAIVAS'), milk), isTrue);
      expect(matches(const ExpenseFilter(query: 'shopping'), milk), isTrue);
      expect(matches(const ExpenseFilter(query: 'naivas'), fuel), isFalse);
    });

    test('finds part of a word', () {
      expect(matches(const ExpenseFilter(query: 'super'), milk), isTrue);
    });

    test('needs every word, in any order and across vendor and title', () {
      expect(
        matches(const ExpenseFilter(query: 'shopping naivas'), milk),
        isTrue,
      );
      expect(
        matches(const ExpenseFilter(query: 'naivas lunch'), milk),
        isFalse,
      );
    });

    test('blank or only spaces takes everything', () {
      expect(matches(const ExpenseFilter(query: '   '), fuel), isTrue);
      expect(const ExpenseFilter(query: '  ').isEmpty, isTrue);
    });
  });

  group('dates', () {
    test('both ends are included, whatever the time of day', () {
      final filter = ExpenseFilter(
        from: DateTime(2026, 11, 10, 23, 59),
        to: DateTime(2026, 11, 12, 1),
      );

      expect(filter.matches(milk), isTrue); // the first day, at 18:30
      expect(filter.matches(fuel), isTrue); // the last day
      expect(filter.matches(lunch), isFalse);
    });

    test('one end alone is enough', () {
      expect(
        ExpenseFilter(from: DateTime(2026, 11, 1)).matches(lunch),
        isFalse,
      );
      expect(ExpenseFilter(to: DateTime(2026, 10, 31)).matches(milk), isFalse);
    });
  });

  group('amount', () {
    test('lowest and highest are both included', () {
      const filter = ExpenseFilter(minMinor: 250000, maxMinor: 500000);

      expect(filter.matches(milk), isTrue);
      expect(filter.matches(fuel), isTrue);
      expect(filter.matches(lunch), isFalse);
    });

    test('one end alone is enough', () {
      expect(const ExpenseFilter(maxMinor: 100000).matches(lunch), isTrue);
      expect(const ExpenseFilter(maxMinor: 100000).matches(milk), isFalse);
    });
  });

  test('all the parts have to pass together', () {
    const filter = ExpenseFilter(
      query: 'naivas',
      categoryId: 'food',
      minMinor: 100000,
    );

    expect(filter.matches(milk), isTrue);
    expect(filter.matches(lunch), isFalse);
  });

  group('describing a filter', () {
    test('counts the category, dates and amount, but not the words', () {
      final filter = ExpenseFilter(
        query: 'x',
        categoryId: 'food',
        from: DateTime(2026, 11, 1),
        to: DateTime(2026, 11, 5),
        minMinor: 1,
        maxMinor: 2,
      );

      expect(filter.activeCount, 3);
      expect(const ExpenseFilter(query: 'x').activeCount, 0);
    });

    test('copyWith keeps the rest and can clear a part', () {
      final filter = ExpenseFilter(
        query: 'x',
        categoryId: 'food',
        from: DateTime(2026, 11, 1),
        to: DateTime(2026, 11, 5),
        minMinor: 1,
      );

      final cleared = filter.copyWith(clearCategory: true, clearDates: true);

      expect(cleared.categoryId, isNull);
      expect(cleared.from, isNull);
      expect(cleared.query, 'x');
      expect(cleared.minMinor, 1);
      expect(filter.copyWith(query: 'y').categoryId, 'food');
    });

    test('is equal when it limits the same way', () {
      expect(
        const ExpenseFilter(query: ' Shell '),
        const ExpenseFilter(query: 'shell'),
      );
      expect(
        ExpenseFilter(from: DateTime(2026, 11, 1, 9)),
        ExpenseFilter(from: DateTime(2026, 11, 1, 20)),
      );
    });
  });

  group('ExpenseListCubit.setFilter', () {
    late FakeExpenseRepository repository;
    late ExpenseListCubit cubit;

    setUp(() async {
      repository = FakeExpenseRepository(initial: [milk, fuel, lunch]);
      cubit = ExpenseListCubit(repository);
      await pumpEventQueue();
    });

    tearDown(() => cubit.close());

    test('starts with everything and no filter', () {
      final state = cubit.state as ExpenseListLoaded;

      expect(state.expenses, hasLength(3));
      expect(state.filter.isEmpty, isTrue);
      expect(state.totalCount, 3);
    });

    test('narrows the list and remembers how many there are in all', () {
      cubit.setFilter(const ExpenseFilter(categoryId: 'food'));

      final state = cubit.state as ExpenseListLoaded;
      expect(state.expenses.map((e) => e.id).toSet(), {'a', 'c'});
      expect(state.totalCount, 3);
    });

    test('clearing the filter brings everything back', () {
      cubit.setFilter(const ExpenseFilter(query: 'shell'));
      cubit.setFilter(const ExpenseFilter());

      expect((cubit.state as ExpenseListLoaded).expenses, hasLength(3));
    });

    test('keeps up with new expenses while filtered', () async {
      cubit.setFilter(const ExpenseFilter(query: 'shell'));

      await repository.save(
        buildExpense(
          id: 'd',
          vendor: 'Shell Express',
          date: DateTime(2026, 11, 14),
        ),
      );
      await pumpEventQueue();

      expect(
        (cubit.state as ExpenseListLoaded).expenses.map((e) => e.id).toSet(),
        {'b', 'd'},
      );
    });
  });
}
