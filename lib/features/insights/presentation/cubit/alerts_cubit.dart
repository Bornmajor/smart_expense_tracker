import 'dart:async';

import 'package:flutter_bloc/flutter_bloc.dart';

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
    this._dismissals, {
    this._find = const FindAlerts(),
    DateTime Function()? now,
  }) : _now = now ?? DateTime.now,
       super(const []) {
    _subscription = repository.watchAll().listen((expenses) {
      _expenses = expenses;
      _publish();
    }, onError: (Object _) => emit(const []));
  }

  final AlertDismissals _dismissals;
  final FindAlerts _find;
  final DateTime Function() _now;
  late final StreamSubscription<Object?> _subscription;
  List<Expense> _expenses = const [];

  void _publish() {
    final closed = _dismissals.dismissed();
    emit([
      for (final alert in _find(_expenses, _now()))
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
    return super.close();
  }
}
