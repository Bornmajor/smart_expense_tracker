/// Remembers which alerts the user has closed, so they stay closed.
abstract interface class AlertDismissals {
  /// The ids of the alerts that were dismissed. Never throws.
  Set<String> dismissed();

  /// Remembers that the alert was dismissed. Never throws: if it cannot be
  /// saved the alert may come back, which does no harm.
  Future<void> dismiss(String id);
}
