import 'package:flutter_bloc/flutter_bloc.dart';

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

    final success = await _authenticator.authenticate(
      reason: 'Unlock SpendWise IQ',
    );

    if (success) {
      emit(LockScreenState(attempt: state.attempt));
      _session.unlock();
    } else {
      emit(
        LockScreenState(status: LockStatus.failed, attempt: state.attempt + 1),
      );
    }
  }
}
