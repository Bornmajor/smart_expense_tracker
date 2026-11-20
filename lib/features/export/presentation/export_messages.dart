import 'package:intl/intl.dart';

import '../../../core/errors/app_failure.dart';

/// What to tell the user when an export did not work.
String exportFailureMessage(AppFailure failure, DateTime month) {
  return switch (failure) {
    ExportFailure(problem: ExportProblem.nothingToExport) =>
      'There are no expenses in ${DateFormat.yMMMM().format(month)} to export.',
    ExportFailure(problem: ExportProblem.couldNotShare) =>
      'Couldn\'t open the share sheet. Please try again.',
    ExportFailure(problem: ExportProblem.couldNotCreate) =>
      'Couldn\'t make the report. Please try again.',
    StorageFailure() => 'Couldn\'t read your expenses. Please try again.',
    _ => 'Couldn\'t export this month. Please try again.',
  };
}
