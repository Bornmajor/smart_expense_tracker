import '../../../../core/database/app_database.dart';
import '../../../../core/errors/app_failure.dart';
import '../../../../core/errors/storage_exception.dart';
import '../../../categories/domain/entities/category.dart';
import '../../domain/backup_exception.dart';
import '../../domain/entities/backup_data.dart';
import '../../domain/repositories/backup_repository.dart';

/// Reads and replaces everything in the database. Rows go in and out as the
/// JSON the database classes already know how to write and read.
class BackupRepositoryImpl implements BackupRepository {
  BackupRepositoryImpl(this._db, {DateTime Function()? now})
    : _now = now ?? DateTime.now;

  final AppDatabase _db;
  final DateTime Function() _now;

  @override
  Future<BackupData> read() async {
    try {
      final categories = await _db.select(_db.categories).get();
      final expenses = await _db.select(_db.expenses).get();
      final budgets = await _db.select(_db.budgets).get();
      final rules = await _db.select(_db.recurringRules).get();
      return BackupData(
        version: BackupData.currentVersion,
        createdAt: _now(),
        categories: [for (final r in categories) r.toJson()],
        expenses: [for (final r in expenses) r.toJson()],
        budgets: [for (final r in budgets) r.toJson()],
        recurringRules: [for (final r in rules) r.toJson()],
      );
    } on Exception catch (error) {
      throw StorageException(error);
    }
  }

  @override
  Future<void> replaceAll(BackupData data) async {
    // Read every row first, so a damaged file is refused before anything on
    // the phone is touched.
    final List<CategoryRow> categories;
    final List<ExpenseRow> expenses;
    final List<BudgetRow> budgets;
    final List<RecurringRuleRow> rules;
    try {
      categories = [for (final r in data.categories) CategoryRow.fromJson(r)];
      expenses = [for (final r in data.expenses) ExpenseRow.fromJson(r)];
      budgets = [for (final r in data.budgets) BudgetRow.fromJson(r)];
      rules = [
        for (final r in data.recurringRules) RecurringRuleRow.fromJson(r),
      ];
    } on Object {
      throw const BackupException(BackupProblem.damaged);
    }
    // Without the fallback category the app could not add an expense.
    if (!categories.any((c) => c.id == Category.fallbackId)) {
      throw const BackupException(BackupProblem.damaged);
    }

    try {
      await _db.transaction(() async {
        // Children first: expenses point at categories and rules.
        await _db.delete(_db.expenses).go();
        await _db.delete(_db.recurringRules).go();
        await _db.delete(_db.budgets).go();
        await _db.delete(_db.categories).go();

        await _db.batch((batch) {
          batch.insertAll(_db.categories, categories);
          batch.insertAll(_db.recurringRules, rules);
          batch.insertAll(_db.budgets, budgets);
          batch.insertAll(_db.expenses, expenses);
        });
      });
    } on Exception catch (error) {
      throw StorageException(error);
    }
  }
}
