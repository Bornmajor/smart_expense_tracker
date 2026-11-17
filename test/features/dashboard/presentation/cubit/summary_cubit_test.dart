import 'package:bloc_test/bloc_test.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:smart_expense_tracker/features/dashboard/domain/entities/month_summary.dart';
import 'package:smart_expense_tracker/features/dashboard/presentation/cubit/summary_cubit.dart';
import 'package:smart_expense_tracker/features/dashboard/presentation/cubit/summary_state.dart';

import '../../../../support/builders.dart';
import '../../../../support/fakes.dart';

void main() {
  final now = DateTime(2026, 11, 17);
  late FakeExpenseRepository repository;

  SummaryCubit buildCubit() => SummaryCubit(repository, now: () => now);

  const emptySummary = MonthSummary(totalMinor: 0, count: 0, categories: []);

  setUp(() {
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

    blocTest<SummaryCubit, SummaryState>(
      'emits an error state when the stream fails',
      build: () => SummaryCubit(ErrorExpenseRepository(), now: () => now),
      expect: () => const [SummaryError()],
    );
  });
}
