import '../entities/budget.dart';

abstract interface class BudgetRepository {
  /// Emits all budgets now and whenever they change.
  Stream<List<Budget>> watchAll();

  /// Adds the budget, or replaces the one with the same scope.
  /// Throws `StorageException` if storage fails.
  Future<void> save(Budget budget);

  /// Removes the budget. Does nothing when there is none.
  /// Throws `StorageException` if storage fails.
  Future<void> delete(String scopeId);
}
