import 'dart:async';

import 'package:flutter_bloc/flutter_bloc.dart';

import '../../../expenses/domain/entities/expense.dart';
import '../../../expenses/domain/repositories/expense_repository.dart';
import '../../domain/usecases/summarize_month.dart';
import 'summary_state.dart';

class SummaryCubit extends Cubit<SummaryState> {
  SummaryCubit(
    ExpenseRepository repository, {
    this._summarize = const SummarizeMonth(),
    DateTime Function()? now,
  }) : _now = now ?? DateTime.now,
       super(const SummaryLoading()) {
    _month = _firstOfMonth(_now());
    _subscription = repository.watchAll().listen((expenses) {
      _expenses = expenses;
      _hasData = true;
      _emitLoaded();
    }, onError: (Object _) => emit(const SummaryError()));
  }

  final SummarizeMonth _summarize;
  final DateTime Function() _now;
  late final StreamSubscription<Object?> _subscription;
  late DateTime _month;
  List<Expense> _expenses = const [];
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
    emit(
      SummaryLoaded(
        month: _month,
        summary: _summarize(_expenses, _month),
        canGoNext: _canGoNext,
      ),
    );
  }

  DateTime _firstOfMonth(DateTime value) => DateTime(value.year, value.month);

  @override
  Future<void> close() async {
    await _subscription.cancel();
    return super.close();
  }
}
