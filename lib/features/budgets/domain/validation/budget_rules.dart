/// Field names and error codes for a budget. The screen turns the codes into
/// text.
abstract final class BudgetField {
  static const amount = 'amount';
}

abstract final class BudgetError {
  static const amountRequired = 'amount_required';
  static const amountInvalid = 'amount_invalid';
  static const amountMustBePositive = 'amount_must_be_positive';
  static const amountTooLarge = 'amount_too_large';
}

abstract final class BudgetRules {
  /// The largest limit allowed: one billion, in minor units.
  static const maxLimitMinor = 100000000000;

  /// The error code for a limit typed as [text] and read as [minor], or null
  /// when it is fine.
  static String? validateLimit(String text, int? minor) {
    if (text.trim().isEmpty) return BudgetError.amountRequired;
    if (minor == null) return BudgetError.amountInvalid;
    if (minor <= 0) return BudgetError.amountMustBePositive;
    if (minor > maxLimitMinor) return BudgetError.amountTooLarge;
    return null;
  }
}
