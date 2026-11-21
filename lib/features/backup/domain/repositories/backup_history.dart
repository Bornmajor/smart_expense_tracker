/// Remembers when the user last made a backup file, so the app can remind them
/// to back up before they delete everything.
abstract interface class BackupHistory {
  /// When a backup file was last made, or null if never. Never throws.
  DateTime? lastBackupAt();

  /// Remembers that a backup file was made at [when]. Never throws: if it
  /// cannot be saved the reminder is just less exact.
  Future<void> record(DateTime when);
}
