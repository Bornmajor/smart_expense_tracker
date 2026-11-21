import 'package:equatable/equatable.dart';

import '../../../../core/errors/app_failure.dart';

/// `saved` and `deleted` are final: the page shows feedback and closes.
enum RecurringFormStatus { editing, saving, saved, deleting, deleted, failed }

class RecurringFormState extends Equatable {
  const RecurringFormState({
    this.status = RecurringFormStatus.editing,
    this.fieldErrors = const {},
    this.failure,
    this.addedCount = 0,
  });

  final RecurringFormStatus status;

  /// Field name -> error code, from a failed check.
  final Map<String, String> fieldErrors;

  /// Set when saving or deleting failed for a reason other than a bad field.
  final AppFailure? failure;

  /// After `saved`: how many expenses were added straight away because the
  /// date was already due.
  final int addedCount;

  /// True while a save or delete is running, so buttons can be disabled.
  bool get busy =>
      status == RecurringFormStatus.saving ||
      status == RecurringFormStatus.deleting;

  @override
  List<Object?> get props => [status, fieldErrors, failure, addedCount];
}
