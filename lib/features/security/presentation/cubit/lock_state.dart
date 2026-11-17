import 'package:equatable/equatable.dart';

enum LockStatus { idle, authenticating, failed }

class LockScreenState extends Equatable {
  const LockScreenState({this.status = LockStatus.idle, this.attempt = 0});

  final LockStatus status;

  /// Increases with every failed check, so repeated failures still notify.
  final int attempt;

  @override
  List<Object?> get props => [status, attempt];
}
