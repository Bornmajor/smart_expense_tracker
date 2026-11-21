import 'package:equatable/equatable.dart';

import '../../../../core/errors/app_failure.dart';

sealed class BackupState extends Equatable {
  const BackupState();

  @override
  List<Object?> get props => [];
}

final class BackupIdle extends BackupState {
  const BackupIdle();
}

/// Making a backup, opening a file, or restoring.
final class BackupWorking extends BackupState {
  const BackupWorking();
}

/// The backup file was made and handed to the share sheet.
final class BackupCreated extends BackupState {
  const BackupCreated();
}

/// The chosen file is locked. [wrongPassword] is true after a failed try.
final class RestoreNeedsPassword extends BackupState {
  const RestoreNeedsPassword({this.wrongPassword = false});

  final bool wrongPassword;

  @override
  List<Object?> get props => [wrongPassword];
}

/// The file is open and waiting for the user to agree to replace their data.
final class RestoreReady extends BackupState {
  const RestoreReady({
    required this.createdAt,
    required this.expenses,
    required this.categories,
    required this.budgets,
    required this.recurringRules,
  });

  final DateTime createdAt;
  final int expenses;
  final int categories;
  final int budgets;
  final int recurringRules;

  @override
  List<Object?> get props => [
    createdAt,
    expenses,
    categories,
    budgets,
    recurringRules,
  ];
}

/// Everything was replaced. [currencyCode] is the backup's currency, for the
/// screen to apply.
final class RestoreDone extends BackupState {
  const RestoreDone({this.currencyCode});

  final String? currencyCode;

  @override
  List<Object?> get props => [currencyCode];
}

final class BackupFailed extends BackupState {
  const BackupFailed(this.problem);

  /// A storage problem has no specific [BackupProblem], so it is null.
  final BackupProblem? problem;

  @override
  List<Object?> get props => [problem];
}
