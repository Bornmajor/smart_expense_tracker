import 'dart:async';

import 'package:flutter_bloc/flutter_bloc.dart';

import '../../../budgets/domain/entities/budget.dart';
import '../../../budgets/domain/repositories/budget_repository.dart';
import '../../../budgets/domain/usecases/evaluate_budgets.dart';
import '../../../expenses/domain/entities/expense.dart';
import '../../../expenses/domain/repositories/expense_repository.dart';
import '../../domain/usecases/summarize_month.dart';
import 'summary_state.dart';

class SummaryCubit extends Cubit<SummaryState> {
  SummaryCubit(
    ExpenseRepository repository,
    BudgetRepository budgets, {
    this._summarize = const SummarizeMonth(),
    this._evaluate = const EvaluateBudgets(),
    DateTime Function()? now,
  }) : _now = now ?? DateTime.now,
       super(const SummaryLoading()) {
    _month = _firstOfMonth(_now());
    _expenseSubscription = repository.watchAll().listen((expenses) {
      _expenses = expenses;
      _hasData = true;
      _emitLoaded();
    }, onError: (Object _) => emit(const SummaryError()));

    // Budgets are extra. If they cannot be read the month still shows, just
    // without progress bars.
    _budgetSubscription = budgets.watchAll().listen((list) {
      _budgets = list;
      _emitLoaded();
    }, onError: (Object _) {});
  }

  final SummarizeMonth _summarize;
  final EvaluateBudgets _evaluate;
  final DateTime Function() _now;
  late final StreamSubscription<Object?> _expenseSubscription;
  late final StreamSubscription<Object?> _budgetSubscription;
  late DateTime _month;
  List<Expense> _expenses = const [];
  List<Budget> _budgets = const [];
  bool _hasData = false;

  bool get _canGoNext => _month.isBefore(_firstOfMonth(_now()));

  void previousMonth() {
    _month = DateTime(_month.year, _month.month - 1);
    _emitLoaded();
  }

  /// Does nothing when already on the current month (no future months).
  void nextMonth() {
    if (!_canGoNext) return;
    _month = DateTime(_month.year, _month.month + 1);
    _emitLoaded();
  }

  void _emitLoaded() {
    if (!_hasData) return;
    final summary = _summarize(_expenses, _month);
    emit(
      SummaryLoaded(
        month: _month,
        summary: summary,
        canGoNext: _canGoNext,
        budgets: _evaluate(summary, _budgets),
      ),
    );
  }

  DateTime _firstOfMonth(DateTime value) => DateTime(value.year, value.month);

  @override
  Future<void> close() async {
    await _expenseSubscription.cancel();
    await _budgetSubscription.cancel();
    return super.close();
  }
}
