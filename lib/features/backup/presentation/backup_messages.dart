import '../../../core/errors/app_failure.dart';

/// What to tell the user when a backup or a restore did not work. [problem] is
/// null for a storage problem.
String backupFailureMessage(BackupProblem? problem) => switch (problem) {
  BackupProblem.notABackup =>
    'That file is not a SpendWise IQ backup. Choose the file the app made.',
  BackupProblem.newerVersion =>
    'This backup was made by a newer version of the app. Update SpendWise IQ '
        'and try again.',
  BackupProblem.damaged =>
    'This backup is damaged or incomplete, so it can\'t be restored. Nothing '
        'on your phone was changed.',
  BackupProblem.couldNotRead => 'Couldn\'t read that file. Please try again.',
  BackupProblem.couldNotShare =>
    'Couldn\'t open the share sheet. Please try again.',
  BackupProblem.passwordRequired ||
  BackupProblem.wrongPassword => 'That password does not open this backup.',
  null => 'Something went wrong. Your data was not changed. Please try again.',
};

/// The password rules for locking a backup.
abstract final class BackupPasswordRules {
  static const minLength = 6;

  /// Null when [password] and [confirm] are fine, otherwise what to fix.
  static String? problem(String password, String confirm) {
    if (password.length < minLength) {
      return 'Use at least $minLength characters.';
    }
    if (password != confirm) return 'The two passwords do not match.';
    return null;
  }
}
