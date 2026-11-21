import 'package:equatable/equatable.dart';

import 'expense.dart';

/// Which expenses a list shows: those in one category, in one month, or both.
/// Leaving a part out means "any".
class ExpenseFilter extends Equatable {
  const ExpenseFilter({this.categoryId, this.month});

  /// Only expenses in this category, or null for every category.
  final String? categoryId;

  /// Only expenses in the month of this date (the day does not matter), or
  /// null for every month.
  final DateTime? month;

  bool matches(Expense expense) {
    final category = categoryId;
    if (category != null && expense.categoryId != category) return false;
    final wanted = month;
    if (wanted != null &&
        (expense.date.year != wanted.year ||
            expense.date.month != wanted.month)) {
      return false;
    }
    return true;
  }

  @override
  List<Object?> get props => [categoryId, month?.year, month?.month];
}
