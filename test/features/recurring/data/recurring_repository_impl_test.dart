import 'package:drift/native.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:smart_expense_tracker/core/database/app_database.dart';
import 'package:smart_expense_tracker/core/errors/storage_exception.dart';
import 'package:smart_expense_tracker/features/categories/data/repositories/category_repository_impl.dart';
import 'package:smart_expense_tracker/features/expenses/data/repositories/expense_repository_impl.dart';
import 'package:smart_expense_tracker/features/expenses/domain/entities/expense.dart';
import 'package:smart_expense_tracker/features/recurring/data/repositories/recurring_repository_impl.dart';
import 'package:smart_expense_tracker/features/recurring/domain/entities/recurrence_frequency.dart';
import 'package:smart_expense_tracker/features/recurring/domain/entities/recurring_rule.dart';
import 'package:smart_expense_tracker/features/recurring/domain/usecases/generate_due_expenses.dart';

void main() {
  late AppDatabase db;
  late RecurringRepositoryImpl repository;

  RecurringRule rule({
    String id = 'r1',
    String categoryId = 'bills',
    DateTime? nextDue,
  }) => RecurringRule(
    id: id,
    title: 'Family plan',
    vendor: 'Netflix',
    amountMinor: 120000,
    categoryId: categoryId,
    frequency: RecurrenceFrequency.monthly,
    anchor: DateTime(2026, 11, 1),
    nextDue: nextDue ?? DateTime(2026, 11, 1),
    createdAt: DateTime(2026, 10, 1),
    updatedAt: DateTime(2026, 10, 1),
  );

  Expense expense({
    String id = 'e1',
    String categoryId = 'bills',
    String? ruleId = 'r1',
  }) => Expense(
    id: id,
    vendor: 'Netflix',
    amountMinor: 120000,
    date: DateTime(2026, 11, 1),
    categoryId: categoryId,
    createdAt: DateTime(2026, 11, 20),
    updatedAt: DateTime(2026, 11, 20),
    recurringRuleId: ruleId,
  );

  Future<List<Expense>> allExpenses() =>
      ExpenseRepositoryImpl(db).watchAll().first;

  setUp(() {
    db = AppDatabase(NativeDatabase.memory());
    repository = RecurringRepositoryImpl(db);
  });

  tearDown(() => db.close());

  test('starts with no rules', () async {
    expect(await repository.watchAll().first, isEmpty);
    expect(await repository.getAll(), isEmpty);
  });

  test('saves a rule and reads it back unchanged', () async {
    await repository.save(rule());

    expect(await repository.getAll(), [rule()]);
  });

  test('saving again replaces the rule', () async {
    await repository.save(rule());
    await repository.save(rule(nextDue: DateTime(2026, 12, 1)));

    final rules = await repository.getAll();
    expect(rules, hasLength(1));
    expect(rules.single.nextDue, DateTime(2026, 12, 1));
  });

  test('lists the rule due soonest first', () async {
    await repository.save(rule(id: 'later', nextDue: DateTime(2026, 12, 20)));
    await repository.save(rule(id: 'sooner', nextDue: DateTime(2026, 11, 3)));

    expect((await repository.getAll()).map((r) => r.id), ['sooner', 'later']);
  });

  test('reads an unknown saved frequency as monthly, not a crash', () async {
    await db
        .into(db.recurringRules)
        .insert(
          RecurringRulesCompanion.insert(
            id: 'odd',
            vendor: 'Gym',
            amountMinor: 100,
            categoryId: 'bills',
            frequency: 'fortnightly',
            anchor: DateTime(2026, 11, 1),
            nextDue: DateTime(2026, 11, 1),
            createdAt: DateTime(2026, 10, 1),
            updatedAt: DateTime(2026, 10, 1),
          ),
        );

    expect(
      (await repository.getAll()).single.frequency,
      RecurrenceFrequency.monthly,
    );
  });

  group('recordOccurrences', () {
    test('saves the expenses and the new date together', () async {
      await repository.save(rule());

      await repository.recordOccurrences(rule(nextDue: DateTime(2026, 12, 1)), [
        expense(),
      ]);

      expect((await repository.getAll()).single.nextDue, DateTime(2026, 12, 1));
      final saved = (await allExpenses()).single;
      expect(saved.id, 'e1');
      expect(saved.recurringRuleId, 'r1');
    });

    test('saves nothing at all if one expense cannot be saved', () async {
      await repository.save(rule());

      // The second expense is in a category that does not exist, so the
      // database refuses it.
      await expectLater(
        repository.recordOccurrences(rule(nextDue: DateTime(2026, 12, 1)), [
          expense(id: 'e1'),
          expense(id: 'e2', categoryId: 'ghost'),
        ]),
        throwsA(isA<StorageException>()),
      );

      // The first expense was rolled back, and the date did not move, so the
      // same dates are tried again next time.
      expect(await allExpenses(), isEmpty);
      expect((await repository.getAll()).single.nextDue, DateTime(2026, 11, 1));
    });
  });

  group('the generator on a real database', () {
    GenerateDueExpenses generator() =>
        GenerateDueExpenses(repository, now: () => DateTime(2026, 11, 20, 9));

    test('adds each due expense once, however often it runs', () async {
      await repository.save(rule(nextDue: DateTime(2026, 9, 1)));

      final first = await generator()();
      final second = await generator()();
      final third = await generator()();

      expect([first, second, third], [3, 0, 0]);
      final expenses = await allExpenses();
      expect(expenses, hasLength(3));
      expect(expenses.every((e) => e.recurringRuleId == 'r1'), isTrue);
      expect((await repository.getAll()).single.nextDue, DateTime(2026, 12, 1));
    });

    test('adds the expense on the date it was due, not today', () async {
      await repository.save(rule(nextDue: DateTime(2026, 10, 1)));

      await generator()();

      final dates = (await allExpenses()).map((e) => e.date).toSet();
      expect(dates, {DateTime(2026, 10, 1), DateTime(2026, 11, 1)});
    });

    test(
      'a generated expense can be edited like any other, and keeps its marker',
      () async {
        await repository.save(rule());
        await generator()();
        final generated = (await allExpenses()).single;

        final expenses = ExpenseRepositoryImpl(db);
        await expenses.save(
          Expense(
            id: generated.id,
            vendor: generated.vendor,
            amountMinor: 99900,
            date: generated.date,
            categoryId: generated.categoryId,
            createdAt: generated.createdAt,
            updatedAt: DateTime(2026, 11, 21),
            recurringRuleId: generated.recurringRuleId,
          ),
        );

        // A later run does not add it again or undo the edit.
        await generator()();
        final all = await allExpenses();
        expect(all, hasLength(1));
        expect(all.single.amountMinor, 99900);
        expect(all.single.recurringRuleId, 'r1');
      },
    );

    test('deleting a generated expense does not bring it back', () async {
      await repository.save(rule());
      await generator()();
      final generated = (await allExpenses()).single;

      await ExpenseRepositoryImpl(db).delete(generated.id);
      await generator()();

      // This is how a user skips one: it stays skipped.
      expect(await allExpenses(), isEmpty);
    });
  });

  group('deleting a rule', () {
    test('keeps the expenses it added, and clears their marker', () async {
      await repository.save(rule());
      await repository.recordOccurrences(rule(), [expense()]);

      await repository.delete('r1');

      expect(await repository.getAll(), isEmpty);
      final kept = (await allExpenses()).single;
      expect(kept.recurringRuleId, isNull);
    });

    test('is harmless for a rule that is not there', () async {
      await repository.delete('nothing');

      expect(await repository.getAll(), isEmpty);
    });
  });

  group('deleting a category', () {
    test(
      'moves a rule in it to the other category, so nothing breaks',
      () async {
        await repository.save(rule(categoryId: 'food'));

        await CategoryRepositoryImpl(db)
            .deleteAndMoveExpenses(id: 'food', moveToId: 'other');

        expect((await repository.getAll()).single.categoryId, 'other');
      },
    );

    test('leaves rules in other categories alone', () async {
      await repository.save(rule(id: 'a', categoryId: 'food'));
      await repository.save(rule(id: 'b', categoryId: 'bills'));

      await CategoryRepositoryImpl(db)
          .deleteAndMoveExpenses(id: 'food', moveToId: 'other');

      final byId = {for (final r in await repository.getAll()) r.id: r};
      expect(byId['a']!.categoryId, 'other');
      expect(byId['b']!.categoryId, 'bills');
    });
  });
}
