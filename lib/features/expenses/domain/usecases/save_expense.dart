import 'package:uuid/uuid.dart';

import '../../../../core/errors/app_failure.dart';
import '../../../../core/errors/result.dart';
import '../../../../core/errors/storage_exception.dart';
import '../entities/expense.dart';
import '../entities/expense_draft.dart';
import '../repositories/expense_repository.dart';
import '../validation/expense_validation.dart';

/// Validates what the user entered and saves it as an expense.
class SaveExpense {
  SaveExpense(
    this._repository, {
    DateTime Function()? now,
    String Function()? newId,
  }) : _now = now ?? DateTime.now,
       _newId = newId ?? (() => const Uuid().v4());

  static const unknownVendor = 'Unknown';

  final ExpenseRepository _repository;
  final DateTime Function() _now;
  final String Function() _newId;

  Future<Result<Expense>> call(ExpenseDraft draft) async {
    final now = _now();
    final errors = _validate(draft, now);
    if (errors.isNotEmpty) return Failure(ValidationFailure(errors));

    final vendor = draft.vendor.trim();
    final expense = Expense(
      id: _newId(),
      vendor: vendor.isEmpty ? unknownVendor : vendor,
      amountMinor: draft.amountMinor!,
      date: _dayOnly(draft.date),
      categoryId: draft.categoryId!,
      createdAt: now,
      updatedAt: now,
    );

    try {
      await _repository.save(expense);
      return Success(expense);
    } on StorageException {
      return const Failure(StorageFailure());
    }
  }

  Map<String, String> _validate(ExpenseDraft draft, DateTime now) {
    final errors = <String, String>{};

    final amount = draft.amountMinor;
    if (amount == null) {
      errors[ExpenseField.amount] = ExpenseError.amountRequired;
    } else if (amount <= 0) {
      errors[ExpenseField.amount] = ExpenseError.amountMustBePositive;
    }

    if (_dayOnly(draft.date).isAfter(_dayOnly(now))) {
      errors[ExpenseField.date] = ExpenseError.dateInFuture;
    }

    final categoryId = draft.categoryId;
    if (categoryId == null || categoryId.isEmpty) {
      errors[ExpenseField.category] = ExpenseError.categoryRequired;
    }

    return errors;
  }

  DateTime _dayOnly(DateTime value) =>
      DateTime(value.year, value.month, value.day);
}
