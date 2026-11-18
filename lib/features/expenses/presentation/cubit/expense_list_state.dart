import 'package:equatable/equatable.dart';

import '../../domain/entities/expense.dart';
import '../../domain/entities/expense_day_group.dart';

sealed class ExpenseListState extends Equatable {
  const ExpenseListState();

  @override
  List<Object?> get props => [];
}

final class ExpenseListLoading extends ExpenseListState {
  const ExpenseListLoading();
}

final class ExpenseListLoaded extends ExpenseListState {
  const ExpenseListLoaded(this.expenses);

  /// Newest first.
  final List<Expense> expenses;

  /// The same expenses grouped by day, newest day first.
  List<ExpenseDayGroup> get groups => ExpenseDayGroup.from(expenses);

  @override
  List<Object?> get props => [expenses];
}

final class ExpenseListError extends ExpenseListState {
  const ExpenseListError();
}
