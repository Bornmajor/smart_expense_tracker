import 'dart:async';

import 'package:flutter_bloc/flutter_bloc.dart';

import '../../../budgets/domain/repositories/budget_repository.dart';
import '../../../expenses/domain/entities/expense.dart';
import '../../../expenses/domain/repositories/expense_repository.dart';
import '../../domain/entities/insight_alert.dart';
import '../../domain/repositories/alert_dismissals.dart';
import '../../domain/usecases/find_alerts.dart';

/// The alerts to show, kept up to date as expenses change. Alerts are a
/// bonus, so any problem just means none are shown.
class AlertsCubit extends Cubit<List<InsightAlert>> {
  AlertsCubit(
    ExpenseRepository repository,
    this._dismissals,
    BudgetRepository budgets, {
    this._find = const FindAlerts(),
    DateTime Function()? now,
  }) : _now = now ?? DateTime.now,
       super(const []) {
    _subscription = repository.watchAll().listen((expenses) {
      _expenses = expenses;
      _publish();
    }, onError: (Object _) => emit(const []));

    // Budgets are only needed to tell which categories have none. If they
    // cannot be read, that one nudge is simply left out.
    _budgetSubscription = budgets.watchAll().listen((list) {
      _budgeted = {
        for (final budget in list)
          if (!budget.isOverall) budget.scopeId,
      };
      _publish();
    }, onError: (Object _) {});
  }

  final AlertDismissals _dismissals;
  final FindAlerts _find;
  final DateTime Function() _now;
  late final StreamSubscription<Object?> _subscription;
  late final StreamSubscription<Object?> _budgetSubscription;
  List<Expense> _expenses = const [];

  /// The categories with a budget, or null until the budgets have been read.
  Set<String>? _budgeted;

  void _publish() {
    final closed = _dismissals.dismissed();
    emit([
      for (final alert in _find(
        _expenses,
        _now(),
        budgetedCategoryIds: _budgeted,
      ))
        if (!closed.contains(alert.id)) alert,
    ]);
  }

  Future<void> dismiss(String id) async {
    await _dismissals.dismiss(id);
    if (!isClosed) _publish();
  }

  @override
  Future<void> close() async {
    await _subscription.cancel();
    await _budgetSubscription.cancel();
    return super.close();
  }
}
