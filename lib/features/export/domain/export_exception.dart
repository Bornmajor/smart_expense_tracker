import '../../../core/errors/app_failure.dart';

/// Thrown by the share step, and turned into an `ExportFailure` by the use
/// case.
class ExportException implements Exception {
  const ExportException(this.problem);

  final ExportProblem problem;

  @override
  String toString() => 'ExportException($problem)';
}
