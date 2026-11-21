import '../../../core/errors/app_failure.dart';

/// Thrown while reading or opening a backup, and turned into a
/// `BackupFailure` by the use cases.
class BackupException implements Exception {
  const BackupException(this.problem);

  final BackupProblem problem;

  @override
  String toString() => 'BackupException($problem)';
}
