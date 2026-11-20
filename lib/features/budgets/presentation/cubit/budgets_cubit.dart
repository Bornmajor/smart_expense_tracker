import 'dart:async';

import 'package:flutter_bloc/flutter_bloc.dart';

import '../../../../core/errors/result.dart';
import '../../domain/repositories/budget_repository.dart';
import '../../domain/usecases/remove_budget.dart';
import '../../domain/usecases/set_budget.dart';
import 'budgets_state.dart';

/// Lists the budgets and sets or removes them. Each action returns its result,
/// so the sheet that asked can show the outcome itself. An action started
/// while another one runs is ignored and returns null.
class BudgetsCubit extends Cubit<BudgetsState> {
  BudgetsCubit(
    BudgetRepository repository, {
    required this._setBudget,
    required this._removeBudget,
  }) : super(const BudgetsLoading()) {
    _subscription = repository.watchAll().listen(
      (budgets) => emit(BudgetsLoaded({for (final b in budgets) b.scopeId: b})),
      onError: (Object _) => emit(const BudgetsError()),
    );
  }

  final SetBudget _setBudget;
  final RemoveBudget _removeBudget;
  late final StreamSubscription<Object?> _subscription;
  bool _busy = false;

  /// Sets the limit for [scopeId] from what the user typed.
  Future<Result<void>?> save(String scopeId, String amountText) =>
      _run(() => _setBudget(scopeId: scopeId, amountText: amountText));

  Future<Result<void>?> remove(String scopeId) =>
      _run(() => _removeBudget(scopeId));

  Future<Result<void>?> _run(Future<Result<void>> Function() action) async {
    if (_busy) return null;
    _busy = true;
    try {
      return await action();
    } finally {
      _busy = false;
    }
  }

  @override
  Future<void> close() async {
    await _subscription.cancel();
    return super.close();
  }
}
