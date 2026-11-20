import 'package:equatable/equatable.dart';

/// Expected failure outcomes returned by use cases.
sealed class AppFailure extends Equatable {
  const AppFailure();
}

/// One or more business rules were broken.
/// Maps a field name to an error code (the UI turns codes into text).
final class ValidationFailure extends AppFailure {
  const ValidationFailure(this.fieldErrors);

  final Map<String, String> fieldErrors;

  @override
  List<Object?> get props => [fieldErrors];
}

/// Reading from or writing to local storage failed.
final class StorageFailure extends AppFailure {
  const StorageFailure();

  @override
  List<Object?> get props => [];
}

/// Why scanning a receipt did not work.
enum ScanProblem {
  /// The user refused camera or photo access.
  permissionDenied,

  /// No camera, or it could not be opened.
  cameraUnavailable,

  /// The photo was taken but its text could not be read.
  unreadable,

  /// The chosen file is not a photo or a PDF.
  unsupportedFile,

  /// The file could not be opened. A PDF may be protected with a password, or
  /// damaged.
  cannotOpenFile,
}

/// Taking or reading a receipt photo failed.
final class ScanFailure extends AppFailure {
  const ScanFailure(this.problem);

  final ScanProblem problem;

  @override
  List<Object?> get props => [problem];
}

/// Why a monthly report was not exported.
enum ExportProblem {
  /// The month has no expenses, so there is nothing to put in a report.
  nothingToExport,

  /// The report file could not be made.
  couldNotCreate,

  /// The share sheet could not be opened.
  couldNotShare,
}

/// Exporting a monthly report failed.
final class ExportFailure extends AppFailure {
  const ExportFailure(this.problem);

  final ExportProblem problem;

  @override
  List<Object?> get props => [problem];
}

/// The device has no usable biometrics (none enrolled, or not supported).
final class BiometricUnavailableFailure extends AppFailure {
  const BiometricUnavailableFailure();

  @override
  List<Object?> get props => [];
}

/// The user cancelled or failed the biometric check.
final class AuthenticationFailure extends AppFailure {
  const AuthenticationFailure();

  @override
  List<Object?> get props => [];
}
