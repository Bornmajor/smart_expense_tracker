import 'package:flutter_bloc/flutter_bloc.dart';

import '../../../../core/errors/app_failure.dart';
import '../../../../core/errors/result.dart';
import '../../domain/repositories/security_repository.dart';
import '../../domain/usecases/enable_biometric_lock.dart';
import '../lock_session.dart';
import 'security_state.dart';

class SecurityCubit extends Cubit<SecurityState> {
  SecurityCubit(
    SecurityRepository repository,
    this._enableBiometricLock,
    this._session,
  ) : _repository = repository,
      super(SecurityState(enabled: repository.isBiometricEnabled));

  final SecurityRepository _repository;
  final EnableBiometricLock _enableBiometricLock;
  final LockSession _session;

  Future<void> setBiometricEnabled(bool enable) async {
    if (enable) {
      await _turnOn();
    } else {
      await _repository.setBiometricEnabled(false);
      _session.setEnabled(false);
      _emit(enabled: false, feedback: SecurityFeedback.turnedOff);
    }
  }

  Future<void> _turnOn() async {
    final result = await _enableBiometricLock();
    switch (result) {
      case Success():
        _session.setEnabled(true);
        _emit(enabled: true, feedback: SecurityFeedback.turnedOn);
      case Failure(failure: BiometricUnavailableFailure()):
        _emit(enabled: false, feedback: SecurityFeedback.unavailable);
      case Failure():
        _emit(enabled: false, feedback: SecurityFeedback.failed);
    }
  }

  void _emit({required bool enabled, required SecurityFeedback feedback}) {
    emit(
      SecurityState(
        enabled: enabled,
        feedback: feedback,
        attempt: state.attempt + 1,
      ),
    );
  }
}
