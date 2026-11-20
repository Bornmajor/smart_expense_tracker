import '../../../expenses/domain/entities/expense.dart';
import '../entities/recurring_rule.dart';

abstract interface class RecurringRepository {
  /// Emits all rules now and whenever they change.
  Stream<List<RecurringRule>> watchAll();

  Future<List<RecurringRule>> getAll();

  /// Adds the rule, or replaces the one with the same id.
  /// Throws `StorageException` if storage fails.
  Future<void> save(RecurringRule rule);

  /// Removes the rule. Expenses it already added stay, and no longer say they
  /// repeat. Throws `StorageException` if storage fails.
  Future<void> delete(String id);

  /// Saves the expenses added for [rule] and the rule's new next date in one
  /// step: either both happen or neither does. This is what stops an expense
  /// being added twice, or a date being skipped, if the app is closed halfway.
  /// Throws `StorageException` if storage fails.
  Future<void> recordOccurrences(RecurringRule rule, List<Expense> expenses);

  /// Saves a new [rule] together with the [first] expense it comes from, in one
  /// step: either both are saved or neither is. [first] already says it
  /// belongs to the rule. Throws `StorageException` if storage fails.
  Future<void> createWithFirstExpense(RecurringRule rule, Expense first);
}
