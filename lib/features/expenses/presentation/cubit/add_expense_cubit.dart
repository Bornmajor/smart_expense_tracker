import 'package:flutter_bloc/flutter_bloc.dart';

import '../../../../core/errors/app_failure.dart';
import '../../../../core/errors/result.dart';
import '../../../../core/utils/money.dart';
import '../../domain/entities/expense_draft.dart';
import '../../domain/usecases/save_expense.dart';
import '../../domain/validation/expense_validation.dart';
import 'add_expense_state.dart';

class AddExpenseCubit extends Cubit<AddExpenseState> {
  AddExpenseCubit(this._saveExpense) : super(const AddExpenseState());

  final SaveExpense _saveExpense;

  Future<void> submit({
    required String vendor,
    required String amountText,
    required DateTime date,
    required String? categoryId,
  }) async {
    if (state.status == AddExpenseStatus.saving) return;
    emit(const AddExpenseState(status: AddExpenseStatus.saving));

    // Turning text into a number is a form concern; the rules are in the use case.
    final amountMinor = Money.tryParse(amountText);
    final result = await _saveExpense(
      ExpenseDraft(
        vendor: vendor,
        amountMinor: amountMinor,
        date: date,
        categoryId: categoryId,
      ),
    );

    switch (result) {
      case Success():
        emit(const AddExpenseState(status: AddExpenseStatus.saved));
      case Failure(failure: final ValidationFailure validation):
        final errors = {...validation.fieldErrors};
        if (amountMinor == null && amountText.trim().isNotEmpty) {
          errors[ExpenseField.amount] = ExpenseError.amountInvalid;
        }
        emit(
          AddExpenseState(
            status: AddExpenseStatus.editing,
            fieldErrors: errors,
          ),
        );
      case Failure(:final failure):
        emit(
          AddExpenseState(status: AddExpenseStatus.failed, failure: failure),
        );
    }
  }
}
