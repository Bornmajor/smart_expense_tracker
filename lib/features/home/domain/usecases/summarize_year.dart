import '../../../expenses/domain/entities/expense.dart';

/// What was spent in each month of one year, for the bar chart on the home
/// screen.
class SummarizeYear {
  const SummarizeYear();

  /// Twelve totals in minor units, January first. A month with nothing spent is
  /// zero.
  List<int> call(List<Expense> expenses, int year) {
    final totals = List<int>.filled(12, 0);
    for (final expense in expenses) {
      if (expense.date.year == year) {
        totals[expense.date.month - 1] += expense.amountMinor;
      }
    }
    return totals;
  }
}
