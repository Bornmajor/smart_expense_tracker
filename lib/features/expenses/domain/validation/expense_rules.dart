import '../entities/expense_draft.dart';
import 'expense_validation.dart';

/// The rules every saved expense follows, shared by adding and editing.
abstract final class ExpenseRules {
  /// Stored when the user leaves the vendor blank.
  static const unknownVendor = 'Unknown';

  /// The longest title allowed, after trimming.
  static const maxTitleLength = 60;

  /// Checks a draft and returns field name -> error code. Empty when valid.
  static Map<String, String> validate(ExpenseDraft draft, DateTime now) {
    final errors = <String, String>{};

    final amount = draft.amountMinor;
    if (amount == null) {
      errors[ExpenseField.amount] = ExpenseError.amountRequired;
    } else if (amount <= 0) {
      errors[ExpenseField.amount] = ExpenseError.amountMustBePositive;
    }

    if (dayOnly(draft.date).isAfter(dayOnly(now))) {
      errors[ExpenseField.date] = ExpenseError.dateInFuture;
    }

    final categoryId = draft.categoryId;
    if (categoryId == null || categoryId.isEmpty) {
      errors[ExpenseField.category] = ExpenseError.categoryRequired;
    }

    // The title is optional, but it can't be a paragraph.
    if (cleanTitle(draft.title).length > maxTitleLength) {
      errors[ExpenseField.title] = ExpenseError.titleTooLong;
    }

    return errors;
  }

  /// The title as it is stored: trimmed, and empty when the user left it blank.
  static String cleanTitle(String title) => title.trim();

  /// The vendor as it is stored: trimmed, or "Unknown" when blank.
  static String vendorOrUnknown(String vendor) {
    final trimmed = vendor.trim();
    return trimmed.isEmpty ? unknownVendor : trimmed;
  }

  /// The date without its time of day.
  static DateTime dayOnly(DateTime value) =>
      DateTime(value.year, value.month, value.day);
}
