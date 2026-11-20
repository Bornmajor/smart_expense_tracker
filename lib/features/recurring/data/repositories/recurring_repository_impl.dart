import 'package:drift/drift.dart';

import '../../../../core/database/app_database.dart';
import '../../../../core/errors/storage_exception.dart';
import '../../../expenses/domain/entities/expense.dart';
import '../../domain/entities/recurring_rule.dart';
import '../../domain/repositories/recurring_repository.dart';
import '../../../expenses/data/mappers/expense_mapper.dart';
import '../mappers/recurring_rule_mapper.dart';

class RecurringRepositoryImpl implements RecurringRepository {
  RecurringRepositoryImpl(this._db);

  final AppDatabase _db;

  SimpleSelectStatement<$RecurringRulesTable, RecurringRuleRow>
  _selectByDate() => _db.select(_db.recurringRules)
    ..orderBy([
      (t) => OrderingTerm.asc(t.nextDue),
      (t) => OrderingTerm.asc(t.id),
    ]);

  @override
  Stream<List<RecurringRule>> watchAll() => _selectByDate().watch().map(
    (rows) => [for (final row in rows) row.toEntity()],
  );

  @override
  Future<List<RecurringRule>> getAll() async {
    try {
      return [for (final row in await _selectByDate().get()) row.toEntity()];
    } on Exception catch (error) {
      throw StorageException(error);
    }
  }

  @override
  Future<void> save(RecurringRule rule) async {
    try {
      await _db
          .into(_db.recurringRules)
          .insertOnConflictUpdate(rule.toCompanion());
    } on Exception catch (error) {
      throw StorageException(error);
    }
  }

  @override
  Future<void> delete(String id) async {
    try {
      // Expenses it added keep existing; their marker is cleared by the
      // database (ON DELETE SET NULL).
      await (_db.delete(
        _db.recurringRules,
      )..where((r) => r.id.equals(id))).go();
    } on Exception catch (error) {
      throw StorageException(error);
    }
  }

  @override
  Future<void> recordOccurrences(
    RecurringRule rule,
    List<Expense> expenses,
  ) async {
    try {
      // One transaction: the expenses and the new next date are saved together
      // or not at all, so a crash cannot add an expense twice or skip a date.
      await _db.transaction(() async {
        for (final expense in expenses) {
          await _db.into(_db.expenses).insert(expense.toCompanion());
        }
        await (_db.update(
          _db.recurringRules,
        )..where((r) => r.id.equals(rule.id))).write(
          RecurringRulesCompanion(
            nextDue: Value(rule.nextDue),
            updatedAt: Value(rule.updatedAt),
          ),
        );
      });
    } on Exception catch (error) {
      throw StorageException(error);
    }
  }
}
