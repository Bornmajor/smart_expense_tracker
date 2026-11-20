import '../../../expenses/domain/validation/expense_rules.dart';
import '../entities/recurring_draft.dart';

/// Field names and error codes for a recurring rule. The screen turns the
/// codes into text.
abstract final class RecurringField {
  static const name = 'name';
  static const amount = 'amount';
  static const category = 'category';
  static const date = 'date';
}

abstract final class RecurringError {
  static const nameRequired = 'name_required';
  static const nameTooLong = 'name_too_long';
  static const amountRequired = 'amount_required';
  static const amountInvalid = 'amount_invalid';
  static const amountMustBePositive = 'amount_must_be_positive';
  static const amountTooLarge = 'amount_too_large';
  static const categoryRequired = 'category_required';
  static const dateTooOld = 'date_too_old';
  static const dateTooFar = 'date_too_far';
}

abstract final class RecurringChecks {
  /// The largest amount allowed for one occurrence: one billion.
  static const maxAmountMinor = 100000000000;

  /// How far back the first date may be. Every missed date is added when the
  /// rule is saved, so a date years ago would add a pile of old expenses.
  static const maxDaysBack = 366;

  /// How far ahead the first date may be.
  static const maxDaysAhead = 366 * 5;

  /// Field name -> error code for [draft], as of [today]. Empty when it is fine.
  /// [amountText] is what was typed, to tell "blank" from "not a number".
  static Map<String, String> validate(
    RecurringDraft draft,
    DateTime today, {
    String amountText = '',
  }) {
    final errors = <String, String>{};

    final title = ExpenseRules.cleanTitle(draft.title);
    final vendor = draft.vendor.trim();
    if (title.isEmpty && vendor.isEmpty) {
      errors[RecurringField.name] = RecurringError.nameRequired;
    } else if (title.length > ExpenseRules.maxTitleLength ||
        vendor.length > ExpenseRules.maxTitleLength) {
      errors[RecurringField.name] = RecurringError.nameTooLong;
    }

    final amount = draft.amountMinor;
    if (amount == null) {
      errors[RecurringField.amount] = amountText.trim().isEmpty
          ? RecurringError.amountRequired
          : RecurringError.amountInvalid;
    } else if (amount <= 0) {
      errors[RecurringField.amount] = RecurringError.amountMustBePositive;
    } else if (amount > maxAmountMinor) {
      errors[RecurringField.amount] = RecurringError.amountTooLarge;
    }

    final categoryId = draft.categoryId;
    if (categoryId == null || categoryId.isEmpty) {
      errors[RecurringField.category] = RecurringError.categoryRequired;
    }

    final day = ExpenseRules.dayOnly(draft.nextDue);
    final first = DateTime(today.year, today.month, today.day - maxDaysBack);
    final last = DateTime(today.year, today.month, today.day + maxDaysAhead);
    if (day.isBefore(first)) {
      errors[RecurringField.date] = RecurringError.dateTooOld;
    } else if (day.isAfter(last)) {
      errors[RecurringField.date] = RecurringError.dateTooFar;
    }

    return errors;
  }
}
