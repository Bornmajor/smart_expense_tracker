import 'package:flutter_test/flutter_test.dart';
import 'package:smart_expense_tracker/core/errors/app_failure.dart';
import 'package:smart_expense_tracker/core/errors/result.dart';
import 'package:smart_expense_tracker/core/errors/storage_exception.dart';
import 'package:smart_expense_tracker/features/expenses/domain/entities/expense.dart';
import 'package:smart_expense_tracker/features/expenses/domain/entities/expense_draft.dart';
import 'package:smart_expense_tracker/features/expenses/domain/usecases/update_expense.dart';
import 'package:smart_expense_tracker/features/expenses/domain/validation/expense_validation.dart';

import '../../../../support/fakes.dart';

void main() {
  final now = DateTime(2026, 11, 17, 10, 30);
  final createdAt = DateTime(2026, 11, 10, 8);
  late Expense original;
  late FakeExpenseRepository repository;
  late UpdateExpense updateExpense;

  ExpenseDraft draft({
    String vendor = 'BP',
    int? amountMinor = 1250,
    DateTime? date,
    String? categoryId = 'transport',
  }) => ExpenseDraft(
    vendor: vendor,
    amountMinor: amountMinor,
    date: date ?? DateTime(2026, 11, 15),
    categoryId: categoryId,
  );

  Map<String, String> validationErrors(Result<Expense> result) {
    final failure = (result as Failure<Expense>).failure;
    return (failure as ValidationFailure).fieldErrors;
  }

  setUp(() {
    original = Expense(
      id: 'e1',
      vendor: 'Shell',
      amountMinor: 1000,
      date: DateTime(2026, 11, 10),
      categoryId: 'food',
      createdAt: createdAt,
      updatedAt: createdAt,
    );
    repository = FakeExpenseRepository(initial: [original]);
    updateExpense = UpdateExpense(repository, now: () => now);
  });

  group('UpdateExpense', () {
    test('replaces the original and keeps its id and creation time', () async {
      final result = await updateExpense(original, draft());

      final updated = (result as Success<Expense>).value;
      expect(updated.id, 'e1');
      expect(updated.createdAt, createdAt);
      expect(updated.updatedAt, now);
      expect(updated.vendor, 'BP');
      expect(updated.amountMinor, 1250);
      expect(updated.categoryId, 'transport');
      expect(updated.date, DateTime(2026, 11, 15));
      expect(repository.saved, [updated]);
    });

    test('trims the vendor and uses "Unknown" when it is blank', () async {
      final trimmed = await updateExpense(original, draft(vendor: '  BP  '));
      expect((trimmed as Success<Expense>).value.vendor, 'BP');

      final blank = await updateExpense(original, draft(vendor: '   '));
      expect((blank as Success<Expense>).value.vendor, 'Unknown');
    });

    test('applies the same rules as adding an expense', () async {
      final result = await updateExpense(
        original,
        draft(amountMinor: 0, date: DateTime(2026, 11, 18), categoryId: null),
      );

      expect(validationErrors(result).keys, {
        ExpenseField.amount,
        ExpenseField.date,
        ExpenseField.category,
      });
      expect(repository.saved, [original], reason: 'nothing was changed');
    });

    test('returns a storage failure when the repository throws', () async {
      repository.saveError = const StorageException('disk full');

      final result = await updateExpense(original, draft());

      expect((result as Failure<Expense>).failure, const StorageFailure());
      expect(repository.saved, [original]);
    });
  });
}
