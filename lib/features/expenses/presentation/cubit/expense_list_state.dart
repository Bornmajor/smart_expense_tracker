import 'package:equatable/equatable.dart';

import '../../domain/entities/expense.dart';

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

  final List<Expense> expenses;

  @override
  List<Object?> get props => [expenses];
}

final class ExpenseListError extends ExpenseListState {
  const ExpenseListError();
}
