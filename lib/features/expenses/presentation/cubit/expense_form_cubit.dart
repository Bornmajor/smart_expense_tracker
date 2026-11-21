import 'package:flutter_bloc/flutter_bloc.dart';

import '../../../../core/errors/app_failure.dart';
import '../../../../core/errors/result.dart';
import '../../../../core/errors/storage_exception.dart';
import '../../../../core/utils/money.dart';
import '../../../currency_conversion/domain/repositories/exchange_rate_repository.dart';
import '../../../currency_conversion/domain/usecases/convert_amount.dart';
import '../../../recurring/domain/entities/recurrence_frequency.dart';
import '../../../recurring/domain/usecases/save_repeating_expense.dart';
import '../../domain/entities/expense.dart';
import '../../domain/entities/expense_draft.dart';
import '../../domain/repositories/expense_repository.dart';
import '../../domain/usecases/save_expense.dart';
import '../../domain/usecases/update_expense.dart';
import '../../domain/validation/expense_validation.dart';
import 'expense_form_state.dart';

/// Drives the expense form. Without [original] it adds a new expense; with
/// it, the form edits that expense and can delete it.
class ExpenseFormCubit extends Cubit<ExpenseFormState> {
  ExpenseFormCubit({
    required this._saveExpense,
    required this._updateExpense,
    required this._saveRepeating,
    required this._rates,
    required this._repository,
    this.original,
  }) : super(const ExpenseFormState());

  final SaveExpense _saveExpense;
  final UpdateExpense _updateExpense;
  final SaveRepeatingExpense _saveRepeating;
  final ExchangeRateRepository _rates;
  final ExpenseRepository _repository;
  final Expense? original;

  bool get isEditing => original != null;

  Future<void> submit({
    String title = '',
    required String vendor,
    required String amountText,
    required DateTime date,
    required String? categoryId,

    /// How often to repeat the expense, or null for a one-off. Only used when
    /// adding; an expense that is being edited is never made to repeat here.
    RecurrenceFrequency? repeat,

    /// ISO code of another currency [amountText] is written in, or null when it
    /// is in the app's own currency [toCurrency].
    String? fromCurrency,
    String? toCurrency,

    /// The M-Pesa transaction code, when the form was filled in from a pasted
    /// message. Only used when adding.
    String? transactionCode,
  }) async {
    if (state.busy) return;
    emit(const ExpenseFormState(status: ExpenseFormStatus.saving));

    // Turning text into a number is a form concern; the rules are in the use case.
    var amountMinor = Money.tryParse(amountText);
    int? originalMinor;
    final from = fromCurrency;
    final to = toCurrency;
    if (from != null && to != null && amountMinor != null) {
      final rates = await _rates.saved();
      final converted = rates == null
          ? null
          : ConvertAmount.call(
              minor: amountMinor,
              from: from,
              to: to,
              rates: rates,
            );
      if (converted == null) {
        emit(
          const ExpenseFormState(
            status: ExpenseFormStatus.editing,
            fieldErrors: {ExpenseField.amount: ExpenseError.ratesUnavailable},
          ),
        );
        return;
      }
      originalMinor = amountMinor;
      amountMinor = converted;
    }
    final draft = ExpenseDraft(
      originalAmountMinor: originalMinor,
      originalCurrency: originalMinor == null ? null : from,
      transactionCode: transactionCode,
      title: title,
      vendor: vendor,
      amountMinor: amountMinor,
      date: date,
      categoryId: categoryId,
    );
    final existing = original;
    final result = existing != null
        ? await _updateExpense(existing, draft)
        : repeat != null
        ? await _saveRepeating(draft, repeat)
        : await _saveExpense(draft);

    switch (result) {
      case Success():
        emit(const ExpenseFormState(status: ExpenseFormStatus.saved));
      case Failure(failure: final ValidationFailure validation):
        final errors = {...validation.fieldErrors};
        if (amountMinor == null && amountText.trim().isNotEmpty) {
          errors[ExpenseField.amount] = ExpenseError.amountInvalid;
        }
        emit(
          ExpenseFormState(
            status: ExpenseFormStatus.editing,
            fieldErrors: errors,
          ),
        );
      case Failure(:final failure):
        emit(
          ExpenseFormState(status: ExpenseFormStatus.failed, failure: failure),
        );
    }
  }

  /// Deletes the expense being edited. Does nothing when adding.
  Future<void> delete() async {
    final existing = original;
    if (existing == null || state.busy) return;
    emit(const ExpenseFormState(status: ExpenseFormStatus.deleting));

    try {
      await _repository.delete(existing.id);
      emit(const ExpenseFormState(status: ExpenseFormStatus.deleted));
    } on StorageException {
      emit(
        const ExpenseFormState(
          status: ExpenseFormStatus.failed,
          failure: StorageFailure(),
        ),
      );
    }
  }
}
