import 'package:drift/drift.dart';

import '../../../../core/database/app_database.dart';
import '../../../../core/errors/storage_exception.dart';
import '../../domain/entities/expense.dart';
import '../../domain/repositories/expense_repository.dart';
import '../mappers/expense_mapper.dart';

class ExpenseRepositoryImpl implements ExpenseRepository {
  ExpenseRepositoryImpl(this._db);

  final AppDatabase _db;

  @override
  Future<void> save(Expense expense) async {
    try {
      await _db
          .into(_db.expenses)
          .insertOnConflictUpdate(expense.toCompanion());
    } on Exception catch (error) {
      throw StorageException(error);
    }
  }

  @override
  Future<void> delete(String id) async {
    try {
      await (_db.delete(_db.expenses)..where((t) => t.id.equals(id))).go();
    } on Exception catch (error) {
      throw StorageException(error);
    }
  }

  @override
  Stream<List<Expense>> watchAll() {
    final query = _db.select(_db.expenses)
      ..orderBy([
        (t) => OrderingTerm.desc(t.date),
        (t) => OrderingTerm.desc(t.createdAt),
      ]);
    return query.watch().map((rows) => rows.map((r) => r.toEntity()).toList());
  }
}
