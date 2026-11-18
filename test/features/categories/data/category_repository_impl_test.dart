import 'package:drift/native.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:smart_expense_tracker/core/database/app_database.dart';
import 'package:smart_expense_tracker/core/errors/storage_exception.dart';
import 'package:smart_expense_tracker/features/categories/data/repositories/category_repository_impl.dart';
import 'package:smart_expense_tracker/features/categories/domain/entities/category.dart';

void main() {
  late AppDatabase db;
  late CategoryRepositoryImpl repository;
  final clock = DateTime(2026, 11, 17, 9);

  Future<void> addExpense(String id, String categoryId) => db
      .into(db.expenses)
      .insert(
        ExpensesCompanion.insert(
          id: id,
          vendor: 'Shop',
          amountMinor: 100,
          date: DateTime(2026, 11, 16),
          categoryId: categoryId,
          createdAt: DateTime(2026, 11, 16),
          updatedAt: DateTime(2026, 11, 16),
        ),
      );

  Future<List<String>> expenseCategories() async => [
    for (final e in await db.select(db.expenses).get()) e.categoryId,
  ];

  setUp(() {
    db = AppDatabase(NativeDatabase.memory());
    repository = CategoryRepositoryImpl(db, now: () => clock);
  });

  tearDown(() => db.close());

  group('CategoryRepositoryImpl', () {
    test('starts with the default categories, sorted by name', () async {
      final categories = await repository.watchAll().first;

      expect(categories.map((c) => c.name), [
        'Bills',
        'Food',
        'Health',
        'Other',
        'Shopping',
        'Transport',
      ]);
      expect(categories.map((c) => c.id), contains('other'));
    });

    test('getAll returns the same sorted list once', () async {
      final categories = await repository.getAll();

      expect(categories.first.name, 'Bills');
      expect(categories, hasLength(6));
    });

    test('saves a new category', () async {
      await repository.save(const Category(id: 'pets', name: 'Pets'));

      final names = (await repository.getAll()).map((c) => c.name);
      expect(names, contains('Pets'));
    });

    test('renaming keeps the id and when it was created', () async {
      final before = await db.select(db.categories).get();
      final food = before.firstWhere((c) => c.id == 'food');

      await repository.save(const Category(id: 'food', name: 'Groceries'));

      final after = (await db.select(db.categories).get()).firstWhere(
        (c) => c.id == 'food',
      );
      expect(after.name, 'Groceries');
      expect(after.createdAt, food.createdAt);
      expect(after.updatedAt, clock);
    });

    test('emits again when a category is saved', () async {
      final emissions = <int>[];
      final subscription = repository.watchAll().listen(
        (list) => emissions.add(list.length),
      );

      await pumpEventQueue();
      await repository.save(const Category(id: 'pets', name: 'Pets'));
      await pumpEventQueue();
      await subscription.cancel();

      expect(emissions, [6, 7]);
    });

    test('counts the expenses that use a category', () async {
      await addExpense('a', 'food');
      await addExpense('b', 'food');
      await addExpense('c', 'transport');

      expect(await repository.countExpenses('food'), 2);
      expect(await repository.countExpenses('transport'), 1);
      expect(await repository.countExpenses('bills'), 0);
    });

    group('deleteAndMoveExpenses', () {
      test('moves the expenses, then deletes the category', () async {
        await addExpense('a', 'food');
        await addExpense('b', 'food');
        await addExpense('c', 'transport');

        final moved = await repository.deleteAndMoveExpenses(
          id: 'food',
          moveToId: 'other',
        );

        expect(moved, 2);
        expect(
          await expenseCategories(),
          unorderedEquals(['other', 'other', 'transport']),
        );
        final ids = (await repository.getAll()).map((c) => c.id);
        expect(ids, isNot(contains('food')));
      });

      test('marks the moved expenses as updated', () async {
        await addExpense('a', 'food');

        await repository.deleteAndMoveExpenses(id: 'food', moveToId: 'other');

        final expense = await db.select(db.expenses).getSingle();
        expect(expense.updatedAt, clock);
      });

      test('deletes an unused category and reports zero moved', () async {
        final moved = await repository.deleteAndMoveExpenses(
          id: 'bills',
          moveToId: 'other',
        );

        expect(moved, 0);
        final ids = (await repository.getAll()).map((c) => c.id);
        expect(ids, isNot(contains('bills')));
      });

      test('changes nothing when the move fails', () async {
        await addExpense('a', 'food');

        // The target category does not exist, so moving the expenses fails.
        await expectLater(
          repository.deleteAndMoveExpenses(id: 'food', moveToId: 'missing'),
          throwsA(isA<StorageException>()),
        );

        expect(await expenseCategories(), ['food']);
        final ids = (await repository.getAll()).map((c) => c.id);
        expect(ids, contains('food'));
      });
    });
  });
}
