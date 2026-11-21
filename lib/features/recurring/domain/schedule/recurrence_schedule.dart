import '../entities/recurrence_frequency.dart';

/// The dates a recurring rule falls on, and which of them are due.
///
/// All dates are plain dates (midnight). They are built from year, month and
/// day, never by adding a number of hours, so a clock change cannot move one.
abstract final class RecurrenceSchedule {
  /// The most expenses added for one rule in one go. A rule can only start
  /// about a year back, so this is never reached by honest use; it stops a
  /// mistake from adding thousands.
  static const maxCatchUp = 100;

  /// The date after [current].
  ///
  /// Monthly and yearly dates are counted from [anchor], not from [current],
  /// so a rule that starts on the 31st goes 31 Jan, 28 Feb, 31 Mar, and a 29
  /// February rule falls on 28 February in years without one and returns to
  /// the 29th in leap years.
  static DateTime next(
    RecurrenceFrequency frequency,
    DateTime anchor,
    DateTime current,
  ) => switch (frequency) {
    RecurrenceFrequency.weekly => DateTime(
      current.year,
      current.month,
      current.day + 7,
    ),
    RecurrenceFrequency.monthly => _inMonth(
      current.year,
      current.month + 1,
      anchor.day,
    ),
    RecurrenceFrequency.yearly => _inMonth(
      current.year + 1,
      anchor.month,
      anchor.day,
    ),
  };

  /// The dates from [nextDue] up to and including [today], oldest first, and
  /// the first date after that, which is the rule's new "next due".
  ///
  /// When more than [maxCatchUp] are due, only that many are returned and
  /// [DueDates.nextDue] is where to carry on, so the rest follow next time.
  static DueDates dueDates({
    required RecurrenceFrequency frequency,
    required DateTime anchor,
    required DateTime nextDue,
    required DateTime today,
  }) {
    final dates = <DateTime>[];
    var date = nextDue;
    while (!date.isAfter(today) && dates.length < maxCatchUp) {
      dates.add(date);
      date = next(frequency, anchor, date);
    }
    return DueDates(dates: dates, nextDue: date);
  }

  /// [day] of the month, or the last day when the month is shorter.
  static DateTime _inMonth(int year, int month, int day) {
    // Day 0 of the next month is the last day of this one.
    final lastDay = DateTime(year, month + 1, 0).day;
    return DateTime(year, month, day > lastDay ? lastDay : day);
  }
}

class DueDates {
  const DueDates({required this.dates, required this.nextDue});

  /// Dates to add an expense for. Empty when nothing is due yet.
  final List<DateTime> dates;

  /// The date after the last one added.
  final DateTime nextDue;
}
