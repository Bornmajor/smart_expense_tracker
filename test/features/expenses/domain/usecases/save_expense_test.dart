import 'package:flutter_test/flutter_test.dart';
import 'package:smart_expense_tracker/core/errors/app_failure.dart';
import 'package:smart_expense_tracker/core/errors/result.dart';
import 'package:smart_expense_tracker/core/errors/storage_exception.dart';
import 'package:smart_expense_tracker/features/expenses/domain/entities/expense.dart';
import 'package:smart_expense_tracker/features/expenses/domain/entities/expense_draft.dart';
import 'package:smart_expense_tracker/features/expenses/domain/usecases/save_expense.dart';
import 'package:smart_expense_tracker/features/expenses/domain/validation/expense_rules.dart';
import 'package:smart_expense_tracker/features/expenses/domain/validation/expense_validation.dart';

import '../../../../support/fakes.dart';

void main() {
  final now = DateTime(2026, 11, 17, 10, 30);
  late FakeExpenseRepository repository;
  late SaveExpense saveExpense;

  ExpenseDraft draft({
    String title = '',
    String vendor = 'Corner Cafe',
    int? amountMinor = 847,
    DateTime? date,
    String? categoryId = 'food',
  }) => ExpenseDraft(
    title: title,
    vendor: vendor,
    amountMinor: amountMinor,
    date: date ?? DateTime(2026, 11, 16),
    categoryId: categoryId,
  );

  Map<String, String> validationErrors(Result<Expense> result) {
    final failure = (result as Failure<Expense>).failure;
    return (failure as ValidationFailure).fieldErrors;
  }

  setUp(() {
    repository = FakeExpenseRepository();
    saveExpense = SaveExpense(repository, now: () => now, newId: () => 'id-1');
  });

  group('SaveExpense', () {
    test('saves a valid expense with generated id and timestamps', () async {
      final result = await saveExpense(draft());

      final expense = (result as Success<Expense>).value;
      expect(expense.id, 'id-1');
      expect(expense.vendor, 'Corner Cafe');
      expect(expense.amountMinor, 847);
      expect(expense.categoryId, 'food');
      expect(expense.createdAt, now);
      expect(expense.updatedAt, now);
      expect(repository.saved, [expense]);
    });

    test('trims the vendor and drops the time from the date', () async {
      final result = await saveExpense(
        draft(vendor: '  Shell  ', date: DateTime(2026, 11, 16, 23, 59)),
      );

      final expense = (result as Success<Expense>).value;
      expect(expense.vendor, 'Shell');
      expect(expense.date, DateTime(2026, 11, 16));
    });

    test('uses "Unknown" when the vendor is blank', () async {
      final result = await saveExpense(draft(vendor: '   '));

      expect(
        (result as Success<Expense>).value.vendor,
        SaveExpense.unknownVendor,
      );
    });

    test('saves the title trimmed, and no title when it is blank', () async {
      final withTitle = await saveExpense(draft(title: '  Lunch with team  '));
      expect((withTitle as Success<Expense>).value.title, 'Lunch with team');

      final blank = await saveExpense(draft(title: '   '));
      expect((blank as Success<Expense>).value.title, isEmpty);
    });

    test('accepts a title of exactly the longest length', () async {
      final title = 'a' * ExpenseRules.maxTitleLength;

      final result = await saveExpense(draft(title: title));

      expect(result, isA<Success<Expense>>());
    });

    test('rejects a title that is too long, and saves nothing', () async {
      final title = 'a' * (ExpenseRules.maxTitleLength + 1);

      final result = await saveExpense(draft(title: title));

      expect(validationErrors(result), {
        ExpenseField.title: ExpenseError.titleTooLong,
      });
      expect(repository.saved, isEmpty);
    });

    test('does not count the spaces around a long title', () async {
      final title = '  ${'a' * ExpenseRules.maxTitleLength}  ';

      final result = await saveExpense(draft(title: title));

      expect(result, isA<Success<Expense>>());
    });

    test('accepts today as the date', () async {
      final result = await saveExpense(draft(date: DateTime(2026, 11, 17)));

      expect(result, isA<Success<Expense>>());
    });

    test('rejects a missing amount', () async {
      final result = await saveExpense(draft(amountMinor: null));

      expect(validationErrors(result), {
        ExpenseField.amount: ExpenseError.amountRequired,
      });
    });

    test('rejects zero and negative amounts', () async {
      for (final amount in [0, -100]) {
        final result = await saveExpense(draft(amountMinor: amount));

        expect(validationErrors(result), {
          ExpenseField.amount: ExpenseError.amountMustBePositive,
        }, reason: 'amount: $amount');
      }
    });

    test('rejects a date in the future', () async {
      final result = await saveExpense(draft(date: DateTime(2026, 11, 18)));

      expect(validationErrors(result), {
        ExpenseField.date: ExpenseError.dateInFuture,
      });
    });

    test('rejects a missing or empty category', () async {
      for (final category in [null, '']) {
        final result = await saveExpense(draft(categoryId: category));

        expect(validationErrors(result), {
          ExpenseField.category: ExpenseError.categoryRequired,
        }, reason: 'category: $category');
      }
    });

    test('reports every broken rule at once and saves nothing', () async {
      final result = await saveExpense(
        draft(amountMinor: 0, date: DateTime(2027, 1, 1), categoryId: null),
      );

      expect(validationErrors(result).keys, {
        ExpenseField.amount,
        ExpenseField.date,
        ExpenseField.category,
      });
      expect(repository.saved, isEmpty);
    });

    test('returns a storage failure when the repository throws', () async {
      repository.saveError = const StorageException('disk full');

      final result = await saveExpense(draft());

      expect((result as Failure<Expense>).failure, const StorageFailure());
    });

    test('generates a different id each time by default', () async {
      final useCase = SaveExpense(repository, now: () => now);

      final first = await useCase(draft());
      final second = await useCase(draft());

      expect(
        (first as Success<Expense>).value.id,
        isNot((second as Success<Expense>).value.id),
      );
    });
  });
}
