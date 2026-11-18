abstract final class AppRoutes {
  static const welcome = '/welcome';
  static const onboarding = '/onboarding';
  static const lock = '/lock';
  static const expenses = '/';
  static const summary = '/summary';
  static const settings = '/settings';
  static const addExpense = '/expenses/new';

  /// Needs the expense to edit passed as `extra`.
  static const editExpense = '/expenses/edit';
  static const categories = '/categories';

  /// TEMPORARY, debug builds only: see what the scanner reads.
  static const ocrDebug = '/debug/ocr';
}
