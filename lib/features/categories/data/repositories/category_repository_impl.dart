import 'package:drift/drift.dart';

import '../../../../core/database/app_database.dart';
import '../../../../core/errors/storage_exception.dart';
import '../../domain/entities/category.dart';
import '../../domain/repositories/category_repository.dart';
import '../mappers/category_mapper.dart';

class CategoryRepositoryImpl implements CategoryRepository {
  CategoryRepositoryImpl(this._db, {DateTime Function()? now})
    : _now = now ?? DateTime.now;

  final AppDatabase _db;
  final DateTime Function() _now;

  SimpleSelectStatement<$CategoriesTable, CategoryRow> _selectByName() =>
      _db.select(_db.categories)..orderBy([(t) => OrderingTerm.asc(t.name)]);

  @override
  Stream<List<Category>> watchAll() => _selectByName().watch().map(_toEntities);

  @override
  Future<List<Category>> getAll() async {
    try {
      return _toEntities(await _selectByName().get());
    } on Exception catch (error) {
      throw StorageException(error);
    }
  }

  @override
  Future<void> save(Category category) async {
    final now = _now();
    try {
      await _db
          .into(_db.categories)
          .insert(
            CategoriesCompanion.insert(
              id: category.id,
              name: category.name,
              createdAt: now,
              updatedAt: now,
            ),
            // An existing category is renamed; when it was created stays.
            onConflict: DoUpdate(
              (_) => CategoriesCompanion(
                name: Value(category.name),
                updatedAt: Value(now),
              ),
            ),
          );
    } on Exception catch (error) {
      throw StorageException(error);
    }
  }

  @override
  Future<int> countExpenses(String id) async {
    try {
      final count = _db.expenses.id.count();
      final query = _db.selectOnly(_db.expenses)
        ..addColumns([count])
        ..where(_db.expenses.categoryId.equals(id));
      return await query.map((row) => row.read(count) ?? 0).getSingle();
    } on Exception catch (error) {
      throw StorageException(error);
    }
  }

  @override
  Future<int> deleteAndMoveExpenses({
    required String id,
    required String moveToId,
  }) async {
    try {
      // One transaction: if anything fails, expenses stay where they were.
      return await _db.transaction(() async {
        final moved =
            await (_db.update(
              _db.expenses,
            )..where((e) => e.categoryId.equals(id))).write(
              ExpensesCompanion(
                categoryId: Value(moveToId),
                updatedAt: Value(_now()),
              ),
            );
        // The category's budget goes with it, or it would be left measuring a
        // category that no longer exists.
        await (_db.delete(
          _db.budgets,
        )..where((b) => b.scopeId.equals(id))).go();
        await (_db.delete(_db.categories)..where((c) => c.id.equals(id))).go();
        return moved;
      });
    } on Exception catch (error) {
      throw StorageException(error);
    }
  }

  List<Category> _toEntities(List<CategoryRow> rows) =>
      rows.map((r) => r.toEntity()).toList();
}
