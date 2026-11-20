import '../../../../core/errors/app_failure.dart';
import '../../../../core/errors/result.dart';
import '../../../../core/errors/storage_exception.dart';
import '../entities/expense.dart';
import '../entities/expense_draft.dart';
import '../repositories/expense_repository.dart';
import '../validation/expense_rules.dart';

/// Validates an edited expense and saves it over the original.
/// The id and the time it was created stay the same.
class UpdateExpense {
  UpdateExpense(this._repository, {DateTime Function()? now})
    : _now = now ?? DateTime.now;

  final ExpenseRepository _repository;
  final DateTime Function() _now;

  Future<Result<Expense>> call(Expense original, ExpenseDraft draft) async {
    final now = _now();
    final errors = ExpenseRules.validate(draft, now);
    if (errors.isNotEmpty) return Failure(ValidationFailure(errors));

    final updated = Expense(
      id: original.id,
      title: ExpenseRules.cleanTitle(draft.title),
      vendor: ExpenseRules.vendorOrUnknown(draft.vendor),
      amountMinor: draft.amountMinor!,
      date: ExpenseRules.dayOnly(draft.date),
      categoryId: draft.categoryId!,
      createdAt: original.createdAt,
      updatedAt: now,
      recurringRuleId: original.recurringRuleId,
    );

    try {
      await _repository.save(updated);
      return Success(updated);
    } on StorageException {
      return const Failure(StorageFailure());
    }
  }
}
