import '../../../core/errors/app_failure.dart';

/// Thrown by the camera and text-reading wrappers when they cannot do their
/// job. The [ScanReceipt] use case turns it into a [ScanFailure].
class ScanException implements Exception {
  const ScanException(this.problem, [this.cause]);

  final ScanProblem problem;

  /// The underlying error, for debugging.
  final Object? cause;

  @override
  String toString() => 'ScanException($problem, $cause)';
}
