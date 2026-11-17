import 'package:equatable/equatable.dart';

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
  });

  /// First day of the month being shown.
  final DateTime month;
  final MonthSummary summary;
  final bool canGoNext;

  @override
  List<Object?> get props => [month, summary, canGoNext];
}

final class SummaryError extends SummaryState {
  const SummaryError();
}
