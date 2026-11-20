import 'package:flutter_test/flutter_test.dart';
import 'package:smart_expense_tracker/core/errors/app_failure.dart';
import 'package:smart_expense_tracker/core/errors/result.dart';
import 'package:smart_expense_tracker/core/errors/storage_exception.dart';
import 'package:smart_expense_tracker/features/expenses/domain/entities/expense_draft.dart';
import 'package:smart_expense_tracker/features/recurring/domain/entities/recurrence_frequency.dart';
import 'package:smart_expense_tracker/features/recurring/domain/usecases/save_repeating_expense.dart';

import '../../../support/fakes.dart';

void main() {
  late FakeRecurringRepository repository;
  var ids = 0;

  SaveRepeatingExpense useCase() => SaveRepeatingExpense(
    repository,
    now: () => DateTime(2026, 11, 20, 9),
    newId: () => 'id${ids++}',
  );

  ExpenseDraft draft({DateTime? date, int? amountMinor = 50000}) =>
      ExpenseDraft(
        title: 'Rent',
        vendor: 'Landlord',
        amountMinor: amountMinor,
        date: date ?? DateTime(2026, 11, 5),
        categoryId: 'housing',
      );

  setUp(() {
    repository = FakeRecurringRepository();
    ids = 0;
  });

  test('saves the expense as the first one, linked to its rule', () async {
    final result = await useCase()(draft(), RecurrenceFrequency.monthly);

    final expense = (result as Success).value;
    expect(expense.date, DateTime(2026, 11, 5));
    expect(expense.recurringRuleId, repository.rules.single.id);
    expect(repository.created.single, expense);
  });

  test('the rule starts at the next date, so nothing is added twice', () async {
    await useCase()(draft(), RecurrenceFrequency.monthly);

    final rule = repository.rules.single;
    expect(rule.anchor, DateTime(2026, 11, 5));
    expect(rule.nextDue, DateTime(2026, 12, 5));
    expect(rule.amountMinor, 50000);
    expect(rule.vendor, 'Landlord');
    expect(rule.categoryId, 'housing');
  });

  test('weekly and yearly step by a week and a year', () async {
    await useCase()(draft(), RecurrenceFrequency.weekly);
    expect(repository.rules.last.nextDue, DateTime(2026, 11, 12));

    await useCase()(draft(), RecurrenceFrequency.yearly);
    expect(repository.rules.last.nextDue, DateTime(2027, 11, 5));
  });

  test('a month-end date keeps to the end of the month', () async {
    await useCase()(
      draft(date: DateTime(2026, 1, 31)),
      RecurrenceFrequency.monthly,
    );

    expect(repository.rules.single.nextDue, DateTime(2026, 2, 28));
    expect(repository.rules.single.anchor, DateTime(2026, 1, 31));
  });

  test('an invalid expense saves nothing', () async {
    final result = await useCase()(
      draft(amountMinor: null),
      RecurrenceFrequency.monthly,
    );

    expect(result, isA<Failure>());
    expect((result as Failure).failure, isA<ValidationFailure>());
    expect(repository.rules, isEmpty);
    expect(repository.created, isEmpty);
  });

  test('a storage problem is reported and nothing is kept', () async {
    repository.saveError = StorageException(Exception('disk full'));

    final result = await useCase()(draft(), RecurrenceFrequency.monthly);

    expect((result as Failure).failure, isA<StorageFailure>());
    expect(repository.created, isEmpty);
  });
}
