import 'package:bloc_test/bloc_test.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:smart_expense_tracker/core/errors/storage_exception.dart';
import 'package:smart_expense_tracker/features/budgets/domain/entities/budget.dart';
import 'package:smart_expense_tracker/features/budgets/domain/entities/budget_progress.dart';
import 'package:smart_expense_tracker/features/dashboard/domain/entities/month_summary.dart';
import 'package:smart_expense_tracker/features/recurring/domain/entities/recurrence_frequency.dart';
import 'package:smart_expense_tracker/features/recurring/domain/entities/recurring_rule.dart';
import 'package:smart_expense_tracker/features/dashboard/presentation/cubit/summary_cubit.dart';
import 'package:smart_expense_tracker/features/dashboard/presentation/cubit/summary_state.dart';

import '../../../../support/builders.dart';
import '../../../../support/fakes.dart';

void main() {
  final now = DateTime(2026, 11, 17);
  late FakeExpenseRepository repository;
  late FakeBudgetRepository budgets;
  late FakeRecurringRepository recurring;

  SummaryCubit buildCubit() =>
      SummaryCubit(repository, budgets, recurring, now: () => now);

  const emptySummary = MonthSummary(totalMinor: 0, count: 0, categories: []);

  setUp(() {
    budgets = FakeBudgetRepository();
    recurring = FakeRecurringRepository();
    repository = FakeExpenseRepository(
      initial: [
        buildExpense(id: '1', amountMinor: 700, date: DateTime(2026, 11, 3)),
      ],
    );
  });

  group('SummaryCubit', () {
    blocTest<SummaryCubit, SummaryState>(
      'starts on the current month',
      build: buildCubit,
      expect: () => [
        SummaryLoaded(
          month: DateTime(2026, 11),
          summary: const MonthSummary(
            totalMinor: 700,
            count: 1,
            categories: [
              CategoryTotal(categoryId: 'food', totalMinor: 700, share: 1),
            ],
          ),
          canGoNext: false,
        ),
      ],
    );

    blocTest<SummaryCubit, SummaryState>(
      'moves to the previous month and back',
      build: buildCubit,
      act: (c) async {
        await pumpEventQueue();
        c.previousMonth();
        c.nextMonth();
      },
      skip: 1,
      expect: () => [
        SummaryLoaded(
          month: DateTime(2026, 10),
          summary: emptySummary,
          canGoNext: true,
        ),
        isA<SummaryLoaded>()
            .having((s) => s.month, 'month', DateTime(2026, 11))
            .having((s) => s.canGoNext, 'canGoNext', false),
      ],
    );

    blocTest<SummaryCubit, SummaryState>(
      'does not move past the current month',
      build: buildCubit,
      act: (c) async {
        await pumpEventQueue();
        c.nextMonth();
      },
      skip: 1,
      expect: () => const <SummaryState>[],
    );

    blocTest<SummaryCubit, SummaryState>(
      'updates the totals when an expense is added',
      build: buildCubit,
      act: (c) async {
        await pumpEventQueue();
        await repository.save(
          buildExpense(id: '2', amountMinor: 300, date: DateTime(2026, 11, 10)),
        );
      },
      skip: 1,
      expect: () => [
        isA<SummaryLoaded>().having((s) => s.summary.totalMinor, 'total', 1000),
      ],
    );

    group('safe to spend', () {
      const overall = Budget(scopeId: Budget.overallId, limitMinor: 100000);

      Future<SummaryCubit> start() async {
        budgets = FakeBudgetRepository(initial: const [overall]);
        final cubit = buildCubit();
        addTearDown(cubit.close);
        await pumpEventQueue();
        return cubit;
      }

      test('is worked out for the current month', () async {
        final cubit = await start();

        final safe = (cubit.state as SummaryLoaded).safeToSpend!;
        expect(safe.spentMinor, 700);
        expect(safe.daysLeft, 14); // 17 to 30 November
      });

      test('sets aside a bill still to come this month', () async {
        await recurring.save(
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
        final cubit = await start();

        expect(
          (cubit.state as SummaryLoaded).safeToSpend!.upcomingMinor,
          20000,
        );
      });

      test('is absent without an overall budget', () async {
        budgets = FakeBudgetRepository();
        final cubit = buildCubit();
        addTearDown(cubit.close);
        await pumpEventQueue();

        expect((cubit.state as SummaryLoaded).safeToSpend, isNull);
      });

      test('is absent for a past month', () async {
        final cubit = await start();

        cubit.previousMonth();

        expect((cubit.state as SummaryLoaded).safeToSpend, isNull);
      });
    });

    group('budgets', () {
      Future<SummaryCubit> start(List<Budget> list) async {
        budgets = FakeBudgetRepository(initial: list);
        final cubit = buildCubit();
        addTearDown(cubit.close);
        await pumpEventQueue();
        return cubit;
      }

      test('has none when no budget is set', () async {
        final cubit = await start(const []);

        expect((cubit.state as SummaryLoaded).budgets, isEmpty);
      });

      test('measures each budget against the month shown', () async {
        final cubit = await start(const [
          Budget(scopeId: Budget.overallId, limitMinor: 1000),
          Budget(scopeId: 'food', limitMinor: 500),
        ]);

        // 700 was spent in Food this month, and nothing elsewhere.
        final spent = (cubit.state as SummaryLoaded).budgets.map(
          (p) => (p.budget.scopeId, p.spentMinor),
        );
        expect(spent, [(Budget.overallId, 700), ('food', 700)]);
      });

      test('follows the month when it changes', () async {
        final cubit = await start(const [
          Budget(scopeId: Budget.overallId, limitMinor: 1000),
        ]);

        cubit.previousMonth();

        final loaded = cubit.state as SummaryLoaded;
        expect(loaded.month, DateTime(2026, 10));
        expect(loaded.budgets.single.spentMinor, 0);
      });

      test('updates when a budget is set', () async {
        final cubit = await start(const []);

        await budgets.save(
          const Budget(scopeId: Budget.overallId, limitMinor: 700),
        );
        await pumpEventQueue();

        final progress = (cubit.state as SummaryLoaded).budgets.single;
        expect(progress.level, BudgetLevel.near);
      });

      test('the month still shows when budgets cannot be read', () async {
        final cubit = SummaryCubit(
          repository,
          _BrokenBudgets(),
          FakeRecurringRepository(),
          now: () => now,
        );
        addTearDown(cubit.close);
        await pumpEventQueue();

        final loaded = cubit.state as SummaryLoaded;
        expect(loaded.summary.totalMinor, 700);
        expect(loaded.budgets, isEmpty);
      });
    });

    blocTest<SummaryCubit, SummaryState>(
      'emits an error state when the stream fails',
      build: () => SummaryCubit(
        ErrorExpenseRepository(),
        budgets,
        FakeRecurringRepository(),
        now: () => now,
      ),
      expect: () => const [SummaryError()],
    );
  });
}

class _BrokenBudgets extends FakeBudgetRepository {
  @override
  Stream<List<Budget>> watchAll() => Stream.error(const StorageException('x'));
}
