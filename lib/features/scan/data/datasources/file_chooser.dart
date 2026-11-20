/// Opens the phone's Files app so the user can pick a receipt.
abstract interface class FileChooser {
  /// The path of the chosen file, or null when the user backed out. The file
  /// is a temporary copy made for this app.
  /// Throws `ScanException` if the Files app cannot be opened.
  Future<String?> chooseFile();
}
