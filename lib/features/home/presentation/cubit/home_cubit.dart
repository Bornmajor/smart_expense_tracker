import 'dart:async';

import 'package:flutter_bloc/flutter_bloc.dart';

import '../../../budgets/domain/entities/budget.dart';
import '../../../budgets/domain/repositories/budget_repository.dart';
import '../../../expenses/domain/entities/expense.dart';
import '../../../expenses/domain/repositories/expense_repository.dart';
import '../../../recurring/domain/entities/recurring_rule.dart';
import '../../../recurring/domain/repositories/recurring_repository.dart';
import '../../../safe_to_spend/domain/usecases/calculate_safe_to_spend.dart';
import '../../domain/usecases/summarize_year.dart';
import 'home_state.dart';

/// Everything the home screen shows, kept up to date as expenses, budgets and
/// recurring expenses change. Budgets and recurring expenses are extras: if
/// they cannot be read, the rest still shows.
class HomeCubit extends Cubit<HomeState> {
  HomeCubit(
    ExpenseRepository expenses,
    BudgetRepository budgets,
    RecurringRepository recurring, {
    this._summarizeYear = const SummarizeYear(),
    this._safeToSpend = const CalculateSafeToSpend(),
    DateTime Function()? now,
  }) : _now = now ?? DateTime.now,
       super(const HomeLoading()) {
    _expenseSubscription = expenses.watchAll().listen((list) {
      _expenses = list;
      _hasData = true;
      _publish();
    }, onError: (Object _) => emit(const HomeError()));
    _budgetSubscription = budgets.watchAll().listen((list) {
      _budgets = list;
      _publish();
    }, onError: (Object _) {});
    _recurringSubscription = recurring.watchAll().listen((list) {
      _rules = list;
      _publish();
    }, onError: (Object _) {});
  }

  /// How many of the latest expenses the home screen lists.
  static const recentCount = 5;

  final SummarizeYear _summarizeYear;
  final CalculateSafeToSpend _safeToSpend;
  final DateTime Function() _now;
  late final StreamSubscription<Object?> _expenseSubscription;
  late final StreamSubscription<Object?> _budgetSubscription;
  late final StreamSubscription<Object?> _recurringSubscription;
  List<Expense> _expenses = const [];
  List<Budget> _budgets = const [];
  List<RecurringRule> _rules = const [];
  bool _hasData = false;

  void _publish() {
    if (!_hasData) return;
    final now = _now();
    final totals = _summarizeYear(_expenses, now.year);
    final overall = _budgets.where((b) => b.isOverall).firstOrNull;
    emit(
      HomeLoaded(
        year: now.year,
        month: now.month,
        monthlyTotals: totals,
        recent: _expenses.take(recentCount).toList(),
        hasExpenses: _expenses.isNotEmpty,
        overallBudget: overall,
        safeToSpend: _safeToSpend(
          overall: overall,
          spentMinor: totals[now.month - 1],
          rules: _rules,
          today: now,
        ),
      ),
    );
  }

  @override
  Future<void> close() async {
    await _expenseSubscription.cancel();
    await _budgetSubscription.cancel();
    await _recurringSubscription.cancel();
    return super.close();
  }
}
