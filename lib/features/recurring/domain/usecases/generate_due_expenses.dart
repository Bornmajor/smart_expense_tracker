import 'package:uuid/uuid.dart';

import '../../../../core/errors/storage_exception.dart';
import '../../../expenses/domain/entities/expense.dart';
import '../../../expenses/domain/validation/expense_rules.dart';
import '../entities/recurring_rule.dart';
import '../repositories/recurring_repository.dart';
import '../schedule/recurrence_schedule.dart';

/// Adds an expense for every recurring date that has come due.
///
/// There is no background service: this runs when the app opens, when it comes
/// back to the front, and right after a rule is saved. A rule not opened for a
/// few months simply adds each missed expense, on its own date, the next time.
/// Running it again straight away adds nothing, because each rule's next date
/// moves on in the same step as its expenses are saved.
class GenerateDueExpenses {
  GenerateDueExpenses(
    this._repository, {
    DateTime Function()? now,
    String Function()? newId,
  }) : _now = now ?? DateTime.now,
       _newId = newId ?? (() => const Uuid().v4());

  final RecurringRepository _repository;
  final DateTime Function() _now;
  final String Function() _newId;

  /// Returns how many expenses were added. A rule that cannot be saved is left
  /// as it was and is tried again next time; nothing is reported to the user,
  /// since nothing they can do would help.
  Future<int> call() async {
    final now = _now();
    final today = ExpenseRules.dayOnly(now);

    final rules = await _rulesOrNone();
    var added = 0;
    for (final rule in rules) {
      if (!rule.isActive || rule.nextDue.isAfter(today)) continue;

      final due = RecurrenceSchedule.dueDates(
        frequency: rule.frequency,
        anchor: rule.anchor,
        nextDue: rule.nextDue,
        today: today,
      );
      if (due.dates.isEmpty) continue;

      final expenses = [
        for (final date in due.dates)
          Expense(
            id: _newId(),
            title: rule.title,
            vendor: rule.vendor,
            amountMinor: rule.amountMinor,
            date: date,
            categoryId: rule.categoryId,
            createdAt: now,
            updatedAt: now,
            recurringRuleId: rule.id,
          ),
      ];

      try {
        await _repository.recordOccurrences(
          rule.copyWith(nextDue: due.nextDue, updatedAt: now),
          expenses,
        );
        added += expenses.length;
      } on StorageException {
        // Left as it was: the same dates are due again next time.
      }
    }
    return added;
  }

  Future<List<RecurringRule>> _rulesOrNone() async {
    try {
      return await _repository.getAll();
    } on StorageException {
      return const [];
    }
  }
}
