/// Puts everything the app remembers apart from the database back to how it is
/// on a fresh install: the settings, the app lock, whether the introduction was
/// seen, saved exchange rates, dismissed alerts and the last backup date.
abstract interface class LocalStateReset {
  /// Never throws: if something cannot be cleared the app still starts again.
  Future<void> clear();
}
