import '../../../core/errors/app_failure.dart';
import '../domain/validation/budget_rules.dart';

/// Turns a budget error code into text for the user.
String budgetErrorMessage(String code) => switch (code) {
  BudgetError.amountRequired => 'Enter an amount',
  BudgetError.amountInvalid => 'Enter a number, such as 5000 or 5000.50',
  BudgetError.amountMustBePositive => 'The budget must be more than zero',
  BudgetError.amountTooLarge => 'That is more than a budget can be',
  _ => 'Check the amount',
};

/// What to show under the amount field when saving a budget did not work.
String budgetSaveError(AppFailure failure) => switch (failure) {
  ValidationFailure(:final fieldErrors) => budgetErrorMessage(
    fieldErrors[BudgetField.amount] ?? '',
  ),
  _ => 'Couldn\'t save the budget. Try again.',
};
