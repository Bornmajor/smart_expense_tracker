abstract final class AppRoutes {
  static const welcome = '/welcome';
  static const onboarding = '/onboarding';
  static const lock = '/lock';
  static const expenses = '/';
  static const summary = '/summary';
  static const settings = '/settings';
  static const addExpense = '/expenses/new';

  /// Needs the photo source (a `ReceiptSource`) passed as `extra`. When the
  /// scan succeeds it is replaced by [addExpense] with the scan as `extra`.
  static const scan = '/expenses/scan';

  /// Needs the expense to edit passed as `extra`.
  static const editExpense = '/expenses/edit';
  static const categories = '/categories';
  static const budgets = '/budgets';
  static const recurring = '/recurring';
  static const recurringForm = '/recurring/form';

  /// TEMPORARY, debug builds only: see what the scanner reads.
  static const ocrDebug = '/debug/ocr';
}
