import '../../../categories/domain/entities/category.dart';
import '../../../dashboard/domain/usecases/summarize_month.dart';
import '../../../expenses/domain/entities/expense.dart';
import '../entities/monthly_report.dart';

/// Collects one calendar month of expenses into a [MonthlyReport]: the rows,
/// oldest first, and the totals by category. The category totals come from the
/// same [SummarizeMonth] as the Summary screen, so the two always match.
class BuildMonthlyReport {
  const BuildMonthlyReport({this.summarize = const SummarizeMonth()});

  /// Shown when an expense's category no longer exists.
  static const unknownCategory = 'Uncategorized';

  final SummarizeMonth summarize;

  MonthlyReport call(
    List<Expense> expenses,
    List<Category> categories,
    DateTime month,
  ) {
    final names = {for (final c in categories) c.id: c.name};
    String nameOf(String id) => names[id] ?? unknownCategory;

    final inMonth =
        expenses
            .where(
              (e) => e.date.year == month.year && e.date.month == month.month,
            )
            .toList()
          // Oldest first; ties keep the order they were entered in.
          ..sort((a, b) {
            final byDate = a.date.compareTo(b.date);
            return byDate != 0 ? byDate : a.createdAt.compareTo(b.createdAt);
          });

    final summary = summarize(expenses, month);

    return MonthlyReport(
      month: DateTime(month.year, month.month),
      rows: [
        for (final e in inMonth)
          ReportRow(
            date: e.date,
            title: e.title,
            vendor: e.vendor,
            categoryName: nameOf(e.categoryId),
            amountMinor: e.amountMinor,
          ),
      ],
      categories: [
        for (final c in summary.categories)
          ReportCategory(
            name: nameOf(c.categoryId),
            totalMinor: c.totalMinor,
            share: c.share,
          ),
      ],
      totalMinor: summary.totalMinor,
    );
  }
}
