import 'package:equatable/equatable.dart';

import '../validation/expense_rules.dart';
import 'expense.dart';

/// The expenses of one calendar day, with their total.
class ExpenseDayGroup extends Equatable {
  const ExpenseDayGroup({
    required this.day,
    required this.expenses,
    required this.totalMinor,
  });

  final DateTime day;
  final List<Expense> expenses;
  final int totalMinor;

  /// Groups expenses by calendar day. Days and the expenses inside each day
  /// keep the order of the input, so a newest-first list stays newest first.
  static List<ExpenseDayGroup> from(List<Expense> expenses) {
    final byDay = <DateTime, List<Expense>>{};
    for (final expense in expenses) {
      byDay
          .putIfAbsent(ExpenseRules.dayOnly(expense.date), () => [])
          .add(expense);
    }
    return [
      for (final entry in byDay.entries)
        ExpenseDayGroup(
          day: entry.key,
          expenses: entry.value,
          totalMinor: entry.value.fold(0, (sum, e) => sum + e.amountMinor),
        ),
    ];
  }

  @override
  List<Object?> get props => [day, expenses, totalMinor];
}
