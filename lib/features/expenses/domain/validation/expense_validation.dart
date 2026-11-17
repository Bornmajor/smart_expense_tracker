/// Field names used in validation results.
abstract final class ExpenseField {
  static const amount = 'amount';
  static const date = 'date';
  static const category = 'category';
}

/// Error codes. The UI maps these to user-facing text.
abstract final class ExpenseError {
  static const amountRequired = 'amount_required';
  static const amountMustBePositive = 'amount_must_be_positive';
  static const dateInFuture = 'date_in_future';
  static const categoryRequired = 'category_required';

  /// Raised by the form when the amount text is not a number.
  static const amountInvalid = 'amount_invalid';
}
