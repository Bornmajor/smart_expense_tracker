import 'package:equatable/equatable.dart';

import '../../../budgets/domain/entities/budget.dart';
import '../../../expenses/domain/entities/expense.dart';
import '../../../insights/domain/entities/month_comparison.dart';
import '../../../safe_to_spend/domain/entities/safe_to_spend.dart';

sealed class HomeState extends Equatable {
  const HomeState();

  @override
  List<Object?> get props => [];
}

final class HomeLoading extends HomeState {
  const HomeLoading();
}

final class HomeLoaded extends HomeState {
  const HomeLoaded({
    required this.year,
    required this.month,
    required this.monthlyTotals,
    required this.recent,
    required this.hasExpenses,
    this.overallBudget,
    this.safeToSpend,
    this.comparison,
  });

  final int year;

  /// The current month, 1 to 12.
  final int month;

  /// What was spent in each month of [year], January first.
  final List<int> monthlyTotals;

  /// The latest expenses, newest first.
  final List<Expense> recent;

  /// False for a brand new app with nothing in it yet.
  final bool hasExpenses;

  /// The overall monthly budget, or null when none is set.
  final Budget? overallBudget;

  /// What is safe to spend for the rest of the month, or null with no overall
  /// budget.
  final SafeToSpend? safeToSpend;

  /// This month against the same stretch of last month, or null when there is
  /// no spending last month to compare with.
  final MonthComparison? comparison;

  /// Spent so far this month.
  int get spentThisMonth => monthlyTotals[month - 1];

  @override
  List<Object?> get props => [
    year,
    month,
    monthlyTotals,
    recent,
    hasExpenses,
    overallBudget,
    safeToSpend,
    comparison,
  ];
}

final class HomeError extends HomeState {
  const HomeError();
}
