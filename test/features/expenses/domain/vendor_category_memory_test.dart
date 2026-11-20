import 'package:flutter_test/flutter_test.dart';
import 'package:smart_expense_tracker/core/errors/storage_exception.dart';
import 'package:smart_expense_tracker/features/expenses/domain/entities/expense.dart';
import 'package:smart_expense_tracker/features/expenses/domain/usecases/vendor_category_memory.dart';

import '../../../support/builders.dart';
import '../../../support/fakes.dart';

void main() {
  VendorCategoryMemory memoryOf(List<Expense> history) =>
      VendorCategoryMemory(FakeExpenseRepository(initial: history));

  test('suggests the category used before for the vendor', () async {
    final memory = memoryOf([
      buildExpense(vendor: 'Corner Cafe', categoryId: 'food'),
    ]);

    expect(await memory.categoryFor('Corner Cafe'), 'food');
  });

  test('has no suggestion for a vendor never seen', () async {
    final memory = memoryOf([
      buildExpense(vendor: 'Corner Cafe', categoryId: 'food'),
    ]);

    expect(await memory.categoryFor('Mega Mart'), isNull);
  });

  test('has no suggestion without any history', () async {
    expect(await memoryOf(const []).categoryFor('Corner Cafe'), isNull);
  });

  group('matching the vendor', () {
    test('ignores case', () async {
      final memory = memoryOf([
        buildExpense(vendor: 'DULLA STORES CHUMANI', categoryId: 'bills'),
      ]);

      expect(await memory.categoryFor('Dulla Stores Chumani'), 'bills');
    });

    test('ignores extra spaces', () async {
      final memory = memoryOf([
        buildExpense(vendor: 'Corner   Cafe ', categoryId: 'food'),
      ]);

      expect(await memory.categoryFor('  corner cafe'), 'food');
    });

    test('needs the whole name, not a part of it', () async {
      final memory = memoryOf([
        buildExpense(vendor: 'Corner Cafe Nairobi', categoryId: 'food'),
      ]);

      expect(await memory.categoryFor('Corner Cafe'), isNull);
    });

    test('has no suggestion for a blank vendor', () async {
      final memory = memoryOf([buildExpense(vendor: 'Corner Cafe')]);

      expect(await memory.categoryFor(''), isNull);
      expect(await memory.categoryFor('   '), isNull);
      expect(await memory.categoryFor(null), isNull);
    });

    test('never learns from the placeholder "Unknown" vendor', () async {
      // Blank vendors are saved as "Unknown"; they say nothing about a shop.
      final memory = memoryOf([
        buildExpense(vendor: 'Unknown', categoryId: 'transport'),
      ]);

      expect(await memory.categoryFor('Unknown'), isNull);
      expect(await memory.categoryFor('unknown'), isNull);
    });
  });

  group('when the vendor was used in more than one category', () {
    test('picks the one used most', () async {
      final memory = memoryOf([
        buildExpense(id: '1', vendor: 'Mega Mart', categoryId: 'food'),
        buildExpense(id: '2', vendor: 'Mega Mart', categoryId: 'shopping'),
        buildExpense(id: '3', vendor: 'Mega Mart', categoryId: 'shopping'),
      ]);

      expect(await memory.categoryFor('Mega Mart'), 'shopping');
    });

    test('on a tie, picks the one used most recently', () async {
      final memory = memoryOf([
        buildExpense(
          id: '1',
          vendor: 'Mega Mart',
          categoryId: 'food',
          date: DateTime(2026, 11, 1),
        ),
        buildExpense(
          id: '2',
          vendor: 'Mega Mart',
          categoryId: 'shopping',
          date: DateTime(2026, 11, 20),
        ),
      ]);

      expect(await memory.categoryFor('Mega Mart'), 'shopping');
    });

    test('the tie goes the other way when the other one is newer', () async {
      final memory = memoryOf([
        buildExpense(
          id: '1',
          vendor: 'Mega Mart',
          categoryId: 'food',
          date: DateTime(2026, 11, 20),
        ),
        buildExpense(
          id: '2',
          vendor: 'Mega Mart',
          categoryId: 'shopping',
          date: DateTime(2026, 11, 1),
        ),
      ]);

      expect(await memory.categoryFor('Mega Mart'), 'food');
    });
  });

  group('with a list of available categories', () {
    test('only suggests a category the user still has', () async {
      final memory = memoryOf([
        buildExpense(id: '1', vendor: 'Mega Mart', categoryId: 'gone'),
        buildExpense(id: '2', vendor: 'Mega Mart', categoryId: 'gone'),
        buildExpense(id: '3', vendor: 'Mega Mart', categoryId: 'food'),
      ]);

      final suggestion = await memory.categoryFor(
        'Mega Mart',
        availableIds: {'food', 'transport'},
      );

      expect(suggestion, 'food');
    });

    test(
      'has no suggestion when none of its categories are available',
      () async {
        final memory = memoryOf([
          buildExpense(vendor: 'Mega Mart', categoryId: 'gone'),
        ]);

        expect(
          await memory.categoryFor('Mega Mart', availableIds: {'food'}),
          isNull,
        );
      },
    );
  });

  test('has no suggestion when the history cannot be read', () async {
    final memory = VendorCategoryMemory(_BrokenExpenses());

    expect(await memory.categoryFor('Corner Cafe'), isNull);
  });

  test('learns from a new expense straight away', () async {
    final expenses = FakeExpenseRepository();
    final memory = VendorCategoryMemory(expenses);
    expect(await memory.categoryFor('Corner Cafe'), isNull);

    await expenses.save(
      buildExpense(vendor: 'Corner Cafe', categoryId: 'food'),
    );

    expect(await memory.categoryFor('Corner Cafe'), 'food');
  });
}

class _BrokenExpenses extends FakeExpenseRepository {
  @override
  Stream<List<Expense>> watchAll() => Stream.error(const StorageException('x'));
}
