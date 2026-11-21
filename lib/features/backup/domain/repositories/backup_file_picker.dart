import 'dart:typed_data';

/// Lets the user choose a backup file from the phone.
abstract interface class BackupFilePicker {
  /// The bytes of the chosen file, or null when the user backed out.
  /// Throws `BackupException` (couldNotRead) if the file cannot be read.
  Future<Uint8List?> pick();

  /// True once, on the start after Android closed the app while the Files app
  /// was open to choose a backup. The chosen file is lost with the app, so the
  /// user has to choose it again.
  Future<bool> pickWasInterrupted();
}
