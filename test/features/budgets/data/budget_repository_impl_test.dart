import 'package:drift/native.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:smart_expense_tracker/core/database/app_database.dart';
import 'package:smart_expense_tracker/features/budgets/data/repositories/budget_repository_impl.dart';
import 'package:smart_expense_tracker/features/budgets/domain/entities/budget.dart';
import 'package:smart_expense_tracker/features/categories/data/repositories/category_repository_impl.dart';

void main() {
  late AppDatabase db;
  late BudgetRepositoryImpl repository;

  setUp(() {
    db = AppDatabase(NativeDatabase.memory());
    repository = BudgetRepositoryImpl(db, now: () => DateTime(2026, 11, 20));
  });

  tearDown(() => db.close());

  test('starts with no budgets', () async {
    expect(await repository.watchAll().first, isEmpty);
  });

  test('saves a budget and reads it back', () async {
    await repository.save(const Budget(scopeId: 'food', limitMinor: 500000));

    expect(await repository.watchAll().first, const [
      Budget(scopeId: 'food', limitMinor: 500000),
    ]);
  });

  test('saving again for the same scope replaces the limit', () async {
    await repository.save(const Budget(scopeId: 'food', limitMinor: 100));
    await repository.save(const Budget(scopeId: 'food', limitMinor: 250));

    expect(await repository.watchAll().first, const [
      Budget(scopeId: 'food', limitMinor: 250),
    ]);
  });

  test('keeps the overall budget next to category budgets', () async {
    await repository.save(const Budget(scopeId: 'food', limitMinor: 100));
    await repository.save(
      const Budget(scopeId: Budget.overallId, limitMinor: 900),
    );

    final all = await repository.watchAll().first;

    expect(all.map((b) => b.scopeId).toSet(), {'food', Budget.overallId});
  });

  test('deletes a budget, and ignores one that is not there', () async {
    await repository.save(const Budget(scopeId: 'food', limitMinor: 100));

    await repository.delete('food');
    await repository.delete('food');

    expect(await repository.watchAll().first, isEmpty);
  });

  test('tells listeners when a budget changes', () async {
    final seen = <int>[];
    final subscription = repository.watchAll().listen(
      (budgets) => seen.add(budgets.length),
    );

    await pumpEventQueue();
    await repository.save(const Budget(scopeId: 'food', limitMinor: 100));
    await pumpEventQueue();
    await subscription.cancel();

    expect(seen, [0, 1]);
  });

  group('deleting a category', () {
    test('also removes that category\'s budget, and no other', () async {
      await repository.save(const Budget(scopeId: 'food', limitMinor: 100));
      await repository.save(
        const Budget(scopeId: 'transport', limitMinor: 200),
      );
      await repository.save(
        const Budget(scopeId: Budget.overallId, limitMinor: 900),
      );

      await CategoryRepositoryImpl(db)
          .deleteAndMoveExpenses(id: 'food', moveToId: 'other');

      final left = await repository.watchAll().first;
      expect(left.map((b) => b.scopeId).toSet(), {
        'transport',
        Budget.overallId,
      });
    });
  });
}
