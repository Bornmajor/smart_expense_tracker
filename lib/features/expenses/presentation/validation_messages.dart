import '../domain/validation/expense_rules.dart';
import '../domain/validation/expense_validation.dart';

/// Turns a validation error code into text for the user.
String expenseErrorMessage(String code) => switch (code) {
  ExpenseError.amountRequired => 'Enter an amount',
  ExpenseError.amountMustBePositive => 'Amount must be greater than zero',
  ExpenseError.amountInvalid => 'Enter a valid amount, like 12.50',
  ExpenseError.ratesUnavailable =>
    'No exchange rates yet. Connect to the internet once, or remove the '
        'other currency and enter the amount in yours.',
  ExpenseError.dateInFuture => 'Date can\'t be in the future',
  ExpenseError.categoryRequired => 'Choose a category',
  ExpenseError.titleTooLong =>
    'Keep the title under ${ExpenseRules.maxTitleLength} characters',
  _ => 'Check this field',
};
