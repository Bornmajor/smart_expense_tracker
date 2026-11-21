import 'dart:typed_data';

/// Lets the user choose a backup file from the phone.
abstract interface class BackupFilePicker {
  /// The bytes of the chosen file, or null when the user backed out.
  /// Throws `BackupException` (couldNotRead) if the file cannot be read.
  Future<Uint8List?> pick();
}
