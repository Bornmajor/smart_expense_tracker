import 'package:drift/drift.dart' show Value;
import 'package:drift/native.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:smart_expense_tracker/core/database/app_database.dart';
import 'package:smart_expense_tracker/core/errors/app_failure.dart';
import 'package:smart_expense_tracker/core/errors/storage_exception.dart';
import 'package:smart_expense_tracker/features/backup/data/repositories/backup_repository_impl.dart';
import 'package:smart_expense_tracker/features/backup/domain/backup_exception.dart';
import 'package:smart_expense_tracker/features/backup/domain/entities/backup_data.dart';

void main() {
  late AppDatabase source;
  late AppDatabase target;

  final day = DateTime(2026, 11, 20);

  Future<void> fill(AppDatabase db) async {
    await db
        .into(db.expenses)
        .insert(
          ExpensesCompanion.insert(
            id: 'e1',
            vendor: 'Netflix',
            amountMinor: 120000,
            date: day,
            categoryId: 'bills',
            createdAt: day,
            updatedAt: day,
            recurringRuleId: const Value('r1'),
            originalAmountMinor: const Value(900),
            originalCurrency: const Value('USD'),
          ),
        );
  }

  setUp(() async {
    source = AppDatabase(NativeDatabase.memory());
    target = AppDatabase(NativeDatabase.memory());
    // The rule has to exist before an expense can point at it.
    await source
        .into(source.recurringRules)
        .insert(
          RecurringRulesCompanion.insert(
            id: 'r1',
            vendor: 'Netflix',
            amountMinor: 120000,
            categoryId: 'bills',
            frequency: 'monthly',
            anchor: day,
            nextDue: day,
            createdAt: day,
            updatedAt: day,
          ),
        );
    await fill(source);
    await source
        .into(source.budgets)
        .insert(
          BudgetsCompanion.insert(
            scopeId: '*',
            limitMinor: 5000000,
            updatedAt: day,
          ),
        );
  });

  tearDown(() async {
    await source.close();
    await target.close();
  });

  Future<List<ExpenseRow>> expensesOf(AppDatabase db) =>
      db.select(db.expenses).get();

  test('reads everything the app keeps', () async {
    final data = await BackupRepositoryImpl(source).read();

    expect(data.expenses.single['vendor'], 'Netflix');
    expect(data.recurringRules.single['id'], 'r1');
    expect(data.budgets.single['scopeId'], '*');
    // The default categories made when the database was created.
    expect(data.categories.length, greaterThanOrEqualTo(6));
  });

  test('restores a backup into another database, field for field', () async {
    final data = await BackupRepositoryImpl(source).read();

    await BackupRepositoryImpl(target).replaceAll(data);

    final restored = (await expensesOf(target)).single;
    expect(restored.id, 'e1');
    expect(restored.amountMinor, 120000);
    expect(restored.recurringRuleId, 'r1');
    expect(restored.originalAmountMinor, 900);
    expect(restored.originalCurrency, 'USD');
    expect(restored.date, day);
    expect(
      (await target.select(target.budgets).get()).single.limitMinor,
      5000000,
    );
    expect(await target.select(target.recurringRules).get(), hasLength(1));
  });

  test('removes the data that was on the phone', () async {
    await target
        .into(target.expenses)
        .insert(
          ExpensesCompanion.insert(
            id: 'old',
            vendor: 'Old',
            amountMinor: 1,
            date: day,
            categoryId: 'food',
            createdAt: day,
            updatedAt: day,
          ),
        );
    final data = await BackupRepositoryImpl(source).read();

    await BackupRepositoryImpl(target).replaceAll(data);

    expect((await expensesOf(target)).map((e) => e.id), ['e1']);
  });

  test('refuses a file without the fallback category', () async {
    final data = await BackupRepositoryImpl(source).read();
    final broken = BackupData(
      version: data.version,
      createdAt: data.createdAt,
      categories: [
        for (final c in data.categories)
          if (c['id'] != 'other') c,
      ],
      expenses: const [],
      budgets: const [],
      recurringRules: const [],
    );

    await expectLater(
      BackupRepositoryImpl(target).replaceAll(broken),
      throwsA(
        isA<BackupException>().having(
          (e) => e.problem,
          'problem',
          BackupProblem.damaged,
        ),
      ),
    );
  });

  test('refuses damaged rows before touching anything', () async {
    await target
        .into(target.expenses)
        .insert(
          ExpensesCompanion.insert(
            id: 'keep',
            vendor: 'Keep',
            amountMinor: 1,
            date: day,
            categoryId: 'food',
            createdAt: day,
            updatedAt: day,
          ),
        );
    final data = await BackupRepositoryImpl(source).read();
    final broken = BackupData(
      version: data.version,
      createdAt: data.createdAt,
      categories: data.categories,
      expenses: const [
        {'id': 'x'},
      ],
      budgets: const [],
      recurringRules: const [],
    );

    await expectLater(
      BackupRepositoryImpl(target).replaceAll(broken),
      throwsA(isA<BackupException>()),
    );
    expect((await expensesOf(target)).single.id, 'keep');
  });

  test('changes nothing when the database refuses part of it', () async {
    await target
        .into(target.expenses)
        .insert(
          ExpensesCompanion.insert(
            id: 'keep',
            vendor: 'Keep',
            amountMinor: 1,
            date: day,
            categoryId: 'food',
            createdAt: day,
            updatedAt: day,
          ),
        );
    final data = await BackupRepositoryImpl(source).read();
    // An expense in a category that is not in the backup.
    final orphan = Map<String, Object?>.of(data.expenses.single)
      ..['categoryId'] = 'ghost';
    final broken = BackupData(
      version: data.version,
      createdAt: data.createdAt,
      categories: data.categories,
      expenses: [orphan],
      budgets: data.budgets,
      recurringRules: data.recurringRules,
    );

    await expectLater(
      BackupRepositoryImpl(target).replaceAll(broken),
      throwsA(isA<StorageException>()),
    );
    expect((await expensesOf(target)).single.id, 'keep');
  });
}
