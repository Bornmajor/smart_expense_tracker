import '../../../expenses/domain/entities/expense.dart';
import '../entities/month_summary.dart';

/// Totals one calendar month of expenses and splits it by category.
class SummarizeMonth {
  const SummarizeMonth();

  MonthSummary call(List<Expense> expenses, DateTime month) {
    final inMonth = expenses
        .where((e) => e.date.year == month.year && e.date.month == month.month)
        .toList();

    var total = 0;
    final byCategory = <String, int>{};
    for (final expense in inMonth) {
      total += expense.amountMinor;
      byCategory.update(
        expense.categoryId,
        (sum) => sum + expense.amountMinor,
        ifAbsent: () => expense.amountMinor,
      );
    }

    final categories =
        [
          for (final entry in byCategory.entries)
            CategoryTotal(
              categoryId: entry.key,
              totalMinor: entry.value,
              share: total == 0 ? 0 : entry.value / total,
            ),
        ]..sort((a, b) {
          final byAmount = b.totalMinor.compareTo(a.totalMinor);
          return byAmount != 0
              ? byAmount
              : a.categoryId.compareTo(b.categoryId);
        });

    return MonthSummary(
      totalMinor: total,
      count: inMonth.length,
      categories: categories,
    );
  }
}
