import '../../../../core/errors/app_failure.dart';
import '../../../../core/errors/result.dart';
import '../../../../core/errors/storage_exception.dart';
import '../repositories/budget_repository.dart';

/// Removes the budget for [scopeId], so there is no limit any more.
class RemoveBudget {
  const RemoveBudget(this._repository);

  final BudgetRepository _repository;

  Future<Result<void>> call(String scopeId) async {
    try {
      await _repository.delete(scopeId);
      return const Success(null);
    } on StorageException {
      return const Failure(StorageFailure());
    }
  }
}
