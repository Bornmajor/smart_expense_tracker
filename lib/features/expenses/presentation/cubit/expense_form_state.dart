import 'package:equatable/equatable.dart';

import '../../../../core/errors/app_failure.dart';

/// `saved` and `deleted` are final: the page shows feedback and closes.
enum ExpenseFormStatus { editing, saving, saved, deleting, deleted, failed }

class ExpenseFormState extends Equatable {
  const ExpenseFormState({
    this.status = ExpenseFormStatus.editing,
    this.fieldErrors = const {},
    this.failure,
  });

  final ExpenseFormStatus status;

  /// Field name -> error code, from a failed validation.
  final Map<String, String> fieldErrors;

  /// Set when saving or deleting failed for a reason other than validation.
  final AppFailure? failure;

  /// True while a save or delete is running, so buttons can be disabled.
  bool get busy =>
      status == ExpenseFormStatus.saving ||
      status == ExpenseFormStatus.deleting;

  @override
  List<Object?> get props => [status, fieldErrors, failure];
}
