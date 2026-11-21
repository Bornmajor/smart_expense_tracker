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
  /// up as they are added, changed or deleted.
  ExpenseListCubit(this._repository, {this.filter})
    : super(const ExpenseListLoading()) {
    _subscription = _repository.watchAll().listen(
      (expenses) => emit(
        ExpenseListLoaded([
          for (final expense in expenses)
            if (filter?.matches(expense) ?? true) expense,
        ]),
      ),
      onError: (Object _) => emit(const ExpenseListError()),
    );
  }

  final ExpenseFilter? filter;

  final ExpenseRepository _repository;
  late final StreamSubscription<Object?> _subscription;

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
