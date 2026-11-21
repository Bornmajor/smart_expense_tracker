import 'package:equatable/equatable.dart';

import '../../../budgets/domain/entities/budget_progress.dart';
import '../../domain/entities/month_summary.dart';
import '../../../safe_to_spend/domain/entities/safe_to_spend.dart';

sealed class SummaryState extends Equatable {
  const SummaryState();

  @override
  List<Object?> get props => [];
}

final class SummaryLoading extends SummaryState {
  const SummaryLoading();
}

final class SummaryLoaded extends SummaryState {
  const SummaryLoaded({
    required this.month,
    required this.summary,
    required this.canGoNext,
    this.budgets = const [],
    this.safeToSpend,
  });

  /// First day of the month being shown.
  final DateTime month;
  final MonthSummary summary;
  final bool canGoNext;

  /// Every budget measured against this month, the ones needing attention
  /// first. Empty when no budget is set.
  final List<BudgetProgress> budgets;

  /// What is safe to spend for the rest of this month, or null for a past
  /// month or when there is no overall budget.
  final SafeToSpend? safeToSpend;

  @override
  List<Object?> get props => [month, summary, canGoNext, budgets, safeToSpend];
}

final class SummaryError extends SummaryState {
  const SummaryError();
}
