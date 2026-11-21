import 'package:flutter_bloc/flutter_bloc.dart';

import '../../domain/entities/auth_outcome.dart';
import '../../domain/repositories/biometric_authenticator.dart';
import '../lock_session.dart';
import 'lock_state.dart';

class LockCubit extends Cubit<LockScreenState> {
  LockCubit(this._authenticator, this._session)
    : super(const LockScreenState());

  final BiometricAuthenticator _authenticator;
  final LockSession _session;

  Future<void> authenticate() async {
    if (state.status == LockStatus.authenticating) return;
    emit(
      LockScreenState(
        status: LockStatus.authenticating,
        attempt: state.attempt,
      ),
    );

    final outcome = await _authenticator.authenticate(
      reason: 'Unlock SpendWise IQ',
    );

    switch (outcome) {
      case AuthOutcome.success:
        emit(LockScreenState(attempt: state.attempt));
        _session.unlock();
      case AuthOutcome.cancelled:
        // The user closed the prompt. Nothing went wrong, so show nothing.
        emit(LockScreenState(attempt: state.attempt));
      case AuthOutcome.failed:
        emit(
          LockScreenState(
            status: LockStatus.failed,
            attempt: state.attempt + 1,
          ),
        );
      case AuthOutcome.lockedOut:
        emit(
          LockScreenState(
            status: LockStatus.lockedOut,
            attempt: state.attempt + 1,
          ),
        );
      case AuthOutcome.unavailable:
        emit(
          LockScreenState(
            status: LockStatus.unavailable,
            attempt: state.attempt + 1,
          ),
        );
    }
  }
}
