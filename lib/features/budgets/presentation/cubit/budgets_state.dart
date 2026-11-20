import 'package:equatable/equatable.dart';

import '../../domain/entities/budget.dart';

sealed class BudgetsState extends Equatable {
  const BudgetsState();

  @override
  List<Object?> get props => [];
}

final class BudgetsLoading extends BudgetsState {
  const BudgetsLoading();
}

final class BudgetsLoaded extends BudgetsState {
  const BudgetsLoaded(this.byScope);

  /// The budgets, by `scopeId` (a category id, or `Budget.overallId`).
  final Map<String, Budget> byScope;

  @override
  List<Object?> get props => [byScope];
}

final class BudgetsError extends BudgetsState {
  const BudgetsError();
}
