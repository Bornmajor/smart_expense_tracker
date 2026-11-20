import 'package:flutter_test/flutter_test.dart';
import 'package:smart_expense_tracker/features/recurring/domain/entities/recurrence_frequency.dart';
import 'package:smart_expense_tracker/features/recurring/domain/schedule/recurrence_schedule.dart';

void main() {
  DateTime next(RecurrenceFrequency f, DateTime anchor, DateTime current) =>
      RecurrenceSchedule.next(f, anchor, current);

  group('weekly', () {
    final anchor = DateTime(2026, 11, 2);

    test('is seven days later', () {
      expect(
        next(RecurrenceFrequency.weekly, anchor, DateTime(2026, 11, 2)),
        DateTime(2026, 11, 9),
      );
    });

    test('carries over the end of a month and a year', () {
      expect(
        next(RecurrenceFrequency.weekly, anchor, DateTime(2026, 11, 28)),
        DateTime(2026, 12, 5),
      );
      expect(
        next(RecurrenceFrequency.weekly, anchor, DateTime(2026, 12, 30)),
        DateTime(2027, 1, 6),
      );
    });

    test('stays on the same weekday when the clocks change', () {
      // Counting in days, not hours, so daylight saving cannot move it.
      var date = DateTime(2026, 3, 1);
      for (var i = 0; i < 10; i++) {
        date = next(RecurrenceFrequency.weekly, anchor, date);
      }
      expect(date, DateTime(2026, 5, 10));
      expect(date.hour, 0);
    });
  });

  group('monthly', () {
    test('keeps the same day of the month', () {
      final anchor = DateTime(2026, 1, 15);

      expect(
        next(RecurrenceFrequency.monthly, anchor, DateTime(2026, 1, 15)),
        DateTime(2026, 2, 15),
      );
    });

    test('a rule on the 31st falls on the last day of shorter months', () {
      final anchor = DateTime(2026, 1, 31);

      expect(
        next(RecurrenceFrequency.monthly, anchor, DateTime(2026, 1, 31)),
        DateTime(2026, 2, 28),
      );
      expect(
        next(RecurrenceFrequency.monthly, anchor, DateTime(2026, 4, 30)),
        DateTime(2026, 5, 31),
      );
    });

    test('and goes back to the 31st afterwards, without drifting', () {
      final anchor = DateTime(2026, 1, 31);

      // Feb 28 -> Mar 31, not Mar 28.
      expect(
        next(RecurrenceFrequency.monthly, anchor, DateTime(2026, 2, 28)),
        DateTime(2026, 3, 31),
      );
    });

    test('uses 29 February in a leap year', () {
      final anchor = DateTime(2028, 1, 31);

      expect(
        next(RecurrenceFrequency.monthly, anchor, DateTime(2028, 1, 31)),
        DateTime(2028, 2, 29),
      );
    });

    test('carries over the end of the year', () {
      final anchor = DateTime(2026, 12, 15);

      expect(
        next(RecurrenceFrequency.monthly, anchor, DateTime(2026, 12, 15)),
        DateTime(2027, 1, 15),
      );
    });

    test('the 30th falls on the last day of February, and returns', () {
      final anchor = DateTime(2026, 1, 30);

      expect(
        next(RecurrenceFrequency.monthly, anchor, DateTime(2026, 1, 30)),
        DateTime(2026, 2, 28),
      );
      expect(
        next(RecurrenceFrequency.monthly, anchor, DateTime(2026, 2, 28)),
        DateTime(2026, 3, 30),
      );
    });
  });

  group('yearly', () {
    test('is the same day a year later', () {
      final anchor = DateTime(2026, 6, 10);

      expect(
        next(RecurrenceFrequency.yearly, anchor, DateTime(2026, 6, 10)),
        DateTime(2027, 6, 10),
      );
    });

    test('29 February falls on the 28th in years without one', () {
      final anchor = DateTime(2028, 2, 29);

      expect(
        next(RecurrenceFrequency.yearly, anchor, DateTime(2028, 2, 29)),
        DateTime(2029, 2, 28),
      );
      expect(
        next(RecurrenceFrequency.yearly, anchor, DateTime(2031, 2, 28)),
        DateTime(2032, 2, 29),
      );
    });
  });

  group('dueDates', () {
    DueDates due(
      RecurrenceFrequency f,
      DateTime anchor,
      DateTime nextDue,
      DateTime today,
    ) => RecurrenceSchedule.dueDates(
      frequency: f,
      anchor: anchor,
      nextDue: nextDue,
      today: today,
    );

    test('has nothing when the next date is still ahead', () {
      final result = due(
        RecurrenceFrequency.monthly,
        DateTime(2026, 12, 1),
        DateTime(2026, 12, 1),
        DateTime(2026, 11, 20),
      );

      expect(result.dates, isEmpty);
      expect(result.nextDue, DateTime(2026, 12, 1));
    });

    test('includes a date that is today', () {
      final result = due(
        RecurrenceFrequency.monthly,
        DateTime(2026, 11, 20),
        DateTime(2026, 11, 20),
        DateTime(2026, 11, 20),
      );

      expect(result.dates, [DateTime(2026, 11, 20)]);
      expect(result.nextDue, DateTime(2026, 12, 20));
    });

    test('catches up on every missed date, oldest first', () {
      final result = due(
        RecurrenceFrequency.monthly,
        DateTime(2026, 8, 1),
        DateTime(2026, 8, 1),
        DateTime(2026, 11, 20),
      );

      expect(result.dates, [
        DateTime(2026, 8, 1),
        DateTime(2026, 9, 1),
        DateTime(2026, 10, 1),
        DateTime(2026, 11, 1),
      ]);
      expect(result.nextDue, DateTime(2026, 12, 1));
    });

    test('a month-end rule catches up on the right days', () {
      final anchor = DateTime(2026, 1, 31);

      final result = due(
        RecurrenceFrequency.monthly,
        anchor,
        DateTime(2026, 1, 31),
        DateTime(2026, 4, 30),
      );

      expect(result.dates, [
        DateTime(2026, 1, 31),
        DateTime(2026, 2, 28),
        DateTime(2026, 3, 31),
        DateTime(2026, 4, 30),
      ]);
      expect(result.nextDue, DateTime(2026, 5, 31));
    });

    test('stops at the limit, and says where to carry on', () {
      final result = due(
        RecurrenceFrequency.weekly,
        DateTime(2020, 1, 1),
        DateTime(2020, 1, 1),
        DateTime(2026, 11, 20),
      );

      expect(result.dates, hasLength(RecurrenceSchedule.maxCatchUp));
      // The rest is left for the next run: the next date is the one after the
      // last one added, and it is still in the past.
      expect(result.nextDue, DateTime(2020, 1, 1 + 7 * 100));
      expect(result.nextDue.isBefore(DateTime(2026, 11, 20)), isTrue);
    });
  });
}
