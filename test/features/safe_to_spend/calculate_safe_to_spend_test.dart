import 'package:flutter_test/flutter_test.dart';
import 'package:smart_expense_tracker/features/budgets/domain/entities/budget.dart';
import 'package:smart_expense_tracker/features/recurring/domain/entities/recurrence_frequency.dart';
import 'package:smart_expense_tracker/features/recurring/domain/entities/recurring_rule.dart';
import 'package:smart_expense_tracker/features/safe_to_spend/domain/usecases/calculate_safe_to_spend.dart';

void main() {
  const calculate = CalculateSafeToSpend();
  const overall = Budget(scopeId: Budget.overallId, limitMinor: 6000000);

  RecurringRule rule({
    required DateTime nextDue,
    int amountMinor = 100000,
    RecurrenceFrequency frequency = RecurrenceFrequency.monthly,
    bool isActive = true,
  }) => RecurringRule(
    id: 'r${nextDue.microsecondsSinceEpoch}',
    vendor: 'Landlord',
    amountMinor: amountMinor,
    categoryId: 'bills',
    frequency: frequency,
    anchor: nextDue,
    nextDue: nextDue,
    isActive: isActive,
    createdAt: DateTime(2026, 1, 1),
    updatedAt: DateTime(2026, 1, 1),
  );

  // 20 Nov 2026: 11 days left, today included (20th to the 30th).
  final today = DateTime(2026, 11, 20, 15, 30);

  group('CalculateSafeToSpend', () {
    test('has nothing to say without an overall budget', () {
      expect(
        calculate(overall: null, spentMinor: 0, rules: const [], today: today),
        isNull,
      );
    });

    test('spreads what is left over the days that are left', () {
      final result = calculate(
        overall: overall,
        spentMinor: 2500000,
        rules: const [],
        today: today,
      )!;

      expect(result.daysLeft, 11);
      expect(result.remainingMinor, 3500000);
      expect(result.perDayMinor, 318181); // 3,500,000 / 11, rounded down
      expect(result.isOver, isFalse);
    });

    test('sets aside bills that come due before the month ends', () {
      final result = calculate(
        overall: overall,
        spentMinor: 2500000,
        rules: [rule(nextDue: DateTime(2026, 11, 25), amountMinor: 1200000)],
        today: today,
      )!;

      expect(result.upcomingMinor, 1200000);
      expect(result.remainingMinor, 2300000);
    });

    test('ignores bills due next month, today, or paused', () {
      final result = calculate(
        overall: overall,
        spentMinor: 0,
        rules: [
          rule(nextDue: DateTime(2026, 12, 1)),
          // Due today: the app adds it on opening, so it is already spent.
          rule(nextDue: DateTime(2026, 11, 20)),
          rule(nextDue: DateTime(2026, 11, 28), isActive: false),
        ],
        today: today,
      )!;

      expect(result.upcomingMinor, 0);
    });

    test('counts a weekly bill every time it falls before month end', () {
      final result = calculate(
        overall: overall,
        spentMinor: 0,
        rules: [
          rule(
            nextDue: DateTime(2026, 11, 22),
            frequency: RecurrenceFrequency.weekly,
            amountMinor: 50000,
          ),
        ],
        today: today,
      )!;

      // 22nd and 29th.
      expect(result.upcomingMinor, 100000);
    });

    test('is over when spending and bills already pass the budget', () {
      final result = calculate(
        overall: overall,
        spentMinor: 5500000,
        rules: [rule(nextDue: DateTime(2026, 11, 28), amountMinor: 1000000)],
        today: today,
      )!;

      expect(result.isOver, isTrue);
      expect(result.remainingMinor, -500000);
      expect(result.perDayMinor, 0);
    });

    test('on the last day, the whole remainder is for today', () {
      final result = calculate(
        overall: overall,
        spentMinor: 5000000,
        rules: const [],
        today: DateTime(2026, 11, 30),
      )!;

      expect(result.daysLeft, 1);
      expect(result.perDayMinor, 1000000);
    });

    test('knows how long February is', () {
      final result = calculate(
        overall: overall,
        spentMinor: 0,
        rules: const [],
        today: DateTime(2028, 2, 1),
      )!;

      expect(result.daysLeft, 29);
    });
  });
}
