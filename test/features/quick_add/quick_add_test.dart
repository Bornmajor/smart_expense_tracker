import 'package:flutter_test/flutter_test.dart';
import 'package:smart_expense_tracker/features/categories/domain/entities/category.dart';
import 'package:smart_expense_tracker/features/expenses/domain/usecases/vendor_category_memory.dart';
import 'package:smart_expense_tracker/features/quick_add/domain/usecases/parse_quick_add.dart';
import 'package:smart_expense_tracker/features/quick_add/domain/usecases/quick_add.dart';

import '../../support/builders.dart';
import '../../support/fakes.dart';

void main() {
  late FakeExpenseRepository expenses;
  late FakeCategoryRepository categories;

  QuickAdd build() => QuickAdd(
    categories: categories,
    memory: VendorCategoryMemory(expenses),
    parse: ParseQuickAdd(now: () => DateTime(2026, 11, 21)),
  );

  setUp(() {
    expenses = FakeExpenseRepository();
    categories = FakeCategoryRepository(const [
      Category(id: 'food', name: 'Food'),
      Category(id: 'transport', name: 'Transport'),
      Category(id: 'other', name: 'Other'),
    ]);
  });

  test('reads the line and keeps what was typed', () async {
    final result = await build()('  lunch 350 at java yesterday ');

    expect(result.text, 'lunch 350 at java yesterday');
    expect(result.draft.amountMinor, 35000);
    expect(result.draft.vendor, 'Java');
    expect(result.draft.title, 'Lunch');
    expect(result.draft.date, DateTime(2026, 11, 20));
  });

  test('suggests a category from the words', () async {
    final result = await build()('fuel 3000 at shell');

    expect(result.suggestedCategoryId, 'transport');
    expect(result.categoryFromHistory, isFalse);
  });

  test(
    'what the user did with this vendor before wins over the words',
    () async {
      // Java is a "food" word nowhere; the user filed it under transport once.
      expenses = FakeExpenseRepository(
        initial: [
          buildExpense(id: '1', vendor: 'Java', categoryId: 'transport'),
        ],
      );

      final result = await build()('lunch 350 at java');

      expect(result.suggestedCategoryId, 'transport');
      expect(result.categoryFromHistory, isTrue);
    },
  );

  test('never suggests a category the user does not have', () async {
    categories = FakeCategoryRepository(const [
      Category(id: 'other', name: 'Other'),
    ]);

    final result = await build()('fuel 3000 at shell');

    expect(result.suggestedCategoryId, isNull);
  });

  test('has no suggestion when nothing points anywhere', () async {
    final result = await build()('something 500');

    expect(result.suggestedCategoryId, isNull);
    expect(result.draft.amountMinor, 50000);
  });
}
