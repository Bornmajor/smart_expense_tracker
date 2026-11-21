import '../entities/backup_data.dart';

abstract interface class BackupRepository {
  /// Everything the app keeps. The currency is left for the caller to add.
  /// Throws `StorageException` if storage fails.
  Future<BackupData> read();

  /// Replaces everything on this phone with [data], in one step: either all of
  /// it is restored or nothing is changed.
  /// Throws `BackupException` (damaged) if the data does not fit, and
  /// `StorageException` if storage fails.
  Future<void> replaceAll(BackupData data);
}
