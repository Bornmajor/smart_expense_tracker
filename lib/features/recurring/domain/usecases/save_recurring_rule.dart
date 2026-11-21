import 'package:uuid/uuid.dart';

import '../../../../core/errors/app_failure.dart';
import '../../../../core/errors/result.dart';
import '../../../../core/errors/storage_exception.dart';
import '../../../expenses/domain/validation/expense_rules.dart';
import '../entities/recurring_draft.dart';
import '../entities/recurring_rule.dart';
import '../repositories/recurring_repository.dart';
import '../validation/recurring_checks.dart';

/// Checks what the user typed and saves it as a recurring rule: a new one, or
/// a change to [original].
class SaveRecurringRule {
  SaveRecurringRule(
    this._repository, {
    DateTime Function()? now,
    String Function()? newId,
  }) : _now = now ?? DateTime.now,
       _newId = newId ?? (() => const Uuid().v4());

  final RecurringRepository _repository;
  final DateTime Function() _now;
  final String Function() _newId;

  /// [amountText] is what was typed, only used to say whether a missing
  /// amount was blank or not a number.
  Future<Result<RecurringRule>> call(
    RecurringDraft draft, {
    RecurringRule? original,
    String amountText = '',
  }) async {
    final now = _now();
    final errors = RecurringChecks.validate(draft, now, amountText: amountText);
    if (errors.isNotEmpty) return Failure(ValidationFailure(errors));

    final nextDue = ExpenseRules.dayOnly(draft.nextDue);
    // The schedule is counted from the date the user chose. When they change
    // something else and leave the date alone, it keeps its old anchor, so a
    // rule on the 31st does not slip to the 28th.
    final keepsAnchor = original != null && original.nextDue == nextDue;

    final rule = RecurringRule(
      id: original?.id ?? _newId(),
      title: ExpenseRules.cleanTitle(draft.title),
      vendor: ExpenseRules.vendorOrUnknown(draft.vendor),
      amountMinor: draft.amountMinor!,
      categoryId: draft.categoryId!,
      frequency: draft.frequency,
      anchor: keepsAnchor ? original.anchor : nextDue,
      nextDue: nextDue,
      isActive: draft.isActive,
      createdAt: original?.createdAt ?? now,
      updatedAt: now,
    );

    try {
      await _repository.save(rule);
      return Success(rule);
    } on StorageException {
      return const Failure(StorageFailure());
    }
  }
}
