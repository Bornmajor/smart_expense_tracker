import '../../../dashboard/domain/entities/month_summary.dart';
import '../entities/budget.dart';
import '../entities/budget_progress.dart';

/// Measures each budget against what was spent in one month.
///
/// The overall budget is measured against the month's total, and a category
/// budget against that category's spending, which is zero when nothing was
/// spent in it.
class EvaluateBudgets {
  const EvaluateBudgets();

  /// The overall budget first, then the budgets closest to (or past) their
  /// limit, so the ones that need attention come first.
  List<BudgetProgress> call(MonthSummary summary, List<Budget> budgets) {
    final spentByCategory = {
      for (final c in summary.categories) c.categoryId: c.totalMinor,
    };

    final progress = [
      for (final budget in budgets)
        BudgetProgress(
          budget: budget,
          spentMinor: budget.isOverall
              ? summary.totalMinor
              : spentByCategory[budget.scopeId] ?? 0,
        ),
    ];

    progress.sort((a, b) {
      if (a.budget.isOverall != b.budget.isOverall) {
        return a.budget.isOverall ? -1 : 1;
      }
      final byFraction = b.fraction.compareTo(a.fraction);
      return byFraction != 0
          ? byFraction
          : a.budget.scopeId.compareTo(b.budget.scopeId);
    });
    return progress;
  }
}
