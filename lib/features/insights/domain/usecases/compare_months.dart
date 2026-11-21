import '../../../expenses/domain/entities/expense.dart';
import '../entities/month_comparison.dart';

/// Compares this month with last month, fairly: only up to today's date in
/// each. Comparing a half-finished month with a whole one would say "much less"
/// on the second day of every month.
class CompareMonths {
  const CompareMonths();

  /// A category has to change by at least this much (in minor units, 100.00) to
  /// be named as the biggest change.
  static const minChangeMinor = 10000;

  /// Null when there is nothing to compare: no spending last month, so no
  /// percentage, or no spending in either.
  MonthComparison? call(List<Expense> expenses, DateTime today) {
    final day = DateTime(today.year, today.month, today.day);
    final lastMonth = DateTime(day.year, day.month - 1);
    final daysInLastMonth = DateTime(day.year, day.month, 0).day;
    // On the 31st, last month may have only 30 days: take all of them.
    final sameDay = day.day < daysInLastMonth ? day.day : daysInLastMonth;

    final current = <String, int>{};
    final previous = <String, int>{};
    for (final expense in expenses) {
      final date = expense.date;
      if (date.year == day.year &&
          date.month == day.month &&
          date.day <= day.day) {
        current.update(
          expense.categoryId,
          (sum) => sum + expense.amountMinor,
          ifAbsent: () => expense.amountMinor,
        );
      } else if (date.year == lastMonth.year &&
          date.month == lastMonth.month &&
          date.day <= sameDay) {
        previous.update(
          expense.categoryId,
          (sum) => sum + expense.amountMinor,
          ifAbsent: () => expense.amountMinor,
        );
      }
    }

    final currentTotal = current.values.fold(0, (a, b) => a + b);
    final previousTotal = previous.values.fold(0, (a, b) => a + b);
    if (previousTotal == 0) return null;

    String? biggest;
    var biggestChange = 0;
    for (final id in {...current.keys, ...previous.keys}) {
      final change = (current[id] ?? 0) - (previous[id] ?? 0);
      if (change.abs() >= minChangeMinor &&
          change.abs() > biggestChange.abs()) {
        biggest = id;
        biggestChange = change;
      }
    }

    return MonthComparison(
      currentMinor: currentTotal,
      previousMinor: previousTotal,
      biggestChangeCategoryId: biggest,
      biggestChangeMinor: biggestChange,
    );
  }
}
