import '../entities/report_file.dart';

/// Hands a finished report to the user through the system share sheet, which
/// also offers "Save to files" and "Save to Drive".
abstract interface class ReportSharer {
  /// Completes when the share sheet has been shown, whether or not the user
  /// picked a place to send the file.
  /// Throws `ExportException` when the sheet could not be opened.
  Future<void> share(ReportFile file);
}
