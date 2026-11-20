import 'package:equatable/equatable.dart';

import '../../../../core/errors/app_failure.dart';
import '../../domain/entities/export_format.dart';

sealed class ExportState extends Equatable {
  const ExportState();

  @override
  List<Object?> get props => [];
}

/// Nothing is being exported.
final class ExportIdle extends ExportState {
  const ExportIdle();
}

/// The report is being made, then the share sheet opens.
final class ExportWorking extends ExportState {
  const ExportWorking(this.format);

  final ExportFormat format;

  @override
  List<Object?> get props => [format];
}

/// The last export did not work. The screen shows the reason once.
final class ExportFailed extends ExportState {
  const ExportFailed(this.failure, this.month);

  final AppFailure failure;

  /// The month that was being exported, for the message.
  final DateTime month;

  @override
  List<Object?> get props => [failure, month];
}
