import 'package:equatable/equatable.dart';

import '../../domain/entities/recurring_rule.dart';

sealed class RecurringState extends Equatable {
  const RecurringState();

  @override
  List<Object?> get props => [];
}

final class RecurringLoading extends RecurringState {
  const RecurringLoading();
}

final class RecurringLoaded extends RecurringState {
  const RecurringLoaded(this.rules);

  /// Every rule, the one due soonest first.
  final List<RecurringRule> rules;

  /// About what the active rules cost in a month, added up.
  int get monthlyCostMinor => rules
      .where((r) => r.isActive)
      .fold(0, (sum, r) => sum + r.monthlyCostMinor);

  @override
  List<Object?> get props => [rules];
}

final class RecurringLoadFailed extends RecurringState {
  const RecurringLoadFailed();
}
