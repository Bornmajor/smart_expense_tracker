import 'dart:async';

import 'package:flutter_bloc/flutter_bloc.dart';

import '../../domain/repositories/expense_repository.dart';
import 'expense_list_state.dart';

/// Plain read: calls the repository directly, no use case needed.
class ExpenseListCubit extends Cubit<ExpenseListState> {
  ExpenseListCubit(ExpenseRepository repository)
    : super(const ExpenseListLoading()) {
    _subscription = repository.watchAll().listen(
      (expenses) => emit(ExpenseListLoaded(expenses)),
      onError: (Object _) => emit(const ExpenseListError()),
    );
  }

  late final StreamSubscription<Object?> _subscription;

  @override
  Future<void> close() async {
    await _subscription.cancel();
    return super.close();
  }
}
