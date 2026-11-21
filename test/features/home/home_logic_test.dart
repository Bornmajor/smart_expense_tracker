import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:smart_expense_tracker/features/budgets/domain/entities/budget.dart';
import 'package:smart_expense_tracker/features/home/domain/usecases/summarize_year.dart';
import 'package:smart_expense_tracker/features/home/presentation/cubit/home_cubit.dart';
import 'package:smart_expense_tracker/features/home/presentation/cubit/home_state.dart';
import 'package:smart_expense_tracker/features/home/presentation/widgets/greeting_header.dart';
import 'package:smart_expense_tracker/features/profile/data/repositories/profile_repository_impl.dart';
import 'package:smart_expense_tracker/features/profile/presentation/cubit/profile_cubit.dart';
import 'package:smart_expense_tracker/features/recurring/domain/entities/recurrence_frequency.dart';
import 'package:smart_expense_tracker/features/recurring/domain/entities/recurring_rule.dart';

import '../../support/builders.dart';
import '../../support/fakes.dart';

void main() {
  // Saturday 21 November 2026.
  final now = DateTime(2026, 11, 21, 9);

  group('SummarizeYear', () {
    test('adds each month up, January first', () {
      final totals = const SummarizeYear()([
        buildExpense(id: '1', amountMinor: 100, date: DateTime(2026, 1, 5)),
        buildExpense(id: '2', amountMinor: 250, date: DateTime(2026, 1, 31)),
        buildExpense(id: '3', amountMinor: 400, date: DateTime(2026, 11, 2)),
      ], 2026);

      expect(totals, hasLength(12));
      expect(totals[0], 350);
      expect(totals[10], 400);
      expect(totals.where((t) => t == 0), hasLength(10));
    });

    test('leaves out other years', () {
      final totals = const SummarizeYear()([
        buildExpense(id: '1', amountMinor: 100, date: DateTime(2025, 12, 31)),
        buildExpense(id: '2', amountMinor: 200, date: DateTime(2027, 1, 1)),
      ], 2026);

      expect(totals.every((t) => t == 0), isTrue);
    });

    test('an empty list is twelve zeros', () {
      expect(const SummarizeYear()(const [], 2026), List.filled(12, 0));
    });
  });

  group('the greeting', () {
    test('follows the time of day', () {
      expect(
        GreetingHeader.greeting(DateTime(2026, 1, 1, 6), ''),
        'Good morning',
      );
      expect(
        GreetingHeader.greeting(DateTime(2026, 1, 1, 12), ''),
        'Good afternoon',
      );
      expect(
        GreetingHeader.greeting(DateTime(2026, 1, 1, 16, 59), ''),
        'Good afternoon',
      );
      expect(
        GreetingHeader.greeting(DateTime(2026, 1, 1, 17), ''),
        'Good evening',
      );
      expect(
        GreetingHeader.greeting(DateTime(2026, 1, 1, 23), ''),
        'Good evening',
      );
    });

    test('adds the name when there is one', () {
      expect(
        GreetingHeader.greeting(DateTime(2026, 1, 1, 9), 'Maja'),
        'Good morning, Maja',
      );
    });
  });

  group('HomeCubit', () {
    late FakeExpenseRepository expenses;
    late FakeBudgetRepository budgets;
    late FakeRecurringRepository recurring;

    Future<HomeLoaded> load() async {
      final cubit = HomeCubit(expenses, budgets, recurring, now: () => now);
      addTearDown(cubit.close);
      await pumpEventQueue();
      return cubit.state as HomeLoaded;
    }

    setUp(() {
      budgets = FakeBudgetRepository();
      recurring = FakeRecurringRepository();
      expenses = FakeExpenseRepository(
        initial: [
          for (var i = 1; i <= 7; i++)
            buildExpense(
              id: 'e$i',
              amountMinor: 1000,
              date: DateTime(2026, 11, i),
            ),
          buildExpense(id: 'old', amountMinor: 500, date: DateTime(2026, 3, 9)),
        ],
      );
    });

    test('knows this month, the year and the latest five expenses', () async {
      final state = await load();

      expect(state.year, 2026);
      expect(state.month, 11);
      expect(state.spentThisMonth, 7000);
      expect(state.monthlyTotals[2], 500);
      expect(state.recent, hasLength(HomeCubit.recentCount));
      expect(state.hasExpenses, isTrue);
    });

    test('has no budget numbers without an overall budget', () async {
      final state = await load();

      expect(state.overallBudget, isNull);
      expect(state.safeToSpend, isNull);
    });

    test(
      'works out what is safe to spend with a budget and a bill coming',
      () async {
        budgets = FakeBudgetRepository(
          initial: const [
            Budget(scopeId: Budget.overallId, limitMinor: 100000),
          ],
        );
        recurring = FakeRecurringRepository()
          ..rules.add(
            RecurringRule(
              id: 'r1',
              vendor: 'Landlord',
              amountMinor: 20000,
              categoryId: 'bills',
              frequency: RecurrenceFrequency.monthly,
              anchor: DateTime(2026, 11, 25),
              nextDue: DateTime(2026, 11, 25),
              createdAt: DateTime(2026, 10, 1),
              updatedAt: DateTime(2026, 10, 1),
            ),
          );

        final state = await load();

        final safe = state.safeToSpend!;
        expect(safe.spentMinor, 7000);
        expect(safe.upcomingMinor, 20000);
        expect(safe.daysLeft, 10);
      },
    );

    test('a new app has no expenses', () async {
      expenses = FakeExpenseRepository();

      final state = await load();

      expect(state.hasExpenses, isFalse);
      expect(state.recent, isEmpty);
      expect(state.spentThisMonth, 0);
    });

    test('follows a new expense', () async {
      final cubit = HomeCubit(expenses, budgets, recurring, now: () => now);
      addTearDown(cubit.close);
      await pumpEventQueue();

      await expenses.save(
        buildExpense(
          id: 'new',
          amountMinor: 3000,
          date: DateTime(2026, 11, 20),
        ),
      );
      await pumpEventQueue();

      expect((cubit.state as HomeLoaded).spentThisMonth, 10000);
    });
  });

  group('the name', () {
    late SharedPreferences preferences;

    setUp(() async {
      SharedPreferences.setMockInitialValues({});
      preferences = await SharedPreferences.getInstance();
    });

    test('is tidied before it is kept', () async {
      final repository = ProfileRepositoryImpl(preferences);

      await repository.setName('  Maja   Lee ');

      expect(repository.name, 'Maja Lee');
    });

    test('a blank name clears it', () async {
      final repository = ProfileRepositoryImpl(preferences);
      await repository.setName('Maja');

      await repository.setName('   ');

      expect(repository.name, isEmpty);
    });

    test('a very long name is cut', () async {
      final repository = ProfileRepositoryImpl(preferences);

      await repository.setName('A' * 80);

      expect(repository.name.length, ProfileRepositoryImpl.maxLength);
    });

    test('the cubit holds the saved name', () async {
      final cubit = ProfileCubit(ProfileRepositoryImpl(preferences));
      addTearDown(cubit.close);
      expect(cubit.state, isEmpty);

      await cubit.setName(' Sam ');

      expect(cubit.state, 'Sam');
    });
  });
}
