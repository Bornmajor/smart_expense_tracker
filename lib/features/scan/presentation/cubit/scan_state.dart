import 'package:equatable/equatable.dart';

import '../../../../core/errors/app_failure.dart';
import '../../domain/entities/scan_result.dart';

/// What the scan is waiting on while it is working.
enum ScanStage {
  /// The camera or the gallery is open.
  picking,

  /// The photo is being read.
  reading,
}

/// Where a scan is. The screen shows one of these at a time.
sealed class ScanState extends Equatable {
  const ScanState();

  @override
  List<Object?> get props => [];
}

/// Busy, with nothing for the user to do.
final class ScanWorking extends ScanState {
  const ScanWorking(this.stage);

  final ScanStage stage;

  @override
  List<Object?> get props => [stage];
}

/// A camera photo, shown so the user can use it or retake it.
final class ScanPreview extends ScanState {
  const ScanPreview(this.photoPath, {this.recovered = false});

  final String photoPath;

  /// True when Android restarted the app while the camera was open, and this
  /// is the photo that was waiting.
  final bool recovered;

  @override
  List<Object?> get props => [photoPath, recovered];
}

/// The user backed out without choosing a photo.
final class ScanCancelled extends ScanState {
  const ScanCancelled();
}

final class ScanFailed extends ScanState {
  const ScanFailed(this.problem);

  final ScanProblem problem;

  @override
  List<Object?> get props => [problem];
}

/// The receipt was read. The result fills in the expense form.
final class ScanDone extends ScanState {
  const ScanDone(this.result);

  final ScanResult result;

  @override
  List<Object?> get props => [result];
}
