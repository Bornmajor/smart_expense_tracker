import 'package:uuid/uuid.dart';

import '../../../../core/errors/app_failure.dart';
import '../../../../core/errors/result.dart';
import '../../../../core/errors/storage_exception.dart';
import '../../../expenses/domain/entities/expense.dart';
import '../../../expenses/domain/entities/expense_draft.dart';
import '../../../expenses/domain/validation/expense_rules.dart';
import '../entities/recurrence_frequency.dart';
import '../entities/recurring_rule.dart';
import '../repositories/recurring_repository.dart';
import '../schedule/recurrence_schedule.dart';

/// Saves a new expense and makes it repeat: the expense is the first one, and
/// a recurring rule adds the next ones. Used when the user ticks "Repeat this
/// expense" while adding, such as for a scanned rent or subscription receipt.
class SaveRepeatingExpense {
  SaveRepeatingExpense(
    this._repository, {
    DateTime Function()? now,
    String Function()? newId,
  }) : _now = now ?? DateTime.now,
       _newId = newId ?? (() => const Uuid().v4());

  final RecurringRepository _repository;
  final DateTime Function() _now;
  final String Function() _newId;

  Future<Result<Expense>> call(
    ExpenseDraft draft,
    RecurrenceFrequency frequency,
  ) async {
    final now = _now();
    final errors = ExpenseRules.validate(draft, now);
    if (errors.isNotEmpty) return Failure(ValidationFailure(errors));

    final date = ExpenseRules.dayOnly(draft.date);
    final title = ExpenseRules.cleanTitle(draft.title);
    final vendor = ExpenseRules.vendorOrUnknown(draft.vendor);
    final ruleId = _newId();

    // This expense is the first one, so the rule starts at the date after it.
    // Otherwise the same expense would be added a second time.
    final rule = RecurringRule(
      id: ruleId,
      title: title,
      vendor: vendor,
      amountMinor: draft.amountMinor!,
      categoryId: draft.categoryId!,
      frequency: frequency,
      anchor: date,
      nextDue: RecurrenceSchedule.next(frequency, date, date),
      createdAt: now,
      updatedAt: now,
    );
    final expense = Expense(
      id: _newId(),
      title: title,
      vendor: vendor,
      amountMinor: draft.amountMinor!,
      date: date,
      categoryId: draft.categoryId!,
      createdAt: now,
      updatedAt: now,
      recurringRuleId: ruleId,
    );

    try {
      await _repository.createWithFirstExpense(rule, expense);
      return Success(expense);
    } on StorageException {
      return const Failure(StorageFailure());
    }
  }
}
