import '../domain/validation/expense_validation.dart';

/// Turns a validation error code into text for the user.
String expenseErrorMessage(String code) => switch (code) {
  ExpenseError.amountRequired => 'Enter an amount',
  ExpenseError.amountMustBePositive => 'Amount must be greater than zero',
  ExpenseError.amountInvalid => 'Enter a valid amount, like 12.50',
  ExpenseError.dateInFuture => 'Date can\'t be in the future',
  ExpenseError.categoryRequired => 'Choose a category',
  _ => 'Check this field',
};
