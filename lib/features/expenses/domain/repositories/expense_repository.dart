import '../entities/expense.dart';

abstract interface class ExpenseRepository {
  /// Inserts the expense, or replaces it when the id already exists.
  /// Throws `StorageException` if storage fails.
  Future<void> save(Expense expense);

  /// Emits all expenses (newest first) now and whenever they change.
  Stream<List<Expense>> watchAll();
}
