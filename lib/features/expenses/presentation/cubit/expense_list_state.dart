import 'package:equatable/equatable.dart';

import '../../domain/entities/expense.dart';
import '../../domain/entities/expense_day_group.dart';
import '../../domain/entities/expense_filter.dart';

sealed class ExpenseListState extends Equatable {
  const ExpenseListState();

  @override
  List<Object?> get props => [];
}

final class ExpenseListLoading extends ExpenseListState {
  const ExpenseListLoading();
}

final class ExpenseListLoaded extends ExpenseListState {
  const ExpenseListLoaded(
    this.expenses, {
    this.filter = const ExpenseFilter(),
    this.allCount,
  });

  /// The expenses that pass the [filter], newest first.
  final List<Expense> expenses;

  /// What the list is limited to. Empty when nothing limits it.
  final ExpenseFilter filter;

  /// How many expenses there are before filtering, or null when no filter is
  /// in use (it is then just [expenses].length).
  final int? allCount;

  /// How many expenses there are in all, shown or not.
  int get totalCount => allCount ?? expenses.length;

  /// The shown expenses grouped by day, newest day first.
  List<ExpenseDayGroup> get groups => ExpenseDayGroup.from(expenses);

  @override
  List<Object?> get props => [expenses, filter, allCount];
}

final class ExpenseListError extends ExpenseListState {
  const ExpenseListError();
}
