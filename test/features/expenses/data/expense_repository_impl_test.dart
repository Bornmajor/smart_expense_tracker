import 'package:drift/drift.dart' show DeleteStatement, Table, TableInfo;
import 'package:drift/native.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:smart_expense_tracker/core/database/app_database.dart';
import 'package:smart_expense_tracker/core/errors/storage_exception.dart';
import 'package:smart_expense_tracker/features/expenses/data/repositories/expense_repository_impl.dart';
import 'package:smart_expense_tracker/features/expenses/domain/entities/expense.dart';

void main() {
  late AppDatabase db;
  late ExpenseRepositoryImpl repository;

  Expense expense({
    String id = 'e1',
    String vendor = 'Shell',
    int amountMinor = 4520,
    DateTime? date,
    String categoryId = 'transport',
    DateTime? createdAt,
  }) => Expense(
    id: id,
    vendor: vendor,
    amountMinor: amountMinor,
    date: date ?? DateTime(2026, 11, 16),
    categoryId: categoryId,
    createdAt: createdAt ?? DateTime(2026, 11, 16, 9),
    updatedAt: createdAt ?? DateTime(2026, 11, 16, 9),
  );

  setUp(() {
    db = AppDatabase(NativeDatabase.memory());
    repository = ExpenseRepositoryImpl(db);
  });

  tearDown(() => db.close());

  group('ExpenseRepositoryImpl', () {
    test('returns a saved expense unchanged', () async {
      final saved = expense();

      await repository.save(saved);

      expect(await repository.watchAll().first, [saved]);
    });

    test('keeps the title, and an empty one when there is none', () async {
      await repository.save(
        Expense(
          id: 'with',
          title: 'Lunch with team',
          vendor: 'Cafe',
          amountMinor: 900,
          date: DateTime(2026, 11, 16),
          categoryId: 'food',
          createdAt: DateTime(2026, 11, 16, 9),
          updatedAt: DateTime(2026, 11, 16, 9),
        ),
      );
      await repository.save(expense(id: 'without'));

      final byId = {
        for (final e in await repository.watchAll().first) e.id: e.title,
      };
      expect(byId, {'with': 'Lunch with team', 'without': ''});
    });

    test('lists the newest date first, then the newest entry', () async {
      final older = expense(id: 'old', date: DateTime(2026, 11, 1));
      final newerEarly = expense(
        id: 'a',
        date: DateTime(2026, 11, 10),
        createdAt: DateTime(2026, 11, 10, 8),
      );
      final newerLate = expense(
        id: 'b',
        date: DateTime(2026, 11, 10),
        createdAt: DateTime(2026, 11, 10, 18),
      );

      for (final e in [older, newerEarly, newerLate]) {
        await repository.save(e);
      }

      final ids = (await repository.watchAll().first).map((e) => e.id);
      expect(ids, ['b', 'a', 'old']);
    });

    test('replaces an expense that has the same id', () async {
      await repository.save(expense(vendor: 'Shell'));
      await repository.save(expense(vendor: 'BP', amountMinor: 999));

      final all = await repository.watchAll().first;
      expect(all, hasLength(1));
      expect(all.single.vendor, 'BP');
      expect(all.single.amountMinor, 999);
    });

    test('emits again when a new expense is saved', () async {
      final emissions = <int>[];
      final subscription = repository.watchAll().listen(
        (list) => emissions.add(list.length),
      );

      await pumpEventQueue();
      await repository.save(expense());
      await pumpEventQueue();
      await subscription.cancel();

      expect(emissions, [0, 1]);
    });

    test('deletes only the expense with that id', () async {
      await repository.save(expense(id: 'keep'));
      await repository.save(expense(id: 'drop'));

      await repository.delete('drop');

      final ids = (await repository.watchAll().first).map((e) => e.id);
      expect(ids, ['keep']);
    });

    test('ignores a delete for an id that does not exist', () async {
      await repository.save(expense());

      await repository.delete('missing');

      expect(await repository.watchAll().first, hasLength(1));
    });

    test('emits again when an expense is deleted', () async {
      await repository.save(expense());
      final emissions = <int>[];
      final subscription = repository.watchAll().listen(
        (list) => emissions.add(list.length),
      );

      await pumpEventQueue();
      await repository.delete('e1');
      await pumpEventQueue();
      await subscription.cancel();

      expect(emissions, [1, 0]);
    });

    test('wraps a database error in a StorageException on delete', () async {
      final broken = _BrokenDatabase();
      addTearDown(broken.close);

      expect(
        ExpenseRepositoryImpl(broken).delete('e1'),
        throwsA(isA<StorageException>()),
      );
    });

    test('throws a StorageException for an unknown category', () async {
      expect(
        repository.save(expense(categoryId: 'does-not-exist')),
        throwsA(isA<StorageException>()),
      );
    });
  });
}

/// A database whose deletes always fail, to test error handling.
class _BrokenDatabase extends AppDatabase {
  _BrokenDatabase() : super(NativeDatabase.memory());

  @override
  DeleteStatement<T, D> delete<T extends Table, D>(TableInfo<T, D> table) =>
      throw Exception('boom');
}
