import 'package:flutter_bloc/flutter_bloc.dart';

import '../../../../core/errors/app_failure.dart';
import '../../../../core/errors/result.dart';
import '../../domain/entities/export_format.dart';
import '../../domain/usecases/export_month.dart';
import 'export_state.dart';

/// Exports a month and tells the screen whether it worked.
class ExportCubit extends Cubit<ExportState> {
  ExportCubit(this._export) : super(const ExportIdle());

  final ExportMonth _export;

  /// Makes the report and opens the share sheet. A second tap while one
  /// export is running is ignored.
  Future<void> export(DateTime month, ExportFormat format) async {
    if (state is ExportWorking) return;
    emit(ExportWorking(format));

    try {
      final result = await _export(month, format);
      if (isClosed) return;
      emit(switch (result) {
        Success() => const ExportIdle(),
        Failure(:final failure) => ExportFailed(failure, month),
      });
    } catch (error, stack) {
      // A bug, not an expected failure. Report it, and still free the screen.
      addError(error, stack);
      if (!isClosed) {
        emit(
          ExportFailed(
            const ExportFailure(ExportProblem.couldNotCreate),
            month,
          ),
        );
      }
    }
  }
}
