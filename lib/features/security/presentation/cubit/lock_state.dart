import 'package:equatable/equatable.dart';

enum LockStatus {
  idle,
  authenticating,

  /// The check did not pass. Trying again can work.
  failed,

  /// Too many wrong tries; the phone blocks checks for a while.
  lockedOut,

  /// The phone cannot check the user (no screen lock or fingerprint left, or
  /// the check is broken). The screen offers to turn the lock off.
  unavailable,
}

class LockScreenState extends Equatable {
  const LockScreenState({this.status = LockStatus.idle, this.attempt = 0});

  final LockStatus status;

  /// Increases with every failed check, so repeated failures still notify.
  final int attempt;

  @override
  List<Object?> get props => [status, attempt];
}
