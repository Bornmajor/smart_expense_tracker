import '../../../../core/errors/app_failure.dart';
import '../../../../core/errors/result.dart';
import '../../../../core/errors/storage_exception.dart';
import '../../../../core/utils/money.dart';
import '../entities/budget.dart';
import '../repositories/budget_repository.dart';
import '../validation/budget_rules.dart';

/// Checks a limit typed by the user and saves it as the budget for [scopeId]
/// (a category id, or `Budget.overallId`). An existing budget is replaced.
class SetBudget {
  const SetBudget(this._repository);

  final BudgetRepository _repository;

  Future<Result<void>> call({
    required String scopeId,
    required String amountText,
  }) async {
    final minor = Money.tryParse(amountText);
    final error = BudgetRules.validateLimit(amountText, minor);
    if (error != null) {
      return Failure(ValidationFailure({BudgetField.amount: error}));
    }

    try {
      await _repository.save(Budget(scopeId: scopeId, limitMinor: minor!));
      return const Success(null);
    } on StorageException {
      return const Failure(StorageFailure());
    }
  }
}
