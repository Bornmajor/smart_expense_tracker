import 'package:drift/drift.dart';

import '../../../../core/database/app_database.dart';
import '../../../../core/errors/storage_exception.dart';
import '../../domain/entities/budget.dart';
import '../../domain/repositories/budget_repository.dart';

class BudgetRepositoryImpl implements BudgetRepository {
  BudgetRepositoryImpl(this._db, {DateTime Function()? now})
    : _now = now ?? DateTime.now;

  final AppDatabase _db;
  final DateTime Function() _now;

  @override
  Stream<List<Budget>> watchAll() =>
      (_db.select(
        _db.budgets,
      )..orderBy([(t) => OrderingTerm.asc(t.scopeId)])).watch().map(
        (rows) => [
          for (final row in rows)
            Budget(scopeId: row.scopeId, limitMinor: row.limitMinor),
        ],
      );

  @override
  Future<void> save(Budget budget) async {
    try {
      await _db
          .into(_db.budgets)
          .insertOnConflictUpdate(
            BudgetsCompanion.insert(
              scopeId: budget.scopeId,
              limitMinor: budget.limitMinor,
              updatedAt: _now(),
            ),
          );
    } on Exception catch (error) {
      throw StorageException(error);
    }
  }

  @override
  Future<void> delete(String scopeId) async {
    try {
      await (_db.delete(
        _db.budgets,
      )..where((b) => b.scopeId.equals(scopeId))).go();
    } on Exception catch (error) {
      throw StorageException(error);
    }
  }
}
