import 'dart:async';

import 'package:flutter_bloc/flutter_bloc.dart';

import '../../../../core/errors/storage_exception.dart';
import '../../domain/entities/expense.dart';
import '../../domain/entities/expense_filter.dart';
import '../../domain/repositories/expense_repository.dart';
import 'expense_list_state.dart';

/// Plain reads and writes: calls the repository directly, no use case needed.
class ExpenseListCubit extends Cubit<ExpenseListState> {
  /// With a [filter] the list shows only the expenses that match it, and keeps
  /// up as they are added, changed or deleted. [setFilter] changes it later.
  ExpenseListCubit(this._repository, {this._filter = const ExpenseFilter()})
    : super(const ExpenseListLoading()) {
    _subscription = _repository.watchAll().listen((expenses) {
      _all = expenses;
      _publish();
    }, onError: (Object _) => emit(const ExpenseListError()));
  }

  final ExpenseRepository _repository;
  late final StreamSubscription<Object?> _subscription;
  List<Expense> _all = const [];
  ExpenseFilter _filter;

  ExpenseFilter get filter => _filter;

  /// Shows only what matches [filter], at once and as expenses change.
  void setFilter(ExpenseFilter filter) {
    if (filter == _filter) return;
    _filter = filter;
    _publish();
  }

  void _publish() {
    emit(
      ExpenseListLoaded(
        [
          for (final expense in _all)
            if (_filter.matches(expense)) expense,
        ],
        filter: _filter,
        // Only told apart from the shown ones while a filter is in use.
        allCount: _filter.isEmpty ? null : _all.length,
      ),
    );
  }

  /// Deletes the expense from storage; the list updates from the watch stream.
  /// Returns false if storage fails, and the list stays as it was.
  Future<bool> delete(Expense expense) async {
    try {
      await _repository.delete(expense.id);
      return true;
    } on StorageException {
      return false;
    }
  }

  /// Puts a deleted expense back (the Undo action). Returns false on failure.
  Future<bool> restore(Expense expense) async {
    try {
      await _repository.save(expense);
      return true;
    } on StorageException {
      return false;
    }
  }

  @override
  Future<void> close() async {
    await _subscription.cancel();
    return super.close();
  }
}
