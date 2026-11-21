import '../../../budgets/domain/entities/budget.dart';
import '../../../recurring/domain/entities/recurring_rule.dart';
import '../../../recurring/domain/schedule/recurrence_schedule.dart';
import '../entities/safe_to_spend.dart';

/// Works out what is safe to spend for the rest of the current month.
class CalculateSafeToSpend {
  const CalculateSafeToSpend();

  /// Null when there is no overall budget, since there is then no limit to
  /// stay under. [spentMinor] is the month's total so far. [today] is a plain
  /// date; its day is counted as still to spend.
  SafeToSpend? call({
    required Budget? overall,
    required int spentMinor,
    required List<RecurringRule> rules,
    required DateTime today,
  }) {
    if (overall == null) return null;

    final day = DateTime(today.year, today.month, today.day);
    final lastDay = DateTime(day.year, day.month + 1, 0);

    return SafeToSpend(
      limitMinor: overall.limitMinor,
      spentMinor: spentMinor,
      upcomingMinor: _upcoming(rules, day, lastDay),
      daysLeft: lastDay.day - day.day + 1,
    );
  }

  /// The bills that come due after [today] and up to the end of the month. A
  /// bill due today is added by the app as soon as it opens, so it is already
  /// part of what was spent.
  int _upcoming(List<RecurringRule> rules, DateTime today, DateTime lastDay) {
    var total = 0;
    for (final rule in rules) {
      if (!rule.isActive) continue;
      var due = rule.nextDue;
      while (!due.isAfter(lastDay)) {
        if (due.isAfter(today)) total += rule.amountMinor;
        due = RecurrenceSchedule.next(rule.frequency, rule.anchor, due);
      }
    }
    return total;
  }
}
