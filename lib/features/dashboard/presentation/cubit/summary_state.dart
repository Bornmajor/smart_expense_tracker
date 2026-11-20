import 'package:equatable/equatable.dart';

import '../../../budgets/domain/entities/budget_progress.dart';
import '../../domain/entities/month_summary.dart';

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
  });

  /// First day of the month being shown.
  final DateTime month;
  final MonthSummary summary;
  final bool canGoNext;

  /// Every budget measured against this month, the ones needing attention
  /// first. Empty when no budget is set.
  final List<BudgetProgress> budgets;

  @override
  List<Object?> get props => [month, summary, canGoNext, budgets];
}

final class SummaryError extends SummaryState {
  const SummaryError();
}
