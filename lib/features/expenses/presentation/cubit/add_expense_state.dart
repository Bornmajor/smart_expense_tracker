import 'package:equatable/equatable.dart';

import '../../../../core/errors/app_failure.dart';

enum AddExpenseStatus { editing, saving, saved, failed }

class AddExpenseState extends Equatable {
  const AddExpenseState({
    this.status = AddExpenseStatus.editing,
    this.fieldErrors = const {},
    this.failure,
  });

  final AddExpenseStatus status;

  /// Field name -> error code, from a failed validation.
  final Map<String, String> fieldErrors;

  /// Set when saving failed for a reason other than validation.
  final AppFailure? failure;

  @override
  List<Object?> get props => [status, fieldErrors, failure];
}
