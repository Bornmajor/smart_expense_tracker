import 'package:uuid/uuid.dart';

import '../../../../core/errors/app_failure.dart';
import '../../../../core/errors/result.dart';
import '../../../../core/errors/storage_exception.dart';
import '../entities/expense.dart';
import '../entities/expense_draft.dart';
import '../repositories/expense_repository.dart';
import '../validation/expense_rules.dart';

/// Validates what the user entered and saves it as a new expense.
class SaveExpense {
  SaveExpense(
    this._repository, {
    DateTime Function()? now,
    String Function()? newId,
  }) : _now = now ?? DateTime.now,
       _newId = newId ?? (() => const Uuid().v4());

  static const unknownVendor = ExpenseRules.unknownVendor;

  final ExpenseRepository _repository;
  final DateTime Function() _now;
  final String Function() _newId;

  Future<Result<Expense>> call(ExpenseDraft draft) async {
    final now = _now();
    final errors = ExpenseRules.validate(draft, now);
    if (errors.isNotEmpty) return Failure(ValidationFailure(errors));

    final expense = Expense(
      id: _newId(),
      title: ExpenseRules.cleanTitle(draft.title),
      vendor: ExpenseRules.vendorOrUnknown(draft.vendor),
      amountMinor: draft.amountMinor!,
      date: ExpenseRules.dayOnly(draft.date),
      categoryId: draft.categoryId!,
      createdAt: now,
      updatedAt: now,
      originalAmountMinor: draft.originalAmountMinor,
      originalCurrency: draft.originalCurrency,
    );

    try {
      await _repository.save(expense);
      return Success(expense);
    } on StorageException {
      return const Failure(StorageFailure());
    }
  }
}
